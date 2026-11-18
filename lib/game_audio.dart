import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_settings.dart';

enum BoardCue {
  place,
  turn,
  connect,
  disconnect,
  adjust,
  reject,
  alarm,
  solved,
}

/// Owns the music loop and reusable cue players across all puzzle boards.
class GameAudio extends StatefulWidget {
  const GameAudio({
    super.key,
    required this.onBoard,
    required this.settings,
    required this.child,
  });

  final bool onBoard;
  final AudioSettings settings;
  final Widget child;

  static void play(BuildContext context, BoardCue cue) =>
      context.getInheritedWidgetOfExactType<_AudioScope>()?.state._playCue(cue);

  @override
  State<GameAudio> createState() => _GameAudioState();
}

class _GameAudioState extends State<GameAudio> {
  late final AppLifecycleListener _lifecycle;
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptions;
  bool _focused = false;
  bool _interrupted = false;
  AudioPlayer? _music;
  final _effects = <BoardCue, AudioPlayer>{};
  Future<void> _pending = Future.value();

  bool get _onBoard =>
      mounted &&
      widget.onBoard &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  bool get _wantsAudio =>
      _onBoard &&
      (widget.settings.musicGain > 0 || widget.settings.effectsGain > 0);

  double get _musicGain =>
      _onBoard && !_interrupted ? widget.settings.musicGain : 0;

  double get _effectsGain =>
      _onBoard && !_interrupted ? widget.settings.effectsGain : 0;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: (_) => _enqueue(_sync));
    if (widget.onBoard) _enqueue(_sync);
  }

  @override
  void didUpdateWidget(GameAudio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onBoard != oldWidget.onBoard ||
        widget.settings != oldWidget.settings) {
      _enqueue(_sync);
    }
  }

  void _enqueue(Future<void> Function() operation) {
    _pending = _pending
        .then((_) async {
          if (mounted) await operation();
        })
        .catchError(_report);
  }

  Future<void> _sync() async {
    if (_musicGain > 0 && await _activate()) {
      final music = _music ??= await _load('ambient.wav', loop: true);
      if (_musicGain > 0) {
        if (music.volume != _musicGain) await music.setVolume(_musicGain);
        if (_musicGain > 0) _start(music);
      }
    }
    if (_musicGain == 0) await _music?.pause();
    for (final player in _effects.values) {
      if (_effectsGain == 0) {
        await player.pause();
      } else if (player.playing && player.volume != _effectsGain) {
        await player.setVolume(_effectsGain);
      }
    }
    if (!_wantsAudio) await _releaseFocus();
  }

  void _playCue(BoardCue cue) {
    if (_effectsGain == 0) return;
    _enqueue(() async {
      if (_effectsGain == 0 || !await _activate()) return;
      final player = _effects[cue] ??= await _load('${cue.name}.wav');
      await player.pause();
      await player.seek(Duration.zero);
      if (_effectsGain == 0) return;
      await player.setVolume(_effectsGain);
      if (_effectsGain > 0) _start(player);
    });
  }

  Future<bool> _activate() async {
    final session = _session ??= await _configureSession();
    if (!_wantsAudio || _interrupted) return false;
    return _focused || (_focused = await session.setActive(true));
  }

  Future<AudioSession> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.game,
        ),
      ),
    );
    _interruptions = session.interruptionEventStream.listen((event) {
      _interrupted = event.begin;
      _enqueue(_sync);
    });
    return session;
  }

  Future<void> _releaseFocus() async {
    if (_focused) await _session?.setActive(false);
    _focused = false;
    _interrupted = false;
  }

  Future<AudioPlayer> _load(String file, {bool loop = false}) async {
    final player = AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
    );
    try {
      await player.setAsset('assets/audio/$file');
      if (loop) await player.setLoopMode(LoopMode.one);
      return player;
    } catch (_) {
      await player.dispose();
      rethrow;
    }
  }

  // play() completes when playback stops. Keep the queue free to pause.
  void _start(AudioPlayer player) =>
      unawaited(player.play().catchError(_report));

  void _report(Object error) => debugPrint('Dark Port audio: $error');

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(
      _pending
          .then((_) async {
            await _interruptions?.cancel();
            await Future.wait([
              if (_music case final music?) music.dispose(),
              for (final player in _effects.values) player.dispose(),
            ]);
            await _releaseFocus();
          })
          .catchError(_report),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _AudioScope(state: this, child: widget.child);
}

class _AudioScope extends InheritedWidget {
  const _AudioScope({required this.state, required super.child});

  final _GameAudioState state;

  @override
  bool updateShouldNotify(_AudioScope oldWidget) => false;
}

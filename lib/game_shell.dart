import 'dart:async';

import 'package:flutter/material.dart';

import 'achievements.dart';
import 'achievements_screen.dart';
import 'drafting_controls.dart';
import 'drafting_theme.dart';
import 'endless_levels.dart';
import 'endless_picker.dart';
import 'game_audio.dart';
import 'game_save.dart';
import 'optical_bay.dart';
import 'optical_deck.dart';
import 'optical_room.dart';
import 'part_guide.dart';
import 'puzzle_announcements.dart';
import 'puzzle_console.dart';
import 'settings_screen.dart';
import 'sheet_style.dart';
import 'signal_room.dart';
import 'tutorial.dart';
import 'tutorial_picker.dart';
import 'tutorial_progress.dart';

class GameShell extends StatefulWidget {
  const GameShell({
    super.key,
    required this.store,
    this.settingsLoaded = true,
    this.audioEnabled = true,
  });

  final GameStore store;
  final bool settingsLoaded;
  final bool audioEnabled;

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  TutorialProgress? _progress;
  GameSave? _board;
  bool _replaying = false;
  bool _showLessonGuide = false;
  bool _showOpticalSection = false;
  bool _loading = true;
  bool _title = true;
  bool _endless = false;
  EndlessGroup? _endlessGroup;
  EndlessLevel? _endlessFocus;
  bool _restarting = false;
  bool _restartFailed = false;
  bool _loadFailed = false;
  int _writeRevision = 0;
  int _lessonSession = 0;
  TutorialLesson? _pickerFocus;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final progress = await widget.store.load();
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _error = null;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Your saved tutorial could not be read.';
        _loadFailed = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _write(TutorialProgress progress) async {
    final revision = ++_writeRevision;
    try {
      await widget.store.write(progress);
      if (!mounted) return false;
      if (revision == _writeRevision) setState(() => _error = null);
      return true;
    } catch (_) {
      if (!mounted) return false;
      if (revision == _writeRevision) {
        setState(() => _error = 'Progress could not be saved on this device.');
      }
      return false;
    }
  }

  void _changed(GameSave board) {
    final previous = _progress;
    setState(() {
      _board = board;
      if (_endless || !_replaying) {
        final progress = previous ?? TutorialProgress(tutorialStarted: false);
        _progress = _endless
            ? progress.recordEndless(board)
            : progress.record(board);
      }
    });
    final progress = _progress;
    if (progress == null || identical(previous, progress)) return;
    unawaited(_write(progress));
    if (!_endless || !board.solved) return;

    final level = endlessLevelsByLessonId[board.lesson.id]!;
    final before = previous?.resultFor(level)?.stars ?? const <String>{};
    final after = progress.resultFor(level)?.stars ?? const <String>{};
    final starConditions = [
      for (final entry in level.solutionConditions.entries)
        if (after.contains(entry.key) && !before.contains(entry.key))
          entry.value,
    ];
    final achievements = [
      for (final achievement in Achievement.values)
        if (achievement.isEarned(progress) && !achievement.isEarned(previous))
          achievement,
    ];
    if (starConditions.isNotEmpty || achievements.isNotEmpty) {
      unawaited(
        showPuzzleAwards(
          context,
          scenario: board.lesson.title,
          starConditions: starConditions,
          achievements: achievements,
        ),
      );
    }
  }

  Future<void> _restart() async {
    setState(() => _restarting = true);
    final fresh = TutorialProgress(
      endlessBoards: _progress?.endlessBoards ?? {},
      endlessResults: _progress?.endlessResults ?? {},
      opened: _progress?.opened ?? {},
    );
    final saved = await _write(fresh);
    if (!mounted) return;
    setState(() {
      _restarting = false;
      _restartFailed = !saved;
      if (saved) {
        _progress = fresh;
        _title = false;
        _board = null;
        _loadFailed = false;
        _pickerFocus = null;
      }
    });
  }

  Future<void> _newGame() async {
    if (_progress?.tutorialStarted == true || _loadFailed) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.sheet.paper,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.sheet.ink, width: 1.6),
          ),
          title: Text(
            'Start a new tutorial?',
            style: draftingLettering(16, color: context.sheet.ink, spacing: .4),
          ),
          content: Text(
            'This replaces the tutorial progress saved on this device.',
            style: draftingLettering(13, color: context.sheet.ink, spacing: .2),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: context.sheet.ink),
              child: const Text('Keep playing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: context.sheet.stamp),
              child: const Text('New game'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    await _restart();
  }

  void _openLesson(TutorialLesson lesson) {
    final progress = _progress!;
    if (!progress.isUnlocked(lesson)) return;
    _openBoard(
      lesson,
      saved: progress.boards[lesson.id],
      replay: progress.isComplete(lesson),
    );
  }

  void _openEndlessLevel(EndlessLevel level) {
    final lesson = level.lesson;
    if (lesson == null) return;
    final saved = _progress?.endlessBoards[lesson.id];
    _openBoard(
      lesson,
      saved: saved,
      replay: saved?.solved == true,
      endlessLevel: level,
    );
  }

  void _openBoard(
    TutorialLesson lesson, {
    GameSave? saved,
    required bool replay,
    EndlessLevel? endlessLevel,
  }) {
    final previous = _progress ?? TutorialProgress(tutorialStarted: false);
    final progress = previous.open(lesson);
    setState(() {
      _progress = progress;
      _endlessFocus = endlessLevel;
      _replaying = replay;
      _showLessonGuide =
          endlessLevel == null && !previous.opened.contains(lesson.id);
      _showOpticalSection = false;
      _board = replay ? GameSave(lesson) : saved ?? GameSave(lesson);
      _lessonSession++;
    });
    if (!identical(progress, previous)) unawaited(_write(progress));
  }

  void _startLesson() => setState(() => _showLessonGuide = false);

  void _openEndlessGroup(EndlessGroup group) => setState(() {
    _endlessGroup = group;
    _endlessFocus = null;
  });

  void _showEndlessGroups() => setState(() {
    _endlessGroup = null;
    _endlessFocus = null;
  });

  void _showPicker() => setState(() {
    final lesson = _board?.lesson;
    _pickerFocus =
        !_endless && (_replaying || practiceLessons.containsKey(lesson))
        ? lesson
        : null;
    _board = null;
  });

  Widget _lessonRoom(GameSave board) {
    final index = requiredLessons.indexOf(board.lesson);
    final progressing = !_replaying && index >= 0;
    final next = progressing
        ? requiredLessons
              .skip(index + 1)
              .where((lesson) => !_progress!.isComplete(lesson))
              .firstOrNull
        : null;
    void advance() {
      if (_board?.solved != true) return;
      if (next == null) {
        _showPicker();
      } else {
        _openLesson(next);
      }
    }

    final lesson = board.lesson;
    final endlessLevel = endlessLevelsByLessonId[lesson.id];
    final result = endlessLevel == null
        ? null
        : _progress?.resultFor(endlessLevel);
    final brief = PuzzleBrief(
      title: lesson.title,
      sheet: endlessLevel == null
          ? sheetOfSet(lesson)
          : endlessLevel.group.sheetNumber(endlessLevel),
      objective: lesson.objective,
      goal: lesson.goal,
      notes: lesson.notes,
      stars: endlessLevel?.starsFor(result?.stars ?? const {}) ?? const [],
      achievements: [
        for (final achievement in Achievement.values)
          if (endlessLevel != null && achievement.blueprint == endlessLevel)
            (achievement: achievement, earned: achievement.isEarned(_progress)),
      ],
    );
    final navigation = PuzzleNavigation(
      backLabel: _endless ? 'Back to puzzles' : 'Back to tutorial',
      onBack: _showPicker,
      backIcon: _endless ? Icons.account_tree_outlined : Icons.arrow_back,
      onStartLesson: _showLessonGuide ? _startLesson : null,
      circuits: board.opticalBoard != null && board.signal != null
          ? (
              opticalSelected: _showOpticalSection,
              wiredSolved: board.signal!.solved,
              opticalSolved: board.opticsSolved,
              selectOptical: (optical) =>
                  setState(() => _showOpticalSection = optical),
            )
          : null,
      advance: progressing
          ? (
              label: next == null ? 'Finish tutorial' : 'Next lesson',
              icon: next == null ? Icons.check : Icons.arrow_forward,
              onPressed: advance,
            )
          : null,
    );
    final revealedParts = {
      for (final revealed
          in _progress?.openedLessons ?? const <TutorialLesson>[])
        ...switch (revealed) {
          OpticalLesson(:final board, :final wiredBoard) => {
            ...opticalGuideParts(board),
            if (wiredBoard != null) ...signalGuideParts(wiredBoard),
          },
          WiredLesson(:final board) => signalGuideParts(board),
        },
    };
    switch (lesson) {
      case OpticalLesson():
        final signal = board.signal;
        final optical = OpticalRoom(
          level: lesson.board,
          layout: board.layout,
          brief: brief,
          navigation: navigation,
          revealedParts: revealedParts,
          otherSectionSolved: signal?.solved ?? true,
          otherSectionParts: signal == null
              ? const {}
              : signalGuideParts(signal.board),
          onChange: (layout) => _changed(
            signal == null
                ? GameSave(lesson, layout: layout)
                : GameSave.fromSignal(lesson, _board!.signal!, layout: layout),
          ),
        );
        if (signal == null) {
          return KeyedSubtree(key: ValueKey(_lessonSession), child: optical);
        }
        return IndexedStack(
          key: ValueKey(_lessonSession),
          index: _showOpticalSection ? 1 : 0,
          sizing: StackFit.expand,
          children: [
            SignalRoom(
              boardState: signal,
              brief: brief,
              navigation: navigation,
              revealedParts: revealedParts,
              otherSectionSolved: board.opticsSolved,
              otherSectionParts: opticalGuideParts(lesson.board),
              onChange: (state) => _changed(
                GameSave.fromSignal(lesson, state, layout: _board!.layout),
              ),
            ),
            optical,
          ],
        );
      case WiredLesson():
        return SignalRoom(
          key: ValueKey(_lessonSession),
          boardState: board.signal!,
          brief: brief,
          navigation: navigation,
          revealedParts: revealedParts,
          onChange: (state) => _changed(GameSave.fromSignal(lesson, state)),
        );
    }
  }

  void _retry() {
    if (_restartFailed) {
      unawaited(_restart());
    } else if (_loadFailed) {
      unawaited(_load());
    } else if (_progress case final progress?) {
      unawaited(_write(progress));
    }
  }

  void _openTitle() => setState(() {
    _title = true;
    _endless = false;
    _endlessGroup = null;
    _endlessFocus = null;
    if (_restartFailed) {
      _restartFailed = false;
      if (!_loadFailed) _error = null;
    }
  });

  @override
  Widget build(BuildContext context) {
    final console = _console(context);
    if (!widget.audioEnabled) return console;
    return GameAudio(
      onBoard: widget.settingsLoaded && !_title && _board != null,
      settings: SheetLook.of(context).audio,
      child: console,
    );
  }

  Widget _console(BuildContext context) {
    final board = _board;
    final group = _endlessGroup;
    final safeArea = MediaQuery.paddingOf(context);
    return PopScope(
      canPop: _title && !_restarting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_title && !_restarting) {
          if (board != null) {
            if (_showLessonGuide) {
              _startLesson();
            } else {
              _showPicker();
            }
          } else if (group != null) {
            _showEndlessGroups();
          } else {
            _openTitle();
          }
        }
      },
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: _restarting,
            child: _title
                ? _titleConsole()
                : board != null
                ? _lessonRoom(board)
                : _endless
                ? group == null
                      ? EndlessGroups(
                          onBack: _openTitle,
                          onOpen: _openEndlessGroup,
                        )
                      : EndlessPicker(
                          group: group,
                          onBack: _showEndlessGroups,
                          onOpen: _openEndlessLevel,
                          progress: _progress,
                          focus: _endlessFocus,
                        )
                : TutorialPicker(
                    progress: _progress!,
                    onBack: _openTitle,
                    onOpen: _openLesson,
                    focusLesson: _pickerFocus,
                  ),
          ),
          if (_error != null)
            Positioned(
              left: safeArea.left + 12,
              right: safeArea.right + 12,
              top: safeArea.top + 4,
              child: Material(
                color: context.sheet.paper,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 5, 4, 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: draftingLettering(
                            12,
                            color: context.sheet.stamp,
                            spacing: .2,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _restarting || _loading ? null : _retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_restarting)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }

  Widget _titleConsole() => DraftingScaffold(
    child: DraftingSheet(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = useConsoleColumns(constraints);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1040 : 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: wide
                    ? Row(
                        children: [
                          const Expanded(
                            flex: 6,
                            child: _TitleViewport(height: 250),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _titleHeading(40),
                                const SizedBox(height: 22),
                                _titleMenu(),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _titleHeading(
                            (constraints.maxWidth * .1).clamp(28, 48),
                          ),
                          const SizedBox(height: 24),
                          const _TitleViewport(height: 215),
                          const SizedBox(height: 24),
                          _titleMenu(),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _titleHeading(double titleSize) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('DARK PORT', style: draftingLettering(titleSize, spacing: 6)),
      const SizedBox(height: 8),
      Text(
        'PUZZLES IN LIGHT AND SIGNAL',
        style: draftingLettering(11, color: context.sheet.faint, spacing: 2),
      ),
    ],
  );

  Widget _titleMenu() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_loading)
        Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: context.sheet.ink,
          ),
        )
      else ...[
        if (_progress?.tutorialStarted == true)
          _action('Continue game', () {
            setState(() {
              _title = false;
              if (_restartFailed) {
                _restartFailed = false;
                _error = null;
              }
            });
            _showPicker();
          }),
        _action('New game', _newGame),
        if (!_loadFailed) ...[
          _action(
            'Endless',
            () => setState(() {
              _title = false;
              _endless = true;
            }),
          ),
          _action(
            'Achievements',
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AchievementsScreen(progress: _progress),
              ),
            ),
          ),
        ],
      ],
      const SizedBox(height: 12),
      Wrap(
        spacing: 4,
        children: [
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: context.sheet.paper,
              showDragHandle: true,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: context.sheet.ink, width: 1.2),
              ),
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DARK PORT',
                        style: draftingLettering(
                          22,
                          color: context.sheet.ink,
                          spacing: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Route light and wired signals through a series of hands-on lessons.',
                        style: draftingLettering(
                          14,
                          color: context.sheet.ink,
                          spacing: .2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your progress is saved on this device.',
                        style: draftingLettering(
                          12,
                          color: context.sheet.faint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: Text(
              'About',
              style: draftingLettering(
                12,
                color: context.sheet.faint,
                spacing: .6,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            child: Text(
              'Settings',
              style: draftingLettering(
                12,
                color: context.sheet.faint,
                spacing: .6,
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _action(String label, VoidCallback onPressed) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        iconAlignment: IconAlignment.end,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.sheet.ink,
          side: BorderSide(color: context.sheet.ink, width: .9),
          shape: const RoundedRectangleBorder(),
          minimumSize: const Size(44, 48),
          alignment: Alignment.centerLeft,
        ),
        icon: const Icon(Icons.arrow_forward, size: 16),
        label: Text(label, style: draftingLettering(14, spacing: .6)),
      ),
    ),
  );
}

/// The cover figure: First reflection as a solved drawing.
class _TitleViewport extends StatelessWidget {
  const _TitleViewport({required this.height});

  final double height;

  static final _layout = [
    reflectionLesson.initial.first,
    reflectionLesson.initial.last.at(const FloorPoint(1.05, -.27)).rotate(),
  ];
  static final _trace = traceOptics(reflectionLesson, _layout);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height),
            child: AspectRatio(
              aspectRatio: 1.65,
              child: LayoutBuilder(
                builder: (context, constraints) => OpticalDeck(
                  geometry: OpticalDeckGeometry(
                    reflectionLesson,
                    constraints.biggest,
                  ),
                  layout: _layout,
                  trace: _trace,
                  held: null,
                  dropSpot: null,
                  validDrop: false,
                  opened: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'FIG. 1  FIRST REFLECTION',
            style: draftingLettering(
              9,
              color: context.sheet.faint,
              spacing: 1.6,
            ),
          ),
        ],
      ),
    ),
  );
}

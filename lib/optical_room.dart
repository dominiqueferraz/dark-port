import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'board_history.dart';
import 'drafting_controls.dart';
import 'drafting_grid.dart';
import 'drafting_parts.dart';
import 'drafting_theme.dart';
import 'optical_bay.dart';
import 'optical_deck.dart';
import 'part_guide.dart';
import 'part_symbols.dart';
import 'puzzle_console.dart';
import 'sheet_style.dart';

class OpticalRoom extends StatefulWidget {
  const OpticalRoom({
    super.key,
    required this.level,
    required this.layout,
    required this.brief,
    required this.navigation,
    required this.onChange,
  });

  final OpticalLevel level;
  final List<Optic> layout;
  final PuzzleBrief brief;
  final PuzzleNavigation navigation;
  final ValueChanged<List<Optic>> onChange;

  @override
  State<OpticalRoom> createState() => _OpticalRoomState();
}

class _OpticalRoomState extends State<OpticalRoom> with WidgetsBindingObserver {
  OpticalLevel get _level => widget.level;
  double get _playfieldAspectRatio =>
      _level.floor.width / _level.floor.height * .9;
  late List<Optic> _layout = List.unmodifiable(widget.layout);
  late OpticalTrace _trace = traceOptics(_level, _layout);
  final _history = BoardHistory<List<Optic>>();
  Optic? _held;
  GridSpot? _dropSpot;
  Offset? _grabOffset;
  var _validDrop = false;
  bool get _opened => _held == null && _trace.solves(_level);
  bool get _alarmFailed => _held == null && _trace.interruptsAlarm(_level);
  bool get _canEdit => _held == null && !_opened && !_alarmFailed;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _held != null) {
      _finishDrag(cancel: true);
    }
  }

  void _persist() => widget.onChange(_layout);

  void _reset() {
    setState(() {
      _history.record(_layout);
      _layout = List.unmodifiable(_level.initial);
      _held = null;
      _dropSpot = null;
      _grabOffset = null;
      _validDrop = false;
      _message = null;
      _trace = traceOptics(_level, _layout);
      _persist();
    });
  }

  List<Optic> _replace(Optic optic) => List.unmodifiable(
    _layout.map((other) => other.id == optic.id ? optic : other),
  );

  void _commit(Optic optic) {
    _history.record(_layout);
    _layout = _replace(optic);
    _trace = traceOptics(_level, _layout);
    _message = null;
    _persist();
  }

  void _restore(List<Optic> layout) => setState(() {
    _layout = layout;
    _trace = traceOptics(_level, _layout);
    _message = null;
    _persist();
  });

  Optic? _hit(OpticalDeckGeometry geometry, Offset pointer) {
    Optic? nearest;
    var distance = double.infinity;
    for (final optic in _layout) {
      final center = geometry.project(optic.position);
      final delta = (center - pointer).distance;
      if (delta <= 24 && delta < distance) {
        nearest = optic;
        distance = delta;
      }
    }
    return nearest;
  }

  void _rotate(Optic optic) {
    if (!_canEdit || optic.fixed) return;
    setState(() => _commit(optic.rotate()));
  }

  void _tap(OpticalDeckGeometry geometry, Offset pointer) {
    final optic = _hit(geometry, pointer);
    if (optic != null) _rotate(optic);
  }

  void _pick(OpticalDeckGeometry geometry, Offset pointer) {
    if (!_canEdit) return;
    final optic = _hit(geometry, pointer);
    if (optic == null || optic.fixed) return;
    setState(() {
      _held = optic;
      _dropSpot = _level.snapAt(optic.position);
      _grabOffset = pointer - geometry.project(optic.position);
      _validDrop = true;
      _message = null;
    });
  }

  void _move(OpticalDeckGeometry geometry, Offset pointer) {
    final held = _held;
    if (held == null) return;
    setState(() {
      final position = geometry.unproject(pointer - _grabOffset!);
      final spot = position == null ? null : _level.snapAt(position);
      _dropSpot = spot;
      final move = spot == null ? null : held.at(spot.position);
      _validDrop = move != null && _level.canPlace(move, _layout);
      if (move != null) _held = move;
      _trace = traceOptics(
        _level,
        _validDrop
            ? _replace(move!)
            : _layout.where((optic) => optic.id != held.id).toList(),
      );
    });
  }

  void _finishDrag({bool cancel = false}) {
    final held = _held;
    if (held == null) return;
    final original = _layout.firstWhere((optic) => optic.id == held.id);
    setState(() {
      if (!cancel &&
          _validDrop &&
          held.position.distanceTo(original.position) > 1e-8) {
        _commit(held);
      } else {
        _trace = traceOptics(_level, _layout);
        if (!cancel && !_validDrop) {
          _message = 'Choose a clear placement dot.';
        }
      }
      _held = null;
      _dropSpot = null;
      _grabOffset = null;
      _validDrop = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final idle = _held == null;
    return PuzzleConsole(
      brief: widget.brief,
      navigation: widget.navigation,
      tools: ConsoleTools(
        onUndo: idle && _history.canUndo
            ? () => _restore(_history.undo(_layout))
            : null,
        onRedo: idle && _history.canRedo
            ? () => _restore(_history.redo(_layout))
            : null,
        onReset: idle ? _reset : null,
      ),
      playfield: _playfield(),
      readings: _partsList(),
      canLeave: idle,
      onHelp: () => showPartGuide(context, wiredFirst: false),
      solved: _opened,
      feedback: [?_status()],
    );
  }

  Widget _playfield() => DraftingPlayfield(
    aspectRatio: _playfieldAspectRatio,
    builder: (context, size) {
      final geometry = OpticalDeckGeometry(_level, size, fill: true);
      return Listener(
        // Flutter reports a cancelled, accepted pan through onPanEnd.
        onPointerCancel: (_) => _finishDrag(cancel: true),
        child: GestureDetector(
          key: const ValueKey('optical-deck'),
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onTapUp: (event) => _tap(geometry, event.localPosition),
          onPanStart: (event) => _pick(geometry, event.localPosition),
          onPanUpdate: (event) => _move(geometry, event.localPosition),
          onPanEnd: (_) => _finishDrag(),
          onPanCancel: () => _finishDrag(cancel: true),
          child: Stack(
            fit: StackFit.expand,
            children: [
              OpticalDeck(
                geometry: geometry,
                layout: _layout,
                trace: _trace,
                held: _held,
                dropSpot: _dropSpot,
                validDrop: _validDrop,
                opened: _opened,
              ),
              for (final optic in _layout) _semanticOptic(geometry, optic),
            ],
          ),
        ),
      );
    },
  );

  Widget _partsList() => DraftingPartsList(
    rows: [
      const DraftingPartRow(
        number: '$laserPartNumber',
        name: 'LASER SOURCE',
        state: '100 U',
        symbol: OpticalPartSymbol.source(),
      ),
      for (final (index, optic) in _layout.indexed) _opticRow(index, optic),
      for (var index = 0; index < _level.receivers.length; index++)
        _receiverReading(index),
    ],
  );

  Widget _opticRow(int index, Optic optic) {
    final shown = optic.id == _held?.id ? _held! : optic;
    final kind = optic.kind.label.toUpperCase();
    return DraftingPartRow(
      number: '${opticPartNumber(index)}',
      name: kind,
      state: optic.fixed
          ? 'FIXED'
          : 'AT ${opticalZone(_level, shown.position)}',
      symbol: OpticalPartSymbol.optic(
        shown.kind,
        turned: shown.turned,
        fixed: shown.fixed,
      ),
    );
  }

  Widget _receiverReading(int index) {
    final receiver = _level.receivers[index];
    final lit = _trace.lit.contains(index);
    final alarm = _level.alarms.contains(index);
    final mustBeDark = _level.dark.contains(index);
    final current = lightUnits(_trace.receivedPower(index) * 100);
    return Semantics(
      key: ValueKey('optical-goal-$index'),
      container: true,
      label: '${receiver.label}. Target ${mustBeDark ? 'dark' : 'lit'}.',
      value: '$current light units, ${lit ? 'lit' : 'dark'}',
      excludeSemantics: true,
      child: DraftingPartRow(
        number: '${receiverPartNumber(index, _layout.length)}',
        name: [
          receiver.label.toUpperCase(),
          if (alarm && !receiver.label.toLowerCase().contains('alarm'))
            '(ALARM)',
        ].join(' '),
        state: '$current U / ${mustBeDark ? '0' : '>0'}',
        symbol: OpticalPartSymbol.receiver(lit: lit, alarm: alarm),
        tone: lit != mustBeDark
            ? (alarm ? PartTone.alarmLit : PartTone.lit)
            : alarm
            ? PartTone.warning
            : PartTone.plain,
      ),
    );
  }

  Widget? _status() {
    if (_opened) return null;
    final sheet = context.sheet;
    final held = _held != null;
    final alarmFailed = _alarmFailed;
    final alarmAtRisk = held && _validDrop && _trace.interruptsAlarm(_level);
    final status =
        _message ??
        (held
            ? (alarmAtRisk
                  ? 'This placement would cut power to the alarm.'
                  : _validDrop
                  ? 'Release to place.'
                  : 'Choose a clear placement dot.')
            : alarmFailed
            ? (!_history.canUndo
                  ? 'Alarm line interrupted. Reset the room to try again.'
                  : 'Alarm line interrupted. Undo or reset to try again.')
            : null);
    if (status == null) return null;
    return Semantics(
      liveRegion: true,
      child: Text(
        status,
        style: draftingLettering(
          11,
          spacing: .3,
          color: alarmFailed || alarmAtRisk ? sheet.stamp : sheet.faint,
        ),
      ),
    );
  }

  Widget _semanticOptic(OpticalDeckGeometry geometry, Optic optic) {
    final p = geometry.project(optic.position);
    return Positioned(
      left: p.dx - 22,
      top: p.dy - 22,
      width: 44,
      height: 44,
      child: Semantics(
        label: optic.fixed
            ? 'Fixed ${optic.kind.label.toLowerCase()}'
            : '${optic.kind.label} ${optic.id}',
        button: !optic.fixed,
        hint: optic.fixed ? null : 'Rotate',
        onTap: !optic.fixed && _canEdit ? () => _rotate(optic) : null,
        child: const SizedBox.expand(),
      ),
    );
  }
}

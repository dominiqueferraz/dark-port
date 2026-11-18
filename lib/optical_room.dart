import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'board_history.dart';
import 'drafting_controls.dart';
import 'drafting_grid.dart';
import 'drafting_parts.dart';
import 'drafting_theme.dart';
import 'fabrication_controls.dart';
import 'fabrication_socket.dart';
import 'game_audio.dart';
import 'optical_bay.dart';
import 'optical_deck.dart';
import 'part_guide.dart';
import 'part_symbols.dart';
import 'puzzle_console.dart';
import 'sheet_style.dart';
import 'splitter_blueprint.dart';

class OpticalRoom extends StatefulWidget {
  const OpticalRoom({
    super.key,
    required this.level,
    required this.layout,
    required this.brief,
    required this.navigation,
    required this.onChange,
    this.revealedParts = const {},
    this.openWorkbench,
    this.otherSectionSolved = true,
    this.otherSectionParts = const {},
  });

  final OpticalLevel level;
  final List<Optic> layout;
  final PuzzleBrief brief;
  final PuzzleNavigation navigation;
  final ValueChanged<List<Optic>> onChange;
  final Set<GuidePart> revealedParts;
  final Future<SplitterBlueprint?> Function(
    FabricationSocket<SplitterBlueprint>, {
    required bool insert,
  })?
  openWorkbench;
  final bool otherSectionSolved;
  final Set<GuidePart> otherSectionParts;

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
      GameAudio.play(context, BoardCue.adjust);
    });
  }

  List<Optic> _replace(Optic optic) => List.unmodifiable(
    _layout.map((other) => other.id == optic.id ? optic : other),
  );

  void _commit(Optic optic, [BoardCue cue = BoardCue.place]) {
    _history.record(_layout);
    _layout = _replace(optic);
    _trace = traceOptics(_level, _layout);
    _message = null;
    _persist();
    GameAudio.play(context, cue);
    if (_trace.interruptsAlarm(_level)) {
      GameAudio.play(context, BoardCue.alarm);
    } else if (widget.otherSectionSolved && _trace.solves(_level)) {
      GameAudio.play(context, BoardCue.solved);
    }
  }

  void _restore(List<Optic> layout) => setState(() {
    _layout = layout;
    _trace = traceOptics(_level, _layout);
    _message = null;
    _persist();
    GameAudio.play(context, BoardCue.adjust);
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
    if (!_canEdit || optic.fixed || optic.converter != null) return;
    setState(() => _commit(optic.rotate(), BoardCue.turn));
  }

  void _activate(Optic optic) {
    if (optic.fabricationSocket != null && optic.blueprint == null) {
      _fitBlueprint(optic);
    } else {
      _rotate(optic);
    }
  }

  Future<void> _fitBlueprint(Optic optic, {bool insert = true}) async {
    final socket = optic.fabricationSocket;
    if (!_canEdit || socket == null) return;
    final design = await widget.openWorkbench?.call(socket, insert: insert);
    if (!mounted ||
        !_canEdit ||
        design == null ||
        !socket.accepts(design) ||
        design == optic.blueprint) {
      return;
    }
    setState(() => _commit(optic.fit(design)));
  }

  void _tap(OpticalDeckGeometry geometry, Offset pointer) {
    final optic = _hit(geometry, pointer);
    if (optic != null) _activate(optic);
  }

  void _pick(OpticalDeckGeometry geometry, Offset pointer) {
    if (!_canEdit) return;
    final optic = _hit(geometry, pointer);
    if (optic == null || !_level.canMove(optic)) return;
    setState(() {
      _held = optic;
      _dropSpot = _level.snapAt(optic.position, id: optic.id);
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
      final spot = position == null
          ? null
          : _level.snapAt(position, id: held.id);
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
          GameAudio.play(context, BoardCue.reject);
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
    final sockets = _layout.where((optic) => optic.fabricationSocket != null);
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
      gridBounds: (size) => _geometry(size).floorRect,
      readings: _partsList(),
      inventory: sockets.isEmpty || widget.openWorkbench == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                for (final optic in sockets)
                  FabricationControls(
                    label: sockets.length > 1 ? optic.id : null,
                    empty: optic.blueprint == null,
                    onWorkbench: _canEdit
                        ? () => _fitBlueprint(optic, insert: false)
                        : null,
                    onInsert: _canEdit ? () => _fitBlueprint(optic) : null,
                  ),
              ],
            ),
      canLeave: idle,
      onHelp: () => showPartGuide(
        context,
        puzzleParts: {
          ...opticalGuideParts(_level),
          ...widget.otherSectionParts,
        },
        revealedParts: widget.revealedParts,
      ),
      solved: _opened && widget.otherSectionSolved,
      failureMessage: !_alarmFailed
          ? null
          : _history.canUndo
          ? 'Alarm line interrupted. Undo or reset to try again.'
          : 'Alarm line interrupted. Reset the room to try again.',
      feedback: [?_status()],
    );
  }

  OpticalDeckGeometry _geometry(Size size) =>
      OpticalDeckGeometry(_level, size, fill: widget.openWorkbench == null);

  Widget _playfield() => DraftingPlayfield(
    aspectRatio: _playfieldAspectRatio,
    builder: (context, size) {
      final geometry = _geometry(size);
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
                awardBounds: widget.brief.awardBounds.shift(
                  geometry.floorRect.topLeft,
                ),
              ),
              for (final optic in _layout) _semanticOptic(geometry, optic),
            ],
          ),
        ),
      );
    },
  );

  Widget _partsList() {
    final receivers = [
      for (var index = 0; index < _level.receivers.length; index++)
        _receiverReading(index),
    ];
    final showTargetsFirst = _level.receivers.any(
      (sensor) => sensor.requiredPower != null,
    );
    return DraftingPartsList(
      rows: [
        if (showTargetsFirst) ...receivers,
        for (final (index, antenna) in _level.antennas.indexed)
          _antennaReading(index, antenna),
        for (final (index, optic) in _layout.indexed)
          if (optic.converter != null) _opticRow(index, optic),
        for (final (index, source) in _level.sources.indexed)
          DraftingPartRow(
            number: _level.additionalSources.isEmpty
                ? '${index + 1}'
                : source.label,
            name: 'LASER SOURCE',
            state: '100 U',
            symbol: const OpticalPartSymbol.source(),
          ),
        for (final (index, optic) in _layout.indexed)
          if (optic.converter == null) _opticRow(index, optic),
        if (!showTargetsFirst) ...receivers,
      ],
    );
  }

  Widget _opticRow(int index, Optic optic) {
    final shown = optic.id == _held?.id ? _held! : optic;
    if (shown.converter case final converter?) {
      return _converterReading(index, shown, converter);
    }
    final design = shown.blueprint;
    final kind = design == null || design.mark.name.isEmpty
        ? (design?.partName ?? optic.kind.label).toUpperCase()
        : design.partName;
    final emptySocket = shown.fabricationSocket != null && design == null;
    final portAngles = design == null
        ? null
        : (shown.turned ? design.mirrored : design).label;
    return DraftingPartRow(
      number: '${opticPartNumber(_level, index)}',
      name: emptySocket ? 'WORKBENCH SOCKET' : kind,
      state: emptySocket
          ? 'EMPTY SOCKET'
          : portAngles ??
                (optic.fixed
                    ? 'FIXED'
                    : 'AT ${opticalZone(_level, shown.position)}'),
      symbol: OpticalPartSymbol.optic(
        shown.kind,
        turned: shown.turned,
        fixed: shown.fixed,
        fitted: design != null,
        mark: design?.mark.icon,
      ),
    );
  }

  Widget _converterReading(int index, Optic optic, OpticalConverter converter) {
    final reading = _trace.converterInputs[optic.id];
    final status = reading?.status ?? ConverterReception.quiet;
    final input = reading?.power ?? 0;
    final received = reading?.source;
    final expected = converter.requiredSource;
    final details = [
      status.label,
      'Channel ${converter.channel}',
      if (expected != null) 'Requires laser $expected',
      if (received != null && _level.additionalSources.isNotEmpty)
        'Received laser $received',
      if (converter.power case final required?)
        'Input target ${lightUnits(required)} u',
    ].join(' · ');
    return DraftingPartRow(
      key: ValueKey('converter-reading-${optic.id}'),
      number: expected ?? '${opticPartNumber(_level, index)}',
      name: 'CONVERTER · CH ${converter.channel}',
      state: '${lightUnits(input)} U IN',
      status: details,
      tone: switch (status) {
        ConverterReception.accepted => PartTone.lit,
        ConverterReception.quiet => PartTone.plain,
        _ => PartTone.warning,
      },
      symbol: ConverterSymbol(
        transmitting: status == ConverterReception.accepted,
      ),
    );
  }

  Widget _antennaReading(int index, OpticalAntenna antenna) {
    final reading = _trace.radioReadings[index];
    final accepted = reading.status == RadioReception.accepted;
    final diagnostic = [
      reading.status.label,
      if (reading.hop case final hop?) ...[
        '${lightUnits(reading.distance!)} of ${lightUnits(hop.reach)} grid steps',
        if (hop.channel != antenna.channel) 'Received channel ${hop.channel}',
      ],
    ].join(' · ');
    final power = lightUnits(reading.power);
    final target = lightUnits(antenna.minimum);
    return Semantics(
      key: ValueKey('optical-antenna-$index'),
      container: true,
      label:
          '${antenna.label}. Channel ${antenna.channel}. Target at least $target units.',
      value: '$power units. $diagnostic.',
      excludeSemantics: true,
      child: DraftingPartRow(
        number: '${antennaPartNumber(_level, index)}',
        name: '${antenna.label.toUpperCase()} · CH ${antenna.channel}',
        state: '$power / ≥$target U',
        status: diagnostic,
        tone: accepted
            ? PartTone.lit
            : reading.status == RadioReception.quiet
            ? PartTone.plain
            : PartTone.warning,
        symbol: OpticalAntennaSymbol(lit: accepted),
      ),
    );
  }

  Widget _receiverReading(int index) {
    final receiver = _level.receivers[index];
    final lit = _trace.lit.contains(index);
    final alarm = _level.alarms.contains(index);
    final mustBeDark = _level.dark.contains(index);
    final current = lightUnits(_trace.receivedPower(index) * 100);
    final power = receiver.requiredPower;
    final target = mustBeDark
        ? '0'
        : power == null
        ? '>0'
        : lightUnits(power);
    final onTarget = _trace.meetsGoal(_level, index);
    return Semantics(
      key: ValueKey('optical-goal-$index'),
      container: true,
      label:
          '${receiver.label}. Target ${mustBeDark
              ? 'dark'
              : power == null
              ? 'lit'
              : '$target light units'}.',
      value: '$current light units, ${lit ? 'lit' : 'dark'}',
      excludeSemantics: true,
      child: DraftingPartRow(
        number: '${receiverPartNumber(_level, index)}',
        name: [
          receiver.label.toUpperCase(),
          if (alarm && !receiver.label.toLowerCase().contains('alarm'))
            '(ALARM)',
        ].join(' '),
        state: '$current U / $target',
        symbol: OpticalPartSymbol.receiver(lit: lit, alarm: alarm),
        tone: onTarget
            ? (alarm ? PartTone.alarmLit : PartTone.lit)
            : alarm
            ? PartTone.warning
            : PartTone.plain,
      ),
    );
  }

  Widget? _status() {
    if (_opened || _alarmFailed) return null;
    final sheet = context.sheet;
    final held = _held != null;
    final alarmAtRisk = held && _validDrop && _trace.interruptsAlarm(_level);
    final radio = _trace.radioReadings.indexed
        .where(
          (entry) =>
              entry.$2.status != RadioReception.accepted &&
              entry.$2.status != RadioReception.quiet,
        )
        .firstOrNull;
    final converter = _trace.converterInputs.entries
        .where(
          (entry) =>
              entry.value.status == ConverterReception.wrongSource ||
              entry.value.status == ConverterReception.wrongPower,
        )
        .firstOrNull;
    final status =
        _message ??
        (held
            ? (alarmAtRisk
                  ? 'This placement would cut power to the alarm.'
                  : _validDrop
                  ? 'Release to place.'
                  : 'Choose a clear placement dot.')
            : radio != null
            ? '${_level.antennas[radio.$1].label} · ${radio.$2.status.label}'
            : converter != null
            ? 'Converter ${_layout.firstWhere((optic) => optic.id == converter.key).converter?.requiredSource ?? converter.key} · ${converter.value.status.label}'
            : null);
    if (status == null) return null;
    return Semantics(
      liveRegion: true,
      child: Text(
        status,
        style: draftingLettering(
          11,
          spacing: .3,
          color: alarmAtRisk ? sheet.stamp : sheet.faint,
        ),
      ),
    );
  }

  Widget _semanticOptic(OpticalDeckGeometry geometry, Optic optic) {
    final p = geometry.project(optic.position);
    final converter = optic.converter;
    final canRotate = !optic.fixed && converter == null;
    final emptySocket =
        optic.fabricationSocket != null && optic.blueprint == null;
    final moves = <CustomSemanticsAction, VoidCallback>{
      if (_canEdit && _level.canMove(optic))
        for (final spot in _level.mounts[optic.id] ?? const <GridSpot>[])
          if (spot.position != optic.position &&
              _level.canPlace(optic.at(spot.position), _layout))
            CustomSemanticsAction(
              label: 'Move to ${opticalZone(_level, spot.position)}',
            ): () =>
                setState(() => _commit(optic.at(spot.position))),
    };
    return Positioned(
      left: p.dx - 22,
      top: p.dy - 22,
      width: 44,
      height: 44,
      child: Semantics(
        label: converter != null
            ? 'Converter ${converter.requiredSource ?? optic.id}, channel ${converter.channel}'
            : optic.blueprint != null
            ? optic.blueprint!.partName
            : optic.fixed
            ? 'Fixed ${optic.kind.label.toLowerCase()}'
            : '${optic.kind.label} ${optic.id}',
        button: canRotate || emptySocket,
        hint: emptySocket
            ? 'Insert fabricated part'
            : canRotate
            ? 'Rotate'
            : null,
        onTap: (canRotate || emptySocket) && _canEdit
            ? () => _activate(optic)
            : null,
        customSemanticsActions: moves,
        child: const SizedBox.expand(),
      ),
    );
  }
}

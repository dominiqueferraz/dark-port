import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'board_history.dart';
import 'drafting_controls.dart';
import 'drafting_parts.dart';
import 'drafting_theme.dart';
import 'game_audio.dart';
import 'part_guide.dart';
import 'lead_stock.dart';
import 'placement_nodes.dart';
import 'puzzle_console.dart';
import 'sheet_style.dart';
import 'signal_board.dart';
import 'signal_board_state.dart';
import 'signal_component.dart';
import 'signal_playfield.dart';

typedef _PartDrag = ({String id, Offset grab, PlacementNode? node});

enum _RadioFailure {
  range('Out of coverage', 'The antenna is outside radio coverage.'),
  concrete('Blocked by concrete', 'Concrete blocks the radio path.');

  const _RadioFailure(this.status, this.warning);

  final String status;
  final String warning;
}

class _PartPan extends Drag {
  _PartPan(this._position, this.onUpdate, this.onFinish);

  Offset _position;
  final ValueChanged<Offset> onUpdate;
  final ValueChanged<bool> onFinish;

  @override
  void update(DragUpdateDetails details) {
    // The first multi-drag update reports accumulated movement from pointer down.
    _position += details.delta;
    onUpdate(_position);
  }

  @override
  void end(DragEndDetails details) => onFinish(false);

  @override
  void cancel() => onFinish(true);
}

class SignalRoom extends StatefulWidget {
  const SignalRoom({
    super.key,
    required this.boardState,
    required this.brief,
    required this.navigation,
    required this.onChange,
    this.revealedParts = const {},
    this.otherSectionSolved = true,
    this.otherSectionParts = const {},
  });

  final SignalBoardState boardState;
  final PuzzleBrief brief;
  final PuzzleNavigation navigation;
  final ValueChanged<SignalBoardState> onChange;
  final Set<GuidePart> revealedParts;
  final bool otherSectionSolved;
  final Set<GuidePart> otherSectionParts;

  @override
  State<SignalRoom> createState() => _SignalRoomState();
}

class _SignalRoomState extends State<SignalRoom> with WidgetsBindingObserver {
  final _surface = GlobalKey();
  final _history = BoardHistory<SignalBoardState>();
  _PartDrag? _drag;
  SignalOutput? _output;
  ({SignalLink link, LeadType? type})? _preview;
  String? _inspected;
  String? _message;
  int _pulseRevision = 0;
  bool _animatePulse = false;

  SignalBoardState get _state => widget.boardState;
  SignalBoard get _board => _state.board;
  SignalDevice _device(String id) => _board.device(id)!;
  bool get _hasSpecialtyLeads =>
      _board.shieldedLeadStock > 0 || _board.trunkLeadStock > 0;

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
    if (state != AppLifecycleState.resumed) _finishDrag(cancel: true);
  }

  LinkIssue? _linkIssue(SignalLink link, LeadType type) => _board.linkIssue(
    _state.links,
    link,
    positions: _state.positions,
    flipped: _state.flipped,
    type: type,
    leadTypes: _state.leadTypes,
  );

  ({LeadType type, LinkIssue? issue}) _connectionFor(SignalLink link) {
    final patchIssue = _linkIssue(link, LeadType.patch);
    // Ordinary routes use patch stock. A specialist cable is chosen only
    // when a physical constraint prevents using a patch lead.
    if (patchIssue == LinkIssue.interference ||
        patchIssue == LinkIssue.feedthrough) {
      for (final type in [LeadType.shielded, LeadType.trunk]) {
        if (_board.leadStock(type) == 0) continue;
        final issue = _linkIssue(link, type);
        if (issue == null ||
            issue == LinkIssue.stock ||
            issue == LinkIssue.occupied) {
          return (type: type, issue: issue);
        }
      }
    }
    return (type: LeadType.patch, issue: patchIssue);
  }

  LinkIssue? _installedIssue(
    SignalLink link,
    Map<String, SignalPoint> positions,
  ) => _board.cableIssue(
    link,
    positions,
    flipped: _state.flipped,
    type: _state.leadType(link),
  );

  String _cableMessage(
    LinkIssue issue,
    SignalLink link,
    LeadType type,
  ) => switch (issue) {
    LinkIssue.range =>
      'Needs ${_distance(link)} length units. Output reaches ${_board.leadReach(link.from, type)}.',
    LinkIssue.stock =>
      'No ${type.label.toLowerCase()}s left. Disconnect a cable to free one.',
    _ => issue.message,
  };

  int? _freeOutput(SignalDevice device) =>
      Iterable<int>.generate(device.outputs)
          .where(
            (port) => !_state.links.any(
              (link) => link.from == device.id && link.output == port,
            ),
          )
          .firstOrNull;

  int _freeInput(SignalDevice device) {
    if (!device.dualInput) return 0;
    for (var input = 0; input < device.inputs; input++) {
      if (!_state.links.any(
        (link) => link.to == device.id && link.input == input,
      )) {
        return input;
      }
    }
    return 0;
  }

  void _tapPart(SignalDevice device, {int? outputPort, int? input}) {
    if (_drag != null) return;
    final output = _output;
    setState(() {
      _inspected = device.id;
      if (_state.alarmFailed) {
        _output = null;
        _preview = null;
        _message = null;
        return;
      }
      if (outputPort == null &&
          output != null &&
          output.id != device.id &&
          device.hasInput) {
        final link = (
          from: output.id,
          to: device.id,
          input: input ?? _freeInput(device),
          output: output.port,
        );
        final (:type, :issue) = _connectionFor(link);
        final confirmed = _preview == (link: link, type: type);
        _preview = _hasSpecialtyLeads
            ? (link: link, type: issue == null ? type : null)
            : null;
        _message = issue == null ? null : _cableMessage(issue, link, type);
        if (issue != null) {
          GameAudio.play(context, BoardCue.reject);
          return;
        }
        if (_hasSpecialtyLeads && !confirmed) {
          _message =
              '${_distance(link)} units. Tap the input again to install.';
          return;
        }
        _output = null;
        _preview = null;
        if (!_state.links.contains(link) || _state.leadType(link) != type) {
          _edit(
            BoardCue.connect,
            links: [
              ..._state.links.where(
                (other) => other.to != device.id || other.input != link.input,
              ),
              link,
            ],
            leadTypes: {..._state.leadTypes, link: type},
          );
        }
      } else {
        _preview = null;
        final port = outputPort ?? _freeOutput(device);
        _output =
            input == null &&
                port != null &&
                (output?.id != device.id || output?.port != port)
            ? (id: device.id, port: port)
            : null;
        _message = _output == null
            ? null
            : 'Choose an input within ${device.range} units of this output.';
      }
    });
  }

  String _distance(SignalLink link) => _value(
    (_board.distance(link, _state.positions, flipped: _state.flipped) * 100 -
                1e-7)
            .ceil() /
        100,
  );

  void _edit(
    BoardCue cue, {
    List<SignalLink>? links,
    Map<String, SignalPoint>? positions,
    Set<String>? flipped,
    Map<String, int>? losses,
    Map<SignalLink, LeadType>? leadTypes,
  }) {
    _pulseRevision++;
    _animatePulse = true;
    _history.record(_state);
    final next = _state.copyWith(
      links: links,
      positions: positions,
      flipped: flipped,
      losses: losses,
      leadTypes: leadTypes,
    );
    if (next.solved && !_state.solved) _clearSelection();
    GameAudio.play(context, cue);
    if (next.alarmFailed && !_state.alarmFailed) {
      GameAudio.play(context, BoardCue.alarm);
    } else if (widget.otherSectionSolved && next.solved && !_state.solved) {
      GameAudio.play(context, BoardCue.solved);
    }
    widget.onChange(next);
  }

  bool _canMove(String id, SignalPoint point) =>
      !_state.alarmFailed &&
      _state.positions[id]!.distanceTo(point) > 1e-9 &&
      _board.canMove(id, point, _state.positions);

  void _move(String id, PlacementNode node) {
    final point = node.position;
    if (!_canMove(id, point)) return;
    setState(() {
      _clearSelection();
      _edit(BoardCue.place, positions: {..._state.positions, id: point});
    });
  }

  Offset _onBoard(Offset global) {
    final box = _surface.currentContext!.findRenderObject()! as RenderBox;
    return box.globalToLocal(global);
  }

  void _startDrag(String id, Offset global, SignalBoardGeometry geometry) {
    if (_drag != null) return;
    final point = _state.positions[id]!;
    final grab = _onBoard(global) - geometry.project(point);
    setState(() {
      _animatePulse = false;
      _drag = (id: id, grab: grab, node: null);
    });
  }

  void _updateDrag(String id, Offset global, SignalBoardGeometry geometry) {
    final drag = _drag;
    if (drag == null || drag.id != id) return;
    final point = geometry.unproject(_onBoard(global) - drag.grab);
    final node = _board.snapAt(point, id: id);
    if (node != drag.node) {
      setState(() => _drag = (id: id, grab: drag.grab, node: node));
    }
  }

  void _finishDrag({String? id, bool cancel = false}) {
    final drag = _drag;
    if (drag == null || (id != null && id != drag.id)) return;
    setState(() => _drag = null);
    if (cancel) return;
    if (drag.node case final node? when _validDrop(drag)) {
      _move(drag.id, node);
    } else {
      GameAudio.play(context, BoardCue.reject);
    }
  }

  bool _validDrop(_PartDrag drag) {
    final node = drag.node;
    return node != null &&
        _board.canMove(drag.id, node.position, _state.positions);
  }

  void _clearSelection() {
    _output = null;
    _preview = null;
    _inspected = null;
    _message = null;
  }

  void _disconnect(SignalLink cable) => setState(() {
    final links = _state.links.where((link) => link != cable).toList();
    if (_board.alarm != null &&
        _board.interruptsAlarm(
          _board.evaluate(
            links,
            positions: _state.positions,
            flipped: _state.flipped,
            losses: _state.losses,
            leadTypes: _state.leadTypes,
          ),
        )) {
      _inspected = cable.to;
      _message = 'Disconnecting this feed would interrupt the alarm blocker.';
      GameAudio.play(context, BoardCue.reject);
      return;
    }
    _clearSelection();
    _edit(BoardCue.disconnect, links: links);
  });

  void _flip(SignalDevice device) {
    if (!device.canFlip || _drag != null || _state.alarmFailed) return;
    final flipped = {..._state.flipped};
    if (!flipped.remove(device.id)) flipped.add(device.id);
    final deliveries = _board.evaluate(
      _state.links,
      positions: _state.positions,
      flipped: flipped,
      losses: _state.losses,
      leadTypes: _state.leadTypes,
    );
    setState(() {
      _clearSelection();
      _inspected = device.id;
      if (_board.interruptsAlarm(deliveries)) {
        _message = 'Flipping this part would take the blocker out of range.';
        GameAudio.play(context, BoardCue.reject);
        return;
      }
      _edit(BoardCue.turn, flipped: flipped);
    });
  }

  void _undo() => setState(() {
    _clearSelection();
    _animatePulse = false;
    widget.onChange(_history.undo(_state));
    GameAudio.play(context, BoardCue.adjust);
  });

  void _redo() => setState(() {
    _clearSelection();
    _animatePulse = false;
    widget.onChange(_history.redo(_state));
    GameAudio.play(context, BoardCue.adjust);
  });

  void _reset() => setState(() {
    _clearSelection();
    _animatePulse = false;
    _history.record(_state);
    widget.onChange(SignalBoardState(_board));
    GameAudio.play(context, BoardCue.adjust);
  });

  SignalDelivery? _incoming(
    SignalDevice device, [
    Map<SignalLink, SignalDelivery>? deliveries,
  ]) {
    final incoming = (deliveries ?? _state.deliveries).entries
        .where((entry) => entry.key.to == device.id)
        .map((entry) => entry.value);
    if (device.kind != SignalDeviceKind.antenna) return incoming.firstOrNull;
    final matching = incoming.where(
      (delivery) => delivery.channel == device.channel,
    );
    if (device.protected) {
      return matching.where(device.trips).firstOrNull ?? matching.firstOrNull;
    }
    return matching
            .where(
              (delivery) => device.read(delivery) == SignalReading.accepted,
            )
            .firstOrNull ??
        matching.firstOrNull ??
        incoming.firstOrNull;
  }

  String _value(double strength) =>
      strength.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  String _band(SignalDevice device) {
    if (device.mustBeQuiet) return '0';
    if (device.tripStrength case final trip?) return '<${_value(trip)}';
    final minimum = _value(device.minimumStrength!);
    if (device.maximumStrength == null) return '≥$minimum';
    final maximum = _value(device.maximumStrength!);
    return minimum == maximum ? minimum : '$minimum–$maximum';
  }

  _RadioFailure? _radioFailure(
    SignalDevice antenna,
    Map<SignalLink, SignalDelivery> deliveries,
    Map<String, SignalPoint> positions,
  ) {
    if (antenna.kind != SignalDeviceKind.antenna) return null;
    final powered = _board.devices.where(
      (device) =>
          device.radioRange > 0 && _incoming(device, deliveries) != null,
    );
    final paths = powered.map(
      (mast) => _board.radioPath(mast, antenna, positions),
    );
    if (paths.isEmpty) return null;
    final inRange = paths.where((path) => path.inRange);
    if (inRange.isEmpty) return _RadioFailure.range;
    if (inRange.every((path) => path.blockedAt != null)) {
      return _RadioFailure.concrete;
    }
    return null;
  }

  ConsoleTools _toolbar() => ConsoleTools(
    key: const ValueKey('signal-toolbar'),
    undoKey: const ValueKey('signal-undo'),
    redoKey: const ValueKey('signal-redo'),
    onUndo: !_history.canUndo || _drag != null ? null : _undo,
    onRedo: !_history.canRedo || _drag != null ? null : _redo,
    onReset: _drag == null ? _reset : null,
  );

  Widget _goalIndicator(
    SignalDevice goal,
    Map<SignalLink, SignalDelivery> deliveries,
    Map<String, SignalPoint> positions,
  ) {
    final delivery = _incoming(goal, deliveries);
    final isBlocker = goal == _board.alarm?.blocker;
    final alarm = isBlocker ? _board.alarmPower(deliveries) : null;
    final reading = alarm?.reading ?? goal.read(delivery);
    final onTarget = goal.protected
        ? delivery == null || !goal.trips(delivery)
        : reading == SignalReading.accepted &&
              (!isBlocker ||
                  alarm!.sources.length == 1 &&
                      alarm.sources.contains(_board.alarm?.source));
    final status = goal.mustBeQuiet
        ? (onTarget ? 'Quiet' : 'Signal detected')
        : goal.tripStrength != null
        ? (onTarget ? 'Below trip threshold' : 'Guard tripped')
        : switch (reading) {
            SignalReading.quiet =>
              _radioFailure(goal, deliveries, positions)?.status ?? 'No signal',
            SignalReading.wrongChannel => 'Wrong channel',
            SignalReading.wrongSource =>
              'Needs ${_device(goal.requiredSource!).name}',
            SignalReading.weak => 'Too weak',
            SignalReading.strong => 'Too strong',
            SignalReading.accepted =>
              alarm == null
                  ? 'Online'
                  : 'Holding on ${alarm.sources.map((id) => _device(id).name).join(' and ')}',
          };
    final invalidSignal = goal.protected
        ? !onTarget
        : reading != SignalReading.quiet && reading != SignalReading.accepted;
    final tone = onTarget
        ? (isBlocker ? PartTone.alarmLit : PartTone.lit)
        : invalidSignal
        ? PartTone.warning
        : PartTone.plain;
    final current = _value(alarm?.strength ?? delivery?.strength ?? 0);
    final band = _band(goal);
    final source = isBlocker ? _board.alarm?.source : goal.requiredSource;
    final sourceTarget = source == null ? '' : ' from ${_device(source).name}';

    return Semantics(
      key: ValueKey('signal-goal-${goal.id}'),
      container: true,
      label: '${goal.name}. $status. Target $band units$sourceTarget.',
      value: '$current units',
      excludeSemantics: true,
      child: DraftingPartRow(
        number: '${_partNumber(goal)}',
        name: (isBlocker ? 'Blocker' : goal.name).toUpperCase(),
        state: '$current / $band u',
        status: status,
        tone: tone,
        symbol: _symbol(goal, deliveries),
      ),
    );
  }

  int _partNumber(SignalDevice device) => _board.devices.indexOf(device) + 1;

  Widget _partsList(
    Map<SignalLink, SignalDelivery> deliveries,
    Map<String, SignalPoint> positions,
  ) => DraftingPartsList(
    key: const ValueKey('signal-goals'),
    rows: [
      for (final goal in _board.goals)
        if (goal.requiredSource == null)
          _goalIndicator(goal, deliveries, positions),
      if (_board.alarm case (:final blocker, source: _))
        _goalIndicator(blocker, deliveries, positions),
      for (final goal in _board.goals)
        if (goal.requiredSource != null)
          _goalIndicator(goal, deliveries, positions),
      for (final device in _board.devices)
        if (!_board.goals.contains(device) && device != _board.alarm?.blocker)
          _partRow(device, deliveries),
    ],
  );

  Widget _partRow(
    SignalDevice device,
    Map<SignalLink, SignalDelivery> deliveries,
  ) {
    final incoming = _incoming(device, deliveries);
    final wrongChannel =
        device.kind == SignalDeviceKind.antenna &&
        device.read(incoming) == SignalReading.wrongChannel;
    return DraftingPartRow(
      number: '${_partNumber(device)}',
      name: device.name.toUpperCase(),
      state: device.kind == SignalDeviceKind.antenna
          ? '${_value(incoming?.strength ?? 0)} u'
          : _partReading(device),
      status: wrongChannel ? 'Wrong channel' : null,
      tone: wrongChannel ? PartTone.warning : PartTone.plain,
      symbol: _symbol(device, deliveries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drag = _drag;
    final positions = switch (drag) {
      (id: final id, node: final node?, grab: _) => {
        ..._state.positions,
        id: node.position,
      },
      _ => _state.positions,
    };
    final cableIssues = {
      for (final link in _state.links) link: ?_installedIssue(link, positions),
    };
    final validDrop = drag != null && _validDrop(drag);
    final deliveries = validDrop
        ? _board.evaluate(
            _state.links,
            positions: positions,
            flipped: _state.flipped,
            losses: _state.losses,
            leadTypes: _state.leadTypes,
          )
        : _state.deliveries;
    final alarmAtRisk = validDrop && _board.interruptsAlarm(deliveries);
    final alarmWarning = alarmAtRisk
        ? 'This placement would interrupt the alarm blocker.'
        : null;
    final inspector = _inspected == null
        ? null
        : _inspector(_device(_inspected!));
    final radioWarning = _board.goals
        .where((goal) => !goal.protected && _incoming(goal, deliveries) == null)
        .map((goal) => _radioFailure(goal, deliveries, positions))
        .nonNulls
        .firstOrNull;
    final failedCable = cableIssues.entries.firstOrNull;
    final pathWarning =
        alarmWarning ??
        (failedCable == null
            ? null
            : _board.cableCorridors == null
            ? 'Dashed cables are out of reach.'
            : '${_state.leadType(failedCable.key).label} · ${_cableMessage(failedCable.value, failedCable.key, _state.leadType(failedCable.key))}') ??
        radioWarning?.warning;
    final visibleDeliveries = drag != null && !validDrop
        ? const <SignalLink, SignalDelivery>{}
        : deliveries;
    return PuzzleConsole(
      brief: widget.brief,
      navigation: widget.navigation,
      tools: _toolbar(),
      playfield: SignalPlayfield(
        state: _state,
        positions: positions,
        beyondReach: cableIssues.keys.toSet(),
        deliveries: visibleDeliveries,
        awardBounds: widget.brief.awardBounds,
        inspectedPart: _inspected,
        placement: drag == null
            ? null
            : (id: drag.id, node: drag.node, valid: validDrop),
        selectedOutput: _output,
        preview: drag == null ? _preview?.link : null,
        animatedRevision: drag == null && _animatePulse ? _pulseRevision : null,
        surfaceKey: _surface,
        onBackgroundTap: () => setState(_clearSelection),
        buildPart: (device, geometry) =>
            _movablePart(device, geometry, visibleDeliveries),
      ),
      readings: _partsList(deliveries, positions),
      inventory: _inventory(),
      canLeave: drag == null,
      onHelp: () => showPartGuide(
        context,
        puzzleParts: {...signalGuideParts(_board), ...widget.otherSectionParts},
        revealedParts: widget.revealedParts,
      ),
      solved: drag == null && _state.solved && widget.otherSectionSolved,
      failureMessage: _state.alarmFailed
          ? 'Alarm tripped. Undo or reset the room.'
          : null,
      feedback: [
        if (!_state.alarmFailed && pathWarning != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                pathWarning,
                style: draftingLettering(
                  12,
                  color: alarmWarning == null
                      ? context.sheet.ink
                      : context.sheet.stamp,
                  spacing: .2,
                ),
              ),
            ),
          ),
        if (drag != null && !validDrop)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Choose a clear placement dot.',
              style: draftingLettering(12, spacing: .2),
            ),
          )
        else if (inspector != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: inspector),
      ],
    );
  }

  Widget? _inventory() {
    if (_board.patchLeadStock == null) return null;
    return Padding(
      key: const ValueKey('cable-inventory'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Wrap(
        spacing: 9,
        runSpacing: 4,
        children: [
          for (final type in LeadType.values)
            if (_board.leadStock(type) case final total? when total > 0)
              LeadStock(
                key: ValueKey('${type.name}-lead-stock'),
                type: type,
                total: total,
                installed: _state.links
                    .where((link) => _state.leadType(link) == type)
                    .length,
              ),
        ],
      ),
    );
  }

  Widget _movablePart(
    SignalDevice device,
    SignalBoardGeometry geometry,
    Map<SignalLink, SignalDelivery> deliveries,
  ) {
    final size = geometry.partSize;
    final point = _state.positions[device.id]!;
    final flipped = _state.flipped.contains(device.id);
    final output = _output;
    final ports = [
      for (var index = 0; index < device.inputs; index++)
        (
          output: false,
          index: index,
          offset: SignalBoard.inputPort(index, flipped: flipped),
        ),
      for (var index = 0; index < device.outputs; index++)
        (
          output: true,
          index: index,
          offset: SignalBoard.outputPort(index, flipped: flipped),
        ),
    ];
    final inputAvailable =
        output != null &&
        _connectionFor((
              from: output.id,
              to: device.id,
              input: _freeInput(device),
              output: output.port,
            )).issue ==
            null;
    final selected = output?.id == device.id || _inspected == device.id;
    final held = _drag?.id == device.id;
    final validDrop = !held || _validDrop(_drag!);
    final actions = <CustomSemanticsAction, VoidCallback>{};
    if (_drag == null) {
      for (var input = 0; input < device.inputs; input++) {
        final label = device.dualInput
            ? 'Use input ${_inputName(input)}'
            : 'Use input';
        actions[CustomSemanticsAction(label: label)] = () =>
            _tapPart(device, input: input);
      }
      for (var port = 0; port < device.outputs; port++) {
        final label = device.outputs == 1
            ? 'Use output'
            : 'Use output ${port + 1}';
        actions[CustomSemanticsAction(label: label)] = () =>
            _tapPart(device, outputPort: port);
      }
      for (final (direction, dx, dy) in const [
        ('left', -1, 0),
        ('right', 1, 0),
        ('up', 0, -1),
        ('down', 0, 1),
      ]) {
        final candidates = _board.mountsFor(device.id).where((node) {
          final offset = node.position - point;
          final along = offset.x * dx + offset.y * dy;
          final across = (offset.x * dy - offset.y * dx).abs();
          return along > 0 &&
              along >= across &&
              _canMove(device.id, node.position);
        });
        final target = nearestPlacementNode(point, candidates);
        if (target != null) {
          actions[CustomSemanticsAction(label: 'Move $direction')] = () =>
              _move(device.id, target);
        }
      }
    }

    return Semantics(
      label:
          '${device.name}, ${_partReading(device)}${device.fixed ? ', anchored' : ''}',
      button: true,
      selected: selected,
      onTap: () => _tapPart(device),
      onLongPress: !device.canFlip || _state.alarmFailed
          ? null
          : () => _flip(device),
      customSemanticsActions: actions,
      child: ExcludeSemantics(
        child: Listener(
          onPointerCancel: (_) => _finishDrag(id: device.id, cancel: true),
          child: RawGestureDetector(
            key: ValueKey('signal-device-${device.id}'),
            behavior: HitTestBehavior.opaque,
            gestures: {
              TapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    TapGestureRecognizer.new,
                    (tap) => tap.onTapUp = (details) {
                      final point = geometry.unproject(
                        details.localPosition - size.center(Offset.zero),
                      );
                      var nearest = .18;
                      int? outputPort;
                      int? input;
                      for (final port in ports) {
                        final distance = port.offset.distanceTo(point);
                        if (distance < nearest) {
                          nearest = distance;
                          outputPort = port.output ? port.index : null;
                          input = port.output ? null : port.index;
                        }
                      }
                      _tapPart(device, outputPort: outputPort, input: input);
                    },
                  ),
              LongPressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    LongPressGestureRecognizer
                  >(
                    LongPressGestureRecognizer.new,
                    (hold) => hold.onLongPress = !device.canFlip
                        ? null
                        : () => _flip(device),
                  ),
              ImmediateMultiDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    ImmediateMultiDragGestureRecognizer
                  >(
                    ImmediateMultiDragGestureRecognizer.new,
                    (pan) => pan.onStart = (position) {
                      if (device.fixed || _drag != null || _state.alarmFailed) {
                        return null;
                      }
                      _startDrag(device.id, position, geometry);
                      return _PartPan(
                        position,
                        (position) =>
                            _updateDrag(device.id, position, geometry),
                        (cancel) => _finishDrag(id: device.id, cancel: cancel),
                      );
                    },
                  ),
            },
            child: Opacity(
              opacity: validDrop ? 1 : .55,
              child: _partFace(
                device,
                size,
                held || selected || inputAvailable,
                deliveries,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _partReading(SignalDevice device) {
    if (device == _board.alarm?.blocker) {
      final power = _board.alarmPower(_state.deliveries)!;
      return '${_value(power.strength)} u';
    }
    final incoming = _drag == null ? _incoming(device) : null;
    final loss = _board.lossFor(device, _state.losses);
    return switch (device.kind) {
      SignalDeviceKind.transmitter => '${_value(device.strength - loss)} u',
      SignalDeviceKind.attenuator =>
        incoming == null
            ? (loss == 0 ? '0 u' : '−$loss u')
            : '${_value(math.max(0, incoming.strength - loss))} u',
      SignalDeviceKind.splitter =>
        incoming == null
            ? device.splitter!.fraction
            : '${_value(incoming.strength / device.outputs)} u',
      SignalDeviceKind.receiver ||
      SignalDeviceKind.antenna ||
      SignalDeviceKind.relay ||
      SignalDeviceKind.broadcaster =>
        incoming != null
            ? '${_value(incoming.strength)} u'
            : device.minimumStrength == null
            ? '—'
            : _band(device),
    };
  }

  Widget _partFace(
    SignalDevice device,
    Size size,
    bool highlighted,
    Map<SignalLink, SignalDelivery> deliveries,
  ) {
    final flipped = _state.flipped.contains(device.id);
    final bottomPortSpace = device.outputs > 2 ? size.width * .25 : 0.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        _symbol(device, deliveries, highlighted: highlighted),
        Positioned(
          left: flipped ? bottomPortSpace : 0,
          right: flipped ? 0 : bottomPortSpace,
          bottom: size.height * .01,
          height: size.height * .27,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _partReading(device),
              maxLines: 1,
              style: draftingLettering(11, spacing: .1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _symbol(
    SignalDevice device,
    Map<SignalLink, SignalDelivery> deliveries, {
    bool highlighted = false,
  }) => SignalComponent(
    device: device,
    flipped: _state.flipped.contains(device.id),
    highlighted: highlighted,
    poweredPorts: {
      for (final MapEntry(key: link, value: delivery) in deliveries.entries)
        if (link.from == device.id && link.output != SignalBoard.radioOutput)
          (output: true, index: link.output): _accent(delivery.source)
        else if (link.to == device.id && link.output != SignalBoard.radioOutput)
          (output: false, index: link.input): _accent(delivery.source),
    },
  );

  Color _accent(String source) => _board.device(source)?.alternateTint == true
      ? context.sheet.alarmBeam
      : context.sheet.beam;

  String _inputName(int input) => input == 0 ? 'A' : 'B';

  Widget _attenuationControls(SignalDevice device) {
    final selected = _board.lossFor(device, _state.losses);
    final choices = {
      for (final loss in attenuationSteps)
        loss: {..._state.losses, device.id: loss},
    };
    final forecasts = {
      for (final entry in choices.entries)
        entry.key: _board.alarmPower(
          _board.evaluate(
            _state.links,
            positions: _state.positions,
            flipped: _state.flipped,
            losses: entry.value,
          ),
        ),
    };
    final affectsAlarm = forecasts.values.any(
      (power) => power?.strength != forecasts[selected]?.strength,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        spacing: 6,
        children: [
          for (final loss in attenuationSteps)
            Expanded(
              child: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.sheet.ink, width: .9),
                    ),
                    child: SizedBox.fromSize(
                      size: consoleButtonSize,
                      child: consoleButton(
                        tooltip: '$loss u loss',
                        emphasized: selected == loss,
                        onPressed:
                            _state.alarmFailed ||
                                _drag != null ||
                                selected == loss ||
                                (forecasts[loss]?.reading ??
                                        SignalReading.accepted) !=
                                    SignalReading.accepted
                            ? null
                            : () => setState(() {
                                _output = null;
                                _message = null;
                                _edit(BoardCue.adjust, losses: choices[loss]);
                              }),
                        icon: Text(
                          loss == 0 ? '0' : '−$loss',
                          style: draftingLettering(12, spacing: 0),
                        ),
                      ),
                    ),
                  ),
                  if (affectsAlarm) _alarmForecast(forecasts[loss]!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _alarmForecast(AlarmPower power) {
    final strength = _value(power.strength);
    final color = power.reading == SignalReading.accepted
        ? context.sheet.ink
        : context.sheet.stamp;
    return Tooltip(
      message: 'Alarm $strength u',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 3,
        children: [
          Icon(Icons.shield_outlined, size: 12, color: color),
          Text(
            strength,
            style: draftingLettering(11, color: color, spacing: 0),
          ),
        ],
      ),
    );
  }

  Widget _alarmFeeds(SignalDevice blocker) => Row(
    spacing: 8,
    children: [
      for (var input = 0; input < blocker.inputs; input++)
        Expanded(
          child: Text(
            '${_inputName(input)} · ${_value(_board.alarmFeed(_state.deliveries, input)?.strength ?? 0)} u',
            style: draftingLettering(12, spacing: 0),
          ),
        ),
    ],
  );

  Widget? _inspector(SignalDevice device) {
    final delivery = _incoming(device);
    final cables = _state.links.where(
      (link) => link.from == device.id || link.to == device.id,
    );
    final invalid = [
      for (final link in cables)
        if (_installedIssue(link, _state.positions) case final issue?)
          (link, issue),
    ].firstOrNull;
    final detail =
        _message ??
        (invalid == null
            ? null
            : _cableMessage(
                invalid.$2,
                invalid.$1,
                _state.leadType(invalid.$1),
              )) ??
        switch (device.kind) {
          SignalDeviceKind.transmitter ||
          SignalDeviceKind.splitter ||
          SignalDeviceKind.relay => 'Reach ${device.range}',
          SignalDeviceKind.broadcaster =>
            'Coverage ${device.radioRange} steps · Channel ${device.channel}',
          SignalDeviceKind.antenna => _inspectAntenna(device),
          SignalDeviceKind.receiver
              when device.read(delivery) == SignalReading.wrongSource =>
            'Use ${_device(device.requiredSource!).name}.',
          _ => null,
        };
    final blocker = device == _board.alarm?.blocker;
    final adjustsLoss = device.initialLoss != null;
    final previewType = _preview?.type;
    if (detail == null && !adjustsLoss && !blocker && cables.isEmpty) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail != null)
          Semantics(
            liveRegion: true,
            child: Row(
              spacing: 6,
              children: [
                if (previewType != null)
                  Semantics(
                    label: previewType.label,
                    child: LeadSymbol(
                      key: const ValueKey('lead-preview-symbol'),
                      type: previewType,
                    ),
                  ),
                Expanded(
                  child: Text(
                    detail,
                    style: draftingLettering(12, spacing: .2),
                  ),
                ),
              ],
            ),
          ),
        if (adjustsLoss) _attenuationControls(device),
        if (blocker) _alarmFeeds(device),
        for (final cable in cables) _cableControl(cable, device),
      ],
    );
  }

  String _inspectAntenna(SignalDevice antenna) {
    final details = [
      'Channel ${antenna.channel}${antenna.protected ? ' · Target ${_band(antenna)} u' : ''}',
    ];
    final deliveries = _state.deliveries;
    final delivery = _incoming(antenna);
    final radioLink = deliveries.entries
        .where((entry) => entry.key.to == antenna.id && entry.value == delivery)
        .firstOrNull
        ?.key;
    final mast = radioLink == null
        ? _board.devices
              .where(
                (device) => device.radioRange > 0 && _incoming(device) != null,
              )
              .firstOrNull
        : _device(radioLink.from);
    if (mast == null) return details.single;
    final path = _board.radioPath(mast, antenna, _state.positions);
    details.add('${_value(path.distance)} of ${mast.radioRange} grid steps');
    if (delivery != null) {
      switch (antenna.read(delivery)) {
        case SignalReading.wrongChannel:
          details.add('Received channel ${delivery.channel} (wrong channel)');
        case SignalReading.weak:
          details.add('${_value(delivery.strength)} u · Too weak');
        default:
          details.add(
            '${_value(delivery.strength)} u${antenna.trips(delivery) ? ' · ${antenna.mustBeQuiet ? 'Signal detected' : 'Guard tripped'}' : ''}',
          );
      }
    } else if (_radioFailure(antenna, deliveries, _state.positions)
        case final failure?) {
      details.add(failure.status);
    }
    return details.join(' · ');
  }

  Widget _cableControl(SignalLink cable, SignalDevice selected) {
    final target = _device(cable.to);
    final source = _device(cable.from);
    final input = target.dualInput ? ' ${_inputName(cable.input)}' : '';
    final route = '${source.name} → ${target.name}$input';
    final endpoint = selected == target
        ? '← ${source.name}$input'
        : '→ ${target.name}$input';
    return Row(
      children: [
        consoleButton(
          tooltip: 'Disconnect $route',
          onPressed: _state.alarmFailed ? null : () => _disconnect(cable),
          icon: const Icon(Icons.link_off),
        ),
        if (_hasSpecialtyLeads)
          Semantics(
            label: _state.leadType(cable).label,
            child: LeadSymbol(type: _state.leadType(cable)),
          ),
        Expanded(
          child: Text(endpoint, style: draftingLettering(12, spacing: .2)),
        ),
      ],
    );
  }
}

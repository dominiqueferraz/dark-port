import 'endless_levels.dart';
import 'optical_bay.dart';
import 'placement_nodes.dart';
import 'signal_board.dart';
import 'signal_board_state.dart';
import 'tutorial.dart';
import 'wired_boards.dart';

class GameSave {
  factory GameSave(
    TutorialLesson lesson, {
    List<Optic>? layout,
    List<SignalLink>? links,
    Map<String, SignalPoint>? positions,
    Set<String>? flipped,
    Map<String, int> losses = const {},
    Map<SignalLink, LeadType> leadTypes = const {},
  }) {
    if (lesson is WiredLesson) {
      return GameSave._wired(
        lesson,
        SignalBoardState(
          lesson.board,
          links: links,
          positions: positions,
          flipped: flipped,
          losses: losses,
          leadTypes: leadTypes,
        ),
        List.unmodifiable(layout ?? const []),
      );
    }
    return GameSave._(
      lesson,
      layout: List.unmodifiable(
        layout ?? (lesson as OpticalLesson).board.initial,
      ),
      links: List.unmodifiable(links ?? const []),
      positions: Map.unmodifiable(positions ?? const {}),
      flipped: Set.unmodifiable(flipped ?? const {}),
      losses: Map.unmodifiable(losses),
    );
  }

  factory GameSave.fromSignal(WiredLesson lesson, SignalBoardState state) {
    assert(identical(lesson.board, state.board));
    return GameSave._wired(lesson, state, const []);
  }

  GameSave._wired(
    WiredLesson lesson,
    SignalBoardState state,
    List<Optic> layout,
  ) : this._(
        lesson,
        layout: layout,
        links: state.links,
        positions: state.positions,
        flipped: state.flipped,
        losses: state.losses,
        signal: state,
      );

  GameSave._(
    this.lesson, {
    required this.layout,
    required this.links,
    required this.positions,
    required this.flipped,
    required this.losses,
    this.signal,
  });

  final TutorialLesson lesson;
  OpticalLevel? get opticalBoard => switch (lesson) {
    OpticalLesson(:final board) => board,
    _ => null,
  };
  SignalBoard? get wiredBoard => signal?.board;
  final SignalBoardState? signal;
  final List<Optic> layout;
  final List<SignalLink> links;
  final Map<String, SignalPoint> positions;
  final Set<String> flipped;
  final Map<String, int> losses;

  Map<SignalLink, SignalDelivery> get deliveries =>
      signal?.deliveries ?? const {};
  bool get alarmFailed => signal?.alarmFailed ?? false;
  late final bool solved = switch (opticalBoard) {
    final level? => traceOptics(level, layout).solves(level),
    null => signal?.solved ?? false,
  };

  Map<String, Object> toJson() => wiredBoard != null
      ? {
          'board': lesson.id,
          'flipped': flipped.toList(),
          'losses': losses,
          'positions': {
            for (final entry in positions.entries)
              entry.key: {'x': entry.value.x, 'y': entry.value.y},
          },
          'links': [
            for (final link in links)
              {
                'from': link.from,
                'to': link.to,
                'input': link.input,
                'output': link.output,
                if (signal!.leadTypes[link] case final type?) 'lead': type.name,
              },
          ],
        }
      : {
          'board': lesson.id,
          'layout': [
            for (final optic in layout)
              {
                'id': optic.id,
                'x': optic.position.x,
                'y': optic.position.y,
                'turned': optic.turned,
              },
          ],
        };

  factory GameSave.fromJson(Map<String, dynamic> json) {
    if (json['board'] case final String id) {
      return switch (lessonsById[id] ?? endlessLevelsByLessonId[id]?.lesson) {
        final OpticalLesson lesson => _readOpticalSave(lesson, json['layout']),
        final WiredLesson lesson => _readWiredSave(lesson, json),
        null => throw const FormatException('Unknown lesson.'),
      };
    }
    if (json['version'] case 2 || 3 || 4 || 5 || 6 || 7 || 8 || 9 || 10 || 11) {
      return _readLegacySignalSave(json);
    }
    if (json['version'] != 1 || json['verified'] is! bool) {
      throw const FormatException('Unsupported save.');
    }
    final lesson = switch (json['journey']) {
      'reflection' => firstReflection,
      'splitting' => dividedBeam,
      'interlock' => opticalInterlock,
      _ => throw const FormatException('Unknown legacy board.'),
    };
    return _readOpticalSave(lesson, json['layout'], verified: json['verified']);
  }

  static GameSave _readOpticalSave(
    OpticalLesson lesson,
    Object? rows, {
    bool? verified,
  }) {
    final level = lesson.board;
    if (rows is! List) throw const FormatException('Missing board.');
    if (rows.length != level.initial.length) {
      throw const FormatException('Incomplete board.');
    }
    // The old interlock used a mirror in place of the second splitter.
    final legacyInterlock =
        verified != null &&
        lesson == opticalInterlock &&
        rows.any((row) => row is Map && row['id'] == 'M1');
    final byId = <String, Optic>{};
    for (final row in rows) {
      if (row is! Map) throw const FormatException('Invalid optic.');
      final entry = row;
      final id = legacyInterlock && entry['id'] == 'M1' ? 'S2' : entry['id'];
      final template = level.initial.where((o) => o.id == id).firstOrNull;
      if (template == null ||
          byId.containsKey(template.id) ||
          entry['turned'] is! bool ||
          entry['x'] is! num ||
          entry['y'] is! num) {
        throw const FormatException('Invalid optic.');
      }
      final p = FloorPoint(
        (entry['x'] as num).toDouble(),
        (entry['y'] as num).toDouble(),
      );
      if (!p.x.isFinite || !p.y.isFinite) {
        throw const FormatException('Invalid position.');
      }
      byId[template.id] = Optic(
        template.id,
        template.kind,
        p,
        turned: entry['turned'] as bool,
        fixed: template.fixed,
      );
    }
    final layout = [for (final template in level.initial) byId[template.id]!];
    for (final optic in layout) {
      final template = level.initial.singleWhere((o) => o.id == optic.id);
      final valid = optic.fixed
          ? optic.position == template.position &&
                optic.turned == template.turned
          : level.canPlace(optic, layout);
      if (!valid) throw const FormatException('Invalid placement.');
    }
    final save = GameSave(lesson, layout: layout);
    if (verified == true && !save.solved && !legacyInterlock) {
      throw const FormatException('Invalid completed route.');
    }
    return save;
  }

  static GameSave _readWiredSave(
    WiredLesson lesson,
    Map<String, dynamic> json,
  ) {
    final board = lesson.board;
    final retired = switch (lesson) {
      _ when lesson == splitRatings => const {'fourWay', 'monitor'},
      _ when lesson == testLine => _retiredTestLineParts,
      _ => const <String>{},
    };
    final positions = _readPositions(
      board,
      board.devices,
      json['positions'],
      retired: retired,
    );
    final (flipped, losses) = _readSettings(board, json, retired: retired);
    final rows = json['links'];
    if (rows is! List) throw const FormatException('Missing cables.');
    final links = <SignalLink>[];
    final leadTypes = <SignalLink, LeadType>{};
    for (final row in rows) {
      if (row case {
        'from': final String from,
        'to': final String to,
        'input': final int input,
        'output': final int output,
      }) {
        if (retired.contains(from) || retired.contains(to)) continue;
        final link = (from: from, to: to, input: input, output: output);
        final type = row.containsKey('lead')
            ? LeadType.values
                  .where((type) => type.name == row['lead'])
                  .firstOrNull
            : LeadType.patch;
        if (type == null) throw const FormatException('Invalid lead type.');
        _appendLink(
          board,
          links,
          link,
          positions,
          type: type,
          leadTypes: leadTypes,
        );
        if (type != LeadType.patch) leadTypes[link] = type;
      } else {
        throw const FormatException('Invalid cable.');
      }
    }
    return GameSave(
      lesson,
      links: links,
      positions: positions,
      flipped: flipped,
      losses: losses,
      leadTypes: leadTypes,
    );
  }

  static void _appendLink(
    SignalBoard board,
    List<SignalLink> links,
    SignalLink link,
    Map<String, SignalPoint> positions, {
    LeadType type = LeadType.patch,
    Map<SignalLink, LeadType> leadTypes = const {},
  }) {
    if (links.any(
          (other) => other.to == link.to && other.input == link.input,
        ) ||
        board.linkIssue(
              links,
              link,
              positions: positions,
              checkReach: false,
              type: type,
              leadTypes: leadTypes,
            ) !=
            null) {
      throw const FormatException('Invalid cable.');
    }
    links.add(link);
  }

  static (Set<String>, Map<String, int>) _readSettings(
    SignalBoard board,
    Map<String, dynamic> json, {
    Set<String> retired = const {},
  }) {
    final flips = json['flipped'];
    final settings = json['losses'];
    if (flips is! List || settings is! Map) {
      throw const FormatException('Invalid component settings.');
    }
    final flipped = <String>{};
    for (final id in flips) {
      if (retired.contains(id)) continue;
      final device = id is String ? board.device(id) : null;
      if (device == null || !flipped.add(device.id)) {
        throw const FormatException('Invalid flipped component.');
      }
      if (!device.fixed && !device.canFlip) {
        throw const FormatException('Invalid component orientation.');
      }
    }
    for (final device in board.devices.where((device) => device.fixed)) {
      if (flipped.contains(device.id) !=
          board.initialFlipped.contains(device.id)) {
        throw const FormatException('Invalid anchored component orientation.');
      }
    }
    final losses = <String, int>{};
    for (final entry in settings.entries) {
      final id = entry.key;
      if (retired.contains(id)) continue;
      final loss = entry.value;
      if (id is! String ||
          board.device(id)?.initialLoss == null ||
          loss is! int ||
          !attenuationSteps.contains(loss)) {
        throw const FormatException('Invalid attenuation.');
      }
      losses[id] = loss;
    }
    return (flipped, losses);
  }

  static GameSave _readLegacySignalSave(Map<String, dynamic> json) {
    final version = json['version'];
    final stage = json['journey'];
    final legacyRelay = version == 2 && stage == 'relayLine';
    final legacyPower = version == 3 && stage == 'powerLine';
    final rows = json['links'];
    final legacy = version < 7;
    final hardware = version >= 9;
    final hasService = version >= 10;
    final blend = version == 8 ? json['alarmBlend'] : 0;
    if ((stage != 'testLine' && !legacyRelay && !legacyPower) ||
        rows is! List ||
        blend is! num ||
        !blend.isFinite ||
        blend < 0 ||
        blend > 1 ||
        (legacy && json['sent'] is! bool)) {
      throw const FormatException('Invalid signal save.');
    }
    final legacyIds = switch (version) {
      2 when legacyRelay && rows.isNotEmpty => {'relay': 'twoWay'},
      3 => _versionThreeIds(json, legacyPower),
      4 => _versionFourIds(json['placements']),
      _ => const <String, String>{},
    };
    final positions = version == 5 || version == 6 || !legacy
        ? _readSignalPositions(
            json['positions'],
            grid: version == 5,
            legacy: legacy,
            hardware: hardware,
            hasService: hasService,
          )
        : _legacySignalPositions(legacyIds);

    final links = <SignalLink>[if (legacy) ...testLineBoard.initialLinks];
    for (final row in rows) {
      if (row is! Map || row['from'] is! String || row['to'] is! String) {
        throw const FormatException('Invalid cable.');
      }
      final from = row['from'] as String;
      final to = row['to'] as String;
      final input = version >= 8 ? row['input'] : 0;
      if (input is! int ||
          (!hardware && (from == 'attenuator' || to == 'attenuator')) ||
          (!hasService && (from == 'service' || to == 'service'))) {
        throw const FormatException('Invalid cable port.');
      }
      final source = legacyIds[from] ?? from;
      final target = legacyIds[to] ?? to;
      if (_retiredTestLineParts.contains(source) ||
          _retiredTestLineParts.contains(target)) {
        continue;
      }
      final output = hardware
          ? row['output']
          : _legacyOutput(links, source, target, input, positions);
      if (output is! int) throw const FormatException('Invalid output port.');
      final link = (from: source, to: target, input: input, output: output);
      _appendLink(testLineBoard, links, link, positions);
    }
    final (flipped, losses) = hardware
        ? _readSettings(testLineBoard, json, retired: _retiredTestLineParts)
        : (<String>{}, <String, int>{});
    if (!hardware) {
      final pad = testLineBoard.device('attenuator')!;
      if (!positions.containsKey(pad.id)) {
        positions[pad.id] = _openNode(pad.id, pad.initialPosition, positions);
      }
      if (version == 8) _restoreLegacyAlarm(links, positions, blend.toDouble());
    }
    if (!hasService) {
      final service = testLineBoard.device('service')!;
      positions[service.id] = _openNode(
        service.id,
        const SignalPoint(.5, 4.5),
        positions,
      );
    }
    if (hardware && version < 11) _moveLegacyOutput(links, positions, flipped);
    return GameSave(
      testLine,
      links: links,
      positions: positions,
      flipped: flipped,
      losses: losses,
    );
  }

  static void _moveLegacyOutput(
    List<SignalLink> links,
    Map<String, SignalPoint> positions,
    Set<String> flipped,
  ) {
    final index = links.indexWhere(
      (link) => link.from == 'fourWay' && link.output == 3,
    );
    if (index == -1) return;
    final board = testLineBoard;
    final link = links[index];
    final start =
        positions[link.from]! +
        SignalPoint(flipped.contains(link.from) ? .37 : -.37, .15);
    final end =
        positions[link.to]! +
        SignalBoard.inputPort(link.input, flipped: flipped.contains(link.to));
    final range = board.device(link.from)!.range;
    final wasInReach =
        (end.x - start.x).abs() + (end.y - start.y).abs() <= range + 1e-9;
    if (board.inReach(link, positions, flipped: flipped) == wasInReach) {
      return;
    }

    for (var port = 0; port < 3; port++) {
      final replacement = (
        from: link.from,
        to: link.to,
        input: link.input,
        output: port,
      );
      if (board.inReach(replacement, positions, flipped: flipped) !=
          wasInReach) {
        continue;
      }
      final occupied = links.indexWhere(
        (other) => other.from == link.from && other.output == port,
      );
      if (occupied != -1) {
        final other = links[occupied];
        final swapped = (
          from: other.from,
          to: other.to,
          input: other.input,
          output: 3,
        );
        if (board.inReach(other, positions, flipped: flipped) !=
            board.inReach(swapped, positions, flipped: flipped)) {
          continue;
        }
        links[occupied] = swapped;
      }
      links[index] = replacement;
      return;
    }

    // Preserve reach on every attached cable when moving the splitter.
    final reaches = {
      for (final other in links)
        if (other.from == link.from || other.to == link.from)
          other: other == link
              ? wasInReach
              : board.inReach(other, positions, flipped: flipped),
    };
    final candidatePositions = {...positions};
    final nearest = nearestPlacementNode(
      positions[link.from]!,
      board.placementNodes.where((node) {
        if (!board.canMove(link.from, node.position, positions)) return false;
        candidatePositions[link.from] = node.position;
        return reaches.entries.every(
          (entry) =>
              board.inReach(entry.key, candidatePositions, flipped: flipped) ==
              entry.value,
        );
      }),
    );
    if (nearest != null) positions[link.from] = nearest.position;
  }

  static int _legacyOutput(
    List<SignalLink> links,
    String from,
    String to,
    int input,
    Map<String, SignalPoint> positions,
  ) {
    final board = testLineBoard;
    final count = board.device(from)?.outputs ?? 0;
    final used = links
        .where((link) => link.from == from)
        .map((link) => link.output);
    final free = Iterable<int>.generate(count)
        .where((port) => !used.contains(port));
    if (positions.containsKey(from) && positions.containsKey(to)) {
      for (final port in free) {
        if (board.inReach((
          from: from,
          to: to,
          input: input,
          output: port,
        ), positions)) {
          return port;
        }
      }
    }
    return free.firstOrNull ?? -1;
  }

  static SignalPoint _openNode(
    String id,
    SignalPoint near,
    Map<String, SignalPoint> positions,
  ) => nearestPlacementNode(
    near,
    testLineBoard.placementNodes.where(
      (node) => testLineBoard.canMove(id, node.position, positions),
    ),
  )!.position;

  static void _restoreLegacyAlarm(
    List<SignalLink> links,
    Map<String, SignalPoint> positions,
    double blend,
  ) {
    final board = testLineBoard;
    final blocker = board.alarm!.blocker;
    final deliveries = board.evaluate(links, positions: positions);
    final preferred = blend <= .5 ? 0 : 1;
    final active = blend == 0 || blend == 1;
    if (!active && !board.interruptsAlarm(deliveries)) return;
    for (final input in [preferred, 1 - preferred]) {
      if (active && input != preferred) break;
      if (blocker.read(board.alarmFeed(deliveries, input)) ==
          SignalReading.accepted) {
        links.removeWhere(
          (link) => link.to == blocker.id && link.input != input,
        );
        return;
      }
    }
    final a = board.alarmFeed(deliveries, 0);
    final b = board.alarmFeed(deliveries, 1);
    final formerTotal =
        (a?.strength ?? 0) * (1 - blend) + (b?.strength ?? 0) * blend;
    if (formerTotal < blocker.minimumStrength! ||
        formerTotal > blocker.maximumStrength!) {
      return;
    }
    // A weighted legacy feed may have no safe equivalent on its own.
    final pilot = board.initialLinks.single;
    links.removeWhere(
      (link) => link.to == blocker.id || link.from == pilot.from,
    );
    if (!board.inReach(pilot, positions)) {
      positions[pilot.from] = _openNode(
        pilot.from,
        positions[blocker.id]!,
        positions,
      );
    }
    links.add(pilot);
  }

  static Map<String, SignalPoint> _readSignalPositions(
    Object? data, {
    required bool grid,
    required bool legacy,
    required bool hardware,
    required bool hasService,
  }) {
    final added = {
      for (final link in testLineBoard.initialLinks) ...[link.from, link.to],
    };
    final devices = testLineBoard.devices.where(
      (device) =>
          (hardware || device.kind != SignalDeviceKind.attenuator) &&
          (hasService || device.id != 'service') &&
          (!legacy || !added.contains(device.id)),
    );
    return _readPositions(
      testLineBoard,
      devices,
      data,
      grid: grid,
      legacy: legacy,
      retired: _retiredTestLineParts,
    );
  }

  static Map<String, SignalPoint> _readPositions(
    SignalBoard board,
    Iterable<SignalDevice> devices,
    Object? data, {
    bool grid = false,
    bool legacy = false,
    Set<String> retired = const {},
  }) {
    if (data is! Map ||
        data.keys.where((id) => !retired.contains(id)).length !=
            devices.length) {
      throw const FormatException('Missing device positions.');
    }
    final positions = <String, SignalPoint>{
      if (legacy) ..._legacyAlarmPositions,
      for (final device in devices)
        if (device.fixed) device.id: device.initialPosition,
    };
    for (final device in devices) {
      final point = switch (data[device.id]) {
        {'column': final int column, 'row': final int row} when grid =>
          SignalPoint(column + .5, row + .5),
        {'x': final num x, 'y': final num y} when !grid => SignalPoint(
          x.toDouble(),
          y.toDouble(),
        ),
        _ => null,
      };
      if (point == null ||
          (legacy && point.y > 5.5) ||
          (device.fixed
              ? point != device.initialPosition
              : !board.canMove(device.id, point, positions))) {
        throw const FormatException('Invalid device position.');
      }
      positions[device.id] = point;
    }
    return positions;
  }

  static Map<String, String> _versionThreeIds(
    Map<String, dynamic> json,
    bool legacyPower,
  ) {
    final installed = json['splitterInstalled'];
    if (installed == false) return const {};
    if (installed == true && legacyPower) return const {'splitter': 'twoWay'};
    throw const FormatException('Invalid splitter placement.');
  }

  static Map<String, String> _versionFourIds(Object? data) {
    if (data is! Map) throw const FormatException('Missing placements.');
    final ids = <String, String>{};
    for (final entry in data.entries) {
      final part = SplitterType.values
          .where((part) => part.name == entry.value)
          .firstOrNull;
      if ((entry.key != 'socketA' && entry.key != 'socketB') ||
          part == null ||
          ids.containsValue(part.name)) {
        throw const FormatException('Invalid splitter placement.');
      }
      ids[entry.key as String] = part.name;
    }
    return ids;
  }

  static Map<String, SignalPoint> _legacySignalPositions(
    Map<String, String> ids,
  ) => {
    'beacon': const SignalPoint(.5, .5),
    'twoWay': const SignalPoint(.5, 3.5),
    'threeWay': const SignalPoint(5.5, 2.5),
    'fourWay': const SignalPoint(2.5, 3.5),
    'attenuator': const SignalPoint(4.5, 6.5),
    'terminal': const SignalPoint(.5, 5.5),
    'recorder': const SignalPoint(5.5, 5.5),
    ..._legacyAlarmPositions,
    for (final entry in ids.entries)
      entry.value: SignalPoint(entry.key == 'socketB' ? 2.5 : .5, 2.5),
  };

  static const _legacyAlarmPositions = {
    'pilot': SignalPoint(.5, 6.5),
    'alarmBlocker': SignalPoint(1.5, 6.5),
  };

  static const _retiredTestLineParts = {'aux', 'monitor'};
}

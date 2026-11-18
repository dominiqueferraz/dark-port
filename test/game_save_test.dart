import 'dart:convert';
import 'dart:io';

import 'package:dark_port/game_save.dart';
import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/signal_board.dart';
import 'package:dark_port/tutorial.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:dark_port/wired_boards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save round trips every chapter and rejects invalid board data', () {
    for (final lesson in lessonsById.values) {
      final save = GameSave(lesson);
      final restored = GameSave.fromJson(jsonDecode(jsonEncode(save.toJson())));
      expect(restored.lesson, lesson);
      expect(
        restored.layout.map((o) => o.position),
        save.layout.map((o) => o.position),
      );
    }
    final invalid = GameSave(firstReflection).toJson();
    (invalid['layout'] as List).first['x'] = 0;
    expect(() => GameSave.fromJson(invalid), throwsFormatException);
    final unverified = {
      'version': 1,
      'journey': 'interlock',
      'verified': true,
      'layout': GameSave(opticalInterlock).toJson()['layout'],
    };
    expect(() => GameSave.fromJson(unverified), throwsFormatException);
    final legacy =
        GameSave(
            firstReflection,
            layout: [
              reflectionLesson.initial.first,
              reflectionLesson.initial.last
                  .at(const FloorPoint(1.05, -.27))
                  .rotate(),
            ],
          ).toJson()
          ..remove('board')
          ..addAll({'version': 1, 'journey': 'reflection', 'verified': false});
    expect(GameSave.fromJson(legacy).solved, isTrue);
    final blocked = GameSave(
      opticalInterlock,
      layout: [
        sealedOpticalBay.initial.first.at(const FloorPoint(-1.05, -.27)),
        ...sealedOpticalBay.initial.skip(1),
      ],
    ).toJson();
    expect(() => GameSave.fromJson(blocked), throwsFormatException);
  });

  test('a saved interlock layout from before the alarm rule can resume', () {
    final saved = {
      'version': 1,
      'journey': 'interlock',
      'verified': true,
      'layout': [
        {'id': 'M1', 'x': 3.15, 'y': .78, 'turned': false},
        {'id': 'S1', 'x': -1.05, 'y': .78, 'turned': false},
        {'id': 'M2', 'x': -3.15, 'y': .78, 'turned': false},
      ],
    };
    final restored = GameSave.fromJson(saved);
    final splitter = restored.layout.singleWhere((optic) => optic.id == 'S2');
    expect(splitter.kind, OpticKind.splitter);
    expect(splitter.position, const FloorPoint(3.15, .78));
    expect(restored.solved, isFalse);
    expect(GameSave.fromJson(restored.toJson()).solved, isFalse);
  });

  test('Test Line evaluates inclusive strength bounds', () {
    final goal = testLineBoard.goals.first;
    expect(goal.read(null), SignalReading.quiet);
    expect(
      goal.read((source: 'beacon', channel: 7, strength: 50, hop: 0)),
      SignalReading.wrongChannel,
    );
    expect(
      goal.read((source: 'beacon', channel: 12, strength: 44.99, hop: 0)),
      SignalReading.weak,
    );
    expect(
      goal.read((source: 'beacon', channel: 12, strength: 45, hop: 0)),
      SignalReading.accepted,
    );
    expect(
      goal.read((source: 'beacon', channel: 12, strength: 60, hop: 0)),
      SignalReading.accepted,
    );
    expect(
      goal.read((source: 'beacon', channel: 12, strength: 60.01, hop: 0)),
      SignalReading.strong,
    );
  });

  const receiverRoute = [
    (from: 'beacon', to: 'threeWay', input: 0, output: 0),
    (from: 'threeWay', to: 'twoWay', input: 0, output: 0),
    (from: 'threeWay', to: 'recorder', input: 0, output: 1),
    (from: 'twoWay', to: 'terminal', input: 0, output: 0),
  ];
  const blockerRoute = [
    (from: 'threeWay', to: 'fourWay', input: 0, output: 2),
    (from: 'fourWay', to: 'alarmBlocker', input: 0, output: 0),
  ];
  const pilotService = (from: 'pilot', to: 'service', input: 0, output: 0);
  const beaconService = (from: 'fourWay', to: 'service', input: 0, output: 1);
  const beaconRoute = [...receiverRoute, ...blockerRoute];
  const winningRoute = [...beaconRoute, pilotService];

  const solvedPositions = {
    'beacon': SignalPoint(2.5, 0.5),
    'twoWay': SignalPoint(2.5, 1.5),
    'threeWay': SignalPoint(1.5, 1.5),
    'fourWay': SignalPoint(1.5, 2.5),
    'terminal': SignalPoint(0.5, 1.5),
    'recorder': SignalPoint(1.5, 0.5),
    'service': SignalPoint(.5, 4.5),
    'pilot': SignalPoint(.5, 6.5),
    'alarmBlocker': SignalPoint(1.5, 6.5),
    'attenuator': SignalPoint(4.5, 6.5),
  };

  test('Test Line needs a shared branch and a rearranged board', () {
    final board = testLineBoard;
    final initial = board.initialPositions;
    expect(board.snapAt(const SignalPoint(1.52, 5.43)), (
      position: const SignalPoint(1.5, 5.5),
      intersection: false,
    ));
    expect(board.snapAt(const SignalPoint(2.06, 1.91)), (
      position: const SignalPoint(2, 2),
      intersection: true,
    ));
    expect(board.snapAt(const SignalPoint(-.1, 1)), isNull);
    for (final device in board.devices) {
      expect(board.canMove(device.id, SignalPoint(1.5, 1.5), initial), isTrue);
    }
    expect(board.canMove('beacon', initial['threeWay']!, initial), isFalse);
    expect(
      board.canMove('beacon', const SignalPoint(-.5, .5), initial),
      isFalse,
    );
    expect(
      board.canMove('beacon', const SignalPoint(5.2, .7), initial),
      isFalse,
    );
    expect(
      board.canMove('beacon', const SignalPoint(1.42, 2.14), initial),
      isTrue,
    );
    final diagonal = {
      ...initial,
      'threeWay': const SignalPoint(2, 2),
      'recorder': const SignalPoint(4.4, 4.4),
    };
    const diagonalLink = (
      from: 'threeWay',
      to: 'recorder',
      input: 0,
      output: 0,
    );
    expect(board.distance(diagonalLink, diagonal), closeTo(4.06, 1e-9));
    expect(board.inReach(diagonalLink, diagonal), isFalse);
    diagonal['recorder'] = const SignalPoint(4.37, 4.37);
    expect(board.distance(diagonalLink, diagonal), closeTo(4, 1e-9));
    expect(board.inReach(diagonalLink, diagonal), isTrue);
    expect(
      board.solves(board.evaluate(winningRoute, positions: initial)),
      isFalse,
    );

    Iterable<List<String>> branches(List<String> available) sync* {
      yield const [];
      for (final id in available) {
        for (final tail in branches(
          available.where((other) => other != id).toList(),
        )) {
          yield [id, ...tail];
        }
      }
    }

    Iterable<List<SignalLink>> routes(String target) sync* {
      for (final middle in branches(['twoWay', 'threeWay', 'fourWay'])) {
        final devices = ['beacon', ...middle, target];
        yield [
          for (var index = 1; index < devices.length; index++)
            (from: devices[index - 1], to: devices[index], input: 0, output: 0),
        ];
      }
    }

    // In this compact arrangement the splitters can reach every other
    // splitter and both receivers. Enumerate all topologies independently
    // of where a player chooses to place the parts.
    final solutions = <Set<SignalLink>>[];
    for (final terminal in routes('terminal')) {
      for (final recorder in routes('recorder')) {
        final candidate = {
          ...terminal,
          ...recorder,
          blockerRoute.last,
          blockerRoute.first,
          pilotService,
        };
        final links = <SignalLink>[];
        for (final edge in candidate) {
          final link = (
            from: edge.from,
            to: edge.to,
            input: edge.input,
            output: links.where((other) => other.from == edge.from).length,
          );
          if (links.any((other) => other.to == link.to) ||
              board.linkIssue(links, link, positions: solvedPositions) !=
                  null) {
            break;
          }
          links.add(link);
        }
        if (links.length == candidate.length &&
            board.solves(board.evaluate(links, positions: solvedPositions))) {
          solutions.add(links.toSet());
        }
      }
    }
    expect(
      solutions.map(
        (route) => route.map((link) => (link.from, link.to)).toSet(),
      ),
      [winningRoute.map((link) => (link.from, link.to)).toSet()],
    );
  });

  test('a version 5 grid save restores the same component centers', () {
    final restored = GameSave.fromJson({
      'version': 5,
      'journey': 'testLine',
      'sent': false,
      'positions': {
        'aux': {'column': 0, 'row': 0},
        'monitor': {'column': 2, 'row': 2},
        for (final entry in solvedPositions.entries)
          if (entry.value.y < 6 && entry.key != 'service')
            entry.key: {
              'column': (entry.value.x - .5).toInt(),
              'row': (entry.value.y - .5).toInt(),
            },
      },
      'links': [
        for (final link in receiverRoute) {'from': link.from, 'to': link.to},
      ],
    });
    expect(restored.positions, solvedPositions);
    expect(restored.deliveries[receiverRoute.last]?.strength, 50);
    expect(restored.alarmFailed, isFalse);
    expect(restored.solved, isFalse);
  });

  test('the alarm blocker gates automatic completion at its strength band', () {
    final board = testLineBoard;
    final blocker = board.alarm!.blocker;
    expect(GameSave(testLine).alarmFailed, isFalse);
    for (final strength in [24.99, 25.0, 35.0, 35.01]) {
      expect(
        blocker.read((
              source: 'beacon',
              channel: 12,
              strength: strength,
              hop: 0,
            )) ==
            SignalReading.accepted,
        strength >= 25 && strength <= 35,
      );
    }

    final onPilot = GameSave(
      testLine,
      links: [...board.initialLinks, ...receiverRoute],
      positions: solvedPositions,
    );
    expect(onPilot.alarmFailed, isFalse);
    expect(onPilot.solved, isFalse);

    final onBeacon = GameSave(
      testLine,
      links: beaconRoute,
      positions: solvedPositions,
    );
    expect(onBeacon.deliveries[blockerRoute.last]?.source, 'beacon');
    expect(onBeacon.deliveries[blockerRoute.last]?.strength, 25);
    expect(onBeacon.alarmFailed, isFalse);
    expect(onBeacon.solved, isFalse);

    final interrupted = GameSave(
      testLine,
      links: receiverRoute,
      positions: solvedPositions,
    );
    expect(interrupted.alarmFailed, isTrue);
    expect(interrupted.solved, isFalse);
    expect(interrupted.deliveries[receiverRoute.last]?.strength, 50);

    final unpowered = GameSave.fromJson(interrupted.toJson());
    expect(unpowered.alarmFailed, isTrue);
    expect(unpowered.solved, isFalse);
  });

  test('Service requires the Pilot output at its full 30 units', () {
    final board = testLineBoard;
    final service = board.device('service')!;
    expect(
      board.linkIssue(
        board.initialLinks,
        pilotService,
        positions: solvedPositions,
      ),
      LinkIssue.occupied,
    );

    for (final (link, loss, reading) in [
      (beaconService, 0, SignalReading.wrongSource),
      (pilotService, 10, SignalReading.weak),
      (pilotService, 0, SignalReading.accepted),
    ]) {
      final save = GameSave(
        testLine,
        links: [...beaconRoute, link],
        positions: solvedPositions,
        losses: {'pilot': loss},
      );
      expect(save.alarmFailed, isFalse);
      expect(service.read(save.deliveries[link]), reading);
      expect(save.solved, reading == SignalReading.accepted);
    }
  });

  test('Test Line saves movable parts and preserves cables beyond reach', () {
    final save = GameSave(
      testLine,
      links: winningRoute,
      positions: {...solvedPositions, 'beacon': const SignalPoint(3.47, .71)},
    );
    final json = jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
    final restored = GameSave.fromJson(json);
    expect(restored.positions, save.positions);
    expect(restored.links, save.links);
    expect(restored.deliveries[receiverRoute.last]?.strength, 50);
    expect(restored.solved, isTrue);

    final positions = json['positions'] as Map;
    positions['recorder'] = {'x': 5.5, 'y': 5.5};
    final moved = GameSave.fromJson(json);
    expect(moved.links, save.links);
    expect(moved.solved, isFalse);
    expect(
      moved.deliveries.containsKey((
        from: 'threeWay',
        to: 'recorder',
        input: 0,
        output: 1,
      )),
      isFalse,
    );
    positions['recorder'] = positions['twoWay'];
    expect(() => GameSave.fromJson(json), throwsFormatException);
    positions['recorder'] = {'x': -1, 'y': 0};
    expect(() => GameSave.fromJson(json), throwsFormatException);
  });

  test(
    'saved boards retain their routes after redundant parts are retired',
    () {
      final capstone = GameSave(
        testLine,
        links: winningRoute,
        positions: solvedPositions,
      ).toJson();
      (capstone['positions'] as Map<String, Map<String, double>>).addAll({
        'aux': {'x': .5, 'y': .5},
        'monitor': {'x': 2.5, 'y': 2.5},
      });
      (capstone['links'] as List<Map<String, Object>>).add({
        'from': 'twoWay',
        'to': 'monitor',
        'input': 0,
        'output': 1,
      });
      (capstone['flipped'] as List<String>).add('aux');
      final restored = GameSave.fromJson(capstone);
      expect(restored.solved, isTrue);
      expect(restored.links, winningRoute);
      expect(restored.positions, solvedPositions);
      expect(restored.flipped, isEmpty);

      final split = GameSave(splitRatings).toJson();
      (split['positions'] as Map<String, Map<String, double>>).addAll({
        'fourWay': {'x': 2.5, 'y': 4.5},
        'monitor': {'x': 5.5, 'y': 4.5},
      });
      final restoredSplit = GameSave.fromJson(split);
      expect(restoredSplit.positions, splitRatings.board.initialPositions);
    },
  );

  test('discrete attenuation keeps the combined alarm feed within range', () {
    final board = testLineBoard;
    final beaconFeed = [
      ...receiverRoute,
      blockerRoute.first,
      (from: 'fourWay', to: 'attenuator', input: 0, output: 0),
      (from: 'attenuator', to: 'alarmBlocker', input: 1, output: 0),
    ];
    final links = [...board.initialLinks, ...beaconFeed];
    for (final (pilot, pad, total) in [
      (0, 20, 35),
      (10, 20, 25),
      (10, 10, 35),
      (20, 10, 25),
      (20, 0, 35),
    ]) {
      final save = GameSave(
        testLine,
        links: links,
        positions: solvedPositions,
        flipped: {'attenuator'},
        losses: {'pilot': pilot, 'attenuator': pad},
      );
      final restored = GameSave.fromJson(save.toJson());
      expect(restored.flipped, {'attenuator'});
      expect(restored.losses, save.losses);
      expect(restored.links, links);
      expect(board.alarmPower(restored.deliveries)!.strength, total);
      expect(restored.alarmFailed, isFalse);
      expect(restored.solved, isFalse);
    }
    final handedOff = GameSave(
      testLine,
      links: beaconFeed,
      positions: solvedPositions,
      flipped: {'attenuator'},
      losses: {'pilot': 20, 'attenuator': 0},
    );
    expect(board.alarmPower(handedOff.deliveries)!.strength, 25);
    expect(handedOff.solved, isFalse);
    final solved = GameSave(
      testLine,
      links: [...beaconFeed, pilotService],
      positions: solvedPositions,
      flipped: handedOff.flipped,
      losses: {'pilot': 0, 'attenuator': 0},
    );
    expect(solved.solved, isTrue);
  });

  test('older completed saves retain Beacon power and add Service', () {
    for (final version in [7, 8, 9]) {
      final oldSave = GameSave(
        testLine,
        links: version != 8
            ? beaconRoute
            : [
                ...testLineBoard.initialLinks,
                ...beaconRoute.take(beaconRoute.length - 1),
                (from: 'fourWay', to: 'alarmBlocker', input: 1, output: 0),
              ],
        positions: solvedPositions,
        flipped: version == 9 ? {'attenuator'} : {},
        losses: version == 9 ? {'pilot': 20} : {},
      ).toJson();
      oldSave
        ..remove('board')
        ..addAll({'version': version, 'journey': 'testLine'});
      if (version == 8) oldSave['alarmBlend'] = 1.0;
      (oldSave['positions'] as Map).remove('service');
      if (version < 9) (oldSave['positions'] as Map).remove('attenuator');
      for (final link in oldSave['links'] as List) {
        if (version < 9) (link as Map).remove('output');
        if (version == 7) link.remove('input');
      }
      final migrated = GameSave.fromJson(oldSave);
      expect(migrated.alarmFailed, isFalse);
      expect(migrated.solved, isFalse);
      expect(migrated.positions['service'], solvedPositions['service']);
      expect(migrated.flipped, version == 9 ? {'attenuator'} : isEmpty);
      expect(migrated.losses, version == 9 ? {'pilot': 20} : isEmpty);
      expect(migrated.positions['attenuator'], solvedPositions['attenuator']);
      expect(
        migrated.links.where((link) => link.to == 'alarmBlocker').single.from,
        'fourWay',
      );
    }
  });

  test('a live version 10 cable can migrate to a jack within reach', () {
    const oldCable = (from: 'fourWay', to: 'terminal', input: 0, output: 3);
    const beaconFeed = (from: 'beacon', to: 'fourWay', input: 0, output: 0);
    final save = GameSave(
      testLine,
      links: [...testLineBoard.initialLinks, beaconFeed, oldCable],
      positions: {
        ...solvedPositions,
        'fourWay': const SignalPoint(4.5, 5.5),
        'terminal': const SignalPoint(.5, 3),
      },
    );
    expect(save.deliveries[oldCable], isNull);
    final json = save.toJson()
      ..remove('board')
      ..addAll({'version': 10, 'journey': 'testLine'});
    final restored = GameSave.fromJson(json);
    final cable = restored.links.singleWhere((link) => link.to == 'terminal');
    expect(cable.output, 1);
    expect(restored.deliveries[cable]?.strength, 75);
    expect(restored.positions, save.positions);
  });

  test('a dashed version 10 cable stays out of reach after migration', () {
    const oldCable = (from: 'fourWay', to: 'terminal', input: 0, output: 3);
    const beaconFeed = (from: 'beacon', to: 'fourWay', input: 0, output: 0);
    final save = GameSave(
      testLine,
      links: [...testLineBoard.initialLinks, beaconFeed, oldCable],
      positions: {
        ...solvedPositions,
        'fourWay': const SignalPoint(.5, 2.5),
        'terminal': const SignalPoint(5.5, 5),
      },
    );
    expect(save.deliveries[oldCable]?.strength, 75);
    final restored = GameSave.fromJson(
      save.toJson()
        ..remove('board')
        ..addAll({'version': 10, 'journey': 'testLine'}),
    );
    final cable = restored.links.singleWhere((link) => link.to == 'terminal');
    expect(cable.output, 1);
    expect(restored.deliveries[cable], isNull);
    expect(restored.positions, save.positions);
  });

  test('older Test Line saves restore wiring with movable splitters', () {
    for (final (version, journey, socket) in [
      (2, 'relayLine', 'relay'),
      (3, 'powerLine', 'splitter'),
      (4, 'testLine', 'socketA'),
    ]) {
      final restored = GameSave.fromJson({
        'version': version,
        'journey': journey,
        'sent': true,
        if (version == 3) 'splitterInstalled': true,
        if (version == 4) 'placements': {'socketA': 'twoWay'},
        'links': [
          {'from': 'beacon', 'to': socket},
          {'from': socket, 'to': 'terminal'},
        ],
      });
      expect(restored.lesson, testLine);
      expect(restored.positions['twoWay'], SignalPoint(0.5, 2.5));
      expect(restored.links, [
        ...testLineBoard.initialLinks,
        (from: 'beacon', to: 'twoWay', input: 0, output: 0),
        (from: 'twoWay', to: 'terminal', input: 0, output: 0),
      ]);
      expect(restored.deliveries[restored.links.last]?.strength, 150);
      expect(restored.solved, isFalse);
    }
  });

  test('serialized file writes survive relaunch and a write failure can be retried', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dark-port-save-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/journey.json');
    final store = GameStore(locate: () async => file);
    expect(await store.load(), isNull);
    final writes = [
      store.write(TutorialProgress()),
      store.write(TutorialProgress(completed: {firstReflection.id})),
      store.write(
        TutorialProgress(completed: {firstReflection.id, dividedBeam.id}),
      ),
    ];
    await Future.wait(writes);
    expect((await GameStore(locate: () async => file).load())!.completed, {
      firstReflection.id,
      dividedBeam.id,
    });
    expect(await File('${file.path}.tmp').exists(), isFalse);

    var fail = true;
    final retryStore = GameStore(
      locate: () async {
        if (fail) throw const FileSystemException('Unavailable');
        return file;
      },
    );
    await expectLater(
      retryStore.write(TutorialProgress()),
      throwsA(isA<FileSystemException>()),
    );
    fail = false;
    await retryStore.write(TutorialProgress());
    expect((await retryStore.load())!.completed, isEmpty);
  });
}

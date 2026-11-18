import 'package:dark_port/endless_levels.dart';
import 'package:dark_port/game_save.dart';
import 'package:dark_port/handoff_boards.dart';
import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/optical_deck.dart';
import 'package:dark_port/signal_board.dart';
import 'package:dark_port/signal_playfield.dart';
import 'package:dark_port/tutorial.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/board_arrangements.dart';
import 'support/memory_store.dart';
import 'support/pump_silent_game.dart';
import 'support/puzzle_announcement.dart';

const _fixtures = [
  (EndlessLevel.bothFaces, 6, [100, 100], <int>[]),
  (EndlessLevel.twoBranchesTwoBends, 32, [50, 50], <int>[]),
  (EndlessLevel.firstConversion, 4, [50], [30]),
  (EndlessLevel.meshWindow, 16, [50], [30]),
  (EndlessLevel.aroundTheShield, 36, [50], [30]),
  (EndlessLevel.splitTwice, 16, [25, 25], [30]),
  (EndlessLevel.crossedChannels, 32, <int>[], [30, 30]),
  (EndlessLevel.serviceAndInspection, 4, [50], [30]),
  (EndlessLevel.oneMirrorTwoWindows, 6, <int>[], [80, 80]),
  (EndlessLevel.dualHandoff, 24, [50, 50], [30, 30]),
];

const _mastLink = (from: 'splitter', to: 'broadcaster', output: 0, input: 0);
const _serviceRoutes = [
  ('shielded-service', SignalPoint(4.76, 2.5), LeadType.shielded, 4),
  ('trunk-service', SignalPoint(1.76, 3.5), LeadType.trunk, 6),
  ('ordinary-service', SignalPoint(4.76, 3.5), LeadType.patch, 3),
];

List<Optic> _win(OpticalLevel board) =>
    opticalArrangements(board)
        .singleWhere((layout) => traceOptics(board, layout).solves(board));

List<Optic> _edit(List<Optic> layout, String id, Optic Function(Optic) edit) =>
    [for (final optic in layout) optic.id == id ? edit(optic) : optic];

OpticalLevel _copy(
  OpticalLevel board, {
  List<OpticalSource>? sources,
  List<OpticalBarrier>? barriers,
  List<OpticalAntenna>? antennas,
}) => OpticalLevel(
  title: board.title,
  laser: board.laser,
  laserFoot: board.laserFoot,
  direction: board.direction,
  sourceLabel: board.sourceLabel,
  additionalSources: sources ?? board.additionalSources,
  receivers: board.receivers,
  goal: board.goal,
  initial: board.initial,
  floor: board.floor,
  blocks: board.blocks,
  barriers: barriers ?? board.barriers,
  antennas: antennas ?? board.antennas,
  mounts: board.mounts,
  tileSize: board.tileSize,
);

Optic _changeConverter(
  Optic optic, {
  bool unkey = false,
  int? channel,
  double? reach,
}) {
  final converter = optic.converter!;
  return Optic(
    optic.id,
    optic.kind,
    optic.position,
    fixed: optic.fixed,
    converter: OpticalConverter(
      channel: channel ?? converter.channel,
      power: converter.power,
      requiredSource: unkey ? null : converter.requiredSource,
      reach: reach ?? converter.reach,
      lanes: converter.lanes,
    ),
  );
}

void main() {
  test(
    'exhausts the authored optical mounts and orientations on 1.11–1.20',
    () {
      var progress = TutorialProgress();
      for (final (level, count, local, remote) in _fixtures) {
        final lesson = level.lesson! as OpticalLesson;
        final board = lesson.board;
        final states = opticalArrangements(board).toList();
        expect(states, hasLength(count), reason: level.title);
        expect(GameSave(lesson).solved, isFalse, reason: level.title);
        final victories = states.where(
          (layout) => traceOptics(board, layout).solves(board),
        );
        expect(victories, hasLength(1), reason: level.title);
        final layout = victories.single;
        final trace = traceOptics(board, layout);
        expect(
          board.goal.map((goal) => trace.receivedPower(goal) * 100),
          local,
        );
        expect(trace.radioReadings.map((reading) => reading.power), remote);
        final save = GameSave(lesson, layout: layout);
        if (lesson.wiredBoard == null) {
          expect(save.solved, isTrue);
          final restored = GameSave.fromJson(save.toJson());
          expect(restored.solved, isTrue);
          expect(restored.toJson(), save.toJson());
          progress = progress.recordEndless(save).recordEndless(restored);
          expect(progress.resultFor(level)!.stars, {level.solutionIds.single});
        } else {
          expect(save.solved, isFalse);
          expect(progress.recordEndless(save).resultFor(level), isNull);
        }
      }
      final loaded = TutorialProgress.fromJson(progress.toJson());
      expect(loaded.endlessResults, hasLength(9));
    },
  );

  test(
    'both mirror faces share a diagonal and each branch needs its own bend',
    () {
      final mirror = bothFacesLesson.board;
      final layout = _win(mirror);
      final reversed = _edit(layout, 'M1', (optic) => optic.rotate());
      expect(traceOptics(mirror, reversed).lit, isEmpty);
      final leftOnly = _copy(mirror, sources: []);
      expect(traceOptics(leftOnly, layout).lit, {0});
      final right = mirror.additionalSources.single;
      final rightOnly = OpticalLevel(
        title: mirror.title,
        laser: right.position,
        laserFoot: right.foot,
        direction: right.direction,
        receivers: mirror.receivers,
        goal: mirror.goal,
        initial: mirror.initial,
        floor: mirror.floor,
      );
      expect(traceOptics(rightOnly, layout).lit, {1});
      final decoy = _edit(
        layout,
        'M1',
        (optic) => optic.at(const FloorPoint(6, 4.5)),
      );
      expect(traceOptics(mirror, decoy).lit, {0});

      final bends = twoBranchesTwoBendsLesson.board;
      final routed = _win(bends);
      for (final (mirror, sensor, other) in [('M1', 0, 1), ('M2', 1, 0)]) {
        final missing = traceOptics(
          bends,
          routed.where((optic) => optic.id != mirror).toList(),
        );
        expect(missing.receivedPower(sensor), 0);
        expect(missing.receivedPower(other), .5);
      }
      final sameBranch = _edit(
        routed,
        'M1',
        (optic) => optic.at(const FloorPoint(3, 4)),
      );
      expect(traceOptics(bends, sameBranch).lit, isEmpty);
    },
  );

  test(
    'conversion, wall material, coverage and strength fail independently',
    () {
      final conversion = firstConversionLesson.board;
      expect(traceOptics(conversion, conversion.initial).receivedPower(0), .5);
      expect(
        traceOptics(
          conversion,
          conversion.initial,
        ).converterInputs['C1']!.power,
        0,
      );
      final longHop = _copy(
        conversion,
        antennas: const [
          OpticalAntenna('Remote', FloorPoint(10, 3), channel: 12, minimum: 30),
        ],
      );
      final longer = _edit(
        _win(conversion),
        'C1',
        (optic) => _changeConverter(optic, reach: 5),
      );
      expect(
        traceOptics(longHop, _win(conversion)).radioReadings.single.status,
        RadioReception.outOfRange,
      );
      expect(traceOptics(longHop, longer).radioReadings.single.power, 25);

      final window = meshWindowLesson.board;
      final invalidLayout = GameSave(meshWindowLesson).toJson();
      final savedConverter = (invalidLayout['layout']! as List).last as Map;
      savedConverter['x'] = (savedConverter['x'] as double) + 1e-9;
      expect(() => GameSave.fromJson(invalidLayout), throwsFormatException);
      expect(
        traceOptics(window, window.initial).radioReadings.single.status,
        RadioReception.blocked,
      );
      final swapped = _copy(
        window,
        barriers: [
          for (final barrier in window.barriers)
            (
              bounds: barrier.bounds,
              material: barrier.material == BarrierMaterial.concrete
                  ? BarrierMaterial.mesh
                  : BarrierMaterial.concrete,
            ),
        ],
      );
      expect(traceOptics(swapped, window.initial).solves(swapped), isTrue);
      expect(
        traceOptics(swapped, _win(window)).radioReadings.single.status,
        RadioReception.blocked,
      );
      final mesh = window.barriers.last;
      final lightAtMesh = OpticalLevel(
        title: 'Light at mesh',
        laser: const FloorPoint(7, 2),
        laserFoot: const FloorPoint(7, 1),
        direction: BeamDirection.north,
        receivers: const [
          OpticalReceiver('Beyond', FloorPoint(7, 5), BeamDirection.north),
        ],
        goal: const {0},
        initial: const [],
        floor: window.floor,
        barriers: [mesh],
      );
      final stopped = traceOptics(lightAtMesh, []);
      expect(stopped.segments.single.to.y, closeTo(mesh.bounds.top, 1e-9));
      expect(stopped.lit, isEmpty);

      final shield = aroundTheShieldLesson.board;
      final layouts = opticalArrangements(shield);
      for (final (lane, distance, status, power) in [
        (const FloorPoint(10, 5), 3, RadioReception.blocked, 0),
        (const FloorPoint(7, 1), 4, RadioReception.accepted, 30),
        (const FloorPoint(2, 5), 5, RadioReception.weak, 25),
      ]) {
        final fired = layouts
            .map((layout) => traceOptics(shield, layout))
            .singleWhere((trace) => trace.radioHops.singleOrNull?.from == lane);
        final read = fired.radioReadings.single;
        expect(read.distance, distance);
        expect(read.status, status);
        expect(read.power, power);
        expect(fired.receivedPower(0), .5);
      }
    },
  );

  test(
    '25 u is too weak for radio and a clear wrong channel stays rejected',
    () {
      final split = splitTwiceLesson.board;
      final solution = _win(split);
      final weakLayout = _edit(
        solution,
        'M1',
        (optic) => optic.at(const FloorPoint(8, 5)),
      );
      final weak = traceOptics(split, weakLayout);
      expect(weak.radioHops.single.emitted, 25);
      expect(weak.radioReadings.single.power, 5);
      expect(weak.radioReadings.single.status, RadioReception.weak);
      expect(
        traceOptics(
          split,
          solution.where((optic) => optic.id != 'S2').toList(),
        ).lit,
        {0},
      );

      final crossed = crossedChannelsLesson.board;
      final match = _win(crossed);
      final partial = traceOptics(
        crossed,
        _edit(match, 'M2', (optic) => optic.rotate()),
      );
      expect(partial.radioReadings.map((reading) => reading.status), [
        RadioReception.accepted,
        RadioReception.wrongChannel,
      ]);
      expect(partial.radioReadings.last.hop!.channel, 9);
      final swap = [
        for (final optic in match)
          optic.converter == null
              ? optic
              : _changeConverter(
                  optic,
                  channel: optic.converter!.channel == 9 ? 12 : 9,
                ),
      ];
      expect(
        traceOptics(
          crossed,
          swap,
        ).radioReadings.map((reading) => reading.status),
        [RadioReception.wrongChannel, RadioReception.weak],
      );
      expect(
        opticalArrangements(crossed).where((layout) {
          final open = _copy(crossed, barriers: []);
          return traceOptics(open, layout).solves(open);
        }),
        hasLength(1),
      );
    },
  );

  test(
    'both keyed converters reject the wrong laser even at full input power',
    () {
      for (final lesson in [oneMirrorTwoWindowsLesson, dualHandoffLesson]) {
        final board = lesson.board;
        final win = _win(board);
        final reversed = _edit(win, 'M1', (optic) => optic.rotate());
        final rejected = traceOptics(board, reversed);
        expect(
          rejected.converterInputs.values.map((reading) => reading.status),
          everyElement(ConverterReception.wrongSource),
        );
        expect(
          rejected.converterInputs.values.map((reading) => reading.source),
          ['R', 'L'],
        );
        expect(rejected.radioHops, isEmpty);
        expect(rejected.solves(board), isFalse);
        final unkeyed = [
          for (final optic in reversed)
            optic.converter == null
                ? optic
                : _changeConverter(optic, unkey: true),
        ];
        expect(traceOptics(board, unkeyed).solves(board), isTrue);
        for (final x in [4.0, 6.0]) {
          final displaced = _edit(
            win,
            'M1',
            (optic) => optic.at(FloorPoint(x, 4)),
          );
          expect(traceOptics(board, displaced).radioHops, isEmpty);
        }
      }
      final dual = dualHandoffLesson.board;
      for (final (part, local) in [('SL', 0), ('SR', 1)]) {
        final toggled = _edit(_win(dual), part, (optic) => optic.rotate());
        final trace = traceOptics(dual, toggled);
        expect(trace.receivedPower(local), 0);
        expect(trace.receivedPower(1 - local), .5);
        expect(trace.radioReadings.map((reading) => reading.power), [30, 30]);
      }
    },
  );

  test('service wiring has three canonical routes and needs a live optical circuit', () {
    final board = serviceAndInspectionBoard;
    final lesson = serviceAndInspectionLesson;
    const level = EndlessLevel.serviceAndInspection;
    final states = wiredArrangements(board).toList();
    final solved = states.where((state) => state.solved);
    expect(states.length, 32);
    expect(solved.length, 5);
    expect(solved.map(level.solutionFor).toSet(), level.solutionIds.toSet());
    final layout = _win(lesson.board);
    final optics = opticalArrangements(lesson.board).toList();
    final savedSolutions = <String, int>{};
    var progress = TutorialProgress();
    for (final wiring in states) {
      for (final arrangement in optics) {
        final save = GameSave.fromSignal(lesson, wiring, layout: arrangement);
        final restored = GameSave.fromJson(save.toJson());
        expect(restored.toJson(), save.toJson());
        expect(restored.solved, save.solved);
        if (!save.solved) continue;
        final id = level.solutionFor(wiring)!;
        savedSolutions.update(id, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    expect(savedSolutions.values.fold(0, (a, b) => a + b), solved.length);
    expect(savedSolutions, {
      'shielded-service': 1,
      'trunk-service': 2,
      'ordinary-service': 2,
    });
    for (final (id, mount, type, length) in _serviceRoutes) {
      final wiring = solved.singleWhere(
        (state) =>
            state.positions['splitter'] == mount &&
            state.leadType(_mastLink) == type &&
            state.leadTypes.keys.every((link) => link == _mastLink),
      );
      expect(
        board.distance(_mastLink, wiring.positions),
        closeTo(length, 1e-9),
      );
      expect(
        wiring.deliveries.entries
            .where((entry) => entry.key.to == 'guard')
            .single
            .value
            .strength,
        30,
      );
      expect(
        board.solves({
          for (final entry in wiring.deliveries.entries)
            entry.key: entry.key.to == 'guard'
                ? (source: 'feed', channel: 12, strength: 35, hop: 3)
                : entry.value,
        }),
        isFalse,
      );
      expect(GameSave.fromSignal(lesson, wiring).solved, isFalse);
      final save = GameSave.fromSignal(lesson, wiring, layout: layout);
      progress = progress.recordEndless(save).recordEndless(save);
      expect(progress.resultFor(level)!.stars, contains(id));
      for (final link in wiring.links) {
        final incomplete = wiring.copyWith(
          links: wiring.links.where((installed) => installed != link).toList(),
        );
        expect(
          GameSave.fromSignal(lesson, incomplete, layout: layout).solved,
          isFalse,
        );
      }
    }
    final serialised = TutorialProgress.fromJson(progress.toJson());
    expect(serialised.resultFor(level)!.stars, level.solutionIds.toSet());

    final shielded = solved.firstWhere(
      (state) => state.positions['splitter'] == _serviceRoutes[0].$2,
    );
    final trunk = solved.firstWhere(
      (state) => state.positions['splitter'] == _serviceRoutes[1].$2,
    );
    expect(
      board.cableIssue(_mastLink, shielded.positions),
      LinkIssue.interference,
    );
    expect(board.cableIssue(_mastLink, trunk.positions), LinkIssue.feedthrough);
    expect(
      board.cableIssue(_mastLink, trunk.positions, type: LeadType.shielded),
      LinkIssue.range,
    );
    final occupied = (from: 'splitter', to: 'load', input: 0, output: 1);
    expect(
      board.linkIssue(
        [occupied],
        _mastLink,
        positions: shielded.positions,
        type: LeadType.shielded,
        leadTypes: {occupied: LeadType.shielded},
      ),
      LinkIssue.stock,
    );
  });

  testWidgets('plays all ten sheets and replays every service route', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(667, 375);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await playHandoffBoards(tester, MemoryStore());
  });
}

Future<void> playHandoffBoards(WidgetTester tester, GameStore store) async {
  final optical = find.byKey(const ValueKey('optical-deck'));
  final wired = find.byKey(const ValueKey('signal-playfield'));
  final complete = find.byKey(const ValueKey('lesson-complete'));
  final back = find.byTooltip('Back to puzzles');

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> open(EndlessLevel level) async {
    await tap(find.byKey(ValueKey('endless-1.${level.number}')));
    expect(complete, findsNothing);
  }

  Future<void> playOptics(OpticalLevel board) async {
    final winning = _win(board);
    final bounds = tester.getRect(optical);
    final geometry = OpticalDeckGeometry(board, bounds.size, fill: true);
    Offset point(FloorPoint point) => bounds.topLeft + geometry.project(point);
    for (final start in board.initial) {
      if (start.fixed) continue;
      final needed = winning.singleWhere((optic) => optic.id == start.id);
      if (needed.position != start.position) {
        await tester.dragFrom(
          point(start.position),
          point(needed.position) - point(start.position),
        );
        await tester.pumpAndSettle();
      }
      if (needed.turned != start.turned) {
        await tester.tapAt(point(needed.position));
        await tester.pumpAndSettle();
      }
    }
  }

  Finder part(String id) => find.byKey(ValueKey('signal-device-$id'));
  Future<void> chooseOutput(int output) async {
    final geometry = SignalBoardGeometry(
      serviceAndInspectionBoard,
      tester.getSize(wired),
    );
    await tester.tapAt(
      tester.getCenter(part('splitter')) +
          geometry.project(SignalBoard.outputPort(output)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> previewAndInstall(String target) async {
    await tap(part(target));
    expect(
      find.textContaining('Tap the input again to install.'),
      findsOneWidget,
    );
    await tap(part(target));
  }

  Future<void> playWiring(SignalPoint mount, LeadType type) async {
    final board = serviceAndInspectionBoard;
    final bounds = tester.getRect(wired);
    final geometry = SignalBoardGeometry(board, bounds.size);
    if (mount != board.initialPositions['splitter']) {
      final from = tester.getCenter(part('splitter'));
      await tester.dragFrom(
        from,
        bounds.topLeft + geometry.project(mount) - from,
      );
      await tester.pumpAndSettle();
    }
    await tap(part('feed'));
    await previewAndInstall('splitter');
    await chooseOutput(1);
    await previewAndInstall('load');
    await chooseOutput(0);
    await previewAndInstall('broadcaster');
    if (type != LeadType.patch) {
      expect(
        find.byTooltip('0 of 1 ${type.name} leads available'),
        findsOneWidget,
      );
    }
  }

  await pumpSilentGame(tester, store);
  await tester.pumpAndSettle();
  await tap(find.text('Endless'));
  await tap(find.byKey(const ValueKey('endless-group-1')));
  for (final (level, _, _, _) in _fixtures) {
    final lesson = level.lesson! as OpticalLesson;
    if (level == EndlessLevel.serviceAndInspection) {
      final earned = <String>{};
      for (final (id, mount, type, _) in _serviceRoutes) {
        await open(level);
        if (type == LeadType.shielded) {
          await tap(find.text('Optical'));
          await playOptics(lesson.board);
          expect(complete, findsNothing);
          expect(puzzleAnnouncement, findsNothing);
          await tap(back);
          await open(level);
          await playWiring(mount, type);
        } else {
          await playWiring(mount, type);
          expect(complete, findsNothing);
          expect(puzzleAnnouncement, findsNothing);
          await tap(find.text('Optical'));
          await playOptics(lesson.board);
        }
        expect(complete, findsOneWidget, reason: id);
        await dismissPuzzleAnnouncement(tester);
        earned.add(id);
        final saved = (await store.load())!;
        expect(saved.resultFor(level)!.stars, earned);
        expect(saved.endlessBoards[lesson.id]!.solved, isTrue);
        await tap(back);
      }
    } else {
      await open(level);
      await playOptics(lesson.board);
      expect(complete, findsOneWidget, reason: level.title);
      await dismissPuzzleAnnouncement(tester);
      expect(
        (await store.load())!.resultFor(level)!.stars,
        level.solutionIds.toSet(),
      );
      await tap(back);
    }
  }

  await open(EndlessLevel.dualHandoff);
  await playOptics(dualHandoffLesson.board);
  expect(complete, findsOneWidget);
  expect(puzzleAnnouncement, findsNothing);
}

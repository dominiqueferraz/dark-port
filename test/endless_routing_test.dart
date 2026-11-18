import 'dart:math' as math;

import 'package:dark_port/endless_levels.dart';
import 'package:dark_port/game_save.dart';
import 'package:dark_port/lead_stock.dart';
import 'package:dark_port/main.dart';
import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/optical_deck.dart';
import 'package:dark_port/signal_board.dart';
import 'package:dark_port/signal_board_state.dart';
import 'package:dark_port/signal_playfield.dart';
import 'package:dark_port/tutorial.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_store.dart';
import 'support/puzzle_announcement.dart';

SignalLink _link(String from, String to, [int output = 0]) =>
    (from: from, to: to, output: output, input: 0);

double? _power(SignalBoardState state, String target) => state
    .deliveries
    .entries
    .where((entry) => entry.key.to == target)
    .firstOrNull
    ?.value
    .strength;

Iterable<SignalBoardState> _wiredArrangements(SignalBoard board) sync* {
  final moving = board.devices.where((device) => !device.fixed).toList();
  final outputs = [
    for (final part in board.devices)
      for (var output = 0; output < part.outputs; output++) (part.id, output),
  ];

  Iterable<SignalBoardState> wire(
    Map<String, SignalPoint> positions,
    int index,
    Map<SignalLink, LeadType> leads,
  ) sync* {
    final links = leads.keys.toList();
    if (index == outputs.length) {
      yield SignalBoardState(
        board,
        positions: positions,
        links: links,
        leadTypes: leads,
      );
      return;
    }
    yield* wire(positions, index + 1, leads);
    final (source, output) = outputs[index];
    for (final target in board.devices.where((part) => part.hasInput)) {
      if (links.any((link) => link.to == target.id)) continue;
      final link = _link(source, target.id, output);
      for (final type in LeadType.values) {
        if (board.linkIssue(
              links,
              link,
              positions: positions,
              type: type,
              leadTypes: leads,
            ) ==
            null) {
          yield* wire(positions, index + 1, {...leads, link: type});
        }
      }
    }
  }

  Iterable<SignalBoardState> move(
    int index,
    Map<String, SignalPoint> positions,
  ) sync* {
    if (index == moving.length) {
      yield* wire(positions, 0, {});
      return;
    }
    final part = moving[index];
    expect(part.canFlip, isFalse);
    for (final mark in board.mountsFor(part.id)) {
      if (board.canMove(part.id, mark.position, positions)) {
        yield* move(index + 1, {...positions, part.id: mark.position});
      }
    }
  }

  yield* move(0, board.initialPositions);
}

Iterable<List<Optic>> _opticalArrangements(
  OpticalLevel board, [
  List<Optic> layout = const [],
]) sync* {
  if (layout.length == board.initial.length) {
    yield layout;
    return;
  }
  final optic = board.initial[layout.length];
  for (final mark in board.mounts[optic.id]!) {
    final moved = optic.at(mark.position);
    if (board.canPlace(moved, layout)) {
      yield* _opticalArrangements(board, [...layout, moved]);
      yield* _opticalArrangements(board, [...layout, moved.rotate()]);
    }
  }
}

void main() {
  test(
    'exhausts all authored mounts, sockets, stock and diagonals on 1.6–1.10',
    () async {
      var progress = TutorialProgress(tutorialStarted: false);
      for (final (level, count, readings) in [
        (EndlessLevel.relayShelf, 23, [40]),
        (EndlessLevel.twoMasts, 16, [40, 35]),
        (EndlessLevel.quietSector, 6, [35, 50, null]),
      ]) {
        final lesson = level.lesson! as WiredLesson;
        final states = _wiredArrangements(lesson.board).toList();
        expect(states, hasLength(count), reason: level.title);
        final win = states.where((state) => state.solved).single;
        expect(
          lesson.board.goals.map((goal) => _power(win, goal.id)),
          readings,
        );
        expect(level.solutionFor(win), level.solutionIds.single);
        progress = progress.recordEndless(GameSave.fromSignal(lesson, win));
      }
      for (final (level, count, readings) in [
        (EndlessLevel.cornerMirror, 4, [100]),
        (EndlessLevel.splitAroundTheBaffle, 8, [50, 50]),
      ]) {
        final lesson = level.lesson! as OpticalLesson;
        final states = _opticalArrangements(lesson.board).toList();
        expect(states, hasLength(count));
        final win = states
            .map((layout) => GameSave(lesson, layout: layout))
            .where((board) => board.solved)
            .single;
        final trace = traceOptics(lesson.board, win.layout);
        expect(
          lesson.board.goal.map((i) => trace.receivedPower(i) * 100),
          readings,
        );
        progress = progress.recordEndless(win);
      }
      final store = MemoryStore();
      await store.write(progress);
      final loaded = (await store.load())!;
      for (final level in EndlessLevel.values.skip(5).take(5)) {
        final id = level.lesson!.id;
        final board = loaded.endlessBoards[id]!;
        expect(board.solved, isTrue);
        expect(
          board.signal?.leadTypes,
          progress.endlessBoards[id]!.signal?.leadTypes,
        );
        expect(loaded.resultFor(level)!.stars, level.solutionIds.toSet());
        expect(loaded.recordEndless(board), same(loaded));
      }
    },
  );

  test('Relay Shelf separates reach, stock, interference and relay power', () {
    final board = relayShelfLesson.board;
    final direct = _link('feed', 'broadcaster');
    final first = _link('feed', 'relay');
    final second = _link('relay', 'broadcaster');
    final positions = {
      ...board.initialPositions,
      'relay': const SignalPoint(3, 2.12),
      'broadcaster': const SignalPoint(6.37, .75),
    };
    expect(board.distance(direct, positions), 5);
    expect(board.distance(first, positions), closeTo(3, 1e-9));
    expect(board.distance(second, positions), closeTo(4, 1e-9));
    expect(board.cableIssue(direct, positions), LinkIssue.range);
    expect(board.cableIssue(second, positions), LinkIssue.interference);
    expect(
      board.cableIssue(second, positions, type: LeadType.shielded),
      isNull,
    );
    expect(board.leadReach('feed', LeadType.shielded), 4);
    expect(
      board.linkIssue(
        [first],
        second,
        positions: positions,
        type: LeadType.shielded,
        leadTypes: {first: LeadType.shielded},
      ),
      LinkIssue.stock,
    );
    final state = SignalBoardState(
      board,
      links: [first, second],
      positions: positions,
      leadTypes: {second: LeadType.shielded},
    );
    expect(_power(state, 'relay'), 60);
    expect(_power(state, 'broadcaster'), 60);
    expect(state.deliveries[second]?.source, 'feed');
    expect(state.deliveries[second]?.channel, 12);
    expect(_power(state.copyWith(links: [second]), 'broadcaster'), isNull);
    final alternate = {...positions, 'relay': const SignalPoint(2, 2.12)};
    expect(board.distance(second, alternate), closeTo(5, 1e-9));
    expect(
      board.cableIssue(second, alternate, type: LeadType.shielded),
      LinkIssue.range,
    );
    final dropped = state.copyWith(positions: alternate);
    expect(dropped.solved, isFalse);
    final restored = GameSave.fromJson(
      GameSave.fromSignal(relayShelfLesson, dropped).toJson().cast(),
    );
    expect(restored.signal!.leadType(second), LeadType.shielded);
    expect(restored.links, contains(second));
    expect(restored.solved, isFalse);
    final far = state.copyWith(
      positions: {...positions, 'broadcaster': const SignalPoint(5.37, .75)},
    );
    expect(_power(far, 'serviceAntenna'), 35);
    expect(far.solved, isFalse);
  });

  test('Two Masts isolates trunk geometry and the wall feedthrough', () {
    final board = twoMastsLesson.board;
    final feed = _link('feed', 'splitter');
    final remote = _link('splitter', 'remoteMast');
    final local = _link('splitter', 'localMast', 1);
    final positions = {
      ...board.initialPositions,
      'localMast': const SignalPoint(3.5, 1.5),
    };
    expect(board.distance(remote, positions), closeTo(6, 1e-9));
    expect(board.cableIssue(remote, positions, type: LeadType.trunk), isNull);
    expect(board.cableIssue(remote, positions), LinkIssue.feedthrough);
    expect(
      board.cableIssue(local, positions, type: LeadType.trunk),
      LinkIssue.trunk,
    );
    final closed = SignalBoard(
      devices: board.devices,
      goals: board.goals,
      size: board.size,
      height: board.height,
      placementNodes: board.placementNodes,
      radioWalls: board.radioWalls,
      cableCorridors: board.cableCorridors,
      patchLeadStock: 2,
      trunkLeadStock: 1,
    );
    expect(
      closed.cableIssue(remote, positions, type: LeadType.trunk),
      LinkIssue.feedthrough,
    );
    SignalBoardState feedMasts(
      SignalBoard board,
      List<SignalLink> links,
      Map<String, SignalPoint> positions,
    ) => SignalBoardState(
      board,
      links: links,
      positions: positions,
      leadTypes: {remote: LeadType.trunk},
    );
    final noFeedthrough = feedMasts(closed, [feed, local, remote], positions);
    expect(_power(noFeedthrough, 'localAntenna'), 40);
    expect(_power(noFeedthrough, 'remoteAntenna'), isNull);
    expect(
      _power(
        feedMasts(board, [feed, local, remote], board.initialPositions),
        'localAntenna',
      ),
      35,
    );
    expect(feedMasts(board, [feed, local], positions).solved, isFalse);
    expect(feedMasts(board, [feed, remote], positions).solved, isFalse);
  });

  test('Quiet Sector distinguishes a screened antenna from a live protected channel', () {
    final board = quietSectorLesson.board;
    final link = _link('feed', 'broadcaster');
    SignalBoardState at(SignalPoint point) => SignalBoardState(
      board,
      links: [link],
      positions: {...board.initialPositions, 'broadcaster': point},
    );
    final close = at(const SignalPoint(1.5, .5));
    expect(board.goals.map((goal) => _power(close, goal.id)), [40, 45, 35]);
    expect(close.solved, isFalse);
    final screened = at(const SignalPoint(1.5, 1.5));
    final mast = board.device('broadcaster')!;
    final guard = board.device('protected')!;
    expect(
      board.radioPath(mast, guard, screened.positions).blockedAt,
      isNotNull,
    );
    expect(board.radioPath(mast, guard, screened.positions).inRange, isTrue);
    expect(screened.solved, isTrue);
    final third = at(const SignalPoint(4.5, 2.5));
    expect(
      board.radioPath(mast, board.goals.first, third.positions).blockedAt,
      isNotNull,
    );
    expect(_power(third, 'westAntenna'), 50);
    expect(_power(third, 'northAntenna'), isNull);
    expect(third.solved, isFalse);

    final withLeak = {...screened.deliveries};
    const guardHop = (
      from: 'broadcaster',
      to: 'protected',
      input: 0,
      output: SignalBoard.radioOutput,
    );
    withLeak[guardHop] = (source: 'feed', channel: 12, strength: 1, hop: 1);
    expect(board.solves(withLeak), isFalse);
    withLeak[guardHop] = (source: 'feed', channel: 12, strength: 0, hop: 1);
    expect(board.solves(withLeak), isTrue);
    withLeak[guardHop] = (source: 'feed', channel: 9, strength: 35, hop: 1);
    expect(board.solves(withLeak), isTrue);
  });

  test('optical layouts isolate the baffle and directed sensor inputs', () {
    OpticalLevel copy(
      OpticalLevel board, {
      List<math.Rectangle<double>>? blocks,
      List<OpticalReceiver>? receivers,
    }) => OpticalLevel(
      title: board.title,
      laser: board.laser,
      laserFoot: board.laserFoot,
      direction: board.direction,
      receivers: receivers ?? board.receivers,
      goal: board.goal,
      initial: board.initial,
      floor: board.floor,
      mounts: board.mounts,
      blocks: blocks ?? board.blocks,
    );

    final corner = cornerMirrorLesson.board;
    expect(
      traceOptics(corner, corner.initial).segments.last.to.y,
      closeTo(-.48, 1e-9),
    );
    expect(
      traceOptics(corner, [corner.initial.single.rotate()]).solves(corner),
      isFalse,
    );
    final open = copy(corner, blocks: []);
    expect(
      _opticalArrangements(open)
          .where((layout) => traceOptics(open, layout).solves(open)),
      hasLength(1),
    );

    final split = splitAroundBaffleLesson.board;
    final winning = _opticalArrangements(split)
        .singleWhere((layout) => traceOptics(split, layout).solves(split));
    expect(traceOptics(split, [winning.last]).receivedPower(0), 1);
    expect(traceOptics(split, [winning.last]).solves(split), isFalse);
    expect(traceOptics(split, [winning.first]).receivedPower(0), .5);
    expect(traceOptics(split, [winning.first]).receivedPower(1), 0);
    for (final (i, sensor) in split.receivers.indexed) {
      final reversed = copy(
        split,
        receivers: [
          for (final (j, receiver) in split.receivers.indexed)
            if (i != j)
              receiver
            else
              OpticalReceiver(
                sensor.label,
                sensor.position,
                BeamDirection.west,
                requiredPower: 50,
              ),
        ],
      );
      expect(traceOptics(reversed, winning).receivedPower(i), 0);
      expect(traceOptics(reversed, winning).receivedPower(1 - i), .5);
      expect(traceOptics(reversed, winning).solves(reversed), isFalse);
    }
  });

  testWidgets('plays each new Endless fixture using the landscape controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(667, 375);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await playRoutingBoards(tester, MemoryStore());
  });

  testWidgets(
    'the Parts guide remembers opened boards without exposing unvisited parts',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(667, 375);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final store = MemoryStore();

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> open(int number) async {
        await tap(find.text('Endless'));
        await tap(find.byKey(const ValueKey('endless-group-1')));
        await tap(find.byKey(ValueKey('endless-1.$number')));
        await tap(find.byTooltip('Parts guide'));
      }

      await tester.pumpWidget(DarkPort(store: store));
      await tester.pumpAndSettle();
      await open(7);
      expect(find.text('This puzzle'), findsOneWidget);
      expect(find.text('2-way splitter'), findsOneWidget);
      expect(find.text('Relay'), findsNothing);
      expect(find.text('Optical'), findsNothing);
      await tap(find.text('Cables'));
      expect(find.text('Trunk lead'), findsOneWidget);
      expect(find.text('Shielded lead'), findsNothing);
      final visited = (await store.load())!;
      expect(visited.opened, {twoMastsLesson.id});
      expect(visited.endlessBoards, isEmpty);
      expect(visited.tutorialStarted, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(DarkPort(store: store));
      await tester.pumpAndSettle();
      await open(6);
      expect(find.text('Relay'), findsOneWidget);
      expect(find.text('2-way splitter'), findsNothing);
      expect(find.text('Trunk lead'), findsNothing);
      await tap(find.text('Wired'));
      expect(find.text('2-way splitter'), findsOneWidget);
      expect(find.text('Relay'), findsOneWidget);
      await tap(find.text('Radio'));
      expect(find.text('Concrete wall'), findsOneWidget);
      await tap(find.text('Cables'));
      expect(find.text('Trunk lead'), findsOneWidget);
      expect(find.text('Shielded lead'), findsOneWidget);
      await tap(find.text('Controls'));
      expect(find.text('Placement'), findsOneWidget);
      expect(find.text('Wiring'), findsOneWidget);

      await tap(find.text('Close'));
      await tap(find.byTooltip('Back to puzzles'));
      await tap(find.byTooltip('Back to Endless groups'));
      await tap(find.byTooltip('Return to title'));
      await tap(find.text('New game'));
      await tap(find.byKey(ValueKey('lesson-${firstReflection.id}')));
      await tap(find.byTooltip('Parts guide'));
      expect(find.text('Mirror'), findsOneWidget);
      expect(find.text('Relay'), findsNothing);
      await tap(find.text('Wired'));
      expect(find.text('Relay'), findsOneWidget);
    },
  );
}

Future<void> playRoutingBoards(WidgetTester tester, GameStore store) async {
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder entry(int number) => find.byKey(ValueKey('endless-1.$number'));
  Finder part(String id) => find.byKey(ValueKey('signal-device-$id'));
  Finder stock(LeadType type) =>
      find.byKey(ValueKey('${type.name}-lead-stock'));
  final back = find.byTooltip('Back to puzzles');
  final hint = find.byTooltip('Hint');
  final complete = find.byKey(const ValueKey('lesson-complete'));
  final objective = find.byKey(const ValueKey('puzzle-objective'));
  final preview = find.byKey(const ValueKey('lead-preview-symbol'));
  final stars = find.byKey(const ValueKey('puzzle-solution-stars'));
  final surface = find.byKey(const ValueKey('signal-playfield'));
  final optical = find.byKey(const ValueKey('optical-deck'));

  void expectControls(EndlessLevel level) {
    expect(
      find.descendant(
        of: back,
        matching: find.byIcon(Icons.account_tree_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hint, matching: find.byIcon(Icons.lightbulb_outline)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: objective,
        matching: find.text(level.lesson!.objective),
      ),
      findsOneWidget,
    );
  }

  Future<void> drag(Offset from, Offset to) async {
    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
  }

  Future<void> movePart(SignalBoard board, String id, SignalPoint point) async {
    final bounds = tester.getRect(surface);
    final geometry = SignalBoardGeometry(board, bounds.size);
    await drag(
      tester.getCenter(part(id)),
      bounds.topLeft + geometry.project(point),
    );
  }

  Future<void> wire(
    SignalBoard board,
    String from,
    String to, {
    int? output,
  }) async {
    if (output == null) {
      await tap(part(from));
    } else {
      final geometry = SignalBoardGeometry(board, tester.getSize(surface));
      await tester.tapAt(
        tester.getCenter(part(from)) +
            geometry.project(SignalBoard.outputPort(output)),
      );
      await tester.pumpAndSettle();
    }
    await tap(part(to));
    expect(
      find.textContaining('Tap the input again to install.'),
      findsOneWidget,
    );
    await tap(part(to));
  }

  Future<void> solved(EndlessLevel level) async {
    expect(complete, findsOneWidget, reason: level.title);
    expectControls(level);
    expect(
      find.descendant(of: stars, matching: find.byIcon(Icons.star)),
      findsOneWidget,
    );
    expect(
      (await store.load())!.resultFor(level)!.stars,
      level.solutionIds.toSet(),
    );
    final readings = tester.getRect(
      find.byKey(const ValueKey('landscape-lesson-readings')),
    );
    final goals = switch (level.lesson) {
      WiredLesson(:final board) => board.goals.map(
        (goal) => 'signal-goal-${goal.id}',
      ),
      OpticalLesson(:final board) => board.goal.map((id) => 'optical-goal-$id'),
      null => const <String>[],
    };
    for (final goal in goals) {
      final row = tester.getRect(find.byKey(ValueKey(goal)));
      expect(row.top, greaterThanOrEqualTo(readings.top), reason: goal);
      expect(row.bottom, lessThanOrEqualTo(readings.bottom), reason: goal);
    }
    await dismissPuzzleAnnouncement(tester);
    await tap(back);
  }

  Offset opticPoint(OpticalLevel board, FloorPoint point) {
    final bounds = tester.getRect(optical);
    return bounds.topLeft +
        OpticalDeckGeometry(board, bounds.size, fill: true).project(point);
  }

  await tester.pumpWidget(DarkPort(store: store));
  await tester.pumpAndSettle();
  await tap(find.text('Endless'));
  await tap(find.byKey(const ValueKey('endless-group-1')));
  await tap(entry(6));
  expectControls(EndlessLevel.relayShelf);
  expect(find.text('Patch leads'), findsNothing);
  expect(find.text('Shielded leads'), findsNothing);
  expect(
    find.descendant(
      of: stock(LeadType.shielded),
      matching: find.byType(InkWell),
    ),
    findsNothing,
  );
  await tap(find.byTooltip('Parts guide'));
  await tap(find.text('Cables'));
  for (final type in [LeadType.patch, LeadType.shielded]) {
    expect(find.text(type.label), findsOneWidget);
    expect(
      tester
          .widgetList<LeadSymbol>(
            find.descendant(
              of: find.byType(Dialog),
              matching: find.byType(LeadSymbol),
            ),
          )
          .map((symbol) => symbol.type),
      contains(type),
    );
  }
  expect(find.text('Trunk lead'), findsNothing);
  await tap(find.text('Close'));

  final shelf = relayShelfLesson.board;
  await movePart(shelf, 'broadcaster', const SignalPoint(6.37, .75));
  await movePart(shelf, 'relay', const SignalPoint(3, 2.12));
  await tap(part('feed'));
  await tap(part('broadcaster'));
  expect(find.text('Needs 5 length units. Output reaches 4.'), findsOneWidget);
  await tap(part('relay'));
  expect(find.textContaining('3 units. Tap the input again'), findsOneWidget);
  expect(tester.widget<LeadSymbol>(preview).type, LeadType.patch);
  expect(
    (await store.load())!.endlessBoards[relayShelfLesson.id]!.links,
    isEmpty,
  );
  await tap(part('relay'));
  await tap(part('relay'));
  await tap(part('broadcaster'));
  expect(find.textContaining('4 units. Tap the input again'), findsOneWidget);
  expect(tester.widget<LeadSymbol>(preview).type, LeadType.shielded);
  await tap(part('broadcaster'));
  expect(find.byTooltip('0 of 1 shielded leads available'), findsOneWidget);
  await solved(EndlessLevel.relayShelf);

  await tap(entry(7));
  final masts = twoMastsLesson.board;
  await wire(masts, 'feed', 'splitter');
  await wire(masts, 'splitter', 'localMast', output: 1);
  await wire(masts, 'splitter', 'remoteMast', output: 0);
  expect(find.text('35 / ≥40 u'), findsOneWidget);
  expect(find.text('35 / ≥35 u'), findsOneWidget);
  expect(find.byTooltip('0 of 1 trunk leads available'), findsOneWidget);
  await movePart(masts, 'localMast', const SignalPoint(3.5, 1.5));
  await solved(EndlessLevel.twoMasts);

  await tap(entry(8));
  await tap(part('feed'));
  await tap(part('broadcaster'));
  expect(find.text('35 / 0 u'), findsOneWidget);
  expect(find.byTooltip('Signal detected'), findsOneWidget);
  await movePart(
    quietSectorLesson.board,
    'broadcaster',
    const SignalPoint(1.5, 1.5),
  );
  expect(find.text('0 / 0 u'), findsOneWidget);
  await solved(EndlessLevel.quietSector);

  await tap(entry(9));
  final corner = cornerMirrorLesson.board;
  await drag(
    opticPoint(corner, corner.initial.single.position),
    opticPoint(corner, corner.mounts['M1']!.last.position),
  );
  expect(find.text('100 U / 100'), findsOneWidget);
  await solved(EndlessLevel.cornerMirror);

  await tap(entry(10));
  final split = splitAroundBaffleLesson.board;
  await tester.tapAt(opticPoint(split, split.initial.first.position));
  await tester.pumpAndSettle();
  await drag(
    opticPoint(split, split.initial.last.position),
    opticPoint(split, split.mounts['M1']!.last.position),
  );
  expect(find.text('50 U / 50'), findsNWidgets(2));
  await solved(EndlessLevel.splitAroundTheBaffle);
  await tap(entry(10));
  expect(complete, findsNothing);
  expectControls(EndlessLevel.splitAroundTheBaffle);
  expect(
    find.descendant(of: stars, matching: find.byIcon(Icons.star)),
    findsOneWidget,
  );
}

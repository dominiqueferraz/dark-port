import 'package:dark_port/achievements.dart';
import 'package:dark_port/drafting_grid.dart';
import 'package:dark_port/drafting_theme.dart';
import 'package:dark_port/endless_levels.dart';
import 'package:dark_port/game_save.dart';
import 'package:dark_port/signal_board.dart';
import 'package:dark_port/signal_board_state.dart';
import 'package:dark_port/tutorial.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_silent_game.dart';
import 'support/puzzle_announcement.dart';
import 'support/memory_store.dart';

const _patch = (from: 'feed', to: 'broadcaster', input: 0, output: 0);

SignalLink _lead(String from, String to, [int output = 0]) =>
    (from: from, to: to, output: output, input: 0);

final _balanced = [
  _lead('feed', 'threeWay'),
  _lead('threeWay', 'light2'),
  _lead('threeWay', 'light1', 1),
  _lead('threeWay', 'light3', 2),
];

final _cascade = [
  _lead('feed', 'twoWayA'),
  _lead('twoWayA', 'twoWayB'),
  _lead('twoWayA', 'light1', 1),
  _lead('twoWayB', 'light3'),
  _lead('twoWayB', 'light2', 1),
];

SignalDelivery? _delivery(SignalBoardState state, String target) => state
    .deliveries
    .entries
    .where((entry) => entry.key.to == target)
    .firstOrNull
    ?.value;

Iterable<List<SignalLink>> _wiringArrangements(SignalBoard board) sync* {
  final positions = board.initialPositions;
  final sockets = [
    for (final device in board.devices)
      for (var output = 0; output < device.outputs; output++)
        (from: device.id, output: output),
  ];
  final inputs = board.devices.where((device) => device.hasInput);
  Iterable<List<SignalLink>> search(int index, List<SignalLink> links) sync* {
    if (index == sockets.length) {
      yield links;
      return;
    }
    yield* search(index + 1, links);
    final socket = sockets[index];
    for (final target in inputs) {
      if (links.any((link) => link.to == target.id)) continue;
      final lead = _lead(socket.from, target.id, socket.output);
      if (board.linkIssue(links, lead, positions: positions) == null) {
        yield* search(index + 1, [...links, lead]);
      }
    }
  }

  yield* search(0, []);
}

void main() {
  test('Antenna Test has exactly one winning arrangement', () {
    final board = antennaTestLesson.board;
    const patch = (from: 'feed', to: 'broadcaster', input: 0, output: 0);
    final wins = [
      for (final node in board.placementNodes)
        for (final links in <List<SignalLink>>[
          [],
          [patch],
        ])
          if (SignalBoardState(
            board,
            positions: {
              ...board.initialPositions,
              'broadcaster': node.position,
            },
            links: links,
          ).solved)
            (mount: node.position, links: links),
    ];
    expect(wins.single.mount, const SignalPoint(2.5, 1.5));
    expect(wins.single.links, [patch]);
    expect(board.device('testAntenna')!.inputs, 0);
    expect(
      board.canMove(
        'broadcaster',
        const SignalPoint(3.5, 1.5),
        board.initialPositions,
      ),
      isFalse,
    );
  });

  test(
    'the new radio fixtures each have one winning committed arrangement',
    () {
      for (final (level, mount, units) in [
        (EndlessLevel.edgeOfCoverage, const SignalPoint(2.5, 1.5), 40),
        (EndlessLevel.blindCorner, const SignalPoint(2.5, 2.5), 35),
        (EndlessLevel.fadingSignal, const SignalPoint(2.5, 1.5), 40),
      ]) {
        final board = (level.lesson! as WiredLesson).board;
        final wins = <SignalBoardState>[];
        for (final node in board.placementNodes) {
          final positions = {
            ...board.initialPositions,
            'broadcaster': node.position,
          };
          expect(board.linkIssue([], _patch, positions: positions), isNull);
          for (final links in [
            <SignalLink>[],
            [_patch],
          ]) {
            final state = SignalBoardState(
              board,
              positions: positions,
              links: links,
            );
            if (state.solved) wins.add(state);
          }
        }
        expect(wins.single.positions['broadcaster'], mount);
        expect(_delivery(wins.single, board.goals.single.id)?.strength, units);
        expect(level.solutionFor(wins.single), level.solutionIds.single);
      }
    },
  );

  test('radio distinguishes range, concrete, channel and attenuation', () {
    final edge = edgeOfCoverageLesson.board;
    final edgeState = SignalBoardState(edge, links: [_patch]);
    final decoy = edge.device('channelNine')!;
    final decoyDelivery = _delivery(edgeState, decoy.id);
    expect(decoyDelivery?.strength, 55);
    expect(decoy.read(decoyDelivery), SignalReading.wrongChannel);
    expect(_delivery(edgeState, edge.goals.single.id), isNull);
    expect(
      edge
          .radioPath(
            edge.device('broadcaster')!,
            edge.goals.single,
            edgeState.positions,
          )
          .inRange,
      isFalse,
    );

    final corner = blindCornerLesson.board;
    final target = corner.goals.single;
    final cornerState = SignalBoardState(corner, links: [_patch]);
    final blocked = corner.radioPath(
      corner.device('broadcaster')!,
      target,
      cornerState.positions,
    );
    expect(blocked.distance, 5);
    expect(blocked.inRange, isTrue);
    expect(blocked.blockedAt, const SignalPoint(4.5, 1));
    expect(_delivery(cornerState, target.id), isNull);
    final withoutWall = SignalBoard(
      devices: corner.devices,
      goals: corner.goals,
      size: corner.size,
      height: corner.height,
      placementNodes: corner.placementNodes,
      patchLeadStock: corner.patchLeadStock,
    );
    for (final mount in withoutWall.placementNodes) {
      expect(
        SignalBoardState(
          withoutWall,
          links: [_patch],
          positions: {
            ...withoutWall.initialPositions,
            'broadcaster': mount.position,
          },
        ).solved,
        isTrue,
      );
    }

    final fading = fadingSignalLesson.board;
    final weak = _delivery(
      SignalBoardState(fading, links: [_patch]),
      fading.goals.single.id,
    );
    expect(weak?.strength, 35);
    expect(fading.goals.single.read(weak), SignalReading.weak);
  });

  test('Night Lights has exactly the two registered causal routes', () {
    final board = nightLightsLesson.board;
    final wins = <String, Set<Set<SignalLink>>>{};
    var arrangements = 0;
    var rawWins = 0;
    for (final links in _wiringArrangements(board)) {
      arrangements++;
      final state = SignalBoardState(board, links: links);
      if (!state.solved) continue;
      rawWins++;
      final id = EndlessLevel.nightLights.solutionFor(state)!;
      final powered = state.deliveries.keys.toSet();
      final causal = wins.putIfAbsent(id, () => {});
      if (!causal.any((links) => setEquals(links, powered))) {
        causal.add(powered);
      }
      expect(
        board.goals.map((goal) => _delivery(state, goal.id)?.strength),
        id == 'balanced' ? [100, 100, 100] : [150, 75, 75],
      );
    }
    expect(arrangements, 2233);
    expect(rawWins, 3);
    expect(wins.keys, unorderedEquals(['balanced', 'cascade']));
    expect(wins['balanced']!.single, unorderedEquals(_balanced));
    expect(wins['cascade']!.single, unorderedEquals(_cascade));
    expect({
      for (final link in [..._balanced, ..._cascade]) ...[link.from, link.to],
    }, board.devices.map((device) => device.id).toSet());
    expect(board.patchLeadStock, _cascade.length);

    final overStock = [
      _lead('feed', 'twoWayA'),
      _lead('twoWayA', 'threeWay'),
      _lead('threeWay', 'twoWayB'),
      _lead('threeWay', 'light1', 1),
      _lead('twoWayB', 'light3'),
    ];
    expect(
      board.linkIssue(
        overStock,
        _lead('twoWayB', 'light2', 1),
        positions: board.initialPositions,
      ),
      LinkIssue.stock,
    );
    final weakBranch = SignalBoardState(
      board,
      links: [
        _lead('feed', 'threeWay'),
        _lead('threeWay', 'twoWayA', 1),
        _lead('twoWayA', 'light1', 1),
      ],
    );
    expect(_delivery(weakBranch, 'light1')?.strength, 50);
    expect(weakBranch.solved, isFalse);
  });

  test(
    'Night Lights stars and its cable record accumulate independently',
    () async {
      final level = EndlessLevel.nightLights;
      final first = GameSave(nightLightsLesson, links: _cascade);
      final extra = GameSave(
        nightLightsLesson,
        links: [..._balanced, _lead('twoWayA', 'twoWayB')],
      );
      final record = GameSave(
        nightLightsLesson,
        links: _balanced.reversed.toList(),
      );
      final start = TutorialProgress(tutorialStarted: false)
          .recordEndless(first);
      expect(Achievement.firstSignal.isEarned(start), isTrue);
      expect(Achievement.bothRoutes.isEarned(start), isFalse);
      expect(start.resultFor(level)!.stars, {'cascade'});
      expect(start.recordEndless(first), same(start));
      final both = start.recordEndless(extra);
      expect(both.resultFor(level)!.stars, {'cascade', 'balanced'});
      expect(both.resultFor(level)!.fourCableRecord, isFalse);
      expect(Achievement.bothRoutes.isEarned(both), isTrue);
      expect(Achievement.fourCableRecord.isEarned(both), isFalse);
      final earned = both.recordEndless(record);
      expect(earned.resultFor(level)!.fourCableRecord, isTrue);
      expect(earned.recordEndless(GameSave(nightLightsLesson)), same(earned));
      final store = MemoryStore();
      await store.write(earned);
      final loaded = (await store.load())!;
      expect(loaded.resultFor(level)!.stars, {'cascade', 'balanced'});
      expect(loaded.resultFor(level)!.fourCableRecord, isTrue);
      expect(Achievement.fourCableRecord.isEarned(loaded), isTrue);
      expect(loaded.endlessBoards[nightLightsLesson.id]!.links, _cascade);
      expect(loaded.recordEndless(record), same(loaded));
    },
  );

  testWidgets('opens the group path and saves the playable Antenna Test', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(874, 402);
    tester.view.padding = const FakeViewPadding(
      left: 62,
      right: 62,
      bottom: 21,
    );
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);
    final store = MemoryStore();

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Finder numbered(int number) => find.byKey(ValueKey('endless-1.$number'));
    final pack = find.byKey(const ValueKey('endless-group-1'));
    final signalBoard = find.byKey(const ValueKey('signal-playfield'));
    final feed = find.byKey(const ValueKey('signal-device-feed'));
    final broadcaster = find.byKey(const ValueKey('signal-device-broadcaster'));

    await pumpSilentGame(tester, store);
    await tester.pumpAndSettle();
    await tap(find.text('Endless'));
    expect(numbered(1), findsNothing);
    await tap(pack);
    expect(pack, findsNothing);
    expect(find.text('1.1'), findsOneWidget);
    expect(find.text('1.2'), findsOneWidget);
    expect(find.text('1.20'), findsOneWidget);
    expect(numbered(20), findsOneWidget);
    expect(
      tester.getCenter(numbered(2)).dx,
      allOf(
        greaterThan(tester.getCenter(numbered(1)).dx),
        lessThan(tester.getCenter(numbered(3)).dx),
      ),
    );
    expect(
      tester.getTopLeft(numbered(2)).dy,
      greaterThan(tester.getBottomLeft(numbered(1)).dy),
    );
    expect(
      tester.getTopLeft(numbered(3)).dy,
      tester.getTopLeft(numbered(1)).dy,
    );
    await tap(numbered(2));
    expect(signalBoard, findsOneWidget);
    await tap(feed);
    await tap(broadcaster);
    await tap(find.byKey(const ValueKey('signal-device-channelNine')));
    expect(find.byTooltip('Wrong channel'), findsOneWidget);
    expect(
      find.text(
        'Channel 9 · 1 of 4 grid steps · Received channel 12 (wrong channel)',
      ),
      findsOneWidget,
    );
    await tap(find.byTooltip('Back to puzzles'));
    await tester.ensureVisible(numbered(20));
    await tester.pumpAndSettle();
    expect(
      tester
          .getRect(find.byKey(const ValueKey('endless-level-line')))
          .contains(tester.getCenter(numbered(20))),
      isTrue,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(numbered(1), findsNothing);
    expect(pack, findsOneWidget);
    await tap(pack);
    await tap(numbered(1));

    await tap(feed);
    await tap(broadcaster);
    expect(find.text('The antenna is outside radio coverage.'), findsOneWidget);
    expect(
      (await store.load())!.endlessBoards[antennaTestLesson.id]!.solved,
      isFalse,
    );
    await tap(find.byTooltip('Back to puzzles'));
    expect(find.byTooltip('Antenna Test · Resume'), findsOneWidget);
    await tap(numbered(1));

    final bounds = tester.getRect(signalBoard);
    final target = Offset(
      bounds.left + bounds.width * 2.5 / antennaTestLesson.board.size,
      bounds.top + bounds.height * 1.5 / antennaTestLesson.board.height,
    );
    final from = tester.getCenter(broadcaster);
    await tester.dragFrom(from, target - from);
    await tester.pumpAndSettle();

    expect(find.text('40 / ≥30 u'), findsOneWidget);
    expect(
      (await store.load())!.endlessBoards[antennaTestLesson.id]!.solved,
      isTrue,
    );
    expect(find.text('Awards earned'), findsOneWidget);
    expect(find.text('Scenario approved'), findsNothing);
    expect(find.text('Solution Star earned'), findsOneWidget);
    expect(find.text('Achievement earned · First Signal'), findsOneWidget);
    await dismissPuzzleAnnouncement(tester);
    await tap(find.byTooltip('Back to puzzles'));
    expect(find.byTooltip('Antenna Test · Replay'), findsOneWidget);
    // Saves written before Solution Stars still contain the completed fixture.
    store.data!.remove('endlessResults');

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpSilentGame(tester, store);
    await tester.pumpAndSettle();
    expect(find.text('Continue game'), findsNothing);
    await tap(find.text('Endless'));
    await tap(pack);
    expect(find.byTooltip('Antenna Test · Replay'), findsOneWidget);
    expect((await store.load())!.resultFor(EndlessLevel.antennaTest)!.stars, {
      'coverage-boundary',
    });
    await tap(numbered(1));
    expect(puzzleAnnouncement, findsNothing);
    expect(find.text('40 / ≥30 u'), findsNothing);
    await tap(feed);
    await tap(broadcaster);
    final replayFrom = tester.getCenter(broadcaster);
    await tester.dragFrom(replayFrom, target - replayFrom);
    await tester.pumpAndSettle();
    expect(find.text('APPROVED'), findsOneWidget);
    expect(puzzleAnnouncement, findsNothing);
    expect(
      (await store.load())!.endlessBoards[antennaTestLesson.id]!.solved,
      isTrue,
    );
    await tap(find.byTooltip('Back to puzzles'));
    await tap(find.byTooltip('Back to Endless groups'));
    await tap(find.byTooltip('Return to title'));
    await tap(find.text('New game'));
    expect((await store.load())!.tutorialStarted, isTrue);
    expect(
      (await store.load())!.endlessBoards[antennaTestLesson.id]!.solved,
      isTrue,
    );
  });

  testWidgets('plays, saves, and replays the new Endless fixtures', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(874, 402);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await playNewEndlessBoards(tester, MemoryStore());
  });
}

Future<void> playNewEndlessBoards(WidgetTester tester, GameStore store) async {
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder part(String id) => find.byKey(ValueKey('signal-device-$id'));
  final boardSurface = find.byKey(const ValueKey('signal-playfield'));
  final back = find.byTooltip('Back to puzzles');
  final puzzleStars = find.byKey(const ValueKey('puzzle-solution-stars'));
  final leadStock = find.byKey(const ValueKey('patch-lead-stock'));
  final trophy = find.byKey(
    const ValueKey('puzzle-achievement-fourCableRecord'),
  );

  void expectTitleSpacing(String status) {
    final titleBlock = find.byType(DraftingTitleBlock);
    final titleBounds = tester.getRect(titleBlock);
    final inventory = find.byKey(const ValueKey('cable-inventory'));
    expect(titleBounds.top - tester.getRect(inventory).bottom, closeTo(6, .01));
    final statusBounds = tester.getRect(
      find.descendant(
        of: titleBlock,
        matching: find.text(status, findRichText: true),
      ),
    );
    expect(titleBounds.contains(statusBounds.topLeft), isTrue);
    expect(titleBounds.contains(statusBounds.bottomRight), isTrue);
    expect(statusBounds.left, greaterThan(titleBounds.center.dx));
  }

  void expectTrophy(IconData icon) => expect(
    find.descendant(of: trophy, matching: find.byIcon(icon)),
    findsOneWidget,
  );

  Finder entry(int number) => find.byKey(ValueKey('endless-1.$number'));

  void expectLeads(int available, int total) {
    expect(
      find.descendant(of: leadStock, matching: find.byType(CustomPaint)),
      findsNWidgets(total),
    );
    expect(
      find.byTooltip('$available of $total patch leads available'),
      findsOneWidget,
    );
  }

  void expectStars(Finder surface, List<IconData> expected) {
    final icons = tester.widgetList<Icon>(
      find.descendant(of: surface, matching: find.byType(Icon)),
    );
    expect(
      icons
          .map((icon) => icon.icon)
          .where((icon) => icon == Icons.star || icon == Icons.star_border),
      expected,
    );
  }

  Future<void> open(int number) => tap(entry(number));

  Future<void> openSignalRouting() async {
    await tap(find.text('Endless'));
    await tap(find.byKey(const ValueKey('endless-group-1')));
  }

  Future<void> openAchievementsFromPuzzles() async {
    await tap(find.byTooltip('Back to Endless groups'));
    await tap(find.byTooltip('Return to title'));
    await tap(find.text('Achievements'));
  }

  Future<void> checkNightLightsHint(
    Finder trigger,
    List<IconData> stars,
  ) async {
    await tap(trigger);
    final dialog = find.byType(AlertDialog);
    final divider = find.byKey(const ValueKey('solution-stars-divider'));
    expect(divider, findsOneWidget);
    expect(
      tester.getTopLeft(divider).dy,
      greaterThan(tester.getTopLeft(find.text('HOW IT WORKS')).dy),
    );
    expect(
      tester.getTopLeft(find.text('SOLUTION STARS')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(divider).dy),
    );
    expect(
      find.text('Deliver 100 u to each of the three lights.'),
      findsOneWidget,
    );
    expect(
      find
          .text('Deliver 150 u to Light 1 and 75 u each to Lights 2 and 3.')
          .hitTestable(),
      findsOneWidget,
    );
    expectStars(dialog, stars);
    await tap(find.byTooltip('Close hint'));
  }

  Future<void> dragMast(SignalBoard board, SignalPoint point) async {
    final bounds = tester.getRect(boardSurface);
    final target = Offset(
      bounds.left + bounds.width * point.x / board.size,
      bounds.top + bounds.height * point.y / board.height,
    );
    final from = tester.getCenter(part('broadcaster'));
    await tester.dragFrom(from, target - from);
    await tester.pumpAndSettle();
  }

  Future<void> wireNightLights(List<SignalLink> route) async {
    final size = tester.getSize(boardSurface);
    final tile = Size(
      size.width / nightLightsLesson.board.size,
      size.height / nightLightsLesson.board.height,
    );
    for (final link in route) {
      final from = tester.getCenter(part(link.from));
      final output = SignalBoard.outputPort(link.output);
      await tester.tapAt(
        from + Offset(output.x * tile.width, output.y * tile.height),
      );
      await tester.pumpAndSettle();
      await tap(part(link.to));
    }
  }

  await pumpSilentGame(tester, store);
  await tester.pumpAndSettle();
  await tap(find.text('Achievements'));
  expect(find.text('0 OF 3 EARNED'), findsOneWidget);
  expect(find.text('UNEARNED'), findsNWidgets(3));
  for (final achievement in Achievement.values) {
    expect(find.text(achievement.title), findsOneWidget);
    expect(find.text(achievement.condition), findsOneWidget);
  }
  await tap(find.byTooltip('Return to title'));
  await openSignalRouting();
  for (final (level, failure, reading) in [
    (EndlessLevel.edgeOfCoverage, 'Wrong channel', '40 / ≥40 u'),
    (EndlessLevel.blindCorner, 'Blocked by concrete', '35 / ≥35 u'),
    (EndlessLevel.fadingSignal, 'Too weak', '40 / ≥40 u'),
  ]) {
    final lesson = level.lesson! as WiredLesson;
    expectStars(entry(level.number), [Icons.star_border]);
    await open(level.number);
    expectStars(puzzleStars, [Icons.star_border]);
    expectLeads(1, 1);
    await tap(part('feed'));
    await tap(part('broadcaster'));
    expectLeads(0, 1);
    if (level == EndlessLevel.edgeOfCoverage) {
      await tap(find.byTooltip('Disconnect Feed → Broadcaster'));
      expectLeads(1, 1);
      await tap(find.byKey(const ValueKey('signal-undo')));
      expectLeads(0, 1);
    }
    expect(find.byTooltip(failure), findsOneWidget);
    expect((await store.load())!.endlessBoards[lesson.id]!.solved, isFalse);
    if (level == EndlessLevel.fadingSignal) {
      expect(find.text('35 / ≥40 u'), findsOneWidget);
      await tap(part(lesson.board.goals.single.id));
      expect(
        find.text('Channel 12 · 5 of 6 grid steps · 35 u · Too weak'),
        findsOneWidget,
      );
    }
    await dragMast(lesson.board, lesson.board.placementNodes.last.position);
    expect(find.text(reading), findsOneWidget);
    expect(
      (await store.load())!.resultFor(level)!.stars,
      level.solutionIds.toSet(),
    );
    expectStars(puzzleStars, [Icons.star]);
    await dismissPuzzleAnnouncement(tester);
    await tap(back);
  }

  await openAchievementsFromPuzzles();
  expect(find.text('1 OF 3 EARNED'), findsOneWidget);
  expect(find.text('EARNED'), findsOneWidget);
  expect(find.text('UNEARNED'), findsNWidgets(2));
  await tap(find.byTooltip('Return to title'));
  await openSignalRouting();

  final night = EndlessLevel.nightLights;
  const unearned = [Icons.star_border, Icons.star_border];
  const cascadeEarned = [Icons.star_border, Icons.star];
  const bothEarned = [Icons.star, Icons.star];
  expectStars(entry(night.number), unearned);
  await open(night.number);
  expectStars(puzzleStars, unearned);
  expect(find.text('Solution Stars'), findsNothing);
  final starBounds = tester.getRect(puzzleStars);
  final boardBounds = tester.getRect(boardSurface);
  final viewport = tester.getRect(
    find.byKey(const ValueKey('landscape-viewport')),
  );
  expect(boardBounds.top, closeTo(viewport.top + draftingGridMargins.top, .01));
  final awardBox = find.byKey(const ValueKey('blueprint-awards'));
  final awardsBounds = tester.getRect(awardBox);
  expect(awardsBounds.topLeft, within(distance: 8, from: boardBounds.topLeft));
  expect(boardBounds.contains(awardsBounds.topLeft), isTrue);
  expect(boardBounds.contains(awardsBounds.bottomRight), isTrue);
  expect(awardsBounds.height, lessThanOrEqualTo(26));
  expect(tester.getRect(trophy).left, greaterThanOrEqualTo(starBounds.right));
  final awardIcons = find.descendant(of: awardBox, matching: find.byType(Icon));
  expect(awardIcons, findsNWidgets(3));
  final centers = [
    for (var index = 0; index < 3; index++)
      tester.getCenter(awardIcons.at(index)),
  ];
  for (var index = 0; index < centers.length; index++) {
    expect(tester.getSize(awardIcons.at(index)), const Size.square(16));
    expect(
      centers[index].dx,
      closeTo(awardsBounds.left + 12 + 24 * index, .01),
    );
    expect(centers[index].dy, closeTo(awardsBounds.center.dy, .01));
  }
  expectTitleSpacing('IN PROGRESS');
  expectTrophy(Icons.emoji_events_outlined);
  await tap(trophy);
  expect(find.text(Achievement.fourCableRecord.condition), findsOneWidget);
  expect(find.text('UNEARNED'), findsOneWidget);
  await tap(find.byTooltip('Close achievement'));
  expectLeads(5, 5);
  await checkNightLightsHint(find.byTooltip('Hint'), unearned);
  await wireNightLights(_cascade);
  expectLeads(0, 5);
  expect(find.text('150 / 75–150 u'), findsOneWidget);
  expect(find.text('75 / 75–150 u'), findsNWidgets(2));
  expect((await store.load())!.resultFor(night)!.stars, {'cascade'});
  expectStars(puzzleStars, cascadeEarned);
  expectTrophy(Icons.emoji_events_outlined);
  expect(find.text('Solution Star earned'), findsOneWidget);
  expect(find.text('Achievement earned · First Signal'), findsNothing);
  await dismissPuzzleAnnouncement(tester);
  await checkNightLightsHint(puzzleStars, cascadeEarned);
  await tap(back);
  expectStars(entry(night.number), cascadeEarned);

  await open(night.number);
  expectStars(puzzleStars, cascadeEarned);
  expectLeads(5, 5);
  expect(find.text('0 / 75–150 u'), findsNWidgets(3));
  await wireNightLights([_lead('twoWayA', 'twoWayB'), ..._balanced]);
  expectLeads(0, 5);
  expectStars(puzzleStars, bothEarned);
  expectTrophy(Icons.emoji_events_outlined);
  expect(find.text('Solution Star earned'), findsOneWidget);
  expect(find.text('Achievement earned · Both Routes'), findsOneWidget);
  expect(find.text('Achievement earned · Four-Cable Record'), findsNothing);
  await dismissPuzzleAnnouncement(tester);
  await tap(part('twoWayB'));
  await tap(find.byTooltip('Disconnect Two-way A → Two-way B'));
  expectLeads(1, 5);
  expect(find.text('100 / 75–150 u'), findsNWidgets(3));
  expectTrophy(Icons.emoji_events);
  expectTitleSpacing('APPROVED');
  final result = (await store.load())!.resultFor(night)!;
  expect(result.stars, {'balanced', 'cascade'});
  expect(result.fourCableRecord, isTrue);
  expectStars(puzzleStars, bothEarned);
  expect(find.text('Achievement earned · Four-Cable Record'), findsOneWidget);
  expect(find.text('Scenario approved'), findsNothing);
  expect(find.text('Solution Star earned'), findsNothing);
  await dismissPuzzleAnnouncement(tester);
  await tap(back);
  expectStars(entry(night.number), bothEarned);
  await openAchievementsFromPuzzles();
  expect(find.text('3 OF 3 EARNED'), findsOneWidget);
  expect(find.text('EARNED'), findsNWidgets(3));
}

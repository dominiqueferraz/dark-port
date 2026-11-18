import 'dart:math' as math;

import 'package:dark_port/endless_levels.dart';
import 'package:dark_port/game_save.dart';
import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/optical_deck.dart';
import 'package:dark_port/part_symbols.dart';
import 'package:dark_port/socket_aim.dart';
import 'package:dark_port/splitter_blueprint.dart';
import 'package:dark_port/tutorial.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:dark_port/workbench_boards.dart';
import 'package:dark_port/workbench_part_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_store.dart';
import 'support/pump_silent_game.dart';
import 'support/puzzle_announcement.dart';

final _straightAndRight = SplitterBlueprint(
  SplitterPort.straight,
  SplitterPort.right45,
);
final _twin = SplitterBlueprint(SplitterPort.left45, SplitterPort.right45);
final _offset = SplitterBlueprint(SplitterPort.left45, SplitterPort.right90);
final _filtered = SplitterBlueprint(
  SplitterPort.straight,
  SplitterPort.right45,
  filteredPort: SplitterPort.right45,
);
final _designs = [
  for (final a in SplitterPort.values)
    for (final b in SplitterPort.values.skip(a.index + 1))
      for (final filter in [null, a, b])
        SplitterBlueprint(a, b, filteredPort: filter),
];

Iterable<List<Optic>> _layouts(
  OpticalLevel board,
  SplitterBlueprint? design, [
  List<Optic> placed = const [],
]) sync* {
  if (placed.length == board.initial.length) {
    yield placed;
    return;
  }
  final template = board.initial[placed.length];
  final part = template.kind == OpticKind.workbenchSplitter && design != null
      ? template.fit(design)
      : template;
  for (final mount in board.mounts[part.id]!) {
    final optic = part.at(mount.position);
    if (board.canPlace(optic, placed)) {
      yield* _layouts(board, design, [...placed, optic]);
      yield* _layouts(board, design, [...placed, optic.rotate()]);
    }
  }
}

void main() {
  test(
    'an optical fabrication socket must be filled to complete the level',
    () {
      final board = workbenchTestBoard;
      expect(board.goal, isEmpty);
      expect(traceOptics(board, [workbenchSocket]).solves(board), isFalse);
      expect(traceOptics(board, []).solves(board), isFalse);
      expect(
        traceOptics(board, [
          workbenchSocket.fit(_straightAndRight),
        ]).solves(board),
        isTrue,
      );
    },
  );

  test('an optical impulse needs a matching open sightline', () {
    final aimed = SplitterBlueprint(
      SplitterPort.straight,
      SplitterPort.right45,
      inputAim: SocketAim.right,
    );
    final rotated = SplitterBlueprint(
      SplitterPort.straight,
      SplitterPort.right45,
      inputAim: SocketAim.left,
      turns: 1,
    );
    OpticalTrace testPulse(
      SplitterBlueprint design,
      BeamDirection direction, {
      bool blocked = false,
    }) => traceOptics(
      aimedWorkbenchBench(
        workbenchTestBoard,
        direction,
        blocks: [
          if (blocked) const math.Rectangle<double>(-1.5, -1.5, .45, .45),
        ],
      ),
      [workbenchSocket.fit(design)],
    );

    expect(testPulse(aimed, BeamDirection.north).segments, hasLength(1));
    expect(
      testPulse(aimed, BeamDirection.northEast, blocked: true).segments,
      hasLength(1),
    );
    final straight = testPulse(
      aimed,
      BeamDirection.northEast,
    ).segments.skip(1).first;
    expect(straight.to.x, closeTo(straight.from.x, 1e-9));
    final east = testPulse(
      rotated,
      BeamDirection.northEast,
    ).segments.skip(1).first;
    expect(east.to.y, closeTo(east.from.y, 1e-9));
    expect(east.to.x, greaterThan(east.from.x));
    expect(SplitterBlueprint.fromJson(rotated.toJson()), rotated);
    expect(
      () => SplitterBlueprint.fromJson({
        'ports': ['straight', 'right45'],
        'inputAim': 2,
        'turns': 0,
      }),
      throwsFormatException,
    );
  });

  test(
    'six sheets require a custom splitter and have one effective route each',
    () async {
      var progress = TutorialProgress(tutorialStarted: false);
      for (final (level, expected) in [
        (EndlessLevel.diagonalLatch, _straightAndRight),
        (EndlessLevel.twinLatches, _twin),
        (EndlessLevel.offsetLatch, _offset),
        (EndlessLevel.returnFold, _offset),
        (EndlessLevel.splitTheSplit, _straightAndRight),
        (EndlessLevel.splitAndDim, _filtered),
      ]) {
        final lesson = level.lesson! as OpticalLesson;
        final board = lesson.board;
        expect(GameSave(lesson).solved, isFalse);
        final empty = traceOptics(board, board.initial);
        expect(empty.lit, isEmpty, reason: level.title);
        final incoming = empty.segments.single;
        expect(incoming.toOptic, workbenchSocket.id, reason: level.title);
        expect(incoming.blocked, isTrue, reason: level.title);
        expect(incoming.fromOptic, isNull, reason: level.title);
        final wins = [
          for (final design in [null, ..._designs])
            for (final layout in _layouts(board, design))
              if (traceOptics(board, layout).solves(board)) layout,
        ];
        // Mirroring a mirrored recipe (or the symmetric twin) gives the same ray path.
        expect(wins, hasLength(2), reason: level.title);
        for (final layout in wins) {
          final socket = layout.first;
          expect(
            socket.turned ? socket.blueprint?.mirrored : socket.blueprint,
            expected,
            reason: level.title,
          );
          expect(socket.position, const FloorPoint(0, 0));
          expect(
            traceOptics(board, layout).segments,
            unorderedEquals(traceOptics(board, wins.first).segments),
          );
        }
        final winningLayout = wins.singleWhere(
          (layout) => !layout.first.turned,
        );
        progress = progress
            .saveBlueprint(expected)
            .recordEndless(GameSave(lesson, layout: winningLayout));
        expect(progress.resultFor(level)?.stars, level.solutionIds.toSet());
      }
      final store = MemoryStore();
      await store.write(progress);
      final loaded = (await store.load())!;
      expect(loaded.blueprints, {_straightAndRight, _twin, _offset, _filtered});
      expect(loaded.endlessBoards, hasLength(6));
      for (final saved in loaded.endlessBoards.values) {
        expect(saved.solved, isTrue);
        expect(loaded.blueprints, contains(saved.layout.first.blueprint));
      }
    },
  );

  test('diagonal rays respect both the wall and the receiver approach', () {
    OpticalLevel board({bool blocked = false, bool wrongApproach = false}) =>
        OpticalLevel(
          title: 'Diagonal ray',
          laser: const FloorPoint(0, 0),
          laserFoot: const FloorPoint(0, 0),
          direction: BeamDirection.northEast,
          floor: const math.Rectangle<double>(-1, -1, 5, 3),
          receivers: [
            if (wrongApproach)
              const OpticalReceiver(
                'Wrong approach',
                FloorPoint(1, 1),
                BeamDirection.north,
              ),
            const OpticalReceiver(
              'Latch',
              FloorPoint(2, 2),
              BeamDirection.northEast,
            ),
          ],
          goal: {wrongApproach ? 1 : 0},
          initial: const [],
          blocks: [if (blocked) const math.Rectangle<double>(1, .7, .3, .6)],
        );
    final clear = traceOptics(board(), const []);
    expect(clear.lit, {0});
    expect(
      clear.segments.single.to.distanceTo(const FloorPoint(2, 2)),
      lessThan(1e-9),
    );
    final rejected = traceOptics(board(wrongApproach: true), const []);
    expect(rejected.lit, isEmpty);
    expect(rejected.segments.single.blocked, isTrue);
    expect(
      rejected.segments.single.to.distanceTo(const FloorPoint(1, 1)),
      lessThan(1e-9),
    );
    final blocked = traceOptics(board(blocked: true), const []);
    expect(blocked.lit, isEmpty);
    expect(
      blocked.segments.single.to.distanceTo(const FloorPoint(1, 1)),
      lessThan(1e-9),
    );
  });

  test('blueprints canonicalize port order and reject invalid assemblies', () {
    expect(
      SplitterBlueprint(SplitterPort.right45, SplitterPort.straight),
      _straightAndRight,
    );
    expect(
      () => SplitterBlueprint.fromJson(['straight', 'straight']),
      throwsFormatException,
    );
    expect(
      () => SplitterBlueprint.fromJson(['straight', 'right22']),
      throwsFormatException,
    );
    expect(
      SplitterBlueprint.fromJson(['straight', 'right45']),
      _straightAndRight,
    );
    expect(SplitterBlueprint.fromJson(_filtered.toJson()), _filtered);
    expect(
      () => SplitterBlueprint.fromJson(['straight', 'right45', 'right90']),
      throwsFormatException,
    );
  });

  testWidgets(
    'learns, tests, saves, fits and reuses a blueprint across app runs',
    (tester) async {
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

      await playWorkbench(
        tester,
        store,
        failNextWrite: () => store.failNextWrite = true,
      );
    },
  );
}

Future<void> playWorkbench(
  WidgetTester tester,
  GameStore store, {
  VoidCallback? failNextWrite,
  Future<void> Function(String)? capture,
}) async {
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> turn(String port, String side) async {
    await tap(find.byKey(ValueKey('optical-port-${port.toLowerCase()}')));
    await tap(find.byTooltip('Turn Port $port $side'));
  }

  await pumpSilentGame(tester, store);
  await tester.pumpAndSettle();
  await tap(find.text('Endless'));
  await tap(find.byKey(const ValueKey('endless-group-1')));
  await tap(find.text('Workbench sheets'));
  await tap(find.byKey(const ValueKey('endless-1.21')));
  expect(find.text('Fabrication required'), findsOneWidget);
  await capture?.call('fabrication-empty-optical');
  await tap(find.text('Insert part'));
  expect(find.textContaining('No compatible parts saved'), findsOneWidget);
  await tap(find.text('Build'));
  expect(find.text('WORKBENCH TUTORIAL'), findsOneWidget);
  void expectOutput(String port, String reading) {
    expect(
      find.descendant(
        of: find.byKey(ValueKey('optical-reading-$port')),
        matching: find.text(reading),
      ),
      findsOneWidget,
    );
  }

  final save = find.widgetWithText(OutlinedButton, 'Save blueprint');
  final test = find.widgetWithText(OutlinedButton, 'Test');
  Future<void> savePart() async {
    await tap(save);
    await tap(find.text('Save part'));
  }

  expect(tester.widget<OutlinedButton>(save).onPressed, isNull);
  expect(tester.widget<OutlinedButton>(test).onPressed, isNull);

  await turn('B', 'left');
  await tap(test);
  expect(find.textContaining('A latch is dark'), findsOneWidget);
  expect(tester.widget<OutlinedButton>(save).onPressed, isNull);
  await turn('B', 'right');
  expect(tester.widget<OutlinedButton>(test).onPressed, isNull);
  await turn('B', 'right');
  expect(tester.widget<OutlinedButton>(save).onPressed, isNull);
  await tap(test);
  expect(find.textContaining('Both latches lit'), findsOneWidget);
  await turn('B', 'right');
  expect(find.textContaining('Both latches lit'), findsNothing);
  final right = find.widgetWithIcon(IconButton, Icons.rotate_right).last;
  expect(tester.widget<IconButton>(right).onPressed, isNull);
  await turn('B', 'left');
  await tap(test);
  expect(find.textContaining('Both latches lit'), findsOneWidget);
  await tap(find.byKey(const ValueKey('optical-port-input')));
  await tap(find.byTooltip('Turn input right'));
  await tap(test);
  expect(find.textContaining('No pulse reached'), findsOneWidget);
  expect(tester.widget<OutlinedButton>(save).onPressed, isNull);
  expect(
    tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.rotate_right).last,
        )
        .onPressed,
    isNull,
  );
  await tap(find.byKey(const ValueKey('optical-laser')));
  await tap(find.byTooltip('Turn test laser right'));
  await tap(test);
  expect(find.textContaining('Both latches lit'), findsOneWidget);
  await tap(find.byKey(const ValueKey('optical-splitter')));
  await tap(find.byTooltip('Turn splitter right'));
  await tap(test);
  expect(find.textContaining('No pulse reached'), findsOneWidget);
  await tap(find.byTooltip('Turn splitter left'));
  await tap(find.byKey(const ValueKey('optical-port-input')));
  await tap(find.byTooltip('Turn input left'));
  await tap(find.byKey(const ValueKey('optical-laser')));
  await tap(find.byTooltip('Turn test laser left'));
  await tap(test);
  expect(find.textContaining('Both latches lit'), findsOneWidget);
  if (failNextWrite != null) {
    failNextWrite();
    await savePart();
    expect(
      find.text('The blueprint could not be saved. Try again.'),
      findsOneWidget,
    );
  }
  await savePart();
  expect(find.text('Tutorial complete. Blueprint saved.'), findsOneWidget);
  final fit = find.text('Fit to puzzle');
  await tap(fit);
  expect(find.byKey(const ValueKey('lesson-complete')), findsOneWidget);
  await dismissPuzzleAnnouncement(tester);
  expect((await store.load())?.blueprints, {_straightAndRight});

  await tester.pumpWidget(const SizedBox.shrink());
  await pumpSilentGame(tester, store);
  await tester.pumpAndSettle();
  await tap(find.text('Workbench'));
  expect(find.text('WORKBENCH'), findsOneWidget);
  await tap(find.text('Add part'));
  await tap(find.text('Optical splitter'));
  await turn('A', 'left');
  await tap(find.text('Blueprints'));
  expect(find.byKey(ValueKey(_straightAndRight)), findsOneWidget);
  await tap(find.text('Build'));
  await turn('B', 'right');
  await tap(test);
  await savePart();
  expect(find.byKey(ValueKey(_twin)), findsOneWidget);
  await tap(find.byKey(ValueKey(_straightAndRight)));
  expect(
    tester
        .widget<OpticalDeck>(find.byType(OpticalDeck))
        .layout
        .single
        .blueprint,
    _straightAndRight,
  );
  await tap(find.text('Load blueprint'));
  expectOutput('a', '50 u');
  expectOutput('b', '50 u');
  await tap(find.text('Tutorial'));
  expect(find.text('WORKBENCH TUTORIAL'), findsOneWidget);
  await tap(find.byTooltip('Return to title'));
  await tap(find.text('Endless'));
  await tap(find.byKey(const ValueKey('endless-group-1')));
  await tap(find.text('Workbench sheets'));
  await tap(find.byKey(const ValueKey('endless-1.21')));
  expect(find.byKey(const ValueKey('lesson-complete')), findsNothing);
  await tap(find.text('Insert part'));
  await tap(fit);
  expect(find.byKey(const ValueKey('lesson-complete')), findsOneWidget);
  await tap(find.byTooltip('Back to puzzles'));
  await tap(find.byKey(const ValueKey('endless-1.26')));
  await tap(find.text('Insert part'));
  await tap(find.byKey(ValueKey(_straightAndRight)));
  await tap(fit);
  expect(find.byKey(const ValueKey('lesson-complete')), findsNothing);
  expect(find.text('50 U / 25'), findsOneWidget);
  await tap(find.text('Workbench'));
  await tap(find.text('Build'));
  await tap(find.byTooltip('Remove optical output B'));
  expect(tester.widget<OutlinedButton>(test).onPressed, isNull);
  await turn('B', 'right');
  await tap(find.byTooltip('Clip filter to Port B'));
  await tap(find.byTooltip('Flip splitter'));
  await tap(find.byTooltip('Flip splitter'));
  await tap(test);
  expectOutput('a', '50 u');
  expectOutput('b', '25 u');
  await tap(save);
  await tap(find.byTooltip('Prism'));
  await tester.enterText(find.byType(TextField), 'Prism Relay');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  await tap(find.text('Save part'));
  final named = _filtered.withMark((
    name: 'Prism Relay',
    icon: WorkbenchIcon.prism,
  ));
  expect(find.byKey(ValueKey(named)), findsOneWidget);
  await tap(fit);
  expect(find.byKey(const ValueKey('lesson-complete')), findsOneWidget);
  await dismissPuzzleAnnouncement(tester);
  expect(find.text('Prism Relay'), findsOneWidget);
  expect(
    tester
        .widgetList<OpticalPartSymbol>(find.byType(OpticalPartSymbol))
        .where((symbol) => symbol.mark == WorkbenchIcon.prism),
    hasLength(1),
  );
  final fitted =
      (await store.load())!.endlessBoards[EndlessLevel.splitAndDim.lesson!.id]!;
  expect(fitted.layout.single.blueprint, named);
  await capture?.call('named-optical-part');

  await tap(find.byTooltip('Back to puzzles'));
  await tap(find.byKey(const ValueKey('endless-1.25')));
  await tap(find.text('Insert part'));
  await tap(fit);
  expect(find.byKey(const ValueKey('lesson-complete')), findsNothing);
  final deck = find.byType(OpticalDeck);
  final geometry = tester.widget<OpticalDeck>(deck).geometry;
  final origin = tester.getTopLeft(deck);
  final from = geometry.project(const FloorPoint(0, 2.1));
  final to = geometry.project(const FloorPoint(0, 1.05));
  await tester.dragFrom(origin + from, to - from);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('lesson-complete')), findsOneWidget);
  await dismissPuzzleAnnouncement(tester);

  final progress = (await store.load())!;
  expect(progress.blueprints, {_straightAndRight, _twin, named});
  expect(progress.resultFor(EndlessLevel.diagonalLatch)?.stars, {
    'custom-split',
  });
  expect(progress.resultFor(EndlessLevel.splitTheSplit)?.stars, {
    'custom-split',
  });
  expect(progress.resultFor(EndlessLevel.splitAndDim)?.stars, {
    'filtered-branch',
  });
  expect(tester.takeException(), isNull);
}

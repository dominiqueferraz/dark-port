import 'package:dark_port/assembly.dart';
import 'package:dark_port/drafting_parts.dart';
import 'package:dark_port/workbench_part_mark.dart';
import 'package:dark_port/endless_levels.dart';
import 'package:dark_port/game_save.dart';
import 'package:dark_port/socket_aim.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_store.dart';
import 'support/pump_silent_game.dart';
import 'support/puzzle_announcement.dart';

const _feeds = AssemblyBlueprint.inputs;
const _outputs = AssemblyBlueprint.outputs;

AssemblyBlueprint _wire(
  AssemblyBlueprint design,
  int from,
  int port,
  int to,
  int socket,
) => design.connect((cell: from, port: port), (cell: to, port: socket))!;

AssemblyBlueprint _pair(AssemblyModule second) {
  var design = AssemblyBlueprint.empty
      .withJacks(2, second.outputs)
      .place(3, AssemblyModule.interlock)
      .place(4, second);
  design = _wire(design, _feeds, 0, 3, 0);
  design = _wire(design, _feeds, 1, 3, 1);
  design = _wire(design, 3, 0, 4, 0);
  design = _wire(design, 4, 0, _outputs, 0);
  if (second.outputs == 2) design = _wire(design, 4, 1, _outputs, 1);
  return design;
}

AssemblyBlueprint _withExtraEnableModule(AssemblyBlueprint design) {
  design = _wire(design.place(1, AssemblyModule.fanout), _feeds, 1, 1, 0);
  return _wire(design, 1, 0, 3, 1);
}

void main() {
  test('three modules and three jacks on each side work independently', () {
    const feeds = [100.0, 80.0, 60.0];
    final pair = _pair(AssemblyModule.fanout);
    var design = pair.withJacks(3, 3).place(8, AssemblyModule.pad);
    design = _wire(design, _feeds, 2, 8, 0);
    design = _wire(design, 8, 0, _outputs, 2);
    expect(design.evaluate(feeds, 3), [50, 50, 35]);
    expect(design.evaluate([100, 0, 60], 3), [0, 0, 35]);
    expect(design.evaluate([0, 80, 60], 3), [0, 0, 35]);
    expect(design.evaluate([100, 80, 0], 3), [50, 50, 0]);
    expect(
      design.connect((cell: 4, port: 0), (cell: 3, port: 0)),
      isNull,
      reason: 'Feedback would create a cycle.',
    );
    final recovered = AssemblyBlueprint.fromJson(design.toJson());
    expect(recovered, design);
    expect(recovered.evaluate(feeds, 3), [50, 50, 35]);
    expect(twinReleaseLesson.fixture.accepts(design), isFalse);
    final moved = design.orient(8, (turns: 1, flipped: true)).move(8, 7);
    expect(moved.orientation(7), (turns: 1, flipped: true));
    expect(moved.evaluate(feeds, 3), [50, 50, 35]);
    expect(AssemblyBlueprint.fromJson(moved.toJson()), moved);
    final aimed = moved
        .aimSocket((cell: _feeds, port: 2), SocketAim.right)
        .aimSocket((cell: _outputs, port: 2), SocketAim.left);
    expect(AssemblyBlueprint.fromJson(aimed.toJson()), aimed);
    expect(aimed.evaluate(feeds, 3), [50, 50, 35]);
    expect(SocketAim.right.turn(1), isNull);
    expect(SocketAim.left.turn(-1), isNull);
    expect(
      () => AssemblyBlueprint.fromJson({
        ...aimed.toJson(),
        'aims': [
          [_feeds, 2, 2],
        ],
      }),
      throwsFormatException,
    );
    expect(moved.withJacks(2, 2).evaluate(feeds, 3), [50, 50, 0]);
    final legacy = AssemblyBlueprint.fromJson({
      'modules': [
        [0, 'pad'],
      ],
      'wires': [
        [_feeds, 2, 0, 0],
        [0, 0, _outputs, 2],
      ],
    });
    expect(legacy.evaluate(feeds, 3), [0, 0, 35]);
  });

  test('fabrication sockets check ports and the fitted part is tested as a black box', () {
    var progress = TutorialProgress(tutorialStarted: false);
    for (final (level, lesson, part) in [
      (EndlessLevel.twinRelease, twinReleaseLesson, AssemblyModule.fanout),
      (EndlessLevel.dimmedRelease, dimmedReleaseLesson, AssemblyModule.pad),
    ]) {
      final design = _pair(part);
      final expanded = _withExtraEnableModule(design);
      expect(GameSave(lesson, assembly: expanded).solved, isFalse);
      final result = GameSave(
        lesson,
        assembly: expanded,
        assemblyInstalled: true,
      );
      expect(result.solved, isTrue);
      expect(
        lesson.fixture.solves(design.place(0, AssemblyModule.pad)),
        isTrue,
      );
      expect(
        lesson.fixture.accepts(design.withJacks(3, part.outputs)),
        isFalse,
      );
      expect(lesson.fixture.solves(design.place(4, null)), isFalse);
      final bypass = _wire(design, _feeds, 0, 4, 0);
      expect(
        lesson.fixture.solves(bypass),
        isFalse,
        reason: 'Missing enable must shut off the output.',
      );
      final incorrect = GameSave(
        lesson,
        assembly: bypass,
        assemblyInstalled: true,
      );
      final reread = GameSave.fromJson(incorrect.toJson());
      expect(reread.assemblyInstalled, isTrue);
      expect(reread.solved, isFalse);
      final draft = GameSave(lesson, assembly: design).toJson();
      expect(GameSave.fromJson(draft).assemblyInstalled, isFalse);
      draft.remove('assemblyInstalled');
      expect(GameSave.fromJson(draft).solved, isTrue);
      progress = progress.saveAssembly(expanded).recordEndless(result);
      expect(progress.resultFor(level)?.stars, {'paired-assembly'});
    }
    final loaded = TutorialProgress.fromJson(progress.toJson());
    expect(loaded.assemblies, progress.assemblies);
    expect(loaded.endlessBoards.values.every((board) => board.solved), isTrue);
  });

  testWidgets(
    'empty sockets accept fabricated designs with any working internal layout',
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
      await playAssemblyWorkbench(tester, MemoryStore());
    },
  );

  test('a future fixture can specify targets for individual input states', () {
    const fixture = AssemblyFixture(
      feeds: [100, 60],
      targets: [50, 50],
      targetsByMask: {
        1: [50, 50],
      },
    );
    var design = AssemblyBlueprint.blank
        .withJacks(2, 2)
        .place(0, AssemblyModule.fanout);
    design = _wire(design, _feeds, 0, 0, 0);
    design = _wire(design, 0, 0, _outputs, 0);
    design = _wire(design, 0, 1, _outputs, 1);
    expect(fixture.solves(design), isTrue);
    expect(twinReleaseLesson.fixture.solves(design), isFalse);
  });
}

Future<void> playAssemblyWorkbench(
  WidgetTester tester,
  GameStore store, {
  Future<void> Function(String)? capture,
}) async {
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder key(String value) => find.byKey(ValueKey(value));

  void expectReading(int output, String state) {
    final row = tester.widget<DraftingPartRow>(key('assembly-output-$output'));
    expect(row.state, state);
  }

  Future<void> place(int cell, AssemblyModule part) async {
    await tap(key('assembly-cell-$cell'));
    await tap(key('assembly-module-${part.name}'));
  }

  Future<void> wire(int from, int port, int to, int socket) async {
    await tap(key('assembly-out-$from-$port'));
    await tap(key('assembly-in-$to-$socket'));
  }

  await pumpSilentGame(tester, store);
  await tester.pumpAndSettle();
  await tap(find.text('Endless'));
  await tap(key('endless-group-1'));
  await tap(find.text('Workbench sheets'));
  await tap(key('endless-1.27'));
  expect(find.text('TWIN RELEASE'), findsWidgets);
  expect(find.text('Fabrication required'), findsOneWidget);
  expect(key('empty-assembly-socket'), findsOneWidget);
  expect(key('assembly-cell-3'), findsNothing);
  await capture?.call('fabrication-empty-wired');
  await tap(find.text('Insert part'));
  expect(find.textContaining('No compatible parts saved'), findsOneWidget);
  await tap(find.text('Build'));
  await place(3, AssemblyModule.interlock);
  await place(4, AssemblyModule.fanout);
  await place(1, AssemblyModule.fanout);
  await wire(_feeds, 0, 3, 0);
  await wire(_feeds, 1, 1, 0);
  await wire(1, 0, 3, 1);
  await wire(3, 0, 4, 0);
  await wire(4, 0, _outputs, 0);
  expect(key('lesson-complete'), findsNothing);
  await wire(4, 1, _outputs, 1);
  expect(key('lesson-complete'), findsNothing);
  await tap(key('assembly-feed-1'));
  expect(find.byType(DraftingPartsList), findsOneWidget);
  expect(
    find.descendant(
      of: key('assembly-feed-1'),
      matching: find.byIcon(Icons.power_off_outlined),
    ),
    findsOneWidget,
  );
  expectReading(0, '0 u / 0 u');
  await tap(key('assembly-feed-1'));
  await capture?.call('workbench-two-module-sheet');
  await tap(find.text('Save blueprint'));
  await tap(find.byTooltip('Shield'));
  await tester.enterText(find.byType(TextField), 'Twin Gate');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  await capture?.call('customize-workbench-part');
  await tap(find.text('Save part'));
  final named = _withExtraEnableModule(_pair(AssemblyModule.fanout))
      .withMark((name: 'Twin Gate', icon: WorkbenchIcon.shield));
  expect((await store.load())!.assemblies.single, named);
  await tap(find.text('Fit to puzzle'));
  expect(key('lesson-complete'), findsOneWidget);
  await dismissPuzzleAnnouncement(tester);
  expect(key('assembly-cell-3'), findsNothing);
  expect(
    find.descendant(
      of: key('fitted-assembly'),
      matching: find.text('Twin Gate'),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: key('fitted-assembly'),
      matching: find.byIcon(Icons.shield_outlined),
    ),
    findsOneWidget,
  );
  final fitted =
      (await store.load())!.endlessBoards[EndlessLevel.twinRelease.lesson!.id]!;
  expect(fitted.assemblyInstalled, isTrue);
  expect(fitted.assembly, named);
  await capture?.call('named-wired-part');
  await tap(key('assembly-feed-1'));
  expectReading(0, '0 u / 0 u');
  await tap(key('assembly-feed-1'));
  await tap(find.byTooltip('Back to puzzles'));
  await tap(key('endless-1.28'));
  expect(key('empty-assembly-socket'), findsOneWidget);
  await tap(key('empty-assembly-socket'));
  expect(find.text('Twin Gate'), findsNothing);
  expect(find.textContaining('No compatible parts saved'), findsOneWidget);
  await tap(find.byTooltip('Return to puzzle'));
  await tap(find.text('Workbench'));
  await place(3, AssemblyModule.interlock);
  await place(4, AssemblyModule.pad);
  await wire(_feeds, 0, 4, 0);
  await wire(4, 0, _outputs, 0);
  await tap(find.text('Save blueprint'));
  await tap(find.text('Save part'));
  await tap(find.text('Fit to puzzle'));
  expect(key('fitted-assembly'), findsOneWidget);
  expect(key('lesson-complete'), findsNothing);
  expect(find.text('Replace part'), findsOneWidget);
  await tap(find.text('Workbench'));
  await wire(_feeds, 0, 3, 0);
  await wire(_feeds, 1, 3, 1);
  await wire(3, 0, 4, 0);
  await wire(4, 0, _outputs, 0);
  expect(key('lesson-complete'), findsNothing);
  await tap(find.text('Save blueprint'));
  await tap(find.text('Save part'));
  await tap(find.text('Fit to puzzle'));
  expect(key('lesson-complete'), findsOneWidget);
  await dismissPuzzleAnnouncement(tester);
  await tap(find.byTooltip('Back to puzzles'));
  await tap(find.byTooltip('Back to Endless groups'));
  await tap(find.byTooltip('Return to title'));
  await tap(find.text('Workbench'));
  expect(find.text('WORKBENCH'), findsOneWidget);
  expect(find.text('Optical'), findsNothing);
  expect(find.text('Wired'), findsNothing);
  final tutorial = find.widgetWithText(OutlinedButton, 'Tutorial');
  final blueprints = find.widgetWithText(OutlinedButton, 'Blueprints');
  final build = find.widgetWithText(OutlinedButton, 'Build');
  final addPart = find.widgetWithText(OutlinedButton, 'Add part');
  expect(tester.getCenter(blueprints).dy, tester.getCenter(tutorial).dy);
  expect(tester.getCenter(build).dy, tester.getCenter(addPart).dy);
  for (final button in [tutorial, blueprints, build, addPart]) {
    expect(
      find.descendant(of: button, matching: find.byType(Icon)),
      findsOneWidget,
    );
  }
  expect(key('assembly-out--1-0'), findsNothing);
  expect(find.byTooltip('Add input'), findsOneWidget);
  expect(find.byTooltip('Add output'), findsOneWidget);
  await tap(find.text('Blueprints'));
  await tap(find.text('Twin Gate'));
  await tap(find.text('Load blueprint'));
  await tap(find.byTooltip('Add input'));
  await tap(find.byTooltip('Add output'));
  await place(8, AssemblyModule.pad);
  await wire(_feeds, 2, 8, 0);
  await wire(8, 0, _outputs, 2);
  expectReading(2, '35 u');
  expect(
    tester.getBottomRight(key('assembly-output-2')).dy,
    lessThanOrEqualTo(
      tester.getBottomRight(find.byKey(const ValueKey(false))).dy + .5,
    ),
  );
  await tap(find.byTooltip('Turn part right'));
  await tap(find.byTooltip('Flip part'));
  final from = tester.getCenter(key('assembly-cell-8'));
  final to = tester.getCenter(key('assembly-cell-7'));
  await tester.dragFrom(from, to - from);
  await tester.pumpAndSettle();
  expect(key('assembly-out-7-0'), findsOneWidget);
  expectReading(2, '35 u');
  await tap(key('assembly-aim--1-2'));
  await tap(find.byTooltip('Turn input C right'));
  final right = find.widgetWithIcon(IconButton, Icons.rotate_right).first;
  expect(tester.widget<IconButton>(right).onPressed, isNull);
  await tap(key('assembly-aim--2-2'));
  await tap(find.byTooltip('Turn output 3 left'));
  expectReading(2, '35 u');
  await capture?.call('workbench-expanded-grid');

  await tap(find.text('Add part'));
  expect(find.text('Optical splitter'), findsOneWidget);
  expect(find.text('Interlock'), findsOneWidget);
  expect(find.text('Fan-out'), findsOneWidget);
  expect(find.text('25 u pad'), findsOneWidget);
  for (final module in AssemblyModule.values) {
    expect(
      find.descendant(
        of: key('assembly-module-${module.name}'),
        matching: find.text(module.symbol),
      ),
      findsOneWidget,
    );
  }
  await capture?.call('workbench-part-picker');
  await tap(find.text('Optical splitter'));
  await tap(key('optical-port-b'));
  await tap(find.byTooltip('Turn Port B right'));
  await tap(find.text('Test'));
  await capture?.call('workbench-optical-splitter');
  await tap(find.text('Save blueprint'));
  await tap(find.text('Save part'));
  expect(find.textContaining('Optical splitter'), findsOneWidget);
  expect(find.text('Twin Gate'), findsOneWidget);
  await capture?.call('workbench-shared-library');
  await tap(find.text('Twin Gate'));
  expect(key('assembly-cell-3'), findsOneWidget);
  await tap(find.text('Build'));
  expect(key('optical-port-b'), findsOneWidget);
  await tap(find.text('Add part'));
  await tap(find.text('Return to assembly'));
  expectReading(2, '35 u');
  await tap(find.text('Save blueprint'));
  await tap(find.text('Save part'));
  final extended = (await store.load())!.assemblies.singleWhere(
    (design) => design.modules.length == 4,
  );
  expect(extended.orientation(7), (turns: 1, flipped: true));
  expect(extended.aim((cell: _feeds, port: 2)), SocketAim.right);
  expect(extended.aim((cell: _outputs, port: 2)), SocketAim.left);
  expect(
    (await store.load())!.assemblies.any(
      (design) => design.modules.length == 4,
    ),
    isTrue,
  );
}

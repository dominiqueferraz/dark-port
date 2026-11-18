import 'dart:math' as math;

import 'package:dark_port/drafting_controls.dart';
import 'package:dark_port/drafting_grid.dart';
import 'package:dark_port/drafting_parts.dart';
import 'package:dark_port/drafting_theme.dart';
import 'package:dark_port/game_save.dart';
import 'package:dark_port/main.dart';
import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/optical_deck.dart';
import 'package:dark_port/puzzle_console.dart';
import 'package:dark_port/signal_board.dart';
import 'package:dark_port/signal_wiring.dart';
import 'package:dark_port/tutorial.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:dark_port/wired_boards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> playTutorial(
  WidgetTester tester, {
  required GameStore Function() makeStore,
  required Future<void> Function(String name) capture,
}) async {
  var store = makeStore();
  Future<void> tap(Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> press(String text) => tap(find.text(text));
  Future<void> pressIcon(String label) => tap(find.byTooltip(label));
  final advance = find.byKey(const ValueKey('lesson-advance'));
  final complete = find.byKey(const ValueKey('lesson-complete'));

  Finder row(TutorialLesson lesson) =>
      find.byKey(ValueKey('lesson-${lesson.id}'));

  Future<void> open(TutorialLesson lesson) async {
    await tester.ensureVisible(row(lesson));
    await tester.pumpAndSettle();
    await tester.tap(row(lesson));
    await tester.pumpAndSettle();
  }

  Future<void> relaunch() async {
    await tester.pumpWidget(const SizedBox.shrink());
    store = makeStore();
    await tester.pumpWidget(DarkPort(store: store));
    await tester.pumpAndSettle();
  }

  Future<void> back() async {
    await tester.tap(find.byTooltip('Back to tutorial'));
    await tester.pumpAndSettle();
  }

  await tester.pumpWidget(DarkPort(store: store));
  await tester.pumpAndSettle();
  final screen = tester.getRect(find.byType(Scaffold));
  final insets = MediaQuery.paddingOf(tester.element(find.byType(Scaffold)));
  final viewport = find.byKey(const ValueKey('landscape-viewport'));
  expect(screen.width, greaterThan(screen.height));
  expect(find.text('New game').hitTestable(), findsOneWidget);

  final details = find.byKey(const ValueKey('landscape-lesson-details'));
  void expectFits(Finder finder, Rect bounds) {
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(bounds.left - .01));
    expect(rect.top, greaterThanOrEqualTo(bounds.top - .01));
    expect(rect.right, lessThanOrEqualTo(bounds.right + .01));
    expect(rect.bottom, lessThanOrEqualTo(bounds.bottom + .01));
  }

  final toolbarGroup = find.byKey(const ValueKey('lesson-toolbar'));
  final readings = find.byKey(const ValueKey('landscape-lesson-readings'));

  void expectPanelAlignment() {
    final toolbarBounds = tester.getRect(toolbarGroup);
    final viewportBounds = tester.getRect(viewport);
    expect(viewportBounds.center.dy, closeTo(screen.center.dy, .51));
    final readingsBounds = tester.getRect(readings);
    expect(
      readingsBounds.top,
      closeTo(viewportBounds.top + draftingGridMargins.top, .51),
    );
    expect(tester.getRect(details).top - toolbarBounds.bottom, closeTo(6, .01));
    expect(
      toolbarBounds.top - tester.getRect(readings).bottom,
      closeTo(6, .01),
    );

    final buttons = find.descendant(
      of: toolbarGroup,
      matching: find.byType(IconButton),
    );
    expect(buttons, findsNWidgets(6));
    for (var i = 0; i < buttons.evaluate().length; i++) {
      final button = buttons.at(i);
      final bounds = tester.getRect(button);
      final glyph = find.descendant(of: button, matching: find.byType(Icon));
      expect(bounds.height, closeTo(consoleButtonSize.height, .01));
      expect(bounds.width, greaterThanOrEqualTo(32));
      expect(bounds.center.dy, closeTo(toolbarBounds.center.dy, .01));
      expect(tester.getSize(glyph), const Size.square(20));
      final glyphCenter = tester.getRect(glyph).center;
      expect(glyphCenter.dx, closeTo(bounds.center.dx, .01));
      expect(glyphCenter.dy, closeTo(bounds.center.dy, .01));
    }
  }

  Future<void> capturePhase(TutorialLesson lesson) async {
    final board = find.byKey(
      ValueKey(lesson is OpticalLesson ? 'optical-deck' : 'signal-playfield'),
    );
    expect(
      tester.widget<PuzzleConsole>(find.byType(PuzzleConsole)).brief.title,
      lesson.title,
    );
    expectPanelAlignment();
    final pane = tester.getRect(details);
    final window = tester.getRect(viewport);
    expect(window.width / (window.width + pane.width), closeTo(.7, .005));
    final verticalMargin =
        math.max(insets.top, insets.bottom) +
        7 +
        DraftingSheetFrame.contentPadding.top;
    expect(window.top, closeTo(screen.top + verticalMargin, .51));
    expect(window.bottom, closeTo(screen.bottom - verticalMargin, .51));
    expectFits(board, window);
    final grid = lesson is OpticalLesson
        ? tester
              .widget<OpticalDeck>(find.byType(OpticalDeck))
              .geometry
              .floorRect
              .shift(tester.getTopLeft(board))
        : tester.getRect(board);
    final expectedGrid = draftingGridMargins.deflateRect(window);
    expect(grid.topLeft, within(distance: .51, from: expectedGrid.topLeft));
    expect(
      grid.bottomRight,
      within(distance: .51, from: expectedGrid.bottomRight),
    );
    expect(tester.getTopLeft(readings).dy, closeTo(grid.top, .51));
    expect(tester.getRect(board).right, lessThan(pane.left));
    expectFits(find.byTooltip('Reset room'), screen);
    expectFits(find.text(lesson.objective), pane);
    final title = find.byType(DraftingTitleBlock);
    expectFits(title, screen);
    expect(find.ancestor(of: title, matching: details), findsNothing);
    expectFits(find.byType(DraftingPartRow).first, tester.getRect(readings));
    expectFits(find.byTooltip('Hint'), screen);
    expect(find.text(lesson.goal), findsNothing);
    await capture(lesson.id);
  }

  void expectAdvanceVisible(String label) {
    expect(tester.widget<IconButton>(advance).tooltip, label);
    expect(advance.hitTestable(), findsOneWidget);
    expectFits(advance, screen);
    expectFits(advance, tester.getRect(toolbarGroup));
    expectPanelAlignment();
  }

  await capture('qa-title');
  await press('New game');
  expect(find.text('TUTORIAL'), findsOneWidget);
  await capture('qa-tutorial-start');
  await open(firstReflection);
  await capturePhase(firstReflection);
  await pressIcon('Hint');
  expect(find.text(firstReflection.goal).hitTestable(), findsOneWidget);
  await pressIcon('Close hint');
  await pressIcon('Parts guide');
  expect(find.text('Beam splitter'), findsOneWidget);
  expect(find.text('Alarm blocker'), findsOneWidget);
  await press('Close');

  final deck = find.byKey(const ValueKey('optical-deck'));
  OpticalDeck board() => tester.widget<OpticalDeck>(find.byType(OpticalDeck));
  Offset at(FloorPoint p) =>
      tester.getTopLeft(deck) + board().geometry.project(p);
  Optic optic(String id) => board().layout.singleWhere((o) => o.id == id);
  Future<void> move(String id, FloorPoint to) async {
    final from = at(optic(id).position);
    await tester.dragFrom(from, at(to) - from);
    await tester.pump();
  }

  Future<void> rotate(String id) async {
    await tester.tapAt(at(optic(id).position));
    await tester.pump();
  }

  await move('M1', const FloorPoint(1.05, -.27));
  await rotate('M1');
  await capture('qa-reflection-solved');
  await tap(advance);
  await capturePhase(dividedBeam);

  await move('S1', const FloorPoint(-3.15, -.27));
  await tap(advance);
  await capturePhase(opticalInterlock);
  expect(board().trace.lit, {0});
  expect(advance, findsNothing);
  const alarmLine = FloorPoint(-3.15, .78);
  await move('M2', alarmLine);
  expect(find.textContaining('Alarm line interrupted.'), findsOneWidget);
  expect(advance, findsNothing);
  expect((await store.load())!.boards[opticalInterlock.id]!.solved, isFalse);
  await relaunch();
  await press('Continue game');
  await open(opticalInterlock);
  expect(
    find.text('Alarm line interrupted. Reset the room to try again.'),
    findsOneWidget,
  );
  await tester.tap(find.byTooltip('Reset room'));
  await tester.pumpAndSettle();
  expect(board().trace.lit, {0});
  await move('S2', alarmLine);
  await rotate('S2');
  await move('S1', const FloorPoint(-1.05, .78));
  await move('M2', const FloorPoint(3.15, .78));
  await rotate('M2');
  expect(board().trace.lit, {0, 1, 2});
  expect(board().opened, isTrue);
  expectAdvanceVisible('Next lesson');
  await capture('qa-interlock-solved');
  await tap(advance);
  await capturePhase(patchLead);
  WiredLesson active = patchLead;
  Future<GameSave> currentSave() async =>
      (await store.load())!.boards[active.id] ?? GameSave(active);

  Finder part(String id) => find.byKey(ValueKey('signal-device-$id'));

  Future<void> tapPart(String id) async {
    final target = part(id);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  final signalBoard = find.byKey(const ValueKey('signal-playfield'));
  Offset boardOffset(double x, double y) {
    final size = tester.getSize(signalBoard);
    return Offset(
      x * size.width / active.board.size,
      y * size.height / active.board.height,
    );
  }

  Offset boardPoint(double x, double y) =>
      tester.getTopLeft(signalBoard) + boardOffset(x, y);

  Future<void> tapPort(
    String id, {
    required bool output,
    int input = 0,
    int port = 0,
  }) async {
    await tester.ensureVisible(part(id));
    await tester.pumpAndSettle();
    final flipped = (await currentSave()).flipped.contains(id);
    final offset = output
        ? SignalBoard.outputPort(port, flipped: flipped)
        : SignalBoard.inputPort(input, flipped: flipped);
    await tester.tapAt(
      tester.getCenter(part(id)) + boardOffset(offset.x, offset.y),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dragPart(String id, double x, double y) async {
    await tester.ensureVisible(signalBoard);
    await tester.pumpAndSettle();
    final from = tester.getCenter(part(id));
    await tester.dragFrom(from, boardPoint(x, y) - from);
    await tester.pumpAndSettle();
  }

  Future<void> flip(String id) async {
    await tester.ensureVisible(part(id));
    await tester.pumpAndSettle();
    await tester.longPress(part(id));
    await tester.pumpAndSettle();
  }

  void expectGoal(String id, String reading, String status) {
    final indicator = find.byKey(ValueKey('signal-goal-$id'));
    expect(
      find.descendant(of: indicator, matching: find.byTooltip(status)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: indicator,
        matching: find.textContaining(
          RegExp(
            '^${RegExp.escape(reading.replaceAll('/', ' / '))}'
            r' (?:u|units)$',
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<Semantics>(indicator).properties.label,
      contains(status),
    );
  }

  Future<void> setLoss(String id, int loss, String total) async {
    await tapPart(id);
    await pressIcon('$loss u loss');
    final saved = await currentSave();
    expect(saved.losses[id], loss);
    expect(saved.alarmFailed, isFalse);
    expectGoal('alarmBlocker', '$total/25–35', 'Holding on Pilot and Beacon');
  }

  Future<void> pressHistory(String action) async {
    final button = find.byKey(ValueKey('signal-${action.toLowerCase()}'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> wire(
    String from,
    String to, {
    int port = 0,
    int input = 0,
  }) async {
    await tapPort(from, output: true, port: port);
    await tapPort(to, output: false, input: input);
  }

  expect(find.text('Dashed cables are out of reach.'), findsOneWidget);
  await tapPart('lampOne');
  expect(find.textContaining('Output reaches 3'), findsOneWidget);
  await dragPart('feed', 3.5, 2.5);
  expect(find.text('Dashed cables are out of reach.'), findsNothing);
  await tapPart('lampOne');
  await pressIcon('Disconnect Feed → Lamp I');
  await wire('feed', 'lampTwo');
  expect((await currentSave()).solved, isTrue);
  await capture('qa-patch-lead');
  await tap(advance);
  active = splitRatings;
  await capturePhase(splitRatings);

  await wire('beacon', 'threeWay');
  await wire('threeWay', 'loadA', port: 1);
  expectGoal('loadA', '100/90–110', 'Online');
  await wire('threeWay', 'twoWay');
  await wire('twoWay', 'loadB');
  expectGoal('loadB', '50/45–60', 'Online');
  expect((await currentSave()).solved, isTrue);
  await back();
  await capture('qa-tutorial-branch');
  expect(row(splitRatings).hitTestable(), findsOneWidget);
  expect(row(benchPad).hitTestable(), findsOneWidget);
  expect(tester.widget<InkWell>(row(benchPad)).onTap, isNotNull);
  expect(
    tester.getCenter(row(fanOut)).dy,
    greaterThan(tester.getCenter(row(splitRatings)).dy),
  );
  expect(
    tester.getCenter(row(fanOut)).dx,
    greaterThan(tester.getCenter(row(splitRatings)).dx),
  );
  expect(
    tester.getCenter(row(fanOut)).dx,
    lessThan(tester.getCenter(row(benchPad)).dx),
  );
  expect((await store.load())!.isComplete(fanOut), isFalse);

  await open(fanOut);
  active = fanOut;
  await capturePhase(fanOut);
  await wire('beacon', 'fourWay');
  await wire('fourWay', 'east');
  expectGoal('east', '75/75', 'Online');
  await wire('fourWay', 'north', port: 1);
  await wire('fourWay', 'south', port: 2);
  await wire('fourWay', 'west', port: 3);
  expect((await currentSave()).solved, isTrue);
  expectGoal('east', '75/75', 'Online');
  await tap(advance);

  await open(benchPad);
  active = benchPad;
  await capturePhase(benchPad);
  await dragPart('attenuator', 2.5, 2.5);
  await wire('attenuator', 'meter');
  expect(find.textContaining('Output reaches 2'), findsOneWidget);
  expect((await currentSave()).links, isEmpty);
  await flip('attenuator');
  await wire('feed', 'attenuator');
  await wire('attenuator', 'meter');
  expectGoal('meter', '40/30', 'Too strong');
  await tapPart('attenuator');
  await pressIcon('20 u loss');
  expectGoal('meter', '20/30', 'Too weak');
  await pressIcon('10 u loss');
  expectGoal('meter', '30/30', 'Online');
  expect((await currentSave()).solved, isTrue);
  await tap(advance);
  active = keepalive;
  await capturePhase(keepalive);

  await wire('attenuator', 'alarmBlocker', input: 1);
  expectGoal('alarmBlocker', '35/25–35', 'Holding on Pilot and Beacon');
  await setLoss('pilot', 10, '25');
  await setLoss('attenuator', 10, '35');
  await setLoss('pilot', 20, '25');
  await setLoss('attenuator', 0, '35');
  await tapPart('alarmBlocker');
  await pressIcon('Disconnect Pilot → Alarm blocker A');
  expectGoal('alarmBlocker', '25/25–35', 'Holding on Beacon');
  await wire('aux', 'service');
  expectGoal('service', '30/30', 'Needs Pilot');
  await wire('pilot', 'service');
  await tapPart('pilot');
  await pressIcon('0 u loss');
  expect((await currentSave()).solved, isTrue);
  await capture('qa-keepalive');
  await tap(advance);
  active = testLine;
  await capturePhase(testLine);

  final toolbar = find.byKey(const ValueKey('signal-toolbar'));
  final hud = find.byKey(const ValueKey('signal-goals'));
  final boardBounds = tester.getRect(signalBoard);
  expect(boardBounds.bottom, lessThan(screen.bottom));
  expect(boardBounds.top, greaterThanOrEqualTo(screen.top));
  expect(tester.getRect(toolbar).left, greaterThan(boardBounds.right));
  expect(tester.getRect(hud).left, greaterThan(boardBounds.right));
  final beaconCenter = tester.getCenter(part('beacon')).dy;
  expect(
    find.descendant(of: signalBoard, matching: find.text('Beacon')),
    findsNothing,
  );
  final beaconReading = find.descendant(
    of: signalBoard,
    matching: find.text('300 u'),
  );
  expect(tester.getTopLeft(beaconReading).dy, greaterThan(beaconCenter));

  expectGoal('terminal', '0/45–60', 'No signal');
  expectGoal('recorder', '0/90–110', 'No signal');
  expectGoal('service', '0/30', 'No signal');
  final marks = find.byKey(const ValueKey('signal-placement-marks'));
  expect(marks, findsNothing);
  expectGoal('alarmBlocker', '30/25–35', 'Holding on Pilot');
  expect(find.text('Send signal'), findsNothing);

  final blockerDrag = await tester.startGesture(
    tester.getCenter(part('alarmBlocker')),
  );
  await blockerDrag.moveTo(boardPoint(5.5, 6.5));
  await tester.pump();
  expect(
    find.text('This placement would interrupt the alarm blocker.'),
    findsOneWidget,
  );
  expect((await currentSave()).alarmFailed, isFalse);
  await blockerDrag.cancel();
  await tester.pumpAndSettle();

  await dragPart('alarmBlocker', 5.5, 6.5);
  expect(find.text('Alarm tripped. Undo or reset the room.'), findsOneWidget);
  expect((await currentSave()).alarmFailed, isTrue);
  await dragPart('alarmBlocker', 2.5, 5.5);
  expect((await currentSave()).alarmFailed, isTrue);
  await pressHistory('Undo');
  expectGoal('alarmBlocker', '30/25–35', 'Holding on Pilot');
  expect((await currentSave()).alarmFailed, isFalse);

  await pressHistory('Redo');
  expect((await currentSave()).alarmFailed, isTrue);
  await pressHistory('Undo');
  expect((await currentSave()).alarmFailed, isFalse);

  await tapPart('alarmBlocker');
  await pressIcon('Disconnect Pilot → Alarm blocker A');
  expect(
    find.text('Disconnecting this feed would interrupt the alarm blocker.'),
    findsOneWidget,
  );
  expect((await currentSave()).links, testLineBoard.initialLinks);

  await tapPart('beacon');
  await tapPort('alarmBlocker', output: false);
  expect(
    find.text('That alarm input is wired. Use the other input.'),
    findsOneWidget,
  );
  await tapPort('alarmBlocker', output: false, input: 1);
  final redo = find.byKey(const ValueKey('signal-redo'));
  expect(tester.widget<IconButton>(redo).onPressed, isNull);
  expectGoal('alarmBlocker', '330/25–35', 'Too strong');
  expect((await currentSave()).alarmFailed, isTrue);
  await pressHistory('Undo');
  expect((await currentSave()).alarmFailed, isFalse);

  await tapPart('beacon');
  await tapPart('fourWay');
  await tapPart('fourWay');
  await tapPart('terminal');
  expectGoal('terminal', '75/45–60', 'Too strong');
  await tapPart('beacon');
  await pressIcon('Disconnect Beacon → 4-way splitter');

  await tapPart('threeWay');
  await tapPart('fourWay');
  expect(
    find.text('Needs 5.26 length units. Output reaches 4.'),
    findsOneWidget,
  );

  final initialBeacon = (await currentSave()).positions['beacon'];
  await dragPart('beacon', 2.5, 2.5);
  expect((await currentSave()).positions['beacon'], initialBeacon);
  await dragPart('fourWay', .5, 6.5);
  expect(find.text('Dashed cables are out of reach.'), findsOneWidget);
  await dragPart('fourWay', 2.5, 4.5);
  await dragPart('attenuator', 2.5, 6.5);

  await tapPart('beacon');
  await tapPart('threeWay');
  await tapPart('threeWay');
  await tapPart('twoWay');
  await tapPart('twoWay');
  await tapPart('terminal');
  await tapPort('threeWay', output: true, port: 1);
  await tapPort('recorder', output: false);

  expectGoal('terminal', '50/45–60', 'Online');
  expectGoal('recorder', '100/90–110', 'Online');
  expect((await currentSave()).solved, isFalse);
  expectGoal('alarmBlocker', '30/25–35', 'Holding on Pilot');
  await tapPort('threeWay', output: true, port: 2);
  await tapPort('fourWay', output: false);
  expect((await currentSave()).alarmFailed, isFalse);

  final padPosition = (await currentSave()).positions['attenuator'];
  await flip('attenuator');
  expect((await currentSave()).flipped, {'attenuator'});
  expect((await currentSave()).positions['attenuator'], padPosition);
  await pressHistory('Undo');
  expect((await currentSave()).flipped, isEmpty);
  await pressHistory('Redo');
  expect((await currentSave()).flipped, {'attenuator'});

  await tapPort('fourWay', output: true, port: 2);
  await tapPort('attenuator', output: false);
  await tapPort('attenuator', output: true);
  await tapPort('alarmBlocker', output: false, input: 1);
  expectGoal('alarmBlocker', '35/25–35', 'Holding on Pilot and Beacon');
  expect((await currentSave()).alarmFailed, isFalse);

  await tapPart('attenuator');
  final unsafe = find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == '0 u loss',
  );
  expect(tester.widget<IconButton>(unsafe).onPressed, isNull);
  final lossButtons = find.byWidgetPredicate(
    (widget) =>
        widget is IconButton && (widget.tooltip?.endsWith(' u loss') ?? false),
  );
  expect(lossButtons, findsNWidgets(3));
  final lossButtonCenter = tester.getRect(lossButtons.first).center.dy;
  for (var i = 0; i < lossButtons.evaluate().length; i++) {
    expect(tester.getSize(lossButtons.at(i)), consoleButtonSize);
    expect(
      tester.getRect(lossButtons.at(i)).center.dy,
      closeTo(lossButtonCenter, .01),
    );
  }
  expectPanelAlignment();
  final forecast = find.byTooltip('Alarm 55 u');
  expect(forecast, findsOneWidget);
  await tester.ensureVisible(forecast);
  await tester.pumpAndSettle();
  await capture('qa-alarm-controls');
  await tester.tapAt(boardPoint(3, 6));
  await tester.pumpAndSettle();
  await setLoss('pilot', 10, '25');
  await setLoss('attenuator', 10, '35');
  await setLoss('pilot', 20, '25');
  await setLoss('attenuator', 0, '35');
  expect((await currentSave()).solved, isFalse);
  expect(find.byType(Slider), findsNothing);

  await tapPart('alarmBlocker');
  await pressIcon('Disconnect Pilot → Alarm blocker A');
  expectGoal('alarmBlocker', '25/25–35', 'Holding on Beacon');
  expect(complete, findsNothing);

  await tapPort('pilot', output: true);
  await tapPort('service', output: false);
  expectGoal('service', '10/30', 'Too weak');
  expect(complete, findsNothing);
  expect(advance, findsNothing);
  await tapPart('pilot');
  await pressIcon('0 u loss');
  expectGoal('service', '30/30', 'Online');
  expect(complete, findsOneWidget);
  expect(find.byTooltip('0 u loss'), findsNothing);
  expectAdvanceVisible('Finish tutorial');
  await pressIcon('Parts guide');
  expect(find.text('4-way splitter'), findsOneWidget);
  await press('Close');
  expect(find.descendant(of: hud, matching: complete), findsNothing);

  final solved = await currentSave();
  expectGoal('alarmBlocker', '25/25–35', 'Holding on Beacon');
  expect(solved.losses, {'pilot': 0, 'attenuator': 0});
  expect(solved.flipped, {'attenuator'});
  expect(solved.links.where((link) => link.to == 'alarmBlocker'), [
    (from: 'attenuator', to: 'alarmBlocker', input: 1, output: 0),
  ]);
  expect(solved.alarmFailed, isFalse);
  expect(solved.solved, isTrue);
  final wiring = tester
      .widgetList<CustomPaint>(
        find.descendant(of: signalBoard, matching: find.byType(CustomPaint)),
      )
      .map((paint) => paint.painter)
      .whereType<SignalWiring>()
      .single;
  expect(wiring.routes.expand((route) => route.overpasses), isEmpty);
  expect(solved.links.where((link) => link.from == 'pilot'), [
    (from: 'pilot', to: 'service', input: 0, output: 0),
  ]);
  await tester.ensureVisible(hud);
  await tester.pumpAndSettle();
  await capture('qa-test-line-solved');
  final titleBlock = find.byType(DraftingTitleBlock);
  final titleBounds = tester.getRect(titleBlock);
  await tester.drag(readings, const Offset(0, -240));
  await tester.pumpAndSettle();
  expectAdvanceVisible('Finish tutorial');
  expect(tester.getRect(signalBoard), boardBounds);
  expect(tester.getRect(titleBlock), titleBounds);

  await tester.ensureVisible(signalBoard);
  await tester.pumpAndSettle();
  final drag = await tester.startGesture(tester.getCenter(part('beacon')));
  await drag.moveTo(boardPoint(1.08, 1.06));
  await tester.pump();
  expect(marks, findsOneWidget);
  expect(
    (tester.getCenter(part('beacon')) - boardPoint(1, 1)).distance,
    lessThan(1),
  );
  expect((await currentSave()).positions, solved.positions);
  await drag.cancel();
  await tester.pumpAndSettle();
  expect(marks, findsNothing);
  expect((await currentSave()).positions, solved.positions);
  expectGoal('recorder', '100/90–110', 'Online');

  await dragPart('recorder', 5.5, 5.5);
  expect(find.text('Dashed cables are out of reach.'), findsOneWidget);
  expect((await currentSave()).links, solved.links);
  expectGoal('recorder', '0/90–110', 'No signal');
  expect((await currentSave()).solved, isFalse);
  expect(advance, findsNothing);
  await pressHistory('Undo');
  expectGoal('recorder', '100/90–110', 'Online');
  expect((await currentSave()).positions, solved.positions);
  await tap(advance);
  expect(find.text('ALL SHEETS APPROVED'), findsOneWidget);
  await capture('qa-tutorial-complete');
  await relaunch();
  await press('Continue game');
  expect(find.text('ALL SHEETS APPROVED'), findsOneWidget);
  await open(testLine);
  expectGoal('recorder', '0/90–110', 'No signal');
  expect((await currentSave()).solved, isTrue);
  await dragPart('beacon', 1, 1);
  expect((await currentSave()).positions, solved.positions);
}

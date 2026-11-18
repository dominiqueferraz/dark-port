import 'package:dark_port/drafting_theme.dart';
import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/optical_deck.dart';
import 'package:dark_port/puzzle_console.dart';
import 'package:dark_port/tutorial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_silent_game.dart';
import 'support/puzzle_announcement.dart';
import 'support/memory_store.dart';

void main() {
  testWidgets('a failed New game save can retry the intended transition', (
    tester,
  ) async {
    final store = MemoryStore()..failNextWrite = true;
    await pumpSilentGame(tester, store);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('New game'));
    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    expect(
      find.text('Progress could not be saved on this device.'),
      findsOneWidget,
    );
    expect(store.data, isNull);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('TUTORIAL'), findsOneWidget);
    expect(store.data!['completed'], isEmpty);
  });

  testWidgets(
    'the optics track gates progress, resumes drafts and replays independently',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Future<void> tapText(String text) async {
        final target = find.text(text);
        await tester.ensureVisible(target);
        await tester.tap(target);
      }

      final store = MemoryStore();
      await pumpSilentGame(tester, store);
      await tester.pumpAndSettle();
      expect(find.text('Continue game'), findsNothing);
      await tapText('New game');
      await tester.pumpAndSettle();
      expect(find.text('TUTORIAL'), findsOneWidget);
      Finder row(TutorialLesson lesson) =>
          find.byKey(ValueKey('lesson-${lesson.id}'));
      expect(
        tester.widget<InkWell>(row(firstReflection)).onTap != null,
        isTrue,
      );
      expect(tester.widget<InkWell>(row(dividedBeam)).onTap != null, isFalse);
      await tester.tap(row(dividedBeam));
      await tester.pumpAndSettle();
      expect(find.byType(OpticalDeck), findsNothing);
      await tester.tap(row(firstReflection));
      await tester.pumpAndSettle();
      expect(find.text(firstReflection.goal).hitTestable(), findsOneWidget);
      final guide = find.byKey(const ValueKey('lesson-guide'));
      final frame = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is DraftingSheetFrame,
      );
      expect(tester.getRect(frame).overlaps(tester.getRect(guide)), isTrue);
      expect(find.byKey(const ValueKey('puzzle-objective')), findsOneWidget);
      await tapText('Start lesson');
      await tester.pumpAndSettle();
      expect(
        tester.widget<PuzzleConsole>(find.byType(PuzzleConsole)).brief.title,
        firstReflection.title,
      );

      final deck = find.byKey(const ValueKey('optical-deck'));
      OpticalDeck board() =>
          tester.widget<OpticalDeck>(find.byType(OpticalDeck));
      Offset at(FloorPoint p) =>
          tester.getTopLeft(deck) + board().geometry.project(p);
      Optic optic(String id) => board().layout.singleWhere((o) => o.id == id);
      Future<void> rotate(String id) async {
        await tester.tapAt(at(optic(id).position));
        await tester.pump();
      }

      Future<void> move(String id, FloorPoint to) async {
        final from = at(optic(id).position);
        // Short hops on the narrow layout fall inside touch slop, so
        // overshoot first to make the gesture a drag, then settle on target.
        final drag = await tester.startGesture(from);
        await drag.moveTo(from + const Offset(0, 40));
        await drag.moveTo(at(to));
        await drag.up();
        await tester.pump();
      }

      expect(find.text('Rotate'), findsNothing);
      expect(find.text('Test Beam'), findsNothing);
      await rotate('M0');
      expect(optic('M0').turned, isFalse);
      await rotate('M1');
      expect(optic('M1').turned, isFalse);
      const target = FloorPoint(1.05, -.27);
      final start = at(optic('M1').position);
      final finish = at(target);
      final drag = await tester.startGesture(start);
      await drag.moveTo(Offset.lerp(start, finish, .5)!);
      await drag.moveTo(finish);
      await tester.pump();
      expect(board().trace.solves(reflectionLesson), isTrue);
      expect(board().opened, isFalse);
      expect(find.text('Next lesson'), findsNothing);
      expect(find.byKey(const ValueKey('lesson-complete')), findsNothing);
      await drag.cancel();
      await tester.pump();
      expect(board().trace.solves(reflectionLesson), isFalse);

      await move('M1', target);
      expect(optic('M1').turned, isFalse);
      expect(board().opened, isTrue);
      expect(find.byKey(const ValueKey('lesson-complete')), findsOneWidget);
      expect(puzzleAnnouncement, findsNothing);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(board().opened, isFalse);
      expect(find.byKey(const ValueKey('lesson-complete')), findsNothing);
      await tester.tap(find.byTooltip('Redo'));
      await tester.pump();
      expect(board().opened, isTrue);
      expect(puzzleAnnouncement, findsNothing);

      await tester.tap(find.byTooltip('Back to tutorial'));
      await tester.pumpAndSettle();
      expect(find.text('1 OF 8 APPROVED'), findsOneWidget);
      expect(tester.widget<InkWell>(row(dividedBeam)).onTap != null, isTrue);

      await tester.tap(row(firstReflection));
      await tester.pumpAndSettle();
      expect(board().opened, isFalse);
      expect(optic('M1').turned, isTrue);
      await rotate('M1');
      await tester.tap(find.byTooltip('Back to tutorial'));
      await tester.pumpAndSettle();
      expect((await store.load())!.boards[firstReflection.id]!.solved, isTrue);

      await tester.tap(row(dividedBeam));
      await tester.pumpAndSettle();
      await tapText('Start lesson');
      await tester.pumpAndSettle();
      await rotate('S1');
      await tester.tap(find.byTooltip('Back to tutorial'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Return to title'));
      await tester.pumpAndSettle();
      expect(find.text('Continue game'), findsOneWidget);
      await tapText('New game');
      await tester.pumpAndSettle();
      expect(find.text('Start a new tutorial?'), findsOneWidget);
      await tapText('Keep playing');
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpSilentGame(tester, store);
      await tester.pumpAndSettle();
      await tapText('Continue game');
      await tester.pumpAndSettle();
      await tester.tap(row(dividedBeam));
      await tester.pumpAndSettle();
      expect(optic('S1').turned, isTrue);
      await rotate('S1');

      expect(
        tester.widget<PuzzleConsole>(find.byType(PuzzleConsole)).brief.title,
        dividedBeam.title,
      );
      await move('S1', const FloorPoint(-3.15, -.27));
      expect(board().trace.solves(splittingLesson), isTrue);
      expect(find.byKey(const ValueKey('lesson-complete')), findsOneWidget);
      expect(puzzleAnnouncement, findsNothing);
      await tester.ensureVisible(find.text('Next lesson'));
      await tester.tap(find.text('Next lesson'));
      await tester.pumpAndSettle();
      await tapText('Start lesson');
      await tester.pumpAndSettle();

      expect(
        tester.widget<PuzzleConsole>(find.byType(PuzzleConsole)).brief.title,
        opticalInterlock.title,
      );
      expect(board().trace.lit, {0});
      expect(find.text('Next lesson'), findsNothing);
      const alarmLine = FloorPoint(-3.15, .78);
      final mirrorStart = at(optic('M2').position);
      final alarmTarget = at(alarmLine);
      final mirrorDrag = await tester.startGesture(mirrorStart);
      await mirrorDrag.moveTo(Offset.lerp(mirrorStart, alarmTarget, .5)!);
      await mirrorDrag.moveTo(alarmTarget);
      await tester.pump();
      expect(
        find.text('This placement would cut power to the alarm.'),
        findsOneWidget,
      );
      await mirrorDrag.cancel();
      await tester.pump();
      expect(board().trace.lit, {0});

      await move('M2', alarmLine);
      expect(board().trace.lit, isEmpty);
      expect(find.text('FAILED'), findsOneWidget);
      expect(puzzleAnnouncement, findsNothing);
      expect(find.textContaining('Alarm line interrupted.'), findsOneWidget);
      expect(find.text('Next lesson'), findsNothing);
      await rotate('M2');
      expect(optic('M2').turned, isTrue);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(board().trace.lit, {0});
      expect(find.text('FAILED'), findsNothing);

      await move('S2', alarmLine);
      await rotate('S2');
      await move('S1', const FloorPoint(-1.05, .78));
      await move('M2', const FloorPoint(3.15, .78));
      await rotate('M2');
      expect(board().trace.lit, {0, 1, 2});
      expect(board().opened, isTrue);
      expect(find.byKey(const ValueKey('lesson-complete')), findsOneWidget);
      expect(puzzleAnnouncement, findsNothing);
      await tester.ensureVisible(find.text('Next lesson'));
      await tester.tap(find.text('Next lesson'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PuzzleConsole>(find.byType(PuzzleConsole)).brief.title,
        patchLead.title,
      );
      expect((await store.load())!.isComplete(opticalInterlock), isTrue);
      expect((await store.load())!.isUnlocked(splitRatings), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}

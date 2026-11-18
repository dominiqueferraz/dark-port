import 'package:dark_port/drafting_theme.dart';
import 'package:dark_port/endless_levels.dart';
import 'package:dark_port/main.dart';
import 'package:dark_port/optical_deck.dart';
import 'package:dark_port/tutorial.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_store.dart';

void main() {
  for (final (orientation, size) in [
    ('landscape', const Size(874, 402)),
    ('portrait', const Size(390, 844)),
  ]) {
    testWidgets(
      'every playable puzzle puts Hint beside the goal in $orientation',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          final font = FontLoader('DINish Condensed')
            ..addFont(
              rootBundle.load('assets/drafting/DINishCondensed-Regular.ttf'),
            );
          await font.load();
        });

        final tutorial = [...requiredLessons, ...practiceLessons.keys];
        final store = MemoryStore();
        await store.write(
          TutorialProgress(
            completed: requiredLessons.map((lesson) => lesson.id).toSet(),
            opened: tutorial.map((lesson) => lesson.id).toSet(),
          ),
        );

        Future<void> tap(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        Future<void> expectGoalRow(TutorialLesson lesson) async {
          final title = find.byType(DraftingTitleBlock);
          final row = find.byKey(const ValueKey('puzzle-objective'));
          final hint = find.byTooltip('Hint');
          final label = find.descendant(of: row, matching: find.text('GOAL'));
          final objective = find.descendant(
            of: row,
            matching: find.text(lesson.objective),
          );
          expect(find.ancestor(of: row, matching: title), findsOneWidget);
          expect(objective, findsOneWidget);
          expect(hint, findsOneWidget);
          expect(find.ancestor(of: hint, matching: row), findsOneWidget);
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          Finder metadataLabel(String text) =>
              find.descendant(of: title, matching: find.text(text));
          expect(
            tester.getTopLeft(metadataLabel('SHEET')),
            within(
              distance: .01,
              from: Offset(
                tester.getTopLeft(metadataLabel('TITLE')).dx,
                tester.getTopLeft(metadataLabel('REV')).dy,
              ),
            ),
          );
          expect(
            tester.getTopLeft(label).dx,
            tester.getTopLeft(metadataLabel('TITLE')).dx,
          );
          expect(
            tester.getTopLeft(label).dy,
            closeTo(tester.getRect(row).top + 2, .01),
          );
          expect(
            tester.getTopLeft(objective).dy,
            greaterThan(tester.getRect(label).bottom),
          );
          expect(tester.getTopLeft(objective).dx, tester.getTopLeft(label).dx);
          expect(hint.hitTestable(), findsOneWidget);
          expect(tester.getSize(hint), const Size.square(36));
          expect(
            tester.getTopLeft(hint).dx,
            greaterThan(tester.getTopLeft(objective).dx),
          );
          expect(
            tester.getRect(row).bottom,
            closeTo(tester.getRect(title).bottom, .01),
          );
          final awards = find.byKey(const ValueKey('blueprint-awards'));
          final deck = find.byType(OpticalDeck);
          if (awards.evaluate().isNotEmpty && deck.evaluate().length == 1) {
            final floor = tester.widget<OpticalDeck>(deck).geometry.floorRect;
            final corner = tester.getTopLeft(deck) + floor.topLeft;
            expect(
              tester.getTopLeft(awards),
              within(distance: .01, from: corner + const Offset(5, 5)),
              reason: lesson.title,
            );
          }
          expect(tester.takeException(), isNull, reason: lesson.title);
        }

        await tester.pumpWidget(DarkPort(store: store));
        await tester.pumpAndSettle();
        await tap(find.text('Continue game'));
        for (final lesson in tutorial) {
          await tap(find.byKey(ValueKey('lesson-${lesson.id}')));
          await expectGoalRow(lesson);
          await tap(find.byTooltip('Back to tutorial'));
        }
        await tap(find.byTooltip('Return to title'));
        await tap(find.text('Endless'));

        for (final group in EndlessGroup.values) {
          await tap(find.byKey(ValueKey('endless-group-${group.number}')));
          for (final level in group.levels) {
            final lesson = level.lesson;
            if (lesson == null) continue;
            await tap(
              find.byKey(ValueKey('endless-${group.sheetNumber(level)}')),
            );
            await expectGoalRow(lesson);
            final optical = find.widgetWithText(
              SegmentedButton<bool>,
              'Optical',
            );
            if (optical.evaluate().isNotEmpty) {
              await tap(
                find.descendant(of: optical, matching: find.text('Optical')),
              );
              await expectGoalRow(lesson);
            }
            await tap(find.byTooltip('Back to puzzles'));
          }
          await tap(find.byTooltip('Back to Endless groups'));
        }
      },
    );
  }
}

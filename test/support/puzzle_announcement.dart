import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final puzzleAnnouncement = find.byKey(const ValueKey('puzzle-announcement'));

Future<void> dismissPuzzleAnnouncement(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(puzzleAnnouncement, findsOneWidget);
  await tester.tap(
    find.descendant(of: puzzleAnnouncement, matching: find.text('Dismiss')),
  );
  await tester.pumpAndSettle();
  expect(puzzleAnnouncement, findsNothing);
}

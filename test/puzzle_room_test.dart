import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/optical_room.dart';
import 'package:dark_port/puzzle_console.dart';
import 'package:dark_port/signal_board_state.dart';
import 'package:dark_port/signal_room.dart';
import 'package:dark_port/wired_boards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'puzzle rooms accept standalone mode controls and emit snapshots',
    (tester) async {
      var leaves = 0;
      final navigation = PuzzleNavigation(
        backLabel: 'Practice menu',
        onBack: () => leaves++,
        advance: (
          label: 'Next practice board',
          icon: Icons.arrow_forward,
          onPressed: () => fail('Neither practice board has been solved.'),
        ),
      );
      List<Optic>? opticalLayout;
      SignalBoardState? signalState;

      for (final (title, room) in [
        (
          'Optical practice',
          OpticalRoom(
            level: reflectionLesson,
            layout: reflectionLesson.initial.toList(),
            brief: const PuzzleBrief(title: 'Optical practice'),
            navigation: navigation,
            onChange: (layout) => opticalLayout = layout,
          ),
        ),
        (
          'Wiring practice',
          SignalRoom(
            boardState: SignalBoardState(patchLeadBoard),
            brief: const PuzzleBrief(title: 'Wiring practice'),
            navigation: navigation,
            onChange: (state) => signalState = state,
          ),
        ),
      ]) {
        await tester.pumpWidget(MaterialApp(home: room));
        await tester.pumpAndSettle();
        final console = tester.widget<PuzzleConsole>(
          find.byType(PuzzleConsole),
        );
        expect(console.brief.title, title);
        expect(
          tester
              .widget<IconButton>(
                find.byWidgetPredicate(
                  (widget) => widget is IconButton && widget.tooltip == 'Hint',
                ),
              )
              .onPressed,
          isNull,
        );

        await tester.tap(find.byTooltip('Reset room'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Practice menu'));
      }

      expect(leaves, 2);
      expect(opticalLayout, reflectionLesson.initial);
      expect(() => opticalLayout!.clear(), throwsUnsupportedError);
      expect(signalState!.board, same(patchLeadBoard));
      expect(signalState!.links, patchLeadBoard.initialLinks);
    },
  );
}

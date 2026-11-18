import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/optical_deck.dart';
import 'package:dark_port/workbench_boards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Workbench endpoints clear the wall and stay on their beam axes', () {
    final level = workbenchSplitAndDim.board;
    final source = level.sources.first;
    final latch = level.receivers[1];
    for (final size in [const Size(300, 240), const Size(540, 340)]) {
      for (final fill in [false, true]) {
        final deck = OpticalDeckGeometry(level, size, fill: fill);
        final laser = deck.source(source);
        expect(laser.dx, closeTo(deck.project(source.foot).dx, 1e-8));
        final laserBack = laser.dy + .32 * deck.endpointSize;
        expect(deck.floorRect.bottom - laserBack, greaterThanOrEqualTo(8.99));

        final straightBack = deck.receiver(0).dy - .22 * deck.endpointSize;
        expect(straightBack - deck.floorRect.top, greaterThanOrEqualTo(8.99));

        final diagonal = deck.receiver(1);
        final along = deck.heading(latch.incoming);
        final offset = diagonal - deck.project(latch.position);
        expect(offset.dx * along.dy - offset.dy * along.dx, closeTo(0, 1e-8));
        final visibleHeight =
            (.22 * along.dy.abs() + .28 * along.dx.abs()) * deck.endpointSize;
        final diagonalBack = diagonal.dy - visibleHeight;
        expect(diagonalBack - deck.floorRect.top, greaterThanOrEqualTo(8.99));
      }
    }
  });

  testWidgets(
    'the unlabeled interlock renders distinct full, half and quarter power',
    (tester) async {
      const level = sealedOpticalBay;
      const size = Size(320, 352);
      final layout = [
        level.initial[0].at(const FloorPoint(-3.15, .78)).rotate(),
        level.initial[1].at(const FloorPoint(-1.05, .78)),
        level.initial[2].at(const FloorPoint(3.15, .78)).rotate(),
      ];
      final trace = traceOptics(level, layout);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox.fromSize(
              size: size,
              child: OpticalDeck(
                geometry: const OpticalDeckGeometry(level, size),
                layout: layout,
                trace: trace,
                held: null,
                dropSpot: null,
                validDrop: false,
                opened: true,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Text), findsNothing);

      final painter = tester
          .widget<CustomPaint>(find.byType(CustomPaint).first)
          .painter!;
      final canvas = TestRecordingCanvas();
      painter.paint(canvas, size);
      final strokes = canvas.invocations
          .map((record) => record.invocation)
          .where((call) => call.memberName == #drawPath)
          .take(trace.segments.length * 2)
          .map((call) => call.positionalArguments.last as Paint)
          .toList();
      Paint core(double strength) =>
          strokes[trace.segments.indexWhere(
                    (beam) => beam.strength == strength,
                  ) *
                  2 +
              1];

      final full = core(1);
      final half = core(.5);
      final quarter = core(.25);
      expect(full.strokeWidth, greaterThan(2 * half.strokeWidth));
      expect(half.strokeWidth, greaterThan(quarter.strokeWidth));
      expect(full.color.a, greaterThan(half.color.a + .4));
      expect(half.color.a, greaterThan(quarter.color.a + .1));
      expect(quarter.strokeWidth, greaterThan(1));
      expect(quarter.color.a, greaterThan(.4));
    },
  );
}

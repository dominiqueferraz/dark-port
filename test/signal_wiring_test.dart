import 'dart:math' as math;
import 'dart:ui' show Paint, PaintingStyle, Rect;

import 'package:dark_port/signal_board.dart';
import 'package:dark_port/signal_wiring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bounds = Rect.fromLTWH(0, 0, 120, 120);

  test('cables fade over the outer half of their reach', () {
    expect(signalCableOpacity(0), 1);
    expect(signalCableOpacity(.5), 1);
    expect(signalCableOpacity(.75), closeTo(.725, 1e-9));
    expect(signalCableOpacity(1), closeTo(.45, 1e-9));
  });

  test(
    'live cable width and glow follow delivered power independently of reach',
    () {
      const link = (
        from: 'attenuator',
        to: 'alarmBlocker',
        input: 1,
        output: 0,
      );
      const route = SignalCablePath(link, [
        Offset(10, 60),
        Offset(110, 60),
      ], []);

      List<Paint> strokes(double strength, double reachUsed) {
        final canvas = TestRecordingCanvas();
        SignalWiring(
          routes: const [route],
          beyondReach: const {},
          opacities: {link: signalCableOpacity(reachUsed)},
          deliveries: {
            if (strength > 0)
              link: (source: 'beacon', channel: 12, strength: strength, hop: 0),
          },
          referenceUnits: 300,
          time: 1,
          selectedOutput: null,
          reach: null,
        ).paint(canvas, bounds.size);
        return canvas.invocations
            .map((record) => record.invocation)
            .where((call) => call.memberName == #drawPath)
            .map((call) => call.positionalArguments.last as Paint)
            .where((paint) => paint.style == PaintingStyle.stroke)
            .toList();
      }

      final weak = strokes(5, .5);
      final strong = strokes(25, .5);
      final far = strokes(25, 1);
      expect(weak.last.strokeWidth, lessThan(strong.last.strokeWidth));
      expect(weak[1].color.a, lessThan(strong[1].color.a));
      expect(far.last.strokeWidth, strong.last.strokeWidth);
      expect(far.last.color.a, lessThan(strong.last.color.a));
      expect(strokes(0, .5), hasLength(1));
    },
  );

  test('the fourth jack is on the output side and follows a flip', () {
    expect(SignalBoard.outputPort(3), const SignalPoint(.37, .15));
    expect(SignalBoard.outputDirection(3), const SignalPoint(1, 0));
    expect(
      SignalBoard.outputPort(3, flipped: true),
      const SignalPoint(-.37, .15),
    );
    expect(
      SignalBoard.outputDirection(3, flipped: true),
      const SignalPoint(-1, 0),
    );
  });

  test('a cable rounds its ends and steers around empty sibling jacks', () {
    const link = (from: 'splitter', to: 'receiver', input: 1, output: 1);
    const from = Offset(41, 46);
    const to = Offset(88, 87.5);
    const emptyOutput = Offset(45, 55);
    const emptyInput = Offset(88, 80);
    final route = layoutSignalCables(
      const {link: (from: from, to: to)},
      const [link],
      bounds: bounds,
      parts: const [
        Rect.fromLTRB(22, 44, 49, 66),
        Rect.fromLTRB(86, 72, 110, 96),
      ],
      lead: 5,
      directions: const {link: (from: Offset(0, -1), to: Offset(-1, 0))},
      jacks: const [emptyOutput, emptyInput],
    ).single;

    expect(route.points.first, from);
    expect(route.points[1].dx, from.dx);
    expect(route.points[1].dy, lessThan(from.dy));
    expect(route.points.last, to);
    expect(route.points[route.points.length - 2].dy, to.dy);
    expect(route.points[route.points.length - 2].dx, lessThan(to.dx));
    final trace = route.path.computeMetrics().single;
    for (var step = 0.0; step <= trace.length; step += .5) {
      final point = trace.getTangentForOffset(step)!.position;
      for (final jack in [emptyOutput, emptyInput]) {
        expect((point - jack).distance, greaterThan(4));
      }
    }
    expect(
      route.points.indexed.skip(1).any((entry) {
        final (index, point) = entry;
        final delta = point - route.points[index - 1];
        return math.min(delta.dx.abs(), delta.dy.abs()) > 0;
      }),
      isTrue,
    );
  });

  test('crossed cables get an overpass away from their ports', () {
    const horizontal = (from: 'a', to: 'b', input: 0, output: 0);
    const vertical = (from: 'c', to: 'd', input: 0, output: 0);
    final routes = layoutSignalCables(
      const {
        horizontal: (from: Offset(10, 50), to: Offset(90, 50)),
        vertical: (from: Offset(45, 20), to: Offset(55, 80)),
      },
      const [horizontal, vertical],
      bounds: bounds,
      parts: const [],
      lead: 5,
    );

    expect(routes[0].overpasses, isEmpty);
    expect(routes[1].overpasses, hasLength(1));
    expect(routes[1].overpasses.single.dy, closeTo(50, 1e-9));
  });

  test('overlapping cables use separate paths after a shared output', () {
    const near = (from: 'a', to: 'b', input: 0, output: 0);
    const far = (from: 'a', to: 'd', input: 0, output: 0);
    final routes = layoutSignalCables(
      const {
        near: (from: Offset(10, 20), to: Offset(80, 20)),
        far: (from: Offset(10, 20), to: Offset(110, 20)),
      },
      const [near, far],
      bounds: bounds,
      parts: const [],
      lead: 6,
    );

    expect(routes[0].points, [const Offset(10, 20), const Offset(80, 20)]);
    expect(routes[1].points.first, const Offset(10, 20));
    expect(routes[1].points.last, const Offset(110, 20));
    expect(routes[1].points.any((point) => point.dy != 20), isTrue);
    expect(routes[1].overpasses, isEmpty);
  });

  test('two alarm feeds route around each other near the input ports', () {
    const pilot = (from: 'pilot', to: 'blocker', input: 0, output: 0);
    const beacon = (from: 'splitter', to: 'blocker', input: 1, output: 0);
    final routes = layoutSignalCables(
      const {
        pilot: (from: Offset(17.4, 110), to: Offset(22.6, 110)),
        beacon: (from: Offset(97.4, 70), to: Offset(22.6, 113)),
      },
      const [pilot, beacon],
      bounds: bounds,
      parts: const [
        Rect.fromLTRB(1.2, 101.2, 18.8, 118.8),
        Rect.fromLTRB(21.2, 101.2, 38.8, 118.8),
        Rect.fromLTRB(81.2, 61.2, 98.8, 78.8),
      ],
      lead: 1.6,
    );

    expect(routes.last.overpasses, isEmpty);
    expect(routes.last.points.last, const Offset(22.6, 113));
  });

  test(
    'a top port exits upward and a mirrored input enters from the right',
    () {
      const link = (from: 'splitter', to: 'pad', input: 0, output: 1);
      const from = Offset(38, 50);
      const to = Offset(94, 72);
      final route = layoutSignalCables(
        const {link: (from: from, to: to)},
        const [link],
        bounds: bounds,
        parts: const [
          Rect.fromLTRB(22, 50, 42, 70),
          Rect.fromLTRB(74, 62, 95, 82),
        ],
        lead: 5,
        directions: const {link: (from: Offset(0, -1), to: Offset(1, 0))},
      ).single.points;

      expect(route.first, from);
      expect(route[1].dx, from.dx);
      expect(route[1].dy, lessThan(from.dy));
      expect(route.last, to);
      expect(route[route.length - 2].dx, greaterThan(to.dx));
      expect(route[route.length - 2].dy, to.dy);
    },
  );

  test(
    'a backward cable leaves the output right and enters the input left',
    () {
      const link = (from: 'a', to: 'b', input: 0, output: 0);
      const from = Offset(94, 60);
      const to = Offset(26, 60);
      final route = layoutSignalCables(
        const {link: (from: from, to: to)},
        const [link],
        bounds: bounds,
        parts: const [
          Rect.fromLTRB(66, 50, 95, 75),
          Rect.fromLTRB(25, 50, 54, 75),
        ],
        lead: 6,
      ).single.points;

      expect(route.first, from);
      expect(route.last, to);
      expect(route[1].dx, greaterThan(from.dx));
      expect(route[1].dy, from.dy);
      expect(route[route.length - 2].dx, lessThan(to.dx));
      expect(route[route.length - 2].dy, to.dy);
      expect(route.any((point) => point.dy != from.dy), isTrue);
    },
  );
}

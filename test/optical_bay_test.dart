import 'package:dark_port/optical_bay.dart';
import 'package:flutter_test/flutter_test.dart';

List<Optic> interlockRoute(double row) => [
  sealedOpticalBay.initial[0].at(FloorPoint(-3.15, row)).rotate(),
  sealedOpticalBay.initial[1].at(FloorPoint(-1.05, row)),
  sealedOpticalBay.initial[2].at(FloorPoint(3.15, row)).rotate(),
];

void main() {
  test('each tutorial lesson requires its optical rule', () {
    for (final level in [reflectionLesson, splittingLesson, sealedOpticalBay]) {
      expect(traceOptics(level, level.initial).solves(level), isFalse);
    }

    final reflection = [
      reflectionLesson.initial.first,
      reflectionLesson.initial.last.at(const FloorPoint(1.05, -.27)).rotate(),
    ];
    final reflected = traceOptics(reflectionLesson, reflection);
    expect(reflected.solves(reflectionLesson), isTrue);
    expect(reflected.crossings, isEmpty);
    expect(reflected.receivedPower(0), 1);
    final splitting = [
      splittingLesson.initial.first.at(const FloorPoint(-3.15, -.27)),
      splittingLesson.initial.last,
    ];
    final split = traceOptics(splittingLesson, splitting);
    expect(split.solves(splittingLesson), isTrue);
    expect(split.crossings, isEmpty);
    expect(split.receivedPower(0), .5);
    expect(split.receivedPower(1), .5);
    final route = interlockRoute(.78);
    for (final optic in route) {
      expect(sealedOpticalBay.canPlace(optic, route), isTrue);
    }
    final trace = traceOptics(sealedOpticalBay, route);
    expect(trace.lit, {0, 1, 2});
    expect(trace.crossings, isEmpty);
    expect(trace.solves(sealedOpticalBay), isTrue);
  });

  test('interlock requires a live alarm and both latches', () {
    const level = sealedOpticalBay;
    final initial = traceOptics(level, level.initial);
    expect(initial.lit, {0});
    expect(initial.interruptsAlarm(level), isFalse);
    expect(initial.solves(level), isFalse);

    final blocked = traceOptics(level, interlockRoute(-2.37));
    expect(blocked.lit, {0, 2});
    expect(blocked.solves(level), isFalse);

    final route = interlockRoute(.78);
    final latchesOnly = traceOptics(level, [
      route[0].at(route[2].position),
      route[1],
      route[2].at(route[0].position),
    ]);
    expect(latchesOnly.lit, {1, 2});
    expect(latchesOnly.interruptsAlarm(level), isTrue);
    expect(latchesOnly.solves(level), isFalse);
  });

  test('independent rays cross without connecting', () {
    const level = sealedOpticalBay;
    final trace = traceOptics(level, [
      level.initial.first.at(const FloorPoint(-3.15, -2.37)).rotate(),
      const Optic('M2', OpticKind.mirror, FloorPoint(3.15, -2.37)),
      const Optic('M3', OpticKind.mirror, FloorPoint(3.15, 1.83), turned: true),
    ]);
    final crossing = trace.crossings.single;
    expect(crossing.point.x, closeTo(-3.15, 1e-8));
    expect(crossing.point.y, closeTo(1.83, 1e-8));
    expect(trace.segments[crossing.index].fromOptic, 'M3');
    expect(trace.lit, {0});
    expect(trace.receivedPower(0), .5);
  });

  test(
    'snapping and placement reject fixed parts, baffles and occupied spots',
    () {
      const level = sealedOpticalBay;
      final spot = level.snapAt(const FloorPoint(-3.12, -2.30))!;
      expect(spot.intersection, isTrue);
      expect(
        spot.position.distanceTo(const FloorPoint(-3.15, -2.37)),
        lessThan(1e-8),
      );
      expect(
        reflectionLesson.canPlace(
          reflectionLesson.initial.first,
          reflectionLesson.initial,
        ),
        isFalse,
      );
      for (final position in [
        const FloorPoint(-1.05, -.27),
        level.laserFoot,
        const FloorPoint(6.6, 0),
        level.initial.last.position,
      ]) {
        expect(
          level.canPlace(level.initial.first.at(position), level.initial),
          isFalse,
        );
      }
    },
  );
}

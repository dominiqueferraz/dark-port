import 'dart:math' as math;

import 'package:dark_port/optical_bay.dart';
import 'package:flutter_test/flutter_test.dart';

List<Optic> interlockRoute(double row) => [
  sealedOpticalBay.initial[0].at(FloorPoint(-3.15, row)).rotate(),
  sealedOpticalBay.initial[1].at(FloorPoint(-1.05, row)),
  sealedOpticalBay.initial[2].at(FloorPoint(3.15, row)).rotate(),
];

OpticalLevel _straightBeam({
  List<OpticalReceiver> intervening = const [],
  List<math.Rectangle<double>> blocks = const [],
  List<OpticalBarrier> barriers = const [],
  List<OpticalSource> sources = const [],
  List<OpticalAntenna> antennas = const [],
  double height = 0,
}) => OpticalLevel(
  title: 'Clear sightline',
  floor: const math.Rectangle<double>(0, -2, 8, 4),
  laser: FloorPoint(1, height),
  laserFoot: FloorPoint(.5, height),
  direction: BeamDirection.east,
  receivers: [
    ...intervening,
    const OpticalReceiver('Target', FloorPoint(6, 0), BeamDirection.east),
  ],
  goal: {intervening.length},
  initial: const [],
  additionalSources: sources,
  antennas: antennas,
  blocks: blocks,
  barriers: barriers,
);

void _expectStopped(OpticalTrace trace, double x, {int source = 0}) {
  final beam = trace.segments.singleWhere(
    (segment) => segment.source == source,
  );
  expect(beam.blocked, isTrue);
  expect(beam.to.x, closeTo(x, 1e-8));
  expect(beam.receiver, isNull);
  expect(beam.toOptic, isNull);
}

void main() {
  test(
    'a receiver needs the marked approach and a direct hit on its aperture',
    () {
      final clear = _straightBeam(height: .25);
      final direct = traceOptics(clear, []);
      expect(direct.solves(clear), isTrue);
      expect(direct.segments.single.to, const FloorPoint(6, .25));
      expect(direct.segments.single.blocked, isFalse);
      final missed = _straightBeam(height: .40);
      expect(traceOptics(missed, []).solves(missed), isFalse);

      for (final (approach, contact) in [
        (BeamDirection.north, 2.66),
        (BeamDirection.west, 2.78),
      ]) {
        final board = _straightBeam(
          intervening: [
            OpticalReceiver('Shielded input', const FloorPoint(3, 0), approach),
          ],
        );
        final trace = traceOptics(board, []);
        _expectStopped(trace, contact);
        expect(trace.lit, isEmpty);
      }

      final nearest = _straightBeam(
        intervening: const [
          OpticalReceiver('First input', FloorPoint(3, 0), BeamDirection.east),
        ],
      );
      expect(traceOptics(nearest, []).lit, {0});
    },
  );

  test('only a directly fed converter can consume light and emit radio', () {
    final board = _straightBeam();
    Optic port(BeamDirection incoming) => Optic(
      'C1',
      OpticKind.converter,
      const FloorPoint(3, 0),
      converter: OpticalConverter(
        channel: 12,
        reach: 4,
        lanes: {
          const FloorPoint(3, 0): (
            incoming: incoming,
            outgoing: BeamDirection.north,
          ),
        },
      ),
    );
    final rejected = traceOptics(board, [port(BeamDirection.north)]);
    _expectStopped(rejected, 2.66);
    expect(rejected.converterInputs['C1']!.status, ConverterReception.quiet);
    expect(rejected.radioHops, isEmpty);
    expect(rejected.lit, isEmpty);

    final accepted = traceOptics(board, [port(BeamDirection.east)]);
    expect(accepted.segments.single.toOptic, 'C1');
    expect(accepted.converterInputs['C1']!.power, 100);
    expect(accepted.radioHops.single.emitted, 100);
    expect(accepted.lit, isEmpty);
  });

  test('the nearest housing or wall ends the beam before the target', () {
    const at = FloorPoint(3, .30);
    final board = _straightBeam();
    for (final kind in [OpticKind.mirror, OpticKind.splitter]) {
      final grazed = traceOptics(board, [Optic('Optic', kind, at)]);
      expect(grazed.segments.single.to.x, lessThan(at.x));
      expect(grazed.segments.single.blocked, isTrue);
      expect(grazed.lit, isEmpty);

      final clear = traceOptics(board, [
        Optic('Optic', kind, const FloorPoint(3, .40)),
      ]);
      expect(clear.solves(board), isTrue);
    }
    final antenna = _straightBeam(
      antennas: const [
        OpticalAntenna('Antenna', FloorPoint(3, 0), channel: 12, minimum: 5),
      ],
    );
    _expectStopped(traceOptics(antenna, []), 2.76);
    final laser = _straightBeam(
      sources: const [
        OpticalSource(
          'Second laser',
          FloorPoint(3, .15),
          FloorPoint(3, -.35),
          BeamDirection.north,
        ),
      ],
    );
    final trace = traceOptics(laser, []);
    _expectStopped(trace, 2.76);
    expect(trace.lit, isEmpty);
    for (final material in BarrierMaterial.values) {
      final wall = _straightBeam(
        barriers: [
          (
            bounds: const math.Rectangle<double>(4, -.25, .2, .5),
            material: material,
          ),
        ],
      );
      _expectStopped(traceOptics(wall, []), 4);
    }

    final coveredInput = _straightBeam(
      blocks: const [math.Rectangle<double>(6, -.25, .2, .5)],
    );
    final covered = traceOptics(coveredInput, []);
    _expectStopped(covered, 6);
    expect(covered.solves(coveredInput), isFalse);
  });

  test('a source inside a baffle cannot light a target', () {
    final blocked = _straightBeam(
      blocks: const [math.Rectangle<double>(.9, -.25, .2, .5)],
    );
    expect(traceOptics(blocked, []).segments, isEmpty);
    expect(traceOptics(blocked, []).solves(blocked), isFalse);
  });

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

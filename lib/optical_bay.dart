import 'dart:math' as math;

import 'placement_nodes.dart';

typedef FloorPoint = math.Point<double>;

enum BeamDirection {
  north(0, 1),
  east(1, 0),
  south(0, -1),
  west(-1, 0);

  const BeamDirection(this.x, this.y);
  final double x;
  final double y;

  BeamDirection reflected(bool turned) => switch (this) {
    north => turned ? west : east,
    east => turned ? south : north,
    south => turned ? east : west,
    west => turned ? north : south,
  };
}

enum OpticKind {
  splitter('Splitter'),
  mirror('Mirror');

  const OpticKind(this.label);
  final String label;
}

class Optic {
  const Optic(
    this.id,
    this.kind,
    this.position, {
    this.turned = false,
    this.fixed = false,
  });

  final String id;
  final OpticKind kind;
  final FloorPoint position;
  final bool turned;
  final bool fixed;

  Optic at(FloorPoint position) =>
      Optic(id, kind, position, turned: turned, fixed: fixed);
  Optic rotate() => Optic(id, kind, position, turned: !turned, fixed: fixed);
}

class OpticalReceiver {
  const OpticalReceiver(
    this.label,
    this.position,
    this.incoming, {
    this.requiredPower,
  });

  final String label;
  final FloorPoint position;
  final BeamDirection incoming;
  final double? requiredPower;
}

typedef GridSpot = PlacementNode;

const bayTileSize = 1.05;
const _gridOrigin = FloorPoint(-6.3, -4.47);
final _gridSpots = buildPlacementNodes(
  origin: _gridOrigin,
  tileSize: bayTileSize,
  columns: 12,
  rows: 8,
);

class OpticalLevel {
  const OpticalLevel({
    required this.title,
    required this.laser,
    required this.laserFoot,
    required this.direction,
    required this.receivers,
    required this.goal,
    required this.initial,
    required this.floor,
    this.alarms = const {},
    this.dark = const {},
    this.blocks = const [],
    this.mounts = const {},
  });

  final String title;
  final FloorPoint laser;
  final FloorPoint laserFoot;
  final BeamDirection direction;
  final List<OpticalReceiver> receivers;
  final Set<int> goal;

  /// Receivers that must stay powered until the level is solved.
  final Set<int> alarms;
  final Set<int> dark;
  final List<math.Rectangle<double>> blocks;
  final List<Optic> initial;
  final math.Rectangle<double> floor;
  final Map<String, List<GridSpot>> mounts;

  static const opticRadius = .34;

  Iterable<GridSpot> get placementSpots => mounts.isEmpty
      ? _gridSpots.where((spot) => _onDeck(spot.position))
      : mounts.values.expand((spots) => spots).toSet();

  bool canMove(Optic optic) => !optic.fixed && mounts[optic.id]?.length != 1;

  bool _onDeck(FloorPoint p) =>
      p.x >= floor.left + opticRadius &&
      p.x <= floor.right - opticRadius &&
      p.y >= floor.top + opticRadius &&
      p.y <= floor.bottom - opticRadius;

  GridSpot? snapAt(FloorPoint p, {String? id}) {
    if (!floor.containsPoint(p)) return null;
    return nearestPlacementNode(p, mounts[id] ?? placementSpots);
  }

  bool canPlace(Optic optic, List<Optic> layout) {
    final p = optic.position;
    final spot = snapAt(p, id: optic.id);
    return !optic.fixed &&
        _onDeck(p) &&
        spot != null &&
        blocks.every(
          (block) => !math.Rectangle<double>(
            block.left - opticRadius,
            block.top - opticRadius,
            block.width + opticRadius * 2,
            block.height + opticRadius * 2,
          ).containsPoint(p),
        ) &&
        p.distanceTo(spot.position) < 1e-8 &&
        p.distanceTo(laserFoot) >= .77 &&
        layout.every(
          (other) =>
              other.id == optic.id ||
              p.distanceTo(other.position) >= opticRadius * 2,
        );
  }
}

// Twelve tiles wide so the bay fills a landscape drawing sheet.
const _floor = math.Rectangle<double>(-6.3, -4.47, 12.6, 7.647);

const reflectionLesson = OpticalLevel(
  title: 'First reflection',
  laser: FloorPoint(-3.15, -3.126),
  laserFoot: FloorPoint(-3.15, -3.65),
  direction: BeamDirection.north,
  receivers: [
    OpticalReceiver('Latch', FloorPoint(1.05, 3.177), BeamDirection.north),
  ],
  goal: {0},
  initial: [
    Optic('M0', OpticKind.mirror, FloorPoint(-3.15, -.27), fixed: true),
    Optic('M1', OpticKind.mirror, FloorPoint(2.625, -1.845), turned: true),
  ],
  floor: _floor,
);

const splittingLesson = OpticalLevel(
  title: 'A divided beam',
  laser: FloorPoint(-3.15, -3.126),
  laserFoot: FloorPoint(-3.15, -3.65),
  direction: BeamDirection.north,
  receivers: [
    OpticalReceiver('Latch I', FloorPoint(-3.15, 3.177), BeamDirection.north),
    OpticalReceiver('Latch II', FloorPoint(1.05, 3.177), BeamDirection.north),
  ],
  goal: {0, 1},
  initial: [
    Optic('S1', OpticKind.splitter, FloorPoint(-1.575, -1.845)),
    Optic('M0', OpticKind.mirror, FloorPoint(1.05, -.27), fixed: true),
  ],
  floor: _floor,
);

const sealedOpticalBay = OpticalLevel(
  title: 'The interlock',
  laser: FloorPoint(-3.15, -3.126),
  laserFoot: FloorPoint(-3.15, -3.65),
  direction: BeamDirection.north,
  receivers: [
    OpticalReceiver('Alarm', FloorPoint(-3.15, 3.177), BeamDirection.north),
    OpticalReceiver('Latch I', FloorPoint(-1.05, 3.177), BeamDirection.north),
    OpticalReceiver('Latch II', FloorPoint(3.15, 3.177), BeamDirection.north),
  ],
  goal: {1, 2},
  alarms: {0},
  blocks: [math.Rectangle<double>(-1.65, -.42, 3.75, .30)],
  initial: [
    Optic('S2', OpticKind.splitter, FloorPoint(-1.575, -2.895), turned: true),
    Optic('S1', OpticKind.splitter, FloorPoint(-.525, 1.305)),
    Optic('M2', OpticKind.mirror, FloorPoint(2.625, -1.845), turned: true),
  ],
  floor: _floor,
);

typedef BeamSegment = ({
  FloorPoint from,
  FloorPoint to,
  double strength,
  int? receiver,
  String? fromOptic,
  String? toOptic,
});

class OpticalTrace {
  OpticalTrace(List<BeamSegment> segments, Set<int> lit)
    : segments = List.unmodifiable(segments),
      lit = Set.unmodifiable(lit);

  final List<BeamSegment> segments;
  final Set<int> lit;

  double receivedPower(int receiver) => segments
      .where((beam) => beam.receiver == receiver)
      .fold(0.0, (power, beam) => power + beam.strength);

  Iterable<({int index, FloorPoint point})> get crossings sync* {
    for (final (index, beam) in segments.indexed) {
      final horizontal = beam.from.y == beam.to.y;
      for (final other in segments.take(index)) {
        if (horizontal == (other.from.y == other.to.y)) continue;
        final across = horizontal ? beam : other;
        final upright = horizontal ? other : beam;
        final point = FloorPoint(upright.from.x, across.from.y);
        // Endpoints are junctions, so only mark intersections between rays.
        if (_inside(point.x, across.from.x, across.to.x) &&
            _inside(point.y, upright.from.y, upright.to.y)) {
          yield (index: index, point: point);
        }
      }
    }
  }

  bool interruptsAlarm(OpticalLevel level) => !lit.containsAll(level.alarms);

  bool meetsGoal(OpticalLevel level, int receiver) {
    if (level.dark.contains(receiver)) return !lit.contains(receiver);
    final power = level.receivers[receiver].requiredPower;
    return power == null
        ? lit.contains(receiver)
        : (receivedPower(receiver) * 100 - power).abs() < _epsilon;
  }

  bool solves(OpticalLevel level) =>
      !interruptsAlarm(level) &&
      level.goal.every((index) => meetsGoal(level, index)) &&
      lit.intersection(level.dark).isEmpty;
}

typedef _Ray = ({
  FloorPoint from,
  BeamDirection direction,
  double strength,
  String? previous,
});

String lightUnits(double units) =>
    units.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

bool _inside(double value, double a, double b) =>
    value > math.min(a, b) + _epsilon && value < math.max(a, b) - _epsilon;

const _epsilon = .0001;
const _halfOptic = .28;
const _receiverHalfWidth = .34;

// Nearest intersection wins. Both branches leave the actual hit point,
// so a part can catch a beam anywhere along its diagonal aperture.
OpticalTrace traceOptics(OpticalLevel level, List<Optic> layout) {
  final pending = <_Ray>[
    (
      from: level.laser,
      direction: level.direction,
      strength: 1,
      previous: null,
    ),
  ];
  final segments = <BeamSegment>[];
  final lit = <int>{};
  final visited = <(String, BeamDirection, int, int)>{};

  for (var index = 0; index < pending.length && index < 128; index++) {
    final ray = pending[index];
    final direction = ray.direction;
    final origin = ray.from;
    var distance = switch (direction) {
      BeamDirection.north => level.floor.bottom - origin.y,
      BeamDirection.east => level.floor.right - origin.x,
      BeamDirection.south => origin.y - level.floor.top,
      BeamDirection.west => origin.x - level.floor.left,
    };
    Optic? hit;
    int? receiver;

    for (var i = 0; i < level.receivers.length; i++) {
      final sensor = level.receivers[i];
      if (direction != sensor.incoming) continue;
      final offset = sensor.position - origin;
      final along = offset.x * direction.x + offset.y * direction.y;
      final across = offset.x * direction.y - offset.y * direction.x;
      if (along > _epsilon &&
          along <= distance + _epsilon &&
          across.abs() <= _receiverHalfWidth) {
        distance = along;
        receiver = i;
      }
    }

    for (final block in level.blocks) {
      final horizontal = direction.x != 0;
      final across = horizontal ? origin.y : origin.x;
      final low = horizontal ? block.top : block.left;
      final high = horizontal ? block.bottom : block.right;
      if (across < low || across > high) continue;
      final positive = direction.x + direction.y > 0;
      final edge = horizontal
          ? (positive ? block.left : block.right)
          : (positive ? block.top : block.bottom);
      final along =
          (edge - (horizontal ? origin.x : origin.y)) * (positive ? 1 : -1);
      if (along > _epsilon && along <= distance) {
        distance = along;
        receiver = null;
      }
    }

    for (final optic in layout) {
      if (optic.id == ray.previous) continue;
      final offset = optic.position - origin;
      final slope = optic.turned ? -1.0 : 1.0;
      final determinant = direction.x * slope - direction.y;
      final along = (offset.x * slope - offset.y) / determinant;
      final across =
          (offset.x * direction.y - offset.y * direction.x) / determinant;
      if (along > _epsilon && along < distance && across.abs() <= _halfOptic) {
        distance = along;
        hit = optic;
        receiver = null;
      }
    }

    if (distance <= _epsilon) continue;
    final end = FloorPoint(
      origin.x + direction.x * distance,
      origin.y + direction.y * distance,
    );
    segments.add((
      from: origin,
      to: end,
      strength: ray.strength,
      receiver: receiver,
      fromOptic: ray.previous,
      toOptic: hit?.id,
    ));
    if (receiver != null) lit.add(receiver);
    if (hit == null) continue;
    final state = (
      hit.id,
      direction,
      (end.x * 10000).round(),
      (end.y * 10000).round(),
    );
    if (!visited.add(state)) continue;

    final splits = hit.kind == OpticKind.splitter;
    final strength = splits ? ray.strength / 2 : ray.strength;
    pending.add((
      from: end,
      direction: direction.reflected(hit.turned),
      strength: strength,
      previous: hit.id,
    ));
    if (splits) {
      pending.add((
        from: end,
        direction: direction,
        strength: strength,
        previous: hit.id,
      ));
    }
  }
  return OpticalTrace(segments, lit);
}

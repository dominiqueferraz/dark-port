import 'dart:math' as math;

import 'fabrication_socket.dart';
import 'placement_nodes.dart';
import 'radio_propagation.dart';
import 'splitter_blueprint.dart';

typedef FloorPoint = math.Point<double>;

enum BeamDirection {
  north(0, 1),
  northEast(math.sqrt1_2, math.sqrt1_2),
  east(1, 0),
  southEast(math.sqrt1_2, -math.sqrt1_2),
  south(0, -1),
  southWest(-math.sqrt1_2, -math.sqrt1_2),
  west(-1, 0),
  northWest(-math.sqrt1_2, math.sqrt1_2);

  const BeamDirection(this.x, this.y);
  final double x;
  final double y;

  BeamDirection turn(int steps) => values[(index + steps) % values.length];

  BeamDirection reflected(bool turned) =>
      values[((turned ? 6 : 2) - index) % values.length];

  BeamDirection get opposite =>
      values[(index + values.length ~/ 2) % values.length];
}

enum OpticKind {
  splitter('Splitter'),
  mirror('Mirror'),
  workbenchSplitter('Workbench splitter'),
  converter('Optical-to-radio converter');

  const OpticKind(this.label);
  final String label;
}

extension SplitterFacing on SplitterBlueprint {
  BeamDirection get forward => BeamDirection.north.turn(turns * 2);

  BeamDirection inputDirection({bool mirrored = false}) =>
      forward.turn(mirrored ? -inputAim.steps : inputAim.steps);

  BeamDirection outputDirection(SplitterPort port, {bool mirrored = false}) =>
      forward.turn(mirrored ? -port.steps : port.steps);
}

class Optic {
  const Optic(
    this.id,
    this.kind,
    this.position, {
    this.turned = false,
    this.fixed = false,
    this.blueprint,
    this.converter,
  });

  final String id;
  final OpticKind kind;
  final FloorPoint position;
  final bool turned;
  final bool fixed;
  final SplitterBlueprint? blueprint;
  final OpticalConverter? converter;

  FabricationSocket<SplitterBlueprint>? get fabricationSocket =>
      kind == OpticKind.workbenchSplitter ? splitterFabricationSocket : null;

  Optic at(FloorPoint position) => Optic(
    id,
    kind,
    position,
    turned: turned,
    fixed: fixed,
    blueprint: blueprint,
    converter: converter,
  );
  Optic rotate() => Optic(
    id,
    kind,
    position,
    turned: !turned,
    fixed: fixed,
    blueprint: blueprint,
    converter: converter,
  );
  Optic fit(SplitterBlueprint design) => Optic(
    id,
    kind,
    position,
    turned: turned,
    fixed: fixed,
    blueprint: design,
  );
}

class OpticalSource {
  const OpticalSource(this.label, this.position, this.foot, this.direction);

  final String label;
  final FloorPoint position;
  final FloorPoint foot;
  final BeamDirection direction;
}

typedef ConverterLane = ({BeamDirection incoming, BeamDirection outgoing});

class OpticalConverter {
  const OpticalConverter({
    required this.channel,
    required this.reach,
    required this.lanes,
    this.power,
    this.requiredSource,
  });

  final int channel;
  final double reach;
  final double? power;
  final Map<FloorPoint, ConverterLane> lanes;
  final String? requiredSource;
}

class OpticalAntenna {
  const OpticalAntenna(
    this.label,
    this.position, {
    required this.channel,
    required this.minimum,
  });

  final String label;
  final FloorPoint position;
  final int channel;
  final double minimum;
}

enum BarrierMaterial { concrete, mesh }

typedef OpticalBarrier = ({
  math.Rectangle<double> bounds,
  BarrierMaterial material,
});

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
    this.sourceLabel = 'Laser',
    this.additionalSources = const [],
    this.barriers = const [],
    this.antennas = const [],
    this.tileSize = bayTileSize,
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
  final String sourceLabel;
  final List<OpticalSource> additionalSources;
  final List<OpticalBarrier> barriers;
  final List<OpticalAntenna> antennas;
  final double tileSize;

  Iterable<OpticalSource> get sources sync* {
    yield OpticalSource(sourceLabel, laser, laserFoot, direction);
    yield* additionalSources;
  }

  Iterable<math.Rectangle<double>> get lightObstacles sync* {
    yield* blocks;
    for (final barrier in barriers) {
      yield barrier.bounds;
    }
  }

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
        (optic.converter?.lanes.containsKey(p) ?? true) &&
        spot != null &&
        lightObstacles.every(
          (block) => !math.Rectangle<double>(
            block.left - opticRadius,
            block.top - opticRadius,
            block.width + opticRadius * 2,
            block.height + opticRadius * 2,
          ).containsPoint(p),
        ) &&
        p.distanceTo(spot.position) < 1e-8 &&
        sources.every((source) => p.distanceTo(source.foot) >= .77) &&
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
  bool blocked,
  int source,
});

class OpticalTrace {
  OpticalTrace(
    List<BeamSegment> segments,
    Set<int> lit, {
    this.converterInputs = const {},
    this.radioHops = const [],
    this.radioReadings = const [],
    this.fabricatedPartsInstalled = true,
  }) : segments = List.unmodifiable(segments),
       lit = Set.unmodifiable(lit);

  final List<BeamSegment> segments;
  final Set<int> lit;
  final Map<String, ConverterInput> converterInputs;
  final List<OpticalRadioHop> radioHops;
  final List<OpticalRadioReading> radioReadings;
  final bool fabricatedPartsInstalled;

  double receivedPower(int receiver) => segments
      .where((beam) => beam.receiver == receiver)
      .fold(0.0, (power, beam) => power + beam.strength);

  Iterable<({int index, FloorPoint point})> get crossings sync* {
    for (final (index, beam) in segments.indexed) {
      final along = beam.to - beam.from;
      for (final other in segments.take(index)) {
        final across = other.to - other.from;
        final determinant = _cross(along, across);
        if (determinant.abs() < _epsilon) continue;
        final offset = other.from - beam.from;
        final t = _cross(offset, across) / determinant;
        final u = _cross(offset, along) / determinant;
        // Endpoints are junctions, so only mark intersections between rays.
        if (_insideRay(t) && _insideRay(u)) {
          yield (index: index, point: beam.from + along * t);
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
      fabricatedPartsInstalled &&
      !interruptsAlarm(level) &&
      level.goal.every((index) => meetsGoal(level, index)) &&
      lit.intersection(level.dark).isEmpty &&
      radioReadings.length == level.antennas.length &&
      radioReadings.every(
        (reading) => reading.status == RadioReception.accepted,
      );
}

enum ConverterReception {
  quiet('No light at the input'),
  wrongSource('Wrong laser'),
  wrongPower('Input strength does not match'),
  accepted('Transmitting');

  const ConverterReception(this.label);
  final String label;
}

typedef ConverterInput = ({
  double power,
  String? source,
  ConverterReception status,
});

enum RadioReception {
  quiet('No radio signal'),
  outOfRange('Out of coverage'),
  blocked('Blocked by concrete'),
  wrongChannel('Wrong channel'),
  weak('Too weak'),
  accepted('Accepted');

  const RadioReception(this.label);
  final String label;
}

typedef OpticalRadioReading = ({
  double power,
  RadioReception status,
  OpticalRadioHop? hop,
  double? distance,
});

typedef OpticalRadioHop = ({
  String converter,
  String source,
  FloorPoint from,
  FloorPoint to,
  BeamDirection direction,
  double emitted,
  int channel,
  double reach,
  double? blockedDistance,
});

typedef _Ray = ({
  FloorPoint from,
  BeamDirection direction,
  double strength,
  String? previous,
  int source,
});

String lightUnits(double units) =>
    units.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

bool _insideRay(double value) => value > _epsilon && value < 1 - _epsilon;

double _cross(FloorPoint a, FloorPoint b) => a.x * b.y - a.y * b.x;

/// The interval where the ray intersects a slab along one axis.
(double, double) _raySlab(double start, double step, double low, double high) {
  if (step == 0) {
    return start < low || start > high
        ? (double.infinity, double.negativeInfinity)
        : (double.negativeInfinity, double.infinity);
  }
  final a = (low - start) / step;
  final b = (high - start) / step;
  return a <= b ? (a, b) : (b, a);
}

(double, double) _rayBounds(
  FloorPoint origin,
  BeamDirection direction,
  math.Rectangle<double> rect,
) {
  final (xEnter, xExit) = _raySlab(
    origin.x,
    direction.x,
    rect.left,
    rect.right,
  );
  final (yEnter, yExit) = _raySlab(
    origin.y,
    direction.y,
    rect.top,
    rect.bottom,
  );
  return (math.max(xEnter, yEnter), math.min(xExit, yExit));
}

const _epsilon = .0001;
const _halfOptic = .28;
const _receiverHalfWidth = .34;

const _receiverDepth = .22;
const _antennaHalfWidth = .24;
const _laserHalfWidth = .24;

double _dot(FloorPoint a, FloorPoint b) => a.x * b.x + a.y * b.y;

/// Measure the ray's passage through the opaque housing behind an aperture.
(double, double) _housingBounds(
  _Ray ray,
  FloorPoint aperture,
  BeamDirection incoming, {
  required double depth,
  required double halfWidth,
}) {
  final axis = FloorPoint(incoming.x, incoming.y);
  final step = FloorPoint(ray.direction.x, ray.direction.y);
  final offset = ray.from - aperture;
  final (front, back) = _raySlab(
    _dot(offset, axis),
    _dot(step, axis),
    0,
    depth,
  );
  final (left, right) = _raySlab(
    _cross(offset, axis),
    _cross(step, axis),
    -halfWidth,
    halfWidth,
  );
  return (math.max(front, left), math.min(back, right));
}

double? _entry((double, double) bounds) {
  final (near, far) = bounds;
  if (near > far || far <= 0) return null;
  return math.max(0, near);
}

(double, double) _partBounds(_Ray ray, FloorPoint center, double radius) {
  final offset = center - ray.from;
  final heading = FloorPoint(ray.direction.x, ray.direction.y);
  final along = _dot(offset, heading);
  final across = _cross(offset, heading);
  final halfChordSquared = radius * radius - across * across;
  if (halfChordSquared < 0) return (double.infinity, double.negativeInfinity);
  final halfChord = math.sqrt(halfChordSquared);
  return (along - halfChord, along + halfChord);
}

// Each leg stops at its first contact. Correctly approached apertures accept
// the ray. The opaque face takes precedence when contacts tie.
OpticalTrace traceOptics(OpticalLevel level, List<Optic> layout) {
  final sources = level.sources.toList(growable: false);
  final obstacles = level.lightObstacles.toList(growable: false);
  final converters = layout.where((optic) => optic.converter != null).toList();
  final pending = <_Ray>[
    for (final (index, source) in sources.indexed)
      (
        from: source.position,
        direction: source.direction,
        strength: 1,
        previous: null,
        source: index,
      ),
  ];
  final segments = <BeamSegment>[];
  final lit = <int>{};
  final visited = <(int, String, BeamDirection, int, int)>{};

  for (var index = 0; index < pending.length && index < 128; index++) {
    final ray = pending[index];
    final direction = ray.direction;
    final origin = ray.from;
    var (_, distance) = _rayBounds(origin, direction, level.floor);
    Optic? hit;
    int? receiver;
    var blocked = false;
    final heading = FloorPoint(direction.x, direction.y);

    void contact(
      double at, {
      int? sensor,
      Optic? optic,
      bool hitHousing = false,
    }) {
      if (at > distance + _epsilon) return;
      final opaque = hitHousing || (sensor == null && optic == null);
      if (at >= distance - _epsilon &&
          (blocked || (!opaque && (hit != null || receiver != null)))) {
        return;
      }
      distance = math.min(distance, at);
      blocked = opaque;
      receiver = sensor;
      hit = optic;
    }

    void opaque((double, double) bounds, {Optic? optic}) {
      if (_entry(bounds) case final entry?) {
        contact(entry, optic: optic, hitHousing: true);
      }
    }

    void input(
      FloorPoint point,
      BeamDirection incoming, {
      int? sensor,
      Optic? optic,
    }) {
      final offset = point - origin;
      final along = _dot(offset, heading);
      if (direction == incoming &&
          along > _epsilon &&
          _cross(offset, heading).abs() <= _receiverHalfWidth) {
        contact(along, sensor: sensor, optic: optic);
        return;
      }
      opaque(
        _housingBounds(
          ray,
          point,
          incoming,
          depth: _receiverDepth,
          halfWidth: _receiverHalfWidth,
        ),
      );
    }

    for (final (i, sensor) in level.receivers.indexed) {
      input(sensor.position, sensor.incoming, sensor: i);
    }

    for (final block in obstacles) {
      opaque(_rayBounds(origin, direction, block));
    }
    for (final antenna in level.antennas) {
      opaque(_partBounds(ray, antenna.position, _antennaHalfWidth));
    }
    for (final (i, source) in sources.indexed) {
      if (i == ray.source && ray.previous == null) continue;
      final axis = FloorPoint(source.direction.x, source.direction.y);
      final depth = _dot(source.position - source.foot, axis) + .18;
      opaque(
        _housingBounds(
          ray,
          source.position,
          source.direction.opposite,
          depth: depth,
          halfWidth: _laserHalfWidth,
        ),
      );
    }

    for (final optic in layout) {
      if (optic.id == ray.previous) {
        continue;
      }
      if (optic.fabricationSocket != null && optic.blueprint == null) {
        opaque(
          _partBounds(ray, optic.position, OpticalLevel.opticRadius),
          optic: optic,
        );
        continue;
      }
      final offset = optic.position - origin;
      if (optic.converter case final converter?) {
        final lane = converter.lanes[optic.position];
        if (lane != null) {
          input(optic.position, lane.incoming, optic: optic);
        } else {
          opaque(_partBounds(ray, optic.position, OpticalLevel.opticRadius));
        }
        continue;
      }
      if (optic.blueprint case final design?) {
        final along = _dot(offset, heading);
        if (direction == design.inputDirection(mirrored: optic.turned) &&
            along > _epsilon &&
            _cross(offset, heading).abs() <= _halfOptic) {
          contact(along, optic: optic);
        } else {
          opaque(
            _partBounds(ray, optic.position, OpticalLevel.opticRadius),
            optic: optic,
          );
        }
        continue;
      }
      final face = FloorPoint(1, optic.turned ? -1 : 1);
      final determinant = _cross(heading, face);
      if (determinant.abs() > _epsilon) {
        final along = _cross(offset, face) / determinant;
        final across = _cross(offset, heading) / determinant;
        if (along > _epsilon && across.abs() <= _halfOptic) {
          contact(along, optic: optic);
          continue;
        }
      }
      opaque(_partBounds(ray, optic.position, OpticalLevel.opticRadius));
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
      blocked: blocked,
      source: ray.source,
    ));
    if (receiver case final accepted?) lit.add(accepted);
    final struck = hit;
    if (blocked || struck == null || struck.converter != null) continue;
    final state = (
      ray.source,
      struck.id,
      direction,
      (end.x * 10000).round(),
      (end.y * 10000).round(),
    );
    if (!visited.add(state)) continue;

    final outputs = switch (struck.kind) {
      OpticKind.mirror => [(direction.reflected(struck.turned), 1.0)],
      OpticKind.splitter => [
        (direction.reflected(struck.turned), .5),
        (direction, .5),
      ],
      OpticKind.workbenchSplitter => [
        for (final port in struck.blueprint!.ports)
          (
            struck.blueprint!.outputDirection(port, mirrored: struck.turned),
            struck.blueprint!.shareFor(port),
          ),
      ],
      OpticKind.converter => const <(BeamDirection, double)>[],
    };
    for (final (output, share) in outputs) {
      pending.add((
        from: end,
        direction: output,
        strength: ray.strength * share,
        previous: struck.id,
        source: ray.source,
      ));
    }
  }
  final inputs = {
    for (final optic in converters)
      optic.id: _converterInput(optic, segments, sources),
  };
  final hops = [
    for (final optic in converters)
      if (inputs[optic.id] case final input?
          when input.status == ConverterReception.accepted)
        _transmit(level, optic, input),
  ];
  return OpticalTrace(
    segments,
    lit,
    fabricatedPartsInstalled: level.initial
        .where((optic) => optic.fabricationSocket != null)
        .every(
          (mount) => layout.any(
            (optic) => optic.id == mount.id && optic.blueprint != null,
          ),
        ),
    converterInputs: Map.unmodifiable(inputs),
    radioHops: List.unmodifiable(hops),
    radioReadings: List.unmodifiable([
      for (final antenna in level.antennas) _receive(antenna, hops),
    ]),
  );
}

ConverterInput _converterInput(
  Optic optic,
  List<BeamSegment> segments,
  List<OpticalSource> sources,
) {
  final converter = optic.converter!;
  ConverterInput input = (
    power: 0,
    source: null,
    status: ConverterReception.quiet,
  );
  for (final beam in segments.where((beam) => beam.toOptic == optic.id)) {
    final source = sources[beam.source].label;
    final power = beam.strength * 100;
    final status =
        converter.requiredSource != null && converter.requiredSource != source
        ? ConverterReception.wrongSource
        : converter.power != null && (power - converter.power!).abs() > _epsilon
        ? ConverterReception.wrongPower
        : ConverterReception.accepted;
    final candidate = (power: power, source: source, status: status);
    if (status == ConverterReception.accepted) return candidate;
    if (power > input.power) input = candidate;
  }
  return input;
}

OpticalRadioHop _transmit(
  OpticalLevel level,
  Optic optic,
  ConverterInput input,
) {
  final converter = optic.converter!;
  final direction = converter.lanes[optic.position]!.outgoing;
  final (_, exit) = _rayBounds(optic.position, direction, level.floor);
  double? blockedDistance;
  for (final barrier in level.barriers) {
    if (barrier.material != BarrierMaterial.concrete) continue;
    final (entry, exit) = _rayBounds(optic.position, direction, barrier.bounds);
    if (entry > _epsilon &&
        entry <= exit &&
        (blockedDistance == null || entry < blockedDistance)) {
      blockedDistance = entry;
    }
  }
  final length = math.min(
    math.min(exit, converter.reach),
    blockedDistance ?? double.infinity,
  );
  return (
    converter: optic.id,
    source: input.source!,
    from: optic.position,
    to: optic.position + FloorPoint(direction.x, direction.y) * length,
    direction: direction,
    emitted: input.power,
    channel: converter.channel,
    reach: converter.reach,
    blockedDistance: blockedDistance,
  );
}

OpticalRadioReading _receive(
  OpticalAntenna antenna,
  List<OpticalRadioHop> hops,
) {
  OpticalRadioReading reading = (
    power: 0,
    status: RadioReception.quiet,
    hop: null,
    distance: null,
  );
  for (final hop in hops) {
    final heading = FloorPoint(hop.direction.x, hop.direction.y);
    final offset = antenna.position - hop.from;
    final distance = offset.x * heading.x + offset.y * heading.y;
    if (distance <= _epsilon || _cross(offset, heading).abs() > _epsilon) {
      continue;
    }
    final arriving = radioStrength(hop.emitted, distance);
    final status = distance > hop.reach + _epsilon
        ? RadioReception.outOfRange
        : (hop.blockedDistance ?? double.infinity) <= distance
        ? RadioReception.blocked
        : hop.channel != antenna.channel
        ? RadioReception.wrongChannel
        : arriving < antenna.minimum - _epsilon
        ? RadioReception.weak
        : RadioReception.accepted;
    final power =
        status == RadioReception.accepted || status == RadioReception.weak
        ? arriving
        : 0.0;
    if (status.index > reading.status.index ||
        status == reading.status && power > reading.power) {
      reading = (power: power, status: status, hop: hop, distance: distance);
    }
  }
  return reading;
}

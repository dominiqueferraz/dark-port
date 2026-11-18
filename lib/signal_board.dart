import 'dart:math' as math;

import 'placement_nodes.dart';

enum SignalDeviceKind {
  transmitter,
  splitter,
  attenuator,
  relay,
  receiver,
  broadcaster,
  antenna,
}

const attenuationSteps = [0, 10, 20];

enum SplitterType {
  twoWay('2-way splitter', 2, 6),
  threeWay('3-way splitter', 3, 4),
  fourWay('4-way splitter', 4, 7);

  const SplitterType(this.label, this.outputs, this.range);

  final String label;
  final int outputs;
  final int range;

  String get fraction => switch (this) {
    twoWay => '½',
    threeWay => '⅓',
    fourWay => '¼',
  };
}

typedef SignalPoint = math.Point<double>;

class SignalDevice {
  const SignalDevice(
    this.id,
    this.name,
    this.kind,
    this.initialPosition, {
    this.channel = 12,
    this.strength = 0,
    this.minimumStrength,
    this.maximumStrength,
    this.requiredSource,
    this.cableRange,
    this.radioRange = 0,
    this.splitter,
    this.dualInput = false,
    this.initialLoss,
    this.fixed = false,
    this.alternateTint = false,
    this.mounts,
    this.mustBeQuiet = false,
  });

  final String id;
  final String name;
  final SignalDeviceKind kind;
  final SignalPoint initialPosition;
  final int channel;
  final double strength;
  final double? minimumStrength;
  final double? maximumStrength;
  final String? requiredSource;
  final int? cableRange;
  final int radioRange;
  final SplitterType? splitter;
  final bool dualInput;
  final int? initialLoss;
  final bool fixed;
  final bool alternateTint;
  final List<PlacementNode>? mounts;
  final bool mustBeQuiet;
  int get range => cableRange ?? splitter?.range ?? 3;

  bool get canFlip =>
      !fixed && mounts == null && kind != SignalDeviceKind.broadcaster;
  bool get hasInput =>
      kind != SignalDeviceKind.transmitter && kind != SignalDeviceKind.antenna;
  int get inputs => !hasInput ? 0 : (dualInput ? 2 : 1);
  int get outputs => switch (kind) {
    SignalDeviceKind.transmitter ||
    SignalDeviceKind.attenuator ||
    SignalDeviceKind.relay => 1,
    SignalDeviceKind.splitter => splitter!.outputs,
    SignalDeviceKind.receiver ||
    SignalDeviceKind.antenna ||
    SignalDeviceKind.broadcaster => 0,
  };

  SignalReading read(SignalDelivery? delivery) {
    if (delivery == null) return SignalReading.quiet;
    if (delivery.channel != channel) return SignalReading.wrongChannel;
    if (requiredSource != null && delivery.source != requiredSource) {
      return SignalReading.wrongSource;
    }
    return _readStrength(delivery.strength);
  }

  SignalReading _readStrength(double strength) {
    if (minimumStrength case final minimum? when strength < minimum - 1e-9) {
      return SignalReading.weak;
    }
    if (maximumStrength case final maximum? when strength > maximum + 1e-9) {
      return SignalReading.strong;
    }
    return SignalReading.accepted;
  }
}

typedef SignalLink = ({String from, String to, int input, int output});
typedef SignalDelivery = ({
  String source,
  int channel,
  double strength,
  int hop,
});
typedef AlarmPower = ({
  double strength,
  Set<String> sources,
  SignalReading reading,
});

enum SignalReading { quiet, wrongChannel, wrongSource, weak, strong, accepted }

enum LinkIssue {
  direction('Connect an output to an input.'),
  range('That input is out of range.'),
  stock('No patch leads left. Disconnect a cable to free one.'),
  corridor('No cable corridor joins these sockets.'),
  interference('Shielded lead required.'),
  trunk('A trunk lead needs a straight, marked trunk run.'),
  feedthrough('The wall needs a matching feedthrough.'),
  occupied('That output is wired. Choose a free output.'),
  inputOccupied('That alarm input is wired. Use the other input.'),
  cycle('That cable would create a loop.');

  const LinkIssue(this.message);

  final String message;
}

enum LeadType {
  patch('Patch lead'),
  shielded('Shielded lead', 4),
  trunk('Trunk lead', 6);

  const LeadType(this.label, [this.cap]);

  final String label;
  final int? cap;
}

/// A single authored path between two physical jacks, including both ends.
class CableCorridor {
  const CableCorridor(this.points, {this.trunk = false});

  final List<SignalPoint> points;
  final bool trunk;

  double get length {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      final delta = points[i] - points[i - 1];
      total += delta.x.abs() + delta.y.abs();
    }
    return total;
  }
}

/// A vertical concrete barrier in board coordinates, with y increasing down.
class RadioWall {
  const RadioWall(this.x, this.top, this.bottom);

  final double x;
  final double top;
  final double bottom;

  double? _intercept(SignalPoint origin, SignalPoint target) {
    final dx = target.x - origin.x;
    final dy = target.y - origin.y;
    if (dx == 0) {
      if (origin.x != x) return null;
      if (origin.y >= top && origin.y <= bottom) return 0;
      if (origin.y < top && target.y >= top) return (top - origin.y) / dy;
      if (origin.y > bottom && target.y <= bottom) {
        return (bottom - origin.y) / dy;
      }
      return null;
    }
    final progress = (x - origin.x) / dx;
    if (progress < 0 || progress > 1) return null;
    final y = origin.y + dy * progress;
    return y >= top && y <= bottom ? progress : null;
  }
}

typedef RadioPath = ({double distance, bool inRange, SignalPoint? blockedAt});

class SignalBoard {
  const SignalBoard({
    required this.devices,
    required this.goals,
    required this.size,
    required this.height,
    required this.placementNodes,
    this.alarm,
    this.initialLinks = const [],
    this.initialFlipped = const {},
    this.patchLeadStock,
    this.shieldedLeadStock = 0,
    this.trunkLeadStock = 0,
    this.radioWalls = const [],
    this.cableCorridors,
    this.interference,
    this.feedthroughs = const {},
  });

  final List<SignalDevice> devices;
  final List<SignalDevice> goals;
  final double size;
  final double height;
  final List<PlacementNode> placementNodes;
  final ({SignalDevice blocker, String source})? alarm;
  final List<SignalLink> initialLinks;
  final Set<String> initialFlipped;
  final int? patchLeadStock;
  final int shieldedLeadStock;
  final int trunkLeadStock;
  final List<RadioWall> radioWalls;
  final List<CableCorridor>? cableCorridors;
  final math.Rectangle<double>? interference;
  final Map<SignalPoint, Set<LeadType>> feedthroughs;

  int? leadStock(LeadType type) => switch (type) {
    LeadType.patch => patchLeadStock,
    LeadType.shielded => shieldedLeadStock,
    LeadType.trunk => trunkLeadStock,
  };

  int leadReach(String from, LeadType type) {
    final reach = device(from)!.range;
    return math.min(reach, type.cap ?? reach);
  }

  static const partSize = .88;
  static const edgeInset = .5;
  static const inputOffset = SignalPoint(-.37, 0);
  static const secondInputOffset = SignalPoint(-.37, .15);
  static const outputOffset = SignalPoint(.37, 0);
  static const cableLead = .08;

  static SignalPoint inputPort(int input, {bool flipped = false}) {
    final offset = input == 0 ? inputOffset : secondInputOffset;
    return flipped ? SignalPoint(-offset.x, offset.y) : offset;
  }

  static SignalPoint outputPort(int output, {bool flipped = false}) {
    final offset = switch (output) {
      1 => const SignalPoint(.29, -.36),
      2 => const SignalPoint(.29, .36),
      3 => const SignalPoint(.37, .15),
      _ => outputOffset,
    };
    return flipped ? SignalPoint(-offset.x, offset.y) : offset;
  }

  static SignalPoint outputDirection(int output, {bool flipped = false}) =>
      switch (output) {
        1 => const SignalPoint(0, -1),
        2 => const SignalPoint(0, 1),
        _ => SignalPoint(flipped ? -1 : 1, 0),
      };

  Map<String, SignalPoint> get initialPositions => {
    for (final device in devices) device.id: device.initialPosition,
  };

  SignalDevice? device(String id) =>
      devices.where((device) => device.id == id).firstOrNull;

  PlacementNode? snapAt(SignalPoint point, {String? id}) =>
      math.Rectangle<double>(0, 0, size, height).containsPoint(point)
      ? nearestPlacementNode(point, mountsFor(id))
      : null;

  List<PlacementNode> mountsFor(String? id) =>
      device(id ?? '')?.mounts ?? placementNodes;

  bool canMove(
    String id,
    SignalPoint point,
    Map<String, SignalPoint> positions,
  ) {
    final part = device(id);
    if (part == null || part.fixed) return false;
    final mounts =
        part.mounts ??
        (part.kind == SignalDeviceKind.broadcaster ? placementNodes : null);
    return (mounts == null || mounts.any((node) => node.position == point)) &&
        point.x >= edgeInset &&
        point.x <= size - edgeInset &&
        point.y >= edgeInset &&
        point.y <= height - edgeInset &&
        positions.entries.every(
          (entry) =>
              entry.key == id ||
              (entry.value.x - point.x).abs() >= partSize ||
              (entry.value.y - point.y).abs() >= partSize,
        );
  }

  ({SignalPoint from, SignalPoint to}) linkPorts(
    SignalLink link,
    Map<String, SignalPoint> positions, {
    Set<String> flipped = const {},
  }) => (
    from:
        positions[link.from]! +
        outputPort(link.output, flipped: flipped.contains(link.from)),
    to:
        positions[link.to]! +
        inputPort(link.input, flipped: flipped.contains(link.to)),
  );

  double distance(
    SignalLink link,
    Map<String, SignalPoint> positions, {
    Set<String> flipped = const {},
  }) {
    final route = corridorFor(link, positions, flipped: flipped);
    if (route != null) return route.length;
    final ports = linkPorts(link, positions, flipped: flipped);
    final offset = ports.to - ports.from;
    return offset.x.abs() + offset.y.abs();
  }

  bool inReach(
    SignalLink link,
    Map<String, SignalPoint> positions, {
    Set<String> flipped = const {},
  }) =>
      distance(link, positions, flipped: flipped) <=
      device(link.from)!.range + 1e-9;

  CableCorridor? corridorFor(
    SignalLink link,
    Map<String, SignalPoint> positions, {
    Set<String> flipped = const {},
  }) {
    final corridors = cableCorridors;
    if (corridors == null) return null;
    final ports = linkPorts(link, positions, flipped: flipped);
    return corridors
        .where(
          (route) =>
              _samePoint(route.points.first, ports.from) &&
              _samePoint(route.points.last, ports.to),
        )
        .firstOrNull;
  }

  static bool _samePoint(SignalPoint a, SignalPoint b) =>
      a.squaredDistanceTo(b) < 1e-16;

  LinkIssue? cableIssue(
    SignalLink link,
    Map<String, SignalPoint> positions, {
    Set<String> flipped = const {},
    LeadType type = LeadType.patch,
  }) {
    final route = corridorFor(link, positions, flipped: flipped);
    if (cableCorridors != null && route == null) return LinkIssue.corridor;
    final length = route?.length ?? distance(link, positions, flipped: flipped);
    if (length > leadReach(link.from, type) + 1e-9) return LinkIssue.range;
    if (type == LeadType.trunk &&
        (route == null ||
            !route.trunk ||
            route.points.length != 2 ||
            (route.points.first.x != route.points.last.x &&
                route.points.first.y != route.points.last.y))) {
      return LinkIssue.trunk;
    }
    if (route == null) return null;
    for (var i = 1; i < route.points.length; i++) {
      final a = route.points[i - 1];
      final b = route.points[i];
      for (final wall in radioWalls) {
        final intercept = wall._intercept(a, b);
        if (intercept == null) continue;
        final hit = a + (b - a) * intercept;
        if (!feedthroughs.entries.any(
          (entry) => _samePoint(hit, entry.key) && entry.value.contains(type),
        )) {
          return LinkIssue.feedthrough;
        }
      }
      if (interference case final zone?
          when type != LeadType.shielded && _crossesZone(a, b, zone)) {
        return LinkIssue.interference;
      }
    }
    return null;
  }

  static bool _crossesZone(
    SignalPoint a,
    SignalPoint b,
    math.Rectangle<double> zone,
  ) => a.y == b.y
      ? a.y >= zone.top &&
            a.y <= zone.bottom &&
            math.min(a.x, b.x) < zone.right &&
            math.max(a.x, b.x) > zone.left
      : a.x >= zone.left &&
            a.x <= zone.right &&
            math.min(a.y, b.y) < zone.bottom &&
            math.max(a.y, b.y) > zone.top;

  LinkIssue? linkIssue(
    List<SignalLink> links,
    SignalLink proposed, {
    required Map<String, SignalPoint> positions,
    Set<String> flipped = const {},
    bool checkReach = true,
    LeadType type = LeadType.patch,
    Map<SignalLink, LeadType> leadTypes = const {},
  }) {
    final from = device(proposed.from);
    final to = device(proposed.to);
    if (from == null ||
        to == null ||
        proposed.output < 0 ||
        proposed.output >= from.outputs ||
        proposed.input < 0 ||
        proposed.input >= to.inputs) {
      return LinkIssue.direction;
    }
    if (to.dualInput &&
        links.any(
          (link) =>
              link.to == proposed.to &&
              link.input == proposed.input &&
              link != proposed,
        )) {
      return LinkIssue.inputOccupied;
    }
    if (checkReach) {
      final issue = cableIssue(
        proposed,
        positions,
        flipped: flipped,
        type: type,
      );
      if (issue != null) return issue;
    }
    final remaining = links.where(
      (link) => link.to != proposed.to || link.input != proposed.input,
    );
    if (remaining.any(
      (link) => link.from == proposed.from && link.output == proposed.output,
    )) {
      return LinkIssue.occupied;
    }
    if (leadStock(type) case final stock?
        when remaining
                .where((link) => (leadTypes[link] ?? LeadType.patch) == type)
                .length >=
            stock) {
      return LinkIssue.stock;
    }
    final downstream = [proposed.to];
    final visited = <String>{};
    while (downstream.isNotEmpty) {
      final current = downstream.removeLast();
      if (current == proposed.from) return LinkIssue.cycle;
      if (visited.add(current)) {
        downstream.addAll(
          remaining
              .where((link) => link.from == current)
              .map((link) => link.to),
        );
      }
    }
    return null;
  }

  Map<SignalLink, SignalDelivery> evaluate(
    List<SignalLink> links, {
    required Map<String, SignalPoint> positions,
    Set<String> flipped = const {},
    Map<String, int> losses = const {},
    Map<SignalLink, LeadType> leadTypes = const {},
  }) {
    for (final type in LeadType.values) {
      if (leadStock(type) case final stock?
          when links
                  .where((link) => (leadTypes[link] ?? LeadType.patch) == type)
                  .length >
              stock) {
        return const {};
      }
    }
    final active = {for (final device in devices) device.id: device};
    final outputs = <String, List<SignalLink>>{};
    for (final link in links) {
      if (cableIssue(
            link,
            positions,
            flipped: flipped,
            type: leadTypes[link] ?? LeadType.patch,
          ) ==
          null) {
        (outputs[link.from] ??= []).add(link);
      }
    }
    final deliveries = <SignalLink, SignalDelivery>{};

    void propagate(String from, SignalDelivery delivery) {
      if (delivery.strength <= 0) return;
      for (final link in outputs[from] ?? const <SignalLink>[]) {
        if (deliveries.containsKey(link)) continue;
        deliveries[link] = delivery;
        final next = active[link.to]!;
        if (next.outputs > 0) {
          propagate(next.id, (
            source: delivery.source,
            channel: delivery.channel,
            strength: delivery.strength / next.outputs - lossFor(next, losses),
            hop: delivery.hop + 1,
          ));
        }
      }
    }

    for (final source in devices) {
      if (source.kind == SignalDeviceKind.transmitter) {
        propagate(source.id, (
          source: source.id,
          channel: source.channel,
          strength: source.strength - lossFor(source, losses),
          hop: 0,
        ));
      }
    }
    for (final broadcaster in devices.where(
      (device) => device.kind == SignalDeviceKind.broadcaster,
    )) {
      final feed = deliveries.entries
          .where((entry) => entry.key.to == broadcaster.id)
          .firstOrNull
          ?.value;
      if (feed == null) continue;
      for (final antenna in devices.where(
        (device) => device.kind == SignalDeviceKind.antenna,
      )) {
        final path = radioPath(broadcaster, antenna, positions);
        final strength = feed.strength - 5 * path.distance;
        if (path.inRange && path.blockedAt == null && strength > 0) {
          deliveries[(
            from: broadcaster.id,
            to: antenna.id,
            input: 0,
            output: radioOutput,
          )] = (
            source: feed.source,
            channel: feed.channel,
            strength: strength,
            hop: feed.hop + 1,
          );
        }
      }
    }
    return Map.unmodifiable(deliveries);
  }

  // Radio deliveries share receiver evaluation, but never use a cable socket.
  static const radioOutput = -1;

  RadioPath radioPath(
    SignalDevice broadcaster,
    SignalDevice antenna,
    Map<String, SignalPoint> positions,
  ) {
    final origin = positions[broadcaster.id]!;
    final target = positions[antenna.id]!;
    final delta = target - origin;
    final distance = delta.x.abs() + delta.y.abs();
    double? hit;
    for (final wall in radioWalls) {
      final progress = wall._intercept(origin, target);
      if (progress != null && (hit == null || progress < hit)) hit = progress;
    }
    return (
      distance: distance,
      inRange: distance <= broadcaster.radioRange,
      blockedAt: hit == null ? null : origin + delta * hit,
    );
  }

  int lossFor(SignalDevice device, Map<String, int> losses) =>
      losses[device.id] ?? device.initialLoss ?? 0;

  SignalDelivery? alarmFeed(
    Map<SignalLink, SignalDelivery> deliveries,
    int input,
  ) => deliveries.entries
      .where(
        (entry) =>
            entry.key.to == alarm?.blocker.id && entry.key.input == input,
      )
      .firstOrNull
      ?.value;

  AlarmPower? alarmPower(Map<SignalLink, SignalDelivery> deliveries) {
    final blocker = alarm?.blocker;
    if (blocker == null) return null;
    final sources = <String>{};
    var strength = 0.0;
    var wrongChannel = false;
    for (var input = 0; input < blocker.inputs; input++) {
      final delivery = alarmFeed(deliveries, input);
      if (delivery == null) continue;
      sources.add(delivery.source);
      strength += delivery.strength;
      wrongChannel |= delivery.channel != blocker.channel;
    }
    return (
      strength: strength,
      sources: sources,
      reading: sources.isEmpty
          ? SignalReading.quiet
          : wrongChannel
          ? SignalReading.wrongChannel
          : blocker._readStrength(strength),
    );
  }

  bool interruptsAlarm(Map<SignalLink, SignalDelivery> deliveries) =>
      (alarmPower(deliveries)?.reading ?? SignalReading.accepted) !=
      SignalReading.accepted;

  bool solves(Map<SignalLink, SignalDelivery> deliveries) {
    final power = alarmPower(deliveries);
    return (power == null ||
            power.reading == SignalReading.accepted &&
                power.sources.length == 1 &&
                power.sources.contains(alarm!.source)) &&
        goals.every((goal) {
          final incoming = deliveries.entries.where(
            (entry) => entry.key.to == goal.id,
          );
          return goal.mustBeQuiet
              ? !incoming.any(
                  (entry) =>
                      entry.value.channel == goal.channel &&
                      entry.value.strength > 0,
                )
              : incoming.any(
                  (entry) => goal.read(entry.value) == SignalReading.accepted,
                );
        });
  }
}

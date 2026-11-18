import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'signal_board.dart';
import 'sheet_style.dart';

class SignalCablePath {
  const SignalCablePath(this.link, this.points, this.overpasses);

  final SignalLink link;
  final List<Offset> points;
  final List<Offset> overpasses;

  Path get path => Path()..addPolygon(points, false);
}

typedef _Segment = ({Offset from, Offset to});

Iterable<_Segment> _segments(List<Offset> points) sync* {
  for (var i = 1; i < points.length; i++) {
    yield (from: points[i - 1], to: points[i]);
  }
}

double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

double _cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

bool _overlaps(_Segment a, _Segment b) {
  final delta = a.to - a.from;
  final length = delta.distance;
  if (length == 0) return false;
  final direction = delta / length;
  final start = b.from - a.from;
  final end = b.to - a.from;
  if (_cross(direction, start).abs() > .75 ||
      _cross(direction, end).abs() > .75) {
    return false;
  }
  final near = _dot(start, direction);
  final far = _dot(end, direction);
  return math.min(length, math.max(near, far)) -
          math.max(0, math.min(near, far)) >
      4;
}

Offset? _intersection(_Segment a, _Segment b) {
  final first = a.to - a.from;
  final second = b.to - b.from;
  final cross = _cross(first, second);
  if (cross.abs() < 1e-6) return null;
  final offset = b.from - a.from;
  final alongFirst = _cross(offset, second) / cross;
  final alongSecond = _cross(offset, first) / cross;
  if (alongFirst < 0 || alongFirst > 1 || alongSecond < 0 || alongSecond > 1) {
    return null;
  }
  return a.from + first * alongFirst;
}

bool _crossesPart(_Segment segment, Rect part) {
  final (from, to) = (segment.from, segment.to);
  if (from.dy == to.dy) {
    return from.dy > part.top &&
        from.dy < part.bottom &&
        math.min(from.dx, to.dx) < part.right &&
        math.max(from.dx, to.dx) > part.left;
  }
  return from.dx > part.left &&
      from.dx < part.right &&
      math.min(from.dy, to.dy) < part.bottom &&
      math.max(from.dy, to.dy) > part.top;
}

bool _crossesJack(_Segment segment, Rect jack) {
  final delta = segment.to - segment.from;
  var enter = 0.0;
  var exit = 1.0;
  for (final (origin, step, low, high) in [
    (segment.from.dx, delta.dx, jack.left, jack.right),
    (segment.from.dy, delta.dy, jack.top, jack.bottom),
  ]) {
    if (step == 0) {
      if (origin <= low || origin >= high) return false;
      continue;
    }
    final a = (low - origin) / step;
    final b = (high - origin) / step;
    enter = math.max(enter, math.min(a, b));
    exit = math.min(exit, math.max(a, b));
    if (enter >= exit) return false;
  }
  return true;
}

List<Offset> _roundBends(List<Offset> route, double lead) {
  final points = <Offset>[];
  for (final point in route) {
    if (points.isEmpty || point != points.last) points.add(point);
  }
  final rounded = [points.first];
  for (var i = 1; i < points.length - 1; i++) {
    final corner = points[i];
    final incoming = corner - points[i - 1];
    final outgoing = points[i + 1] - corner;
    if (_cross(incoming, outgoing).abs() < 1e-6) {
      if (_dot(incoming, outgoing) < 0) rounded.add(corner);
      continue;
    }
    final radius = math.min(
      lead * 1.8,
      math.min(incoming.distance, outgoing.distance) * .4,
    );
    final before = corner - incoming * (radius / incoming.distance);
    final after = corner + outgoing * (radius / outgoing.distance);
    rounded.add(before);
    for (var step = 1; step <= 5; step++) {
      final t = step / 5;
      rounded.add(
        Offset.lerp(
          Offset.lerp(before, corner, t)!,
          Offset.lerp(corner, after, t)!,
          t,
        )!,
      );
    }
  }
  rounded.add(points.last);
  return rounded;
}

List<Offset> _routeCable(
  Offset from,
  Offset to,
  Offset outputDirection,
  Offset inputDirection,
  Rect bounds,
  List<Rect> parts,
  double lead,
  List<_Segment> previous,
  List<_Segment> siblingFeeds,
  List<Offset> jacks,
) {
  final start = from + outputDirection * lead;
  final end = to + inputDirection * lead;
  final jackClearance = lead * .85;
  final jackBounds = [
    for (final jack in jacks)
      if (jack != from && jack != to)
        Rect.fromCircle(center: jack, radius: jackClearance),
  ];
  // Leave the socket facing outward for short, directly opposed connections.
  final direct = to - from;
  if (_cross(direct, outputDirection).abs() < 1e-6 &&
      _dot(direct, outputDirection) > 0 &&
      inputDirection == -outputDirection &&
      direct.distance <= 2 * lead &&
      !jackBounds.any((jack) => _crossesJack((from: from, to: to), jack))) {
    return [from, to];
  }

  final clearance = lead * .5;
  final obstacles = [...parts, ...jackBounds];
  final columns = {
    start.dx,
    end.dx,
    (start.dx + end.dx) / 2,
    bounds.left,
    bounds.right,
    for (final part in obstacles) ...[
      (part.left - clearance).clamp(bounds.left, bounds.right),
      (part.right + clearance).clamp(bounds.left, bounds.right),
    ],
    for (final x in [start.dx, end.dx])
      for (final side in [-1, 1])
        (x + side * lead * 1.8).clamp(bounds.left, bounds.right),
  };
  final rows = {
    start.dy,
    end.dy,
    (start.dy + end.dy) / 2,
    bounds.top,
    bounds.bottom,
    for (final part in obstacles) ...[
      (part.top - clearance).clamp(bounds.top, bounds.bottom),
      (part.bottom + clearance).clamp(bounds.top, bounds.bottom),
    ],
    for (final y in [start.dy, end.dy])
      for (final side in [-1, 1])
        (y + side * lead * 1.8).clamp(bounds.top, bounds.bottom),
  };
  final candidates = [
    for (final x in columns)
      [start, Offset(x, start.dy), Offset(x, end.dy), end],
    for (final y in rows) [start, Offset(start.dx, y), Offset(end.dx, y), end],
  ];

  // Keep the socket approaches straight and route around every other jack.
  var bestScore = double.infinity;
  List<Offset>? best;
  var bestPinCrossings = 1 << 30;
  var bestPartCrossings = 1 << 30;
  final fromKeepout = Rect.fromCircle(center: from, radius: jackClearance);
  final toKeepout = Rect.fromCircle(center: to, radius: jackClearance);
  void consider(List<Offset> candidate) {
    var score = 0.0;
    var partCrossings = 0;
    var pinCrossings = 0;
    final rounded = _roundBends([from, ...candidate, to], lead);
    final departure = rounded[1] - from;
    final approach = rounded[rounded.length - 2] - to;
    if (_dot(departure, outputDirection) <= 0 ||
        _dot(approach, inputDirection) <= 0) {
      pinCrossings++;
    }
    for (final segment in _segments(rounded)) {
      if (jackBounds.any((jack) => _crossesJack(segment, jack))) pinCrossings++;
    }
    for (final segment in _segments(candidate)) {
      if (segment.from == segment.to) continue;
      score += (segment.to - segment.from).distance;
      if (_crossesJack(segment, fromKeepout) ||
          _crossesJack(segment, toKeepout)) {
        pinCrossings++;
      }
      if (parts.any((part) => _crossesPart(segment, part))) partCrossings++;
      if (previous.any((other) => _overlaps(segment, other))) score += lead * 4;
      if (previous.any((other) {
        final point = _intersection(segment, other);
        return point != null &&
            (point - from).distance > lead &&
            (point - to).distance > lead;
      })) {
        score += lead * 6;
      }
      if (siblingFeeds.any((other) => _intersection(segment, other) != null)) {
        // Keep a crossing gap from erasing a short lead at a nearby input.
        score += math.max(bounds.width, bounds.height);
      }
    }
    // A pin collision matters even when a part leaves no open lane nearby.
    if (pinCrossings < bestPinCrossings ||
        (pinCrossings == bestPinCrossings &&
            (partCrossings < bestPartCrossings ||
                (partCrossings == bestPartCrossings && score < bestScore)))) {
      best = rounded;
      bestScore = score;
      bestPinCrossings = pinCrossings;
      bestPartCrossings = partCrossings;
    }
  }

  for (final candidate in candidates) {
    consider(candidate);
  }
  if (bestPinCrossings > 0 || bestPartCrossings > 0) {
    for (final x in columns) {
      for (final y in rows) {
        final turn = Offset(x, y);
        consider([start, Offset(x, start.dy), turn, Offset(end.dx, y), end]);
        consider([start, Offset(start.dx, y), turn, Offset(x, end.dy), end]);
      }
    }
  }
  return best!;
}

List<SignalCablePath> layoutSignalCables(
  Map<SignalLink, ({Offset from, Offset to})> ports,
  Iterable<SignalLink> links, {
  required Rect bounds,
  required List<Rect> parts,
  required double lead,
  Map<SignalLink, ({Offset from, Offset to})> directions = const {},
  Map<SignalLink, List<Offset>> corridors = const {},
  List<Offset> jacks = const [],
}) {
  final jackPositions = {
    ...jacks,
    for (final pair in ports.values) ...[pair.from, pair.to],
  }.toList();
  final routes = <SignalCablePath>[];
  for (final link in links) {
    final (from: from, to: to) = ports[link]!;
    final direction = directions[link];
    if ((to - from).distanceSquared < .25) continue;
    final corridor = corridors[link];
    final points = corridor != null
        ? _roundBends(corridor, lead)
        : _routeCable(
            from,
            to,
            direction?.from ?? const Offset(1, 0),
            direction?.to ?? const Offset(-1, 0),
            bounds,
            parts,
            lead,
            routes.expand((route) => _segments(route.points)).toList(),
            routes
                .where((route) => route.link.to == link.to)
                .expand((route) => _segments(route.points))
                .toList(),
            jackPositions,
          );

    final overpasses = <Offset>[];
    for (final route in routes) {
      for (final previous in _segments(route.points)) {
        for (final segment in _segments(points)) {
          final point = _intersection(segment, previous);
          if (point == null ||
              jackPositions.any(
                (jack) => (point - jack).distance < math.max(lead * 1.85, 5.0),
              ) ||
              overpasses.any((other) => (point - other).distance < 1)) {
            continue;
          }
          overpasses.add(point);
        }
      }
    }
    routes.add(SignalCablePath(link, points, overpasses));
  }
  return routes;
}

double signalCableOpacity(double reachUsed) =>
    1 - .55 * (2 * reachUsed - 1).clamp(0.0, 1.0);

class SignalWiring extends CustomPainter {
  SignalWiring({
    required this.routes,
    required this.beyondReach,
    required this.opacities,
    required this.deliveries,
    required this.referenceUnits,
    required this.time,
    required this.selectedOutput,
    required this.reach,
    this.sheet = SheetStyle.fallback,
    this.alternateSources = const {},
  });

  final List<SignalCablePath> routes;
  final Set<SignalLink> beyondReach;
  final Map<SignalLink, double> opacities;
  final Map<SignalLink, SignalDelivery> deliveries;
  final double referenceUnits;
  final double time;
  final Offset? selectedOutput;
  final Size? reach;
  final Set<String> alternateSources;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedOutput case final center?) {
      final extent = reach!;
      canvas.drawPath(
        Path()..addPolygon([
          center - Offset(0, extent.height),
          center + Offset(extent.width, 0),
          center + Offset(0, extent.height),
          center - Offset(extent.width, 0),
        ], true),
        Paint()
          ..color = sheet.ink.withValues(alpha: .36)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    final hasCrossings = routes.any((route) => route.overpasses.isNotEmpty);
    if (hasCrossings) canvas.saveLayer(Offset.zero & size, Paint());

    final clear = Paint()..blendMode = BlendMode.clear;
    for (final route in routes) {
      for (final point in route.overpasses) {
        canvas.drawCircle(point, 4.7, clear);
      }
      final path = route.path;
      final metric = path.computeMetrics().single;
      final length = metric.length;
      if (beyondReach.contains(route.link)) {
        final dashed = Paint()
          ..color = sheet.ink.withValues(alpha: .65)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        for (double start = 0; start < length; start += 7) {
          canvas.drawPath(
            metric.extractPath(start, math.min(start + 3, length)),
            dashed,
          );
        }
        continue;
      }

      final delivery = deliveries[route.link];
      final progress = delivery == null
          ? 0.0
          : (time - delivery.hop).clamp(0.0, 1.0);
      final opacity = opacities[route.link]!;
      final idleColor = sheet.ink.withValues(alpha: opacity);
      final accent = alternateSources.contains(delivery?.source)
          ? sheet.alarmBeam
          : sheet.beam;
      final liveColor = accent.withValues(alpha: .19 + opacity * .81);
      final distance = progress * length;
      if (progress < 1) {
        canvas.drawPath(
          progress == 0 ? path : metric.extractPath(distance, length),
          Paint()
            ..color = idleColor
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
      if (delivery != null && progress > 0) {
        // Make low-power branches distinguishable on the board's shared scale.
        final power = math.sqrt(
          (delivery.strength / referenceUnits).clamp(0.0, 1.0),
        );
        final coreWidth = 1.25 + 1.65 * power;
        final livePath = metric.extractPath(0, distance);
        canvas.drawPath(
          livePath,
          Paint()
            ..color = sheet.paper.withValues(alpha: .85)
            ..strokeWidth = coreWidth + 1.9
            ..style = PaintingStyle.stroke,
        );
        canvas.drawPath(
          livePath,
          Paint()
            ..color = accent.withValues(alpha: opacity * (.10 + .42 * power))
            ..strokeWidth = coreWidth + 1.4
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.3),
        );
        canvas.drawPath(
          livePath,
          Paint()
            ..color = liveColor
            ..strokeWidth = coreWidth
            ..style = PaintingStyle.stroke,
        );
        if (progress < 1) {
          canvas.drawCircle(
            metric.getTangentForOffset(distance)!.position,
            2.2 + 1.8 * power,
            Paint()..color = liveColor,
          );
        }
      }

      final tangent = metric.getTangentForOffset(length / 2)!;
      final middle = tangent.position;
      final direction = tangent.vector;
      final side = Offset(-direction.dy, direction.dx);
      final tip = middle + direction * 2.5;
      final tail = middle - direction * 2.5;
      canvas.drawPath(
        Path()..addPolygon([tip, tail + side * 3, tail - side * 3], true),
        Paint()..color = progress >= .5 ? liveColor : idleColor,
      );
    }
    if (hasCrossings) canvas.restore();
  }

  @override
  bool shouldRepaint(SignalWiring oldDelegate) =>
      time != oldDelegate.time ||
      routes != oldDelegate.routes ||
      beyondReach != oldDelegate.beyondReach ||
      opacities != oldDelegate.opacities ||
      deliveries != oldDelegate.deliveries ||
      referenceUnits != oldDelegate.referenceUnits ||
      selectedOutput != oldDelegate.selectedOutput ||
      reach != oldDelegate.reach ||
      alternateSources != oldDelegate.alternateSources ||
      sheet != oldDelegate.sheet;
}

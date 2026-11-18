import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'drafting_theme.dart';
import 'sheet_style.dart';

/// Places part leaders and lettering in the space between marks on a sheet.
class DraftingAnnotations {
  DraftingAnnotations({
    required this.bounds,
    Iterable<Rect> obstacles = const [],
    this.traces = const [],
    this.leaderObstacles = const [],
  }) : _obstacles = obstacles.toList();

  final Rect bounds;
  final List<(Offset, Offset)> traces;
  final List<({Offset center, double radius})> leaderObstacles;
  final List<Rect> _obstacles;

  static final _directions = [
    for (final degrees in [
      -45,
      -135,
      135,
      45,
      -90,
      90,
      0,
      180,
      -22.5,
      -67.5,
      -112.5,
      -157.5,
      22.5,
      67.5,
      112.5,
      157.5,
    ])
      Offset.fromDirection(degrees * math.pi / 180),
  ];

  bool hasRoom(Offset point, double clearance) =>
      bounds.deflate(clearance).contains(point) &&
      !_obstacles.any((area) => area.inflate(clearance).contains(point)) &&
      !traces.any(
        (span) =>
            distanceToDraftingSegment(point, span.$1, span.$2) < clearance + 1,
      );

  ({Offset center, double reach})? placeBalloon({
    required Offset anchor,
    required double radius,
    required double reach,
    required Iterable<double> gaps,
    Offset? preferredOffset,
    double Function(Offset direction)? reachAt,
  }) {
    for (final offset in [
      ?preferredOffset,
      for (final gap in gaps)
        for (final direction in _directions) direction * (reach + radius + gap),
    ]) {
      final center = anchor + offset;
      if (!hasRoom(center, radius + 2)) continue;
      final direction = offset / offset.distance;
      final edge = reachAt?.call(direction) ?? reach;
      final start = anchor + direction * edge;
      final end = center - direction * radius;
      if (leaderObstacles.any(
        (mark) =>
            distanceToDraftingSegment(mark.center, start, end) < mark.radius,
      )) {
        continue;
      }
      _obstacles.add(Rect.fromCircle(center: center, radius: radius));
      return (center: center, reach: edge);
    }
    return null;
  }
}

double distanceToDraftingSegment(Offset point, Offset from, Offset to) {
  final span = to - from;
  if (span.distanceSquared == 0) return (point - from).distance;
  final delta = point - from;
  final t = ((delta.dx * span.dx + delta.dy * span.dy) / span.distanceSquared)
      .clamp(0.0, 1.0);
  return (point - (from + span * t)).distance;
}

void paintPartBalloon(
  Canvas canvas, {
  required int number,
  required Offset anchor,
  required Offset center,
  required double reach,
  required double radius,
  required SheetStyle sheet,
}) {
  final direction = (center - anchor) / (center - anchor).distance;
  final ink = Paint()
    ..color = sheet.fineRule
    ..strokeWidth = .65
    ..style = PaintingStyle.stroke;
  canvas.drawLine(anchor + direction * reach, center - direction * radius, ink);
  canvas.drawCircle(center, radius, Paint()..color = sheet.paper);
  canvas.drawCircle(
    center,
    radius,
    ink
      ..color = sheet.ink
      ..strokeWidth = .9,
  );
  paintLettering(
    canvas,
    '$number',
    center,
    size: radius * 1.3,
    color: sheet.ink,
  );
}

void paintDimensionLine(
  Canvas canvas,
  Offset start,
  Offset end,
  SheetStyle sheet,
) {
  final length = (end - start).distance;
  if (length < 1) return;
  final unit = (end - start) / length;
  final arrow = math.min(5.0, length * .25);
  canvas.drawLine(
    start,
    end,
    Paint()
      ..color = sheet.ink
      ..strokeWidth = .65,
  );
  final ink = Paint()..color = sheet.ink;
  for (final (tip, inward) in [(start, unit), (end, -unit)]) {
    final base = tip + inward * arrow;
    final side = Offset(-inward.dy, inward.dx) * (arrow * .33);
    canvas.drawPath(
      Path()..addPolygon([tip, base + side, base - side], true),
      ink,
    );
  }
}

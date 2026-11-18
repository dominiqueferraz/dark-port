import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'placement_nodes.dart';
import 'sheet_style.dart';

void paintPlacementMarks(
  Canvas canvas,
  Iterable<PlacementNode> nodes,
  Offset Function(math.Point<double>) project, {
  required PlacementNode? target,
  required bool valid,
  required double radius,
  required SheetStyle sheet,
}) {
  final mark = Paint()..color = sheet.faint;
  for (final node in nodes) {
    canvas.drawCircle(
      project(node.position),
      node.intersection ? 1 : 1.6,
      mark,
    );
  }
  if (target != null) {
    canvas.drawCircle(
      project(target.position),
      radius,
      Paint()
        ..color = valid ? sheet.ink : sheet.stamp
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

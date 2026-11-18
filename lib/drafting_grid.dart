import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import 'drafting_theme.dart';
import 'sheet_style.dart';

/// Space around a puzzle grid for its row and column labels.
const draftingGridMargins = EdgeInsets.fromLTRB(24, 22, 1, 8);

/// A landscape console supplies both dimensions. In a scrolling console,
/// the available width and the board's aspect ratio determine its height.
class DraftingPlayfield extends StatelessWidget {
  const DraftingPlayfield({
    super.key,
    required this.aspectRatio,
    required this.builder,
    this.aspectInsets = EdgeInsets.zero,
  });

  final double aspectRatio;
  final Widget Function(BuildContext context, Size size) builder;
  final EdgeInsets aspectInsets;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(
        constraints.maxWidth,
        constraints.hasBoundedHeight
            ? constraints.maxHeight
            : (constraints.maxWidth - aspectInsets.horizontal).clamp(
                        0.0,
                        constraints.maxWidth,
                      ) /
                      aspectRatio +
                  aspectInsets.vertical,
      );
      return SizedBox.fromSize(size: size, child: builder(context, size));
    },
  );
}

void paintHatchedBarrier(Canvas canvas, Rect rect, SheetStyle sheet) {
  canvas.drawRect(rect, Paint()..color = sheet.paper);
  canvas.save();
  canvas.clipRect(rect);
  final line = Paint()
    ..color = sheet.fineRule
    ..strokeWidth = .6;
  for (var x = rect.left - rect.height; x < rect.right; x += 5) {
    canvas.drawLine(
      Offset(x, rect.bottom),
      Offset(x + rect.height, rect.top),
      line,
    );
  }
  canvas.restore();
  canvas.drawRect(
    rect,
    line
      ..color = sheet.ink
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke,
  );
}

void paintDraftingGrid(
  Canvas canvas, {
  required Rect grid,
  required Size tile,
  required int columns,
  required int rows,
  required SheetStyle sheet,
  required double size,
}) {
  final dots = <Offset>[];
  for (var column = 1; column < columns; column++) {
    final x = grid.left + column * tile.width;
    for (var y = grid.top + 2; y < grid.bottom; y += 4) {
      dots.add(Offset(x, y));
    }
  }
  for (var row = 1; row <= rows; row++) {
    final y = grid.bottom - row * tile.height;
    if (y <= grid.top + 1) continue;
    for (var x = grid.left + 2; x < grid.right; x += 4) {
      dots.add(Offset(x, y));
    }
  }
  canvas.drawPoints(
    PointMode.points,
    dots,
    Paint()
      ..color = sheet.grid
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawRect(
    grid,
    Paint()
      ..color = sheet.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4,
  );
  for (var i = 0; i < columns; i++) {
    paintLettering(
      canvas,
      String.fromCharCode(65 + i),
      Offset(grid.left + (i + .5) * tile.width, grid.top - size * .95),
      size: size,
      color: sheet.faint,
    );
  }
  for (var i = 0; i < rows; i++) {
    paintLettering(
      canvas,
      '${i + 1}',
      Offset(
        grid.left - size * .9,
        grid.bottom - (rows - i - .5) * tile.height,
      ),
      size: size,
      color: sheet.faint,
    );
  }
}

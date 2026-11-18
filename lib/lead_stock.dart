import 'package:flutter/material.dart';

import 'sheet_style.dart';
import 'signal_board.dart';

class LeadStock extends StatelessWidget {
  const LeadStock({
    super.key,
    required this.type,
    required this.total,
    required this.installed,
  });

  final LeadType type;
  final int total;
  final int installed;

  @override
  Widget build(BuildContext context) {
    final available = total - installed;
    return Semantics(
      label: '${type.label}s',
      value: '$available of $total available',
      liveRegion: true,
      child: Tooltip(
        message: '$available of $total ${type.label.toLowerCase()}s available',
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var index = 0; index < total; index++)
                LeadSymbol(type: type, available: index < available),
            ],
          ),
        ),
      ),
    );
  }
}

class LeadSymbol extends StatelessWidget {
  const LeadSymbol({super.key, required this.type, this.available = true});

  final LeadType type;
  final bool available;

  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: CustomPaint(
      size: const Size(24, 16),
      painter: _LeadDrawing(type, available, context.sheet),
    ),
  );
}

class _LeadDrawing extends CustomPainter {
  const _LeadDrawing(this.type, this.available, this.sheet);

  final LeadType type;
  final bool available;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    final first = Offset(3, size.height - 4);
    final last = Offset(size.width - 3, 4);
    final stroke = Paint()
      ..color = available ? sheet.ink : sheet.faint
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawCord(Path cord) {
      if (available) {
        canvas.drawPath(cord, stroke);
      } else {
        final line = cord.computeMetrics().single;
        for (var start = 0.0; start < line.length; start += 4) {
          canvas.drawPath(line.extractPath(start, start + 1.5), stroke);
        }
      }
    }

    if (type == LeadType.trunk) {
      for (final offset in const [Offset(0, -1.25), Offset(0, 1.25)]) {
        drawCord(Path()..addPolygon([first + offset, last + offset], false));
      }
      for (final terminal in [first, last]) {
        canvas.drawRect(
          Rect.fromCenter(center: terminal, width: 4, height: 4),
          stroke..style = available ? PaintingStyle.fill : PaintingStyle.stroke,
        );
      }
      return;
    }

    final cord = Path()
      ..moveTo(first.dx, first.dy)
      ..cubicTo(
        size.width * .72,
        first.dy,
        size.width * .28,
        last.dy,
        last.dx,
        last.dy,
      );
    drawCord(cord);
    if (type == LeadType.shielded) {
      final path = cord.computeMetrics().single;
      final sleeve = path.getTangentForOffset(path.length / 2)!;
      canvas.save();
      canvas.translate(sleeve.position.dx, sleeve.position.dy);
      canvas.rotate(sleeve.vector.direction);
      final band = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3.6, -2.4, 7.2, 4.8),
        const Radius.circular(1),
      );
      canvas.drawRRect(band, Paint()..color = sheet.paper);
      canvas.drawRRect(band, stroke);
      canvas.restore();
    }
    stroke.style = available ? PaintingStyle.fill : PaintingStyle.stroke;
    canvas.drawCircle(first, 1.65, stroke);
    canvas.drawCircle(last, 1.65, stroke);
  }

  @override
  bool shouldRepaint(_LeadDrawing oldDelegate) =>
      type != oldDelegate.type ||
      available != oldDelegate.available ||
      sheet != oldDelegate.sheet;
}

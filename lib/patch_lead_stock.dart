import 'package:flutter/material.dart';

import 'drafting_theme.dart';
import 'sheet_style.dart';

class PatchLeadStock extends StatelessWidget {
  const PatchLeadStock({
    super.key,
    required this.total,
    required this.installed,
  });

  final int total;
  final int installed;

  @override
  Widget build(BuildContext context) {
    final available = total - installed;
    final sheet = context.sheet;
    return Semantics(
      label: 'Patch leads',
      value: '$available of $total available',
      liveRegion: true,
      child: Tooltip(
        message: '$available of $total patch leads available',
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text('Patch leads', style: draftingLettering(12, spacing: .3)),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (var index = 0; index < total; index++)
                      CustomPaint(
                        size: const Size(18, 14),
                        painter: _LeadSymbol(
                          available: index < available,
                          ink: index < available ? sheet.ink : sheet.faint,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadSymbol extends CustomPainter {
  const _LeadSymbol({required this.available, required this.ink});

  final bool available;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final first = Offset(2.5, size.height - 3.5);
    final last = Offset(size.width - 2.5, 3.5);
    final stroke = Paint()
      ..color = ink
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cable = Path()
      ..moveTo(first.dx, first.dy)
      ..cubicTo(
        size.width * .7,
        first.dy,
        size.width * .3,
        last.dy,
        last.dx,
        last.dy,
      );
    if (available) {
      canvas.drawPath(cable, stroke);
      stroke.style = PaintingStyle.fill;
    } else {
      final line = cable.computeMetrics().single;
      for (var start = 2.0; start < line.length - 2; start += 4) {
        canvas.drawPath(line.extractPath(start, start + 1), stroke);
      }
    }
    canvas.drawCircle(first, 1.65, stroke);
    canvas.drawCircle(last, 1.65, stroke);
  }

  @override
  bool shouldRepaint(_LeadSymbol oldDelegate) =>
      available != oldDelegate.available || ink != oldDelegate.ink;
}

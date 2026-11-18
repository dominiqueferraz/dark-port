import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sheet_style.dart';

/// Drawing lettering. Without a color it inherits the sheet's ink.
TextStyle draftingLettering(
  double size, {
  Color? color,
  double spacing = 1.1,
}) => TextStyle(
  fontFamily: 'DINish Condensed',
  fontFamilyFallback: const ['monospace'],
  fontSize: size,
  fontWeight: FontWeight.w400,
  letterSpacing: spacing,
  height: 1.2,
  color: color,
);

/// The style's paper behind [child], with its ink as the text colour.
class DraftingPaper extends StatelessWidget {
  const DraftingPaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheet = context.sheet;
    return SheetBackground(
      style: sheet,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: sheet.ink),
        child: IconTheme.merge(
          data: IconThemeData(color: sheet.ink),
          child: child,
        ),
      ),
    );
  }
}

/// A drawing-sheet border: a thin trim line around a heavy frame line.
class DraftingSheetFrame extends CustomPainter {
  const DraftingSheetFrame(this.ink, {required this.trim});

  final Color ink;
  final Color trim;

  static const inset = EdgeInsets.all(9);

  /// Inner edge of the heavy frame line, measured from the sheet's edge.
  static const frameEdge = 5.8;

  /// Paper kept clear on each side of the info panel in a lesson sheet:
  /// between the drawing and the panel, and between the panel and frame.
  static const panelGap = 14.0;

  /// Space between the heavy frame line and a sheet's contents.
  static const contentPadding = EdgeInsets.fromLTRB(
    13,
    13,
    frameEdge + panelGap,
    13,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds.deflate(.5),
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6,
    );
    canvas.drawRect(
      bounds.deflate(frameEdge - .8),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(DraftingSheetFrame oldDelegate) =>
      ink != oldDelegate.ink || trim != oldDelegate.trim;
}

/// A whole screen drawn as one sheet inside a frame.
class DraftingSheet extends StatelessWidget {
  const DraftingSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
    child: CustomPaint(
      painter: DraftingSheetFrame(
        context.sheet.ink,
        trim: context.sheet.fineRule,
      ),
      child: Padding(padding: DraftingSheetFrame.contentPadding, child: child),
    ),
  );
}

/// A ruled line between toolbar cells.
class DraftingCellDivider extends StatelessWidget {
  const DraftingCellDivider({super.key, this.width = .9});

  final double width;

  @override
  Widget build(BuildContext context) => VerticalDivider(
    width: width,
    thickness: width,
    color: context.sheet.fineRule,
  );
}

/// Paints [text] centred on [center] in drawing lettering.
void paintLettering(
  Canvas canvas,
  String text,
  Offset center, {
  double size = 10,
  required Color color,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: draftingLettering(size, color: color, spacing: .4),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - painter.size.center(Offset.zero));
  painter.dispose();
}

/// The lesson's title block, stamped once the drawing is approved.
class DraftingTitleBlock extends StatelessWidget {
  const DraftingTitleBlock({
    super.key,
    required this.title,
    required this.sheet,
    required this.approved,
  });

  final String title;
  final String sheet;
  final bool approved;

  Widget _cell(
    BuildContext context,
    String? label,
    String value, {
    double size = 11,
    double spacing = 1.1,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
    // Narrow panels shrink the lettering rather than cutting it off.
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            if (label != null)
              TextSpan(
                text: '$label ',
                style: draftingLettering(8, color: context.sheet.faint),
              ),
            TextSpan(
              text: value,
              style: draftingLettering(
                size,
                color: context.sheet.ink,
                spacing: spacing,
              ),
            ),
          ],
        ),
        maxLines: 1,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ink = context.sheet.ink;
    return Semantics(
      container: true,
      label: 'Sheet $sheet${approved ? ', approved' : ''}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: ink, width: 1.6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cell(
              context,
              'TITLE',
              title.toUpperCase(),
              size: 13,
              spacing: 1.5,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.sheet.fineRule, width: .7),
                ),
              ),
              child: SizedBox(
                height: 22,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 4, child: _cell(context, 'SHEET', sheet)),
                    const DraftingCellDivider(width: .7),
                    Expanded(
                      flex: 3,
                      child: _cell(context, 'REV', approved ? 'B' : 'A'),
                    ),
                    const DraftingCellDivider(width: .7),
                    Expanded(
                      flex: 5,
                      child: approved
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _ApprovedStamp(),
                              ),
                            )
                          : _cell(context, null, 'IN PROGRESS'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovedStamp extends StatelessWidget {
  const _ApprovedStamp();

  @override
  Widget build(BuildContext context) {
    final stamp = context.sheet.stamp;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .65, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, scale, child) => Opacity(
        opacity: ((scale - .65) / .35).clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      ),
      // Leave room for the rotated corners inside the status cell.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
        child: Transform.rotate(
          angle: -4 * math.pi / 180,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(border: Border.all(color: stamp)),
            child: Text(
              'APPROVED',
              style: draftingLettering(9.5, color: stamp, spacing: .8),
            ),
          ),
        ),
      ),
    );
  }
}

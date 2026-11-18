import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import 'drafting_controls.dart';
import 'drafting_theme.dart';
import 'optical_bay.dart';
import 'part_symbols.dart';
import 'sheet_style.dart';

/// Lets the player pick the sheet style and the signs used for parts.
/// Each option is previewed with the real drawing code.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final look = SheetLook.of(context);
    final change = SheetLook.changerOf(context);
    return DraftingScaffold(
      child: DraftingSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConsoleHeader(
              title: 'SETTINGS',
              caption: 'DRAWING STANDARDS',
              backLabel: 'Back',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel('STYLE'),
                    _OptionRow(
                      children: [
                        for (final style in SheetStyle.all)
                          _OptionCard(
                            label: style.name,
                            selected: style == look.style,
                            onTap: change == null
                                ? null
                                : () => change(look.copyWith(style: style)),
                            preview: SheetBackground(
                              style: style,
                              child: CustomPaint(
                                painter: _SheetPreview(style, look.symbols),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel('PART SYMBOLS'),
                    _OptionRow(
                      children: [
                        for (final symbols in PartSymbols.all)
                          _OptionCard(
                            label: symbols.name,
                            detail: symbols.description,
                            selected: symbols == look.symbols,
                            onTap: change == null
                                ? null
                                : () => change(look.copyWith(symbols: symbols)),
                            preview: SheetBackground(
                              style: look.style,
                              child: CustomPaint(
                                painter: _SymbolsPreview(look.style, symbols),
                              ),
                            ),
                          ),
                      ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: draftingLettering(10, color: context.sheet.faint, spacing: 1.6),
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [for (final child in children) Expanded(child: child)],
    ),
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.preview,
    this.detail,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback? onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final sheet = context.sheet;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      hint: detail,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? sheet.beam : sheet.ink,
                width: selected ? 2 : .9,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRect(
                    child: SizedBox(
                      width: double.infinity,
                      height: 72,
                      child: preview,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: draftingLettering(
                            11,
                            color: selected ? sheet.beam : sheet.ink,
                            spacing: 1,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check, size: 14, color: sheet.beam),
                    ],
                  ),
                  if (detail case final detail?)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        detail,
                        style: draftingLettering(
                          9,
                          color: sheet.faint,
                          spacing: .3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A corner of a drawing in [style]: frame, grid, a beam turned by a part.
class _SheetPreview extends CustomPainter {
  const _SheetPreview(this.style, this.symbols);

  final SheetStyle style;
  final PartSymbols symbols;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = (Offset.zero & size).deflate(6);
    final grid = Paint()
      ..color = style.grid
      ..strokeWidth = 1;
    for (var x = frame.left + 12; x < frame.right; x += 12) {
      for (var y = frame.top + 4; y < frame.bottom; y += 4) {
        canvas.drawPoints(PointMode.points, [Offset(x, y)], grid);
      }
    }
    canvas.drawRect(
      frame,
      Paint()
        ..color = style.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final turn = Offset(frame.left + frame.width * .35, frame.center.dy);
    canvas.drawPath(
      Path()
        ..moveTo(turn.dx, frame.bottom - 8)
        ..lineTo(turn.dx, turn.dy)
        ..lineTo(frame.right - 10, turn.dy),
      Paint()
        ..color = style.beam
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    symbols.paintOptic(
      canvas,
      OpticGlyph(
        center: turn,
        radius: 10,
        kind: OpticKind.mirror,
        turned: false,
        fixed: false,
      ),
      style,
    );
  }

  @override
  bool shouldRepaint(_SheetPreview oldDelegate) =>
      style != oldDelegate.style || symbols != oldDelegate.symbols;
}

/// The parts drawn with [symbols]: loose and bolted mirrors, a splitter,
/// a laser and a lit receiver.
class _SymbolsPreview extends CustomPainter {
  const _SymbolsPreview(this.style, this.symbols);

  final SheetStyle style;
  final PartSymbols symbols;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 5;
    final y = size.height / 2;
    final radius = (step * .28).clamp(6.0, 11.0);
    for (final (index, (kind, fixed)) in const [
      (OpticKind.mirror, false),
      (OpticKind.mirror, true),
      (OpticKind.splitter, false),
    ].indexed) {
      symbols.paintOptic(
        canvas,
        OpticGlyph(
          center: Offset(step * (index + .5), y - 4),
          radius: radius,
          kind: kind,
          turned: false,
          fixed: fixed,
        ),
        style,
      );
    }
    final box = Size.square(radius * 2.8);
    for (final (index, receiver) in const [false, true].indexed) {
      canvas.save();
      canvas.translate(
        step * (index + 3.5) - box.width / 2,
        y - 4 - box.height / 2,
      );
      if (receiver) {
        symbols.paintReceiver(canvas, box, style, lit: true, alarm: false);
      } else {
        symbols.paintSource(canvas, box, style);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SymbolsPreview oldDelegate) =>
      style != oldDelegate.style || symbols != oldDelegate.symbols;
}

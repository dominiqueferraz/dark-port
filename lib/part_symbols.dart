import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'optical_bay.dart';
import 'sheet_style.dart';

/// One optic as the drawing needs to show it.
class OpticGlyph {
  const OpticGlyph({
    required this.center,
    required this.radius,
    required this.kind,
    required this.turned,
    required this.fixed,
    this.opacity = 1,
  });

  final Offset center;
  final double radius;
  final OpticKind kind;
  final bool turned;
  final bool fixed;
  final double opacity;

  /// Half the reflecting face, from the centre toward one end.
  Offset get face => Offset(radius * .62, radius * (turned ? .62 : -.62));
}

/// A set of signs for the parts on a drawing. Every set draws the same
/// parts from the same information, so sets can be swapped freely.
///
/// Endpoint symbols are drawn in a square box with the beam travelling
/// along +x: a source sends it out of the +x side, and a receiver takes it
/// in from the -x side with its back wall at +0.22 of the box and its
/// target at +0.07.
abstract class PartSymbols {
  const PartSymbols();

  String get id;
  String get name;

  /// One line on what sets these signs apart.
  String get description;

  void paintOptic(Canvas canvas, OpticGlyph optic, SheetStyle style);
  void paintSource(Canvas canvas, Size size, SheetStyle style);
  void paintReceiver(
    Canvas canvas,
    Size size,
    SheetStyle style, {
    required bool lit,
    required bool alarm,
  });

  /// Draws the mounting plate for a wired part and returns its marking color.
  /// The caller draws jacks in board coordinates so they stay aligned with
  /// the cables and touch targets across all symbol sets.
  Color paintWiredPlate(
    Canvas canvas,
    Rect bounds,
    SheetStyle style, {
    required bool fixed,
    required Color rim,
  });

  static const drafting = DraftingSymbols();
  static const schematic = SchematicSymbols();
  static const pictogram = PictogramSymbols();
  static const all = [drafting, schematic, pictogram];
  static const fallback = drafting;

  static PartSymbols byId(String? id) =>
      all.firstWhere((symbols) => symbols.id == id, orElse: () => fallback);
}

/// An optical symbol drawn with the current sheet and symbol choices.
class OpticalPartSymbol extends StatelessWidget {
  const OpticalPartSymbol.source({super.key})
    : kind = null,
      receiver = false,
      turned = false,
      fixed = false,
      lit = false,
      alarm = false;

  const OpticalPartSymbol.receiver({
    super.key,
    this.lit = false,
    this.alarm = false,
  }) : kind = null,
       receiver = true,
       turned = false,
       fixed = false;

  const OpticalPartSymbol.optic(
    OpticKind this.kind, {
    super.key,
    this.turned = false,
    this.fixed = false,
  }) : receiver = false,
       lit = false,
       alarm = false;

  final OpticKind? kind;
  final bool receiver;
  final bool turned;
  final bool fixed;
  final bool lit;
  final bool alarm;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _OpticalPartPainter(this, SheetLook.of(context)));
}

class _OpticalPartPainter extends CustomPainter {
  const _OpticalPartPainter(this.part, this.look);

  final OpticalPartSymbol part;
  final SheetLookChoice look;

  @override
  void paint(Canvas canvas, Size size) {
    final symbols = look.symbols;
    final style = look.style;
    if (part.kind case final kind?) {
      symbols.paintOptic(
        canvas,
        OpticGlyph(
          center: size.center(Offset.zero),
          radius: (size.shortestSide * .32).clamp(0.0, 12.0),
          kind: kind,
          turned: part.turned,
          fixed: part.fixed,
        ),
        style,
      );
    } else if (part.receiver) {
      symbols.paintReceiver(
        canvas,
        size,
        style,
        lit: part.lit,
        alarm: part.alarm,
      );
    } else {
      symbols.paintSource(canvas, size, style);
    }
  }

  @override
  bool shouldRepaint(_OpticalPartPainter oldDelegate) =>
      part != oldDelegate.part || look != oldDelegate.look;
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..isAntiAlias = true
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round;

Paint _fill(Color color) => Paint()
  ..color = color
  ..isAntiAlias = true;

void _paintPins(Canvas canvas, Rect bounds, Paint paint, double radius) {
  for (final corner in [
    bounds.topLeft,
    bounds.topRight,
    bounds.bottomLeft,
    bounds.bottomRight,
  ]) {
    canvas.drawCircle(corner, radius, paint);
  }
}

Color _faded(Color color, double opacity) =>
    color.withValues(alpha: color.a * opacity);

/// Round mirrors, travel rings for loose optics, and bolted mounting plates.
class DraftingSymbols extends PartSymbols {
  const DraftingSymbols();

  /// Laser casing in units of its symbol size, with the beam leaving to +x.
  static const sourceCasing = Rect.fromLTRB(-.3, -.2, .18, .2);

  @override
  String get id => 'drafting';
  @override
  String get name => 'Drafting';
  @override
  String get description => 'Round mirrors and bolted mounting plates';

  @override
  Color paintWiredPlate(
    Canvas canvas,
    Rect bounds,
    SheetStyle style, {
    required bool fixed,
    required Color rim,
  }) {
    final plate = Path();
    if (fixed) {
      plate.addRect(bounds);
    } else {
      plate.addOval(bounds);
    }
    canvas.drawPath(plate, _fill(style.paper));
    canvas.drawPath(plate, _stroke(rim, 1.5));
    if (fixed) {
      _paintPins(canvas, bounds.deflate(3.5), _stroke(rim, 1), 1.25);
    }
    return style.ink;
  }

  @override
  void paintOptic(Canvas canvas, OpticGlyph optic, SheetStyle style) {
    final center = optic.center;
    final radius = optic.radius;
    final ink = _faded(style.ink, optic.opacity);
    if (optic.fixed && optic.kind != OpticKind.mirror) {
      final base = Rect.fromCircle(center: center, radius: radius);
      canvas.drawRect(base, _fill(style.paper));
      canvas.drawRect(base, _stroke(ink, 1.2));
      final bolt = _stroke(ink, .7);
      for (final corner in const [
        Offset(-1, -1),
        Offset(1, -1),
        Offset(1, 1),
        Offset(-1, 1),
      ]) {
        final p = center + corner * (radius * .76);
        canvas.drawCircle(p, radius * .13, bolt);
        canvas.drawLine(
          p - Offset(radius * .13, 0),
          p + Offset(radius * .13, 0),
          bolt,
        );
      }
    } else {
      canvas.drawCircle(center, radius, _fill(style.paper));
      canvas.drawCircle(center, radius, _stroke(ink, .9));
      if (!optic.fixed) {
        final ring = Rect.fromCircle(center: center, radius: radius + 3.5);
        const dashes = 16;
        for (var i = 0; i < dashes; i++) {
          canvas.drawArc(
            ring,
            i * 2 * math.pi / dashes,
            math.pi / dashes,
            false,
            _stroke(ink, .9),
          );
        }
      }
    }
    final face = optic.kind == OpticKind.mirror ? optic.face * 1.1 : optic.face;
    if (optic.kind == OpticKind.splitter) {
      final other = Offset(face.dx, -face.dy);
      canvas.drawPath(
        Path()..addPolygon([
          center - face,
          center + other,
          center + face,
          center - other,
        ], true),
        _stroke(ink, .8),
      );
    }
    canvas.drawLine(center - face, center + face, _stroke(ink, 2.2));
  }

  @override
  void paintSource(Canvas canvas, Size size, SheetStyle style) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final body = Rect.fromLTRB(
      c.dx + s * sourceCasing.left,
      c.dy + s * sourceCasing.top,
      c.dx + s * sourceCasing.right,
      c.dy + s * sourceCasing.bottom,
    );
    canvas.drawRect(body, _fill(style.paper));
    canvas.drawRect(body, _stroke(style.ink, 1.3));
    canvas.drawLine(
      Offset(body.right - s * .1, body.top),
      Offset(body.right - s * .1, body.bottom),
      _stroke(style.ink, .7),
    );
    canvas.drawCircle(
      Offset(c.dx - s * .08, c.dy),
      s * .06,
      _stroke(style.ink, .7),
    );
  }

  @override
  void paintReceiver(
    Canvas canvas,
    Size size,
    SheetStyle style, {
    required bool lit,
    required bool alarm,
  }) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final box = Rect.fromLTRB(
      c.dx - s * .1,
      c.dy - s * .24,
      c.dx + s * .22,
      c.dy + s * .24,
    );
    canvas.drawRect(box, _fill(style.paper));
    canvas.drawPath(
      Path()
        ..moveTo(box.left, box.top)
        ..lineTo(box.right, box.top)
        ..lineTo(box.right, box.bottom)
        ..lineTo(box.left, box.bottom),
      _stroke(style.ink, 1.3),
    );
    if (alarm) {
      canvas.drawLine(box.topRight, box.bottomLeft, _stroke(style.ink, .6));
    }
    _target(canvas, Offset(c.dx + s * .07, c.dy), s * .08, style, lit, alarm);
  }
}

void _target(
  Canvas canvas,
  Offset center,
  double radius,
  SheetStyle style,
  bool lit,
  bool alarm,
) {
  final color = alarm ? style.alarmBeam : style.beam;
  canvas.drawCircle(center, radius, _fill(lit ? color : style.paper));
  canvas.drawCircle(center, radius, _stroke(lit ? color : style.ink, 1));
}

/// Optics-diagram signs: mirrors as hatched slabs, splitters as cubes,
/// a pivot on loose parts and a ground mount under bolted ones.
class SchematicSymbols extends PartSymbols {
  const SchematicSymbols();

  @override
  String get id => 'schematic';
  @override
  String get name => 'Schematic';
  @override
  String get description => 'Optics diagram: slabs, cubes and mounts';

  @override
  Color paintWiredPlate(
    Canvas canvas,
    Rect bounds,
    SheetStyle style, {
    required bool fixed,
    required Color rim,
  }) {
    final plate = bounds.deflate(2);
    final body = fixed
        ? Rect.fromLTRB(plate.left, plate.top, plate.right, plate.bottom - 3)
        : plate;
    canvas.drawRect(body, _fill(style.paper));
    canvas.drawRect(body, _stroke(rim, 1.5));
    if (fixed) {
      final y = body.bottom + 3;
      canvas.drawLine(body.bottomCenter, Offset(0, y), _stroke(rim, 1.3));
      canvas.drawLine(Offset(-11, y), Offset(11, y), _stroke(rim, 1.3));
      for (final x in [-7.0, 0.0, 7.0]) {
        canvas.drawLine(Offset(x, y), Offset(x - 3, y + 3), _stroke(rim, 1));
      }
    } else {
      final pivot = plate.topCenter + const Offset(0, -2);
      canvas.drawCircle(pivot, 2.4, _fill(style.paper));
      canvas.drawCircle(pivot, 2.4, _stroke(rim, 1.2));
    }
    return style.ink;
  }

  @override
  void paintOptic(Canvas canvas, OpticGlyph optic, SheetStyle style) {
    final center = optic.center;
    final r = optic.radius;
    final ink = _faded(style.ink, optic.opacity);
    final face = optic.face / .62 * .68;
    if (optic.kind == OpticKind.splitter) {
      final cube = Rect.fromCircle(center: center, radius: r * .72);
      canvas.drawRect(cube, _fill(style.paper));
      canvas.drawRect(cube, _stroke(ink, 1.1));
      final inner = optic.face / .62 * .72;
      canvas.drawLine(center - inner, center + inner, _stroke(ink, 1.6));
    } else {
      // A slab along the face, hatched to read as glass on a backing.
      final along = face / face.distance;
      final across = Offset(-along.dy, along.dx) * (r * .14);
      final corners = [
        center - face - across,
        center + face - across,
        center + face + across,
        center - face + across,
      ];
      final slab = Path()..addPolygon(corners, true);
      canvas.drawPath(slab, _fill(style.paper));
      canvas.save();
      canvas.clipPath(slab);
      for (var t = -1.0; t <= 1.0; t += .25) {
        final p = center + face * t;
        canvas.drawLine(
          p - across * 1.2 - along * (r * .12),
          p + across * 1.2 + along * (r * .12),
          _stroke(ink, .75),
        );
      }
      canvas.restore();
      canvas.drawPath(slab, _stroke(ink, 1.25));
    }
    if (optic.fixed) {
      // Ground mount: a base line with hatching below it.
      final y = center.dy + r * 1.08;
      final half = r * .8;
      canvas.drawLine(
        Offset(center.dx, center.dy + r * .72),
        Offset(center.dx, y),
        _stroke(ink, 1),
      );
      canvas.drawLine(
        Offset(center.dx - half, y),
        Offset(center.dx + half, y),
        _stroke(ink, 1.3),
      );
      for (var x = -half + r * .2; x <= half; x += r * .32) {
        canvas.drawLine(
          Offset(center.dx + x, y),
          Offset(center.dx + x - r * .22, y + r * .24),
          _stroke(ink, .7),
        );
      }
    } else {
      // A pivot: loose parts turn about their centre.
      canvas.drawCircle(center, r * .17, _fill(style.paper));
      canvas.drawCircle(center, r * .17, _stroke(ink, 1));
      final reach = r * 1.12;
      for (final start in [-math.pi * .9, math.pi * .1]) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: reach),
          start,
          math.pi * .45,
          false,
          _stroke(ink, .7),
        );
      }
    }
  }

  @override
  void paintSource(Canvas canvas, Size size, SheetStyle style) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final body = Rect.fromLTRB(
      c.dx - s * .32,
      c.dy - s * .16,
      c.dx + s * .1,
      c.dy + s * .16,
    );
    canvas.drawRect(body, _fill(style.paper));
    canvas.drawRect(body, _stroke(style.ink, 1.2));
    // A zig-zag for the lasing medium and an aperture on the beam side.
    final zig = Path()..moveTo(body.left + s * .05, c.dy);
    for (var i = 1; i <= 4; i++) {
      zig.lineTo(
        body.left + s * .05 + i * s * .07,
        c.dy + (i.isOdd ? -1 : 1) * s * .08,
      );
    }
    canvas.drawPath(zig, _stroke(style.ink, .8));
    canvas.drawPath(
      Path()
        ..moveTo(body.right, c.dy - s * .09)
        ..lineTo(body.right + s * .1, c.dy)
        ..lineTo(body.right, c.dy + s * .09)
        ..close(),
      _fill(style.ink),
    );
  }

  @override
  void paintReceiver(
    Canvas canvas,
    Size size,
    SheetStyle style, {
    required bool lit,
    required bool alarm,
  }) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final back = c.dx + s * .22;
    final radius = s * .24;
    // A detector: a flat back with a dome facing the beam.
    final dome = Path()
      ..moveTo(back, c.dy - radius)
      ..arcTo(
        Rect.fromCircle(center: Offset(back, c.dy), radius: radius),
        -math.pi / 2,
        -math.pi,
        false,
      )
      ..close();
    canvas.drawPath(dome, _fill(style.paper));
    canvas.drawPath(dome, _stroke(style.ink, 1.2));
    if (alarm) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(back, c.dy), radius: radius * .72),
        math.pi / 2,
        math.pi,
        false,
        _stroke(style.ink, .6),
      );
    }
    _target(canvas, Offset(c.dx + s * .07, c.dy), s * .07, style, lit, alarm);
  }
}

/// Bold filled icons: loose parts are ink discs, bolted parts ink squares
/// with pins, each with the reflecting face cut out.
class PictogramSymbols extends PartSymbols {
  const PictogramSymbols();

  @override
  String get id => 'pictogram';
  @override
  String get name => 'Pictogram';
  @override
  String get description => 'Solid discs and pinned squares';

  @override
  Color paintWiredPlate(
    Canvas canvas,
    Rect bounds,
    SheetStyle style, {
    required bool fixed,
    required Color rim,
  }) {
    final plate = Path();
    if (fixed) {
      plate.addRRect(RRect.fromRectAndRadius(bounds, const Radius.circular(3)));
    } else {
      plate.addOval(bounds);
    }
    canvas.drawPath(plate, _fill(style.ink));
    if (rim != style.ink) {
      canvas.drawPath(plate, _stroke(rim, 2.7));
    }
    if (fixed) {
      _paintPins(canvas, bounds.deflate(3.5), _fill(style.paper), 1.35);
    }
    return style.paper;
  }

  @override
  void paintOptic(Canvas canvas, OpticGlyph optic, SheetStyle style) {
    final center = optic.center;
    final r = optic.radius;
    final ink = _faded(style.ink, optic.opacity);
    final paper = _faded(style.paper, optic.opacity);
    if (optic.fixed) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: center, radius: r),
          Radius.circular(r * .18),
        ),
        _fill(ink),
      );
      for (final corner in const [
        Offset(-1, -1),
        Offset(1, -1),
        Offset(1, 1),
        Offset(-1, 1),
      ]) {
        canvas.drawCircle(center + corner * (r * .7), r * .12, _fill(paper));
      }
    } else {
      canvas.drawCircle(center, r, _fill(ink));
    }
    final face = optic.face;
    if (optic.kind == OpticKind.splitter) {
      final other = Offset(face.dx, -face.dy);
      canvas.drawPath(
        Path()..addPolygon([
          center - face,
          center + other,
          center + face,
          center - other,
        ], true),
        _stroke(paper, 1),
      );
    }
    canvas.drawLine(center - face, center + face, _stroke(paper, 2.6));
  }

  @override
  void paintSource(Canvas canvas, Size size, SheetStyle style) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          c.dx - s * .3,
          c.dy - s * .18,
          c.dx + s * .16,
          c.dy + s * .18,
        ),
        Radius.circular(s * .05),
      ),
      _fill(style.ink),
    );
    canvas.drawCircle(Offset(c.dx + s * .06, c.dy), s * .06, _fill(style.beam));
  }

  @override
  void paintReceiver(
    Canvas canvas,
    Size size,
    SheetStyle style, {
    required bool lit,
    required bool alarm,
  }) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final outer = Rect.fromLTRB(
      c.dx - s * .1,
      c.dy - s * .25,
      c.dx + s * .22,
      c.dy + s * .25,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, Radius.circular(s * .05)),
      _fill(style.ink),
    );
    // The cup is open toward the beam.
    canvas.drawRect(
      Rect.fromLTRB(outer.left, c.dy - s * .15, c.dx + s * .14, c.dy + s * .15),
      _fill(style.paper),
    );
    if (alarm) {
      canvas.drawRect(
        Rect.fromLTRB(
          outer.right - s * .05,
          outer.top,
          outer.right,
          outer.bottom,
        ),
        _fill(style.alarmBeam),
      );
    }
    _target(canvas, Offset(c.dx + s * .05, c.dy), s * .07, style, lit, alarm);
  }
}

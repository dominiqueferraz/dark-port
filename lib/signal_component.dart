import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'part_symbols.dart';
import 'sheet_style.dart';
import 'signal_board.dart';

class SignalComponent extends StatelessWidget {
  const SignalComponent({
    super.key,
    required this.device,
    this.highlighted = false,
    this.flipped = false,
    this.poweredPorts = const {},
  });

  final SignalDevice device;
  final bool highlighted;
  final bool flipped;
  final Map<({bool output, int index}), Color> poweredPorts;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ComponentDrawing(
      device: device,
      highlighted: highlighted,
      flipped: flipped,
      poweredPorts: poweredPorts,
      sheet: context.sheet,
      symbols: context.symbols,
    ),
  );
}

class _ComponentDrawing extends CustomPainter {
  const _ComponentDrawing({
    required this.device,
    required this.highlighted,
    required this.flipped,
    required this.poweredPorts,
    required this.sheet,
    required this.symbols,
  });

  final SignalDevice device;
  final bool highlighted;
  final bool flipped;
  final Map<({bool output, int index}), Color> poweredPorts;
  final SheetStyle sheet;
  final PartSymbols symbols;

  @override
  void paint(Canvas canvas, Size size) {
    const unit = .012;
    final scale = size.shortestSide / SignalBoard.partSize * unit;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(flipped ? -scale : scale, scale);

    final plate = Rect.fromCenter(
      center: Offset.zero,
      width: device.kind == SignalDeviceKind.transmitter ? 34 : 45,
      height: 28,
    );
    final ports = [
      for (var index = 0; index < device.inputs; index++)
        (
          point: SignalBoard.inputPort(index),
          vertical: false,
          id: (output: false, index: index),
        ),
      for (var index = 0; index < device.outputs; index++)
        (
          point: SignalBoard.outputPort(index),
          vertical: SignalBoard.outputDirection(index).y != 0,
          id: (output: true, index: index),
        ),
    ];
    final rim = highlighted ? sheet.beam : sheet.ink;
    final lead = Paint()
      ..color = rim
      ..isAntiAlias = true
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;

    Offset jack(SignalPoint point) => Offset(
      point.x * size.width / (SignalBoard.partSize * scale),
      point.y * size.height / (SignalBoard.partSize * scale),
    );

    for (final port in ports) {
      final end = jack(port.point);
      if (port.vertical) {
        final shoulder = Offset(10, end.dy.sign * 8);
        canvas.drawPath(
          Path()..addPolygon([
            shoulder,
            Offset(end.dx, end.dy.sign * 19),
            end,
          ], false),
          lead,
        );
      } else {
        canvas.drawPath(
          Path()..addPolygon([
            Offset(end.dx.sign * 10, end.dy * .48),
            Offset(end.dx.sign * 23, end.dy),
            end,
          ], false),
          lead,
        );
      }
    }

    final glyph = symbols.paintWiredPlate(
      canvas,
      plate,
      sheet,
      fixed: device.fixed,
      rim: rim,
    );
    final marking = Paint()
      ..color = glyph
      ..isAntiAlias = true
      ..strokeWidth = 2.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (device.kind) {
      case SignalDeviceKind.transmitter:
        canvas.drawCircle(Offset.zero, 8, marking);
        canvas.drawCircle(Offset.zero, 2.6, Paint()..color = glyph);
      case SignalDeviceKind.splitter:
        final rows = switch (device.outputs) {
          2 => const [-4.0, 4.0],
          3 => const [-7.0, 0.0, 7.0],
          _ => const [-8.0, -3.0, 3.0, 8.0],
        };
        final branches = Path()
          ..moveTo(-12, 0)
          ..lineTo(-5, 0);
        for (final y in rows) {
          branches
            ..moveTo(-5, 0)
            ..lineTo(5, y)
            ..lineTo(13, y);
        }
        canvas.drawPath(branches, marking);
      case SignalDeviceKind.receiver:
        if (device.dualInput) {
          canvas.drawPath(
            Path()..addPolygon(const [
              Offset(0, -9),
              Offset(11, 8),
              Offset(-11, 8),
            ], true),
            marking,
          );
          canvas.drawLine(const Offset(0, -3), const Offset(0, .5), marking);
          canvas.drawCircle(const Offset(0, 4), 1.1, Paint()..color = glyph);
        } else {
          for (final x in [-7.0, 0.0, 7.0]) {
            canvas.drawLine(Offset(x, -5), Offset(x, 5), marking);
          }
        }
      case SignalDeviceKind.relay:
        final chevron = Path()
          ..addPolygon(const [
            Offset(-6, -6),
            Offset(2, 0),
            Offset(-6, 6),
          ], false);
        canvas.drawPath(chevron, marking);
        canvas.drawPath(chevron.shift(const Offset(7, 0)), marking);
      case SignalDeviceKind.broadcaster:
        // A mast with waves radiating away from its tip.
        const tip = Offset(0, -3);
        canvas.drawLine(tip, const Offset(0, 8), marking);
        canvas.drawLine(const Offset(-4, 8), const Offset(4, 8), marking);
        canvas.drawCircle(tip, 2.1, Paint()..color = glyph);
        for (final side in [0.0, math.pi]) {
          for (final radius in [6.0, 11.0]) {
            canvas.drawArc(
              Rect.fromCircle(center: tip, radius: radius),
              side - .55,
              1.1,
              false,
              marking,
            );
          }
        }
      case SignalDeviceKind.antenna:
        // The dish catches the signal and reflects it to the feed.
        const feed = Offset(-4, -4);
        const mount = Offset(6, 3.5);
        canvas.drawPath(
          Path()
            ..moveTo(6, -8)
            ..quadraticBezierTo(13, 9, -8, 4),
          marking,
        );
        canvas.drawLine(feed, mount, marking);
        canvas.drawLine(mount, const Offset(6, 9), marking);
        canvas.drawLine(const Offset(2, 9), const Offset(10, 9), marking);
        canvas.drawCircle(feed, 2.1, Paint()..color = glyph);
      case SignalDeviceKind.attenuator:
        canvas.drawPath(
          Path()..addPolygon(const [
            Offset(-12, -4),
            Offset(-5, -4),
            Offset(5, 3),
            Offset(12, 3),
          ], false),
          marking,
        );
    }

    const jackRadius = 2.0;
    final jackRim = Paint()
      ..color = rim
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final port in ports) {
      final center = jack(port.point);
      canvas.drawCircle(
        center,
        jackRadius,
        Paint()..color = poweredPorts[port.id] ?? sheet.paper,
      );
      canvas.drawCircle(center, jackRadius, jackRim);
    }
  }

  @override
  bool shouldRepaint(_ComponentDrawing oldDelegate) =>
      device != oldDelegate.device ||
      highlighted != oldDelegate.highlighted ||
      flipped != oldDelegate.flipped ||
      !mapEquals(poweredPorts, oldDelegate.poweredPorts) ||
      sheet != oldDelegate.sheet ||
      symbols != oldDelegate.symbols;
}

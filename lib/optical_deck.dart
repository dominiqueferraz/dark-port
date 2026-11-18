import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'drafting_annotations.dart';
import 'drafting_grid.dart';
import 'drafting_theme.dart';
import 'part_symbols.dart';
import 'sheet_style.dart';
import 'optical_bay.dart';
import 'signal_board.dart';
import 'signal_component.dart';

class OpticalDeckGeometry {
  const OpticalDeckGeometry(this.level, this.size, {this.fill = false});

  final OpticalLevel level;
  final Size size;

  /// Whether the puzzle grid should fill the drawing area in both axes.
  final bool fill;

  Rect get _area => draftingGridMargins.deflateRect(Offset.zero & size);
  Size get _scale {
    final area = _area;
    if (area.isEmpty) return Size.zero;
    final scale = Size(
      area.width / level.floor.width,
      area.height / level.floor.height,
    );
    return fill ? scale : Size.square(scale.shortestSide);
  }

  Size get tile => _scale * level.tileSize;
  double get glyphSize => (_scale.shortestSide * .34).clamp(7, 16);
  double get endpointSize => glyphSize * 2.8;

  Offset project(FloorPoint p) {
    final scale = _scale;
    return _area.center +
        Offset(
          (p.x - level.floor.left - level.floor.width / 2) * scale.width,
          (level.floor.top + level.floor.height / 2 - p.y) * scale.height,
        );
  }

  FloorPoint? unproject(Offset p) {
    final scale = _scale;
    if (scale.isEmpty) return null;
    final offset = p - _area.center;
    return FloorPoint(
      level.floor.left + level.floor.width / 2 + offset.dx / scale.width,
      level.floor.top + level.floor.height / 2 - offset.dy / scale.height,
    );
  }

  /// Clear paper kept between the bay wall and anything drawn inside it.
  static const _wallGap = 9.0;

  Offset source(OpticalSource source) => project(source.foot);

  Offset receiver(int index) {
    final sensor = level.receivers[index];
    final floor = level.floor;
    final point = sensor.position;
    if (point.x > floor.left &&
        point.x < floor.right &&
        point.y > floor.top &&
        point.y < floor.bottom) {
      return project(point);
    }
    return project(point) -
        heading(sensor.incoming) * (endpointSize * .22 + _wallGap);
  }

  Offset heading(BeamDirection direction) {
    final scale = _scale;
    final projected = Offset(
      direction.x * scale.width,
      -direction.y * scale.height,
    );
    return projected.distance == 0
        ? _direction(direction)
        : projected / projected.distance;
  }

  Rect get floorRect => Rect.fromPoints(
    project(FloorPoint(level.floor.left, level.floor.bottom)),
    project(FloorPoint(level.floor.right, level.floor.top)),
  );
}

Offset _direction(BeamDirection direction) => Offset(direction.x, -direction.y);

/// Drawing zones: lettered columns and numbered rows of whole tiles.
int _zoneColumns(OpticalLevel level) =>
    (level.floor.width / level.tileSize).round();
int _zoneRows(OpticalLevel level) =>
    (level.floor.height / level.tileSize + 1e-6).floor();

String opticalZone(OpticalLevel level, FloorPoint p) {
  final columns = _zoneColumns(level);
  final rows = _zoneRows(level);
  final column = ((p.x - level.floor.left) / level.tileSize + 1e-6)
      .floor()
      .clamp(0, columns - 1);
  final fromBottom = ((p.y - level.floor.top) / level.tileSize + 1e-6)
      .floor()
      .clamp(0, rows - 1);
  return '${String.fromCharCode(65 + column)}${rows - fromBottom}';
}

/// Parts are numbered laser first, then optics in layout order, then
/// receivers, so the drawing's balloons match the parts list.
int opticPartNumber(OpticalLevel level, int index) =>
    level.additionalSources.length + 2 + index;
int receiverPartNumber(OpticalLevel level, int index) =>
    opticPartNumber(level, level.initial.length) + index;
int antennaPartNumber(OpticalLevel level, int index) =>
    receiverPartNumber(level, level.receivers.length) + index;

class OpticalAntennaSymbol extends StatelessWidget {
  const OpticalAntennaSymbol({super.key, this.lit = false});

  final bool lit;

  @override
  Widget build(BuildContext context) => SignalComponent(
    device: const SignalDevice(
      '',
      '',
      SignalDeviceKind.antenna,
      SignalPoint(0, 0),
      fixed: true,
    ),
    highlighted: lit,
  );
}

class OpticalDeck extends StatelessWidget {
  const OpticalDeck({
    super.key,
    required this.geometry,
    required this.layout,
    required this.trace,
    required this.held,
    required this.dropSpot,
    required this.validDrop,
    required this.opened,
    this.awardBounds = Rect.zero,
  });

  final OpticalDeckGeometry geometry;
  final List<Optic> layout;
  final OpticalTrace trace;
  final Optic? held;
  final GridSpot? dropSpot;
  final bool validDrop;
  final bool opened;
  final Rect awardBounds;

  @override
  Widget build(BuildContext context) {
    final level = geometry.level;
    final look = SheetLook.of(context);
    final style = look.style;
    final symbols = look.symbols;
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _OpticalDrawing(
            style: style,
            symbols: symbols,
            geometry: geometry,
            layout: layout,
            trace: trace,
            held: held,
            dropSpot: dropSpot,
            validDrop: validDrop,
            opened: opened,
            awardBounds: awardBounds,
          ),
        ),
        for (final source in level.sources)
          _endpoint(
            geometry.source(source),
            source.direction,
            Semantics(
              label: level.additionalSources.isEmpty
                  ? 'Laser'
                  : 'Laser ${source.label}',
              value: '100 u',
              child: const OpticalPartSymbol.source(),
            ),
          ),
        for (var i = 0; i < level.receivers.length; i++)
          _endpoint(
            geometry.receiver(i),
            level.receivers[i].incoming,
            Semantics(
              label: level.receivers[i].label,
              value: '${lightUnits(trace.receivedPower(i) * 100)} u',
              child: OpticalPartSymbol.receiver(
                lit: trace.lit.contains(i),
                alarm: level.alarms.contains(i),
              ),
            ),
          ),
        for (final original in layout)
          if (original.converter case final converter?) ...[
            _converter(original.id == held?.id ? held! : original, converter),
          ],
        for (final (index, antenna) in level.antennas.indexed)
          _endpoint(
            geometry.project(antenna.position),
            BeamDirection.east,
            Semantics(
              label: '${antenna.label}, channel ${antenna.channel}',
              value: '${lightUnits(trace.radioReadings[index].power)} u',
              child: OpticalAntennaSymbol(
                lit:
                    trace.radioReadings[index].status ==
                    RadioReception.accepted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _converter(Optic optic, OpticalConverter converter) {
    final lane = converter.lanes[optic.position]!;
    return _endpoint(
      geometry.project(optic.position),
      BeamDirection.east,
      Opacity(
        opacity: optic.id == held?.id && !validDrop ? .5 : 1,
        child: ConverterSymbol(
          input: geometry.heading(lane.incoming),
          output: geometry.heading(lane.outgoing),
          movable: !optic.fixed,
          transmitting:
              trace.converterInputs[optic.id]?.status ==
              ConverterReception.accepted,
        ),
      ),
    );
  }

  Widget _endpoint(Offset point, BeamDirection direction, Widget child) {
    final size = geometry.endpointSize;
    return Positioned(
      left: point.dx - size / 2,
      top: point.dy - size / 2,
      width: size,
      height: size,
      child: Transform.rotate(
        angle: geometry.heading(direction).direction,
        child: child,
      ),
    );
  }
}

class _OpticalDrawing extends CustomPainter {
  const _OpticalDrawing({
    required this.style,
    required this.symbols,
    required this.geometry,
    required this.layout,
    required this.trace,
    required this.held,
    required this.dropSpot,
    required this.validDrop,
    required this.opened,
    required this.awardBounds,
  });

  final SheetStyle style;
  final PartSymbols symbols;
  final OpticalDeckGeometry geometry;
  final List<Optic> layout;
  final OpticalTrace trace;
  final Optic? held;
  final GridSpot? dropSpot;
  final bool validDrop;
  final bool opened;
  final Rect awardBounds;

  OpticalLevel get level => geometry.level;

  Paint _ink(double width, {Color? color}) => Paint()
    ..color = color ?? style.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  /// The optics as they stand on the drawing, with a part being dragged
  /// shown where it would land.
  List<Optic> get _placed => [
    for (final optic in layout)
      if (optic.id != held?.id) optic else if (validDrop) held!,
  ];

  /// How far [p] sits inside the bay wall; negative outside it.
  double _wallClearance(Offset p) {
    final rect = geometry.floorRect;
    if (!rect.contains(p)) return -1;
    return [
      p.dx - rect.left,
      rect.right - p.dx,
      p.dy - rect.top,
      rect.bottom - p.dy,
    ].reduce(math.min);
  }

  /// Whether a note at [p] would touch the wall, a beam or another note.
  bool _crowded(Offset p, List<Offset> reserved, double room) =>
      _wallClearance(p) < room ||
      (!awardBounds.isEmpty && awardBounds.inflate(room).contains(p)) ||
      level.lightObstacles.any(
        (block) => _blockBounds(block).inflate(room).contains(p),
      ) ||
      reserved.any((other) => (other - p).distance < room * 1.6) ||
      trace.segments.any(
        (beam) =>
            distanceToDraftingSegment(
              p,
              geometry.project(beam.from),
              geometry.project(beam.to),
            ) <
            room,
      );

  @override
  void paint(Canvas canvas, Size size) {
    _paintZones(canvas);
    if (held != null || level.mounts.isNotEmpty) _paintPlacement(canvas);
    _paintBlocks(canvas);
    if (level == reflectionLesson && !opened) _paintReceiverDatum(canvas);
    _paintBeams(canvas);
    _paintRadio(canvas);
    for (final optic in layout) {
      if (optic.id != held?.id && optic.converter == null) {
        _paintOptic(canvas, optic);
      }
    }
    if (held case final optic? when optic.converter == null) {
      _paintOptic(canvas, optic, opacity: validDrop ? 1 : .5);
    }
    // Annotation points that later notes and balloons keep clear of.
    final reserved = [
      for (final optic in _placed) geometry.project(optic.position),
      for (final source in level.sources) geometry.source(source),
      for (var i = 0; i < level.receivers.length; i++) geometry.receiver(i),
      for (final antenna in level.antennas) geometry.project(antenna.position),
    ];
    final mirrorLeaders = _paintCallouts(canvas, reserved);
    if (!opened) _paintClearances(canvas, reserved);
    _paintBalloons(canvas, reserved, mirrorLeaders);
  }

  void _paintReceiverDatum(Canvas canvas) {
    final latch = level.receivers.single.position;
    final start = geometry.receiver(0);
    double? crossing;
    for (final beam in trace.segments) {
      if (beam.from.y != beam.to.y || beam.from.y >= latch.y) continue;
      if (latch.x < math.min(beam.from.x, beam.to.x) ||
          latch.x > math.max(beam.from.x, beam.to.x)) {
        continue;
      }
      crossing = crossing == null
          ? beam.from.y
          : math.max(crossing, beam.from.y);
    }
    if (crossing == null) return;
    final end = geometry.project(FloorPoint(latch.x, crossing)).dy;
    final ink = _ink(.65, color: style.faint);
    for (var y = start.dy + geometry.endpointSize * .25; y < end; y += 12) {
      canvas.drawLine(
        Offset(start.dx, y),
        Offset(start.dx, math.min(y + 7, end)),
        ink,
      );
      if (y + 9 < end) {
        canvas.drawCircle(
          Offset(start.dx, y + 9.5),
          .5,
          Paint()..color = style.faint,
        );
      }
    }
  }

  void _paintZones(Canvas canvas) => paintDraftingGrid(
    canvas,
    grid: geometry.floorRect,
    tile: geometry.tile,
    columns: _zoneColumns(level),
    rows: _zoneRows(level),
    sheet: style,
    size: (geometry.glyphSize * .8).clamp(8.0, 11.0),
  );

  void _paintPlacement(Canvas canvas) {
    final mark = _ink(.8, color: style.faint);
    final arm = geometry.glyphSize * .22;
    for (final spot in level.placementSpots) {
      if (held case final optic?
          when !level.canPlace(optic.at(spot.position), layout)) {
        continue;
      }
      if (_placed.any((optic) => optic.position == spot.position)) continue;
      final p = geometry.project(spot.position);
      canvas.drawLine(p - Offset(arm, 0), p + Offset(arm, 0), mark);
      canvas.drawLine(p - Offset(0, arm), p + Offset(0, arm), mark);
    }
    if (dropSpot case final target?) {
      canvas.drawCircle(
        geometry.project(target.position),
        geometry.glyphSize + 4,
        _ink(1.1, color: validDrop ? style.ink : style.stamp),
      );
    }
  }

  void _paintBlocks(Canvas canvas) {
    for (final block in level.blocks) {
      paintHatchedBarrier(canvas, _blockBounds(block), style);
    }
    for (final barrier in level.barriers) {
      final bounds = _blockBounds(barrier.bounds);
      switch (barrier.material) {
        case BarrierMaterial.concrete:
          paintHatchedBarrier(canvas, bounds, style);
        case BarrierMaterial.mesh:
          paintMeshBarrier(canvas, bounds, style);
      }
    }
  }

  Rect _blockBounds(math.Rectangle<double> block) => Rect.fromPoints(
    geometry.project(FloorPoint(block.left, block.bottom)),
    geometry.project(FloorPoint(block.right, block.top)),
  );

  void _paintBeams(Canvas canvas) {
    final sources = level.sources.toList(growable: false);
    for (final beam in trace.segments) {
      final from = beam.fromOptic == null
          ? geometry.source(sources[beam.source])
          : geometry.project(beam.from);
      final to = switch (beam.receiver) {
        final receiver? =>
          geometry.project(beam.to) +
              (geometry.receiver(receiver) -
                  geometry.project(level.receivers[receiver].position)),
        null => _beamEnd(beam),
      };
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
      final color = _beamColor(beam);
      final strength = beam.strength.clamp(0.0, 1.0);
      // Line weight carries power: full beams are heavy, branches finer.
      final emphasis = strength * strength;
      final thickness = .95 + 3.1 * emphasis;
      // A paper knockout breaks lines that this beam crosses.
      canvas.drawPath(
        path,
        Paint()
          ..color = style.paper
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness + 4,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .4 + .6 * emphasis)
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
    for (final beam in trace.segments) {
      final from = geometry.project(beam.from);
      final to = geometry.project(beam.to);
      final length = (to - from).distance;
      if (length == 0) continue;
      final heading = (to - from) / length;
      if (_exitsBay(beam)) {
        // A beam leaving the bay stops short of the wall with an arrow.
        _arrowhead(canvas, _beamEnd(beam), heading, _beamColor(beam));
      } else if (beam.strength >= .99 && length >= geometry.glyphSize * 4) {
        _arrowhead(canvas, from + (to - from) * .5, heading, _beamColor(beam));
      }
    }
  }

  void _paintRadio(Canvas canvas) {
    for (final hop in trace.radioHops) {
      final start = geometry.project(hop.from);
      final end = geometry.project(hop.to);
      final length = (end - start).distance;
      if (length <= 1) continue;
      final direction = (end - start) / length;
      final ink = _ink(1.3, color: style.beam);
      for (var step = geometry.glyphSize * 1.3; step < length; step += 9) {
        canvas.drawLine(
          start + direction * step,
          start + direction * math.min(step + 5, length),
          ink,
        );
      }
      if ((hop.blockedDistance ?? double.infinity) <= hop.reach) {
        final across = Offset(-direction.dy, direction.dx);
        canvas.drawLine(
          end - across * 4,
          end + across * 4,
          _ink(1.6, color: style.stamp),
        );
      }
    }
  }

  bool _exitsBay(BeamSegment beam) {
    if (beam.blocked || beam.receiver != null || beam.toOptic != null) {
      return false;
    }
    final end = beam.to;
    final floor = level.floor;
    return (end.x - floor.left).abs() < 1e-6 ||
        (end.x - floor.right).abs() < 1e-6 ||
        (end.y - floor.top).abs() < 1e-6 ||
        (end.y - floor.bottom).abs() < 1e-6;
  }

  Color _beamColor(BeamSegment beam) =>
      level.alarms.contains(beam.receiver) ? style.alarmBeam : style.beam;

  Offset _beamEnd(BeamSegment beam) {
    final to = geometry.project(beam.to);
    if (!_exitsBay(beam)) return to;
    final from = geometry.project(beam.from);
    final length = (to - from).distance;
    if (length <= OpticalDeckGeometry._wallGap * 2) return to;
    return to - (to - from) / length * OpticalDeckGeometry._wallGap;
  }

  void _arrowhead(Canvas canvas, Offset tip, Offset direction, Color color) {
    final s = geometry.glyphSize * .55;
    final side = Offset(-direction.dy, direction.dx);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          tip.dx - direction.dx * s * 1.6 + side.dx * s * .7,
          tip.dy - direction.dy * s * 1.6 + side.dy * s * .7,
        )
        ..lineTo(
          tip.dx - direction.dx * s * 1.6 - side.dx * s * .7,
          tip.dy - direction.dy * s * 1.6 - side.dy * s * .7,
        )
        ..close(),
      Paint()..color = color,
    );
  }

  Offset _diagonal(Optic optic, double radius) =>
      Offset(radius * .62, radius * (optic.turned ? .62 : -.62));

  void _paintOptic(Canvas canvas, Optic optic, {double opacity = 1}) =>
      symbols.paintOptic(
        canvas,
        OpticGlyph(
          center: geometry.project(optic.position),
          radius: geometry.glyphSize,
          kind: optic.kind,
          turned: optic.turned,
          fixed: optic.fixed,
          opacity: opacity,
        ),
        style,
      );

  /// Marks the angle between the reflecting face and one of its live rays.
  /// The end of the arc at the mirror face also gives its leader a direction.
  Map<String, double> _paintCallouts(Canvas canvas, List<Offset> reserved) {
    final leaders = <String, double>{};
    final radius = geometry.glyphSize * 1.75;
    final lettering = (geometry.glyphSize * .75).clamp(8.0, 11.0);
    for (final optic in _placed) {
      if (optic.converter != null) continue;
      final center = geometry.project(optic.position);
      final mirror = _diagonal(optic, 1).direction;
      for (final incoming in trace.segments) {
        if (incoming.toOptic != optic.id) continue;
        final inHeading = _heading(incoming);
        for (final out in trace.segments) {
          if (out.fromOptic != optic.id ||
              out.source != incoming.source ||
              out.from != incoming.to) {
            continue;
          }
          final turn = _wrap(_heading(out) - inHeading).abs();
          if ((turn - math.pi / 2).abs() > .1) continue;
          ({double start, double sweep, Offset label})? choice;
          for (final start in [_heading(out), inHeading + math.pi]) {
            var sweep = _wrap(mirror - start);
            if (sweep.abs() > math.pi / 2) sweep = _wrap(sweep + math.pi);
            // Far enough out along the bisector that the lettering clears
            // both rays forming the angle.
            final label =
                center +
                Offset.fromDirection(
                  start + sweep / 2,
                  math.max(
                    radius + geometry.glyphSize,
                    14 / math.sin(math.pi / 8),
                  ),
                );
            final option = (start: start, sweep: sweep, label: label);
            if (!_crowded(label, reserved, 12)) {
              choice = option;
              break;
            }
          }
          if (choice == null) continue;
          final (:start, :sweep, :label) = choice;
          if (optic.kind == OpticKind.mirror) {
            leaders.putIfAbsent(optic.id, () => start + sweep);
            _paintMirrorDatum(canvas, center, start + math.pi);
          }
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: radius),
            start,
            sweep,
            false,
            _ink(.7, color: style.faint),
          );
          reserved
            ..add(label)
            ..add(center + Offset.fromDirection(start + sweep / 2, radius));
          paintLettering(
            canvas,
            '45°',
            label,
            size: lettering,
            color: style.faint,
          );
        }
      }
    }
    return leaders;
  }

  /// A short witness mark on the free end of the ray's axis.
  void _paintMirrorDatum(Canvas canvas, Offset center, double heading) {
    final direction = Offset.fromDirection(heading);
    final radius = geometry.glyphSize;
    final start = center + direction * (radius + 1);
    final end = start + direction * (radius * .36).clamp(3.0, 6.0);
    if (_wallClearance(end) < 3) return;
    final middle = (start + end) / 2;
    if (trace.segments.any(
      (beam) =>
          distanceToDraftingSegment(
            middle,
            geometry.project(beam.from),
            geometry.project(beam.to),
          ) <
          4,
    )) {
      return;
    }
    canvas.drawLine(start, end, _ink(.75, color: style.faint));
  }

  double _heading(BeamSegment beam) =>
      (geometry.project(beam.to) - geometry.project(beam.from)).direction;

  double _wrap(double angle) => math.atan2(math.sin(angle), math.cos(angle));

  /// Dimensions every loose part that no beam reaches, measured square to
  /// the closest beam it could intercept. It follows a part while dragged.
  void _paintClearances(Canvas canvas, List<Offset> reserved) {
    for (final optic in _placed) {
      if (optic.fixed || optic.converter != null) continue;
      final touched = trace.segments.any(
        (beam) => beam.fromOptic == optic.id || beam.toOptic == optic.id,
      );
      if (touched) continue;
      ({BeamSegment beam, double gap})? best;
      for (final beam in trace.segments) {
        final horizontal = beam.from.y == beam.to.y;
        final along = horizontal ? optic.position.x : optic.position.y;
        final a = horizontal ? beam.from.x : beam.from.y;
        final b = horizontal ? beam.to.x : beam.to.y;
        if (along < math.min(a, b) || along > math.max(a, b)) continue;
        final gap = horizontal
            ? optic.position.y - beam.from.y
            : optic.position.x - beam.from.x;
        if (gap.abs() < .05) continue;
        if (best == null || gap.abs() < best.gap.abs()) {
          best = (beam: beam, gap: gap);
        }
      }
      if (best != null) {
        _paintClearance(canvas, reserved, optic, best.beam, best.gap);
      }
    }
  }

  void _paintClearance(
    Canvas canvas,
    List<Offset> reserved,
    Optic optic,
    BeamSegment beam,
    double gap,
  ) {
    final horizontal = beam.from.y == beam.to.y;
    final center = geometry.project(optic.position);
    final beamLine = geometry.project(beam.from);
    final r = geometry.glyphSize;
    final ink = _ink(.6, color: style.fineRule);
    // Run the dimension beside the part, on whichever side has room.
    ({Offset near, Offset far, Offset label, Offset extension})? position;
    for (final side in [1.0, -1.0]) {
      final across = side * r * 2.2;
      final Offset near, far, label, extension;
      if (horizontal) {
        near = Offset(center.dx + across, beamLine.dy);
        far = Offset(center.dx + across, center.dy);
        label = (near + far) / 2 + Offset(side * r * .9, 0);
        extension = Offset(center.dx + side * (r + 5), center.dy);
      } else {
        near = Offset(beamLine.dx, center.dy + across);
        far = Offset(center.dx, center.dy + across);
        label = (near + far) / 2 + Offset(0, side * r * .9);
        extension = Offset(center.dx, center.dy + side * (r + 5));
      }
      final crossesPart = reserved.any(
        (p) => p != center && distanceToDraftingSegment(p, near, far) < r + 5,
      );
      if (!crossesPart &&
          !_crowded(label, reserved, 10) &&
          _wallClearance(far) > 6) {
        position = (near: near, far: far, label: label, extension: extension);
        break;
      }
    }
    if (position == null) return;
    final (:near, :far, :label, :extension) = position;
    canvas.drawLine(extension, far + (far - extension) / 4, ink);
    paintDimensionLine(canvas, near, far, style);
    for (var t = 0.0; t <= 1; t += .25) {
      reserved.add(Offset.lerp(near, far, t)!);
    }
    reserved.add(label);
    paintLettering(
      canvas,
      _tiles(gap.abs() / level.tileSize),
      label,
      size: (r * .8).clamp(8.0, 11.0),
      color: style.ink,
    );
  }

  String _tiles(double tiles) {
    final halves = (tiles * 2).round();
    if ((tiles * 2 - halves).abs() > .05) return tiles.toStringAsFixed(1);
    final whole = halves ~/ 2;
    if (halves.isEven) return '$whole';
    return whole == 0 ? '½' : '$whole½';
  }

  void _paintBalloons(
    Canvas canvas,
    List<Offset> reserved,
    Map<String, double> mirrorLeaders,
  ) {
    final r = (geometry.glyphSize * .72).clamp(7.0, 10.0);
    final sources = level.sources.toList(growable: false);
    final parts = <(String, Offset, double, double?, Offset?)>[
      for (final (index, source) in sources.indexed)
        (
          sources.length == 1 ? '${index + 1}' : source.label,
          geometry.source(source),
          geometry.endpointSize * .3,
          _sourceLeader(source.direction),
          geometry.heading(source.direction),
        ),
      for (final (index, optic) in layout.indexed)
        (
          optic.converter?.requiredSource ?? '${opticPartNumber(level, index)}',
          geometry.project(
            optic.id == held?.id ? held!.position : optic.position,
          ),
          geometry.glyphSize +
              (!optic.fixed && symbols == PartSymbols.drafting ? 3 : 0),
          mirrorLeaders[optic.id],
          null,
        ),
      for (var i = 0; i < level.receivers.length; i++)
        (
          '${receiverPartNumber(level, i)}',
          geometry.receiver(i),
          geometry.endpointSize * .26,
          null,
          null,
        ),
      for (final (i, antenna) in level.antennas.indexed)
        (
          '${antennaPartNumber(level, i)}',
          geometry.project(antenna.position),
          geometry.endpointSize * .36,
          null,
          null,
        ),
    ];
    final annotations = DraftingAnnotations(
      bounds: geometry.floorRect,
      obstacles: [
        for (final (_, p, reach, _, _) in parts)
          Rect.fromCircle(center: p, radius: reach),
        for (final point in reserved)
          Rect.fromCircle(center: point, radius: r * .9),
        ...level.lightObstacles.map(_blockBounds),
        if (!awardBounds.isEmpty) awardBounds,
      ],
      traces: [
        for (final beam in trace.segments)
          (geometry.project(beam.from), geometry.project(beam.to)),
        for (final hop in trace.radioHops)
          (geometry.project(hop.from), geometry.project(hop.to)),
      ],
    );
    final gaps = [r * 1.4, r * 2.2, r * 3.2, r * 4.3];
    for (final (label, anchor, reach, preferred, forward) in parts) {
      final balloon = annotations.placeBalloon(
        anchor: anchor,
        radius: r,
        reach: reach + 1,
        gaps: gaps,
        preferredOffset: preferred == null
            ? null
            : Offset.fromDirection(
                preferred,
                reach + r * (forward != null ? 2.4 : 4.4),
              ),
        reachAt: forward != null && symbols == PartSymbols.drafting
            ? (direction) => _sourceCasingRadius(direction, forward)
            : null,
      );
      if (balloon == null) continue;
      paintPartBalloon(
        canvas,
        number: label,
        anchor: anchor,
        center: balloon.center,
        reach: balloon.reach,
        radius: r,
        sheet: style,
      );
    }
  }

  double _sourceLeader(BeamDirection direction) {
    final forward = _direction(direction);
    return (Offset(-forward.dy, forward.dx) - forward * .45).direction;
  }

  double _sourceCasingRadius(Offset direction, Offset forward) {
    final along = direction.dx * forward.dx + direction.dy * forward.dy;
    final across = direction.dy * forward.dx - direction.dx * forward.dy;
    const casing = DraftingSymbols.sourceCasing;
    return geometry.endpointSize *
        math.min(
          along < 0 ? casing.left / along : casing.right / along,
          across < 0 ? casing.top / across : casing.bottom / across,
        );
  }

  @override
  bool shouldRepaint(_OpticalDrawing oldDelegate) =>
      style != oldDelegate.style ||
      symbols != oldDelegate.symbols ||
      geometry.size != oldDelegate.geometry.size ||
      geometry.level != oldDelegate.geometry.level ||
      layout != oldDelegate.layout ||
      trace != oldDelegate.trace ||
      held != oldDelegate.held ||
      dropSpot != oldDelegate.dropSpot ||
      validDrop != oldDelegate.validDrop ||
      awardBounds != oldDelegate.awardBounds ||
      opened != oldDelegate.opened;
}

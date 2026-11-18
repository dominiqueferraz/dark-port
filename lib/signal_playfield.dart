import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'drafting_annotations.dart';
import 'drafting_grid.dart';
import 'drafting_theme.dart';
import 'placement_marks.dart';
import 'placement_nodes.dart';
import 'sheet_style.dart';
import 'signal_board.dart';
import 'signal_board_state.dart';
import 'signal_wiring.dart';

typedef SignalOutput = ({String id, int port});
typedef SignalPlacement = ({String id, PlacementNode? node, bool valid});

/// Projects board coordinates to the interior of the grid.
class SignalBoardGeometry {
  SignalBoardGeometry(SignalBoard board, Size size)
    : tile = Size(size.width / board.size, size.height / board.height);

  final Size tile;

  Size get partSize => tile * SignalBoard.partSize;

  Offset project(SignalPoint point) =>
      Offset(point.x * tile.width, point.y * tile.height);

  SignalPoint unproject(Offset point) =>
      SignalPoint(point.dx / tile.width, point.dy / tile.height);

  Rect partBounds(SignalPoint position) => Rect.fromCenter(
    center: project(position),
    width: partSize.width,
    height: partSize.height,
  );

  Rect wallBounds(RadioWall wall) {
    final start = project(SignalPoint(wall.x, wall.top));
    final halfWidth = tile.shortestSide * .065;
    return Rect.fromLTRB(
      start.dx - halfWidth,
      start.dy,
      start.dx + halfWidth,
      project(SignalPoint(wall.x, wall.bottom)).dy,
    );
  }

  Rect interferenceBounds(math.Rectangle<double> zone) => Rect.fromPoints(
    project(SignalPoint(zone.left, zone.top)),
    project(SignalPoint(zone.right, zone.bottom)),
  );

  Rect feedthroughBounds(SignalPoint jack) =>
      Rect.fromCenter(center: project(jack), width: 11, height: 11);
}

/// Renders a wired board. The caller supplies the displayed snapshot and
/// builds each part's controls, including any gestures used by the mode.
class SignalPlayfield extends StatelessWidget {
  const SignalPlayfield({
    super.key,
    required this.state,
    required this.positions,
    required this.beyondReach,
    required this.deliveries,
    required this.buildPart,
    this.awardBounds = Rect.zero,
    this.inspectedPart,
    this.surfaceKey,
    this.onBackgroundTap,
    this.placement,
    this.selectedOutput,
    this.preview,
    this.animatedRevision,
  });

  final SignalBoardState state;
  final Map<String, SignalPoint> positions;
  final Set<SignalLink> beyondReach;
  final Map<SignalLink, SignalDelivery> deliveries;
  final Widget Function(SignalDevice device, SignalBoardGeometry geometry)
  buildPart;
  final Rect awardBounds;
  final String? inspectedPart;
  final Key? surfaceKey;
  final VoidCallback? onBackgroundTap;
  final SignalPlacement? placement;
  final SignalOutput? selectedOutput;
  final SignalLink? preview;
  final int? animatedRevision;

  SignalBoard get _board => state.board;

  @override
  Widget build(BuildContext context) => DraftingPlayfield(
    aspectRatio: _board.size / _board.height,
    aspectInsets: draftingGridMargins,
    builder: (context, size) {
      final boardSize = draftingGridMargins.deflateSize(size);
      if (boardSize.isEmpty) return const SizedBox.shrink();
      final geometry = SignalBoardGeometry(_board, boardSize);
      final sheet = context.sheet;
      final drag = placement;
      final routes = _routes(geometry);
      final previewPath = preview == null
          ? null
          : _board.corridorFor(preview!, positions, flipped: state.flipped);
      final radio = [
        for (final mast in _board.devices)
          if (mast.radioRange > 0) _radioCoverage(mast, geometry, sheet),
      ];

      Widget part(SignalDevice device) => Positioned.fromRect(
        key: ValueKey(device.id),
        rect: geometry.partBounds(positions[device.id]!),
        child: buildPart(device, geometry),
      );

      return CustomPaint(
        painter: _SignalGrid(geometry, _board, sheet),
        child: Padding(
          padding: draftingGridMargins,
          child: ClipRect(
            key: const ValueKey('signal-playfield'),
            child: Stack(
              key: surfaceKey,
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBackgroundTap,
                  child: const SizedBox.expand(),
                ),
                if (drag != null || radio.isNotEmpty)
                  IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey('signal-placement-marks'),
                      painter: _SignalPlacementMarks(
                        _board.mountsFor(drag?.id),
                        drag,
                        geometry,
                        sheet,
                      ),
                    ),
                  ),
                _wiring(context, geometry, sheet, routes),
                for (final coverage in radio)
                  IgnorePointer(child: CustomPaint(painter: coverage)),
                if (previewPath != null)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _CablePreview(geometry, previewPath, sheet),
                    ),
                  ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _SignalAnnotations(
                      geometry: geometry,
                      sheet: sheet,
                      state: state,
                      positions: positions,
                      routes: routes,
                      preview: previewPath,
                      radioSpans: [
                        for (final coverage in radio)
                          for (final target in [
                            ...coverage.targets,
                            ...coverage.blockedTargets,
                          ])
                            (coverage.origin, target),
                      ],
                      jacks: [
                        for (final device in _board.devices)
                          ..._deviceJacks(device).map(geometry.project),
                      ],
                      awardBounds: awardBounds,
                      inspectedPart: inspectedPart,
                    ),
                  ),
                ),
                for (final device in _board.devices)
                  if (device.id != drag?.id) part(device),
                if (drag != null) part(_board.device(drag.id)!),
              ],
            ),
          ),
        ),
      );
    },
  );

  _RadioCoverage _radioCoverage(
    SignalDevice mast,
    SignalBoardGeometry geometry,
    SheetStyle sheet,
  ) => _RadioCoverage(
    origin: geometry.project(positions[mast.id]!),
    radius: geometry.tile * mast.radioRange.toDouble(),
    targets: [
      for (final link in deliveries.keys)
        if (link.from == mast.id && link.output == SignalBoard.radioOutput)
          geometry.project(positions[link.to]!),
    ],
    blockedTargets: [
      if (deliveries.keys.any((link) => link.to == mast.id))
        for (final antenna in _board.devices)
          if (antenna.kind == SignalDeviceKind.antenna)
            if (_board.radioPath(mast, antenna, positions) case (
              inRange: true,
              blockedAt: final hit?,
              distance: _,
            ))
              geometry.project(hit),
    ],
    sheet: sheet,
  );

  Widget _wiring(
    BuildContext context,
    SignalBoardGeometry geometry,
    SheetStyle sheet,
    List<SignalCablePath> routes,
  ) {
    final opacities = {
      for (final link in state.links)
        link: signalCableOpacity(
          _board.distance(link, positions, flipped: state.flipped) /
              _board.leadReach(link.from, state.leadType(link)),
        ),
    };
    final sourceStrength = _board.devices
        .where((device) => device.kind == SignalDeviceKind.transmitter)
        .fold(1.0, (maximum, device) => math.max(maximum, device.strength));
    final alternateSources = {
      for (final part in _board.devices)
        if (part.alternateTint) part.id,
    };
    final hops = deliveries.values.fold(
      0,
      (count, delivery) => math.max(count, delivery.hop + 1),
    );
    final animate =
        animatedRevision != null &&
        !MediaQuery.disableAnimationsOf(context) &&
        hops > 0;
    final output = selectedOutput;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey((animatedRevision, animate)),
        tween: Tween(
          begin: animate ? 0 : hops.toDouble(),
          end: hops.toDouble(),
        ),
        duration: animate ? Duration(milliseconds: hops * 320) : Duration.zero,
        builder: (context, time, _) => CustomPaint(
          painter: SignalWiring(
            sheet: sheet,
            routes: routes,
            alternateSources: alternateSources,
            beyondReach: beyondReach,
            opacities: opacities,
            deliveries: deliveries,
            referenceUnits: sourceStrength,
            time: time,
            selectedOutput: output == null
                ? null
                : geometry.project(
                    positions[output.id]! +
                        SignalBoard.outputPort(
                          output.port,
                          flipped: state.flipped.contains(output.id),
                        ),
                  ),
            reach: output == null
                ? null
                : geometry.tile * _board.device(output.id)!.range.toDouble(),
          ),
        ),
      ),
    );
  }

  List<SignalCablePath> _routes(SignalBoardGeometry display) {
    // Route on square cells, then project the result to the displayed grid.
    final step = display.tile.shortestSide;
    final size = Size(step * _board.size, step * _board.height);
    final geometry = SignalBoardGeometry(_board, size);
    final ports = {
      for (final link in state.links)
        link: _board.linkPorts(link, positions, flipped: state.flipped),
    };
    final routes = layoutSignalCables(
      ports.map(
        (link, pair) => MapEntry(link, (
          from: geometry.project(pair.from),
          to: geometry.project(pair.to),
        )),
      ),
      [
        ...state.links.where(beyondReach.contains),
        ...state.links.where((link) => !beyondReach.contains(link)),
      ],
      bounds: (Offset.zero & size).deflate(1),
      parts: positions.values.map(geometry.partBounds).toList(),
      lead: SignalBoard.cableLead * step,
      jacks: [
        for (final device in _board.devices)
          ..._deviceJacks(device).map(geometry.project),
      ],
      directions: {
        for (final link in state.links)
          link: (
            from: _direction(
              SignalBoard.outputDirection(
                link.output,
                flipped: state.flipped.contains(link.from),
              ),
            ),
            to: Offset(state.flipped.contains(link.to) ? 1 : -1, 0),
          ),
      },
      corridors: {
        for (final link in state.links)
          if (_board.corridorFor(link, positions, flipped: state.flipped)
              case final corridor?)
            link: corridor.points.map(geometry.project).toList(),
      },
    );
    Offset project(Offset point) => display.project(geometry.unproject(point));
    return [
      for (final route in routes)
        SignalCablePath(
          route.link,
          route.points.map(project).toList(),
          route.overpasses.map(project).toList(),
        ),
    ];
  }

  Iterable<SignalPoint> _deviceJacks(SignalDevice device) sync* {
    final center = positions[device.id]!;
    final flipped = state.flipped.contains(device.id);
    for (var input = 0; input < device.inputs; input++) {
      yield center + SignalBoard.inputPort(input, flipped: flipped);
    }
    for (var output = 0; output < device.outputs; output++) {
      yield center + SignalBoard.outputPort(output, flipped: flipped);
    }
  }

  static Offset _direction(SignalPoint point) => Offset(point.x, point.y);
}

class _SignalAnnotations extends CustomPainter {
  const _SignalAnnotations({
    required this.geometry,
    required this.sheet,
    required this.state,
    required this.positions,
    required this.routes,
    required this.preview,
    required this.radioSpans,
    required this.jacks,
    required this.awardBounds,
    required this.inspectedPart,
  });

  final SignalBoardGeometry geometry;
  final SheetStyle sheet;
  final SignalBoardState state;
  final Map<String, SignalPoint> positions;
  final List<SignalCablePath> routes;
  final CableCorridor? preview;
  final List<(Offset, Offset)> radioSpans;
  final List<Offset> jacks;
  final Rect awardBounds;
  final String? inspectedPart;

  @override
  void paint(Canvas canvas, Size size) {
    final step = geometry.tile.shortestSide;
    final radius = (step * .19).clamp(6.0, 9.0);
    final reach = step * .22;
    final board = state.board;
    final corridors = board.cableCorridors ?? const <CableCorridor>[];
    final segments = [
      ...radioSpans,
      for (final route in routes)
        for (var i = 1; i < route.points.length; i++)
          (route.points[i - 1], route.points[i]),
      for (final corridor in [...corridors, ?preview])
        for (var i = 1; i < corridor.points.length; i++)
          (
            geometry.project(corridor.points[i - 1]),
            geometry.project(corridor.points[i]),
          ),
    ];
    final readouts = [
      for (final device in state.board.devices)
        geometry
            .project(positions[device.id]!)
            .translate(
              device.outputs > 2
                  ? geometry.partSize.width *
                        (state.flipped.contains(device.id) ? .125 : -.125)
                  : 0,
              geometry.partSize.height * .355,
            ),
    ];
    final annotations = DraftingAnnotations(
      bounds: Offset.zero & size,
      traces: segments,
      obstacles: [
        for (final point in positions.values)
          Rect.fromCenter(
            center: geometry
                .project(point)
                .translate(0, geometry.tile.height * .08),
            width: geometry.partSize.width * .76,
            height: geometry.partSize.height * .77,
          ),
        for (final jack in jacks) Rect.fromCircle(center: jack, radius: 4),
        if (!awardBounds.isEmpty) awardBounds,
        for (final wall in board.radioWalls) geometry.wallBounds(wall),
        if (board.interference case final zone?)
          geometry.interferenceBounds(zone),
        for (final jack in board.feedthroughs.keys)
          geometry.feedthroughBounds(jack),
      ],
      leaderObstacles: [
        for (final jack in jacks) (center: jack, radius: 4.0),
        for (final reading in readouts) (center: reading, radius: step * .18),
      ],
    );
    _paintCorridorLabels(canvas, annotations);
    final gaps = [step * .32, step * .50, step * .70, step * .94, step * 1.18];
    for (final (index, device) in state.board.devices.indexed) {
      final anchor = geometry.project(positions[device.id]!);
      final balloon = annotations.placeBalloon(
        anchor: anchor,
        radius: radius,
        reach: reach,
        gaps: gaps,
      );
      if (balloon == null) continue;
      paintPartBalloon(
        canvas,
        number: '${index + 1}',
        anchor: anchor,
        center: balloon.center,
        reach: balloon.reach,
        radius: radius,
        sheet: sheet,
      );
    }

    // Write the evaluator's jack-to-jack length alongside the inspected
    // lead. The small bends on the sheet are routing marks.
    final route = routes
        .where(
          (route) =>
              route.link.from == inspectedPart ||
              route.link.to == inspectedPart,
        )
        .firstOrNull;
    if (route == null) return;
    final length = state.board.distance(
      route.link,
      positions,
      flipped: state.flipped,
    );
    final label = '${length.toStringAsFixed(2)} TILES';
    final spans = [
      for (var i = 1; i < route.points.length; i++)
        (route.points[i - 1], route.points[i]),
    ]..sort((a, b) => (b.$2 - b.$1).distance.compareTo((a.$2 - a.$1).distance));
    final lettering = layoutDraftingLettering(
      label,
      size: 10,
      color: sheet.ink,
    );
    final note = annotations.placeLabel(lettering.size, [
      for (final (from, to) in spans)
        if ((to - from).distance >= 27)
          for (final sign in [-1, 1])
            (from + to) / 2 +
                ((to - from).dx.abs() > (to - from).dy.abs()
                    ? Offset(0, sign * 15.0)
                    : Offset(sign * (lettering.width / 2 + 8), 0)),
    ]);
    if (note != null) lettering.paint(canvas, note.topLeft);
    lettering.dispose();
  }

  void _paintCorridorLabels(Canvas canvas, DraftingAnnotations annotations) {
    final board = state.board;
    for (final corridor in board.cableCorridors ?? const <CableCorridor>[]) {
      if (!corridor.trunk) continue;
      final from = geometry.project(corridor.points.first);
      final to = geometry.project(corridor.points.last);
      final span = to - from;
      final normal = Offset(-span.dy, span.dx) / span.distance;
      final text = layoutDraftingLettering(
        'TRUNK RUN',
        size: 9,
        color: sheet.ink,
      );
      final label = annotations.placeLabel(text.size, [
        for (final gap in [-13.0, 13.0, -23.0, 23.0])
          for (final fraction in [.75, .25, .6, .4])
            from + span * fraction + normal * gap,
      ]);
      if (label != null) text.paint(canvas, label.topLeft);
      text.dispose();
    }
    if (board.interference case final zone?) {
      final area = geometry.interferenceBounds(zone);
      final text = layoutDraftingLettering(
        'INTERFERENCE',
        size: 9,
        color: sheet.ink,
      );
      final gap = text.height / 2 + 5;
      final label = annotations.placeLabel(text.size, [
        area.bottomCenter.translate(0, gap),
        area.topCenter.translate(0, -gap),
        area.centerRight.translate(text.width / 2 + 5, 0),
        area.centerLeft.translate(-text.width / 2 - 5, 0),
      ]);
      if (label != null) text.paint(canvas, label.topLeft);
      text.dispose();
    }
    for (final jack in board.feedthroughs.keys) {
      final box = geometry.feedthroughBounds(jack);
      final text = layoutDraftingLettering(
        'FEEDTHROUGH',
        size: 9,
        color: sheet.ink,
      );
      final width = text.width / 2 + box.width / 2 + 12;
      final label = annotations.placeLabel(text.size, [
        for (final dy in [19.0, 29.0, -19.0, -29.0])
          for (final dx in [width, -width]) box.center.translate(dx, dy),
      ]);
      if (label != null) {
        final right = label.center.dx > box.center.dx;
        final below = label.center.dy > box.center.dy;
        final start = below
            ? (right ? box.bottomRight : box.bottomLeft)
            : (right ? box.topRight : box.topLeft);
        final end = right
            ? label.centerLeft.translate(-2, 0)
            : label.centerRight.translate(2, 0);
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = sheet.fineRule
            ..strokeWidth = .8,
        );
        text.paint(canvas, label.topLeft);
      }
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(_SignalAnnotations oldDelegate) =>
      geometry.tile != oldDelegate.geometry.tile ||
      sheet != oldDelegate.sheet ||
      state != oldDelegate.state ||
      positions != oldDelegate.positions ||
      routes != oldDelegate.routes ||
      preview != oldDelegate.preview ||
      radioSpans != oldDelegate.radioSpans ||
      awardBounds != oldDelegate.awardBounds ||
      inspectedPart != oldDelegate.inspectedPart;
}

class _SignalGrid extends CustomPainter {
  const _SignalGrid(this.geometry, this.board, this.sheet);

  final SignalBoardGeometry geometry;
  final SignalBoard board;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = draftingGridMargins.deflateRect(Offset.zero & size);
    paintDraftingGrid(
      canvas,
      grid: grid,
      tile: geometry.tile,
      columns: board.size.round(),
      rows: board.height.round(),
      sheet: sheet,
      size: 10,
    );
    for (final wall in board.radioWalls) {
      paintHatchedBarrier(
        canvas,
        geometry.wallBounds(wall).shift(grid.topLeft),
        sheet,
      );
    }
    Offset project(SignalPoint point) => geometry.project(point) + grid.topLeft;
    final guide = Paint()
      ..color = sheet.faint
      ..strokeWidth = .8;
    for (final corridor in board.cableCorridors ?? const <CableCorridor>[]) {
      final points = corridor.points.map(project).toList();
      for (var index = 1; index < points.length; index++) {
        final delta = points[index] - points[index - 1];
        final length = delta.distance;
        if (length == 0) continue;
        final unit = delta / length;
        for (var step = 0.0; step < length; step += 7) {
          canvas.drawLine(
            points[index - 1] + unit * step,
            points[index - 1] + unit * math.min(step + 3, length),
            guide,
          );
        }
      }
    }
    if (board.interference case final zone?) {
      final area = geometry.interferenceBounds(zone).shift(grid.topLeft);
      paintHatchedBarrier(canvas, area, sheet);
    }
    for (final jack in board.feedthroughs.keys) {
      final box = geometry.feedthroughBounds(jack).shift(grid.topLeft);
      canvas.drawRect(box, Paint()..color = sheet.paper);
      canvas.drawRect(
        box,
        Paint()
          ..color = sheet.ink
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_SignalGrid oldDelegate) =>
      geometry.tile != oldDelegate.geometry.tile ||
      board != oldDelegate.board ||
      sheet != oldDelegate.sheet;
}

class _CablePreview extends CustomPainter {
  const _CablePreview(this.geometry, this.corridor, this.sheet);

  final SignalBoardGeometry geometry;
  final CableCorridor corridor;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addPolygon(corridor.points.map(geometry.project).toList(), false);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = sheet.ink;
    final line = path.computeMetrics().single;
    for (var start = 0.0; start < line.length; start += 8) {
      canvas.drawPath(line.extractPath(start, start + 4), paint);
    }
  }

  @override
  bool shouldRepaint(_CablePreview oldDelegate) =>
      geometry.tile != oldDelegate.geometry.tile ||
      corridor != oldDelegate.corridor ||
      sheet != oldDelegate.sheet;
}

class _SignalPlacementMarks extends CustomPainter {
  const _SignalPlacementMarks(
    this.nodes,
    this.placement,
    this.geometry,
    this.sheet,
  );

  final List<PlacementNode> nodes;
  final SignalPlacement? placement;
  final SignalBoardGeometry geometry;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) => paintPlacementMarks(
    canvas,
    nodes,
    geometry.project,
    target: placement?.node,
    valid: placement?.valid ?? false,
    radius: geometry.partSize.shortestSide * .65,
    sheet: sheet,
  );

  @override
  bool shouldRepaint(_SignalPlacementMarks oldDelegate) =>
      nodes != oldDelegate.nodes ||
      placement != oldDelegate.placement ||
      geometry.tile != oldDelegate.geometry.tile ||
      sheet != oldDelegate.sheet;
}

class _RadioCoverage extends CustomPainter {
  const _RadioCoverage({
    required this.origin,
    required this.radius,
    required this.targets,
    required this.blockedTargets,
    required this.sheet,
  });

  final Offset origin;
  final Size radius;
  final List<Offset> targets;
  final List<Offset> blockedTargets;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    final diamond = Path()
      ..addPolygon([
        origin.translate(radius.width, 0),
        origin.translate(0, radius.height),
        origin.translate(-radius.width, 0),
        origin.translate(0, -radius.height),
      ], true);
    canvas.drawPath(
      diamond,
      Paint()..color = sheet.beam.withValues(alpha: .09),
    );
    canvas.drawPath(
      diamond,
      Paint()
        ..color = sheet.beam.withValues(alpha: .52)
        ..style = PaintingStyle.stroke,
    );
    final trace = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    void drawTrace(Offset target, Color color) {
      final delta = target - origin;
      final length = delta.distance;
      if (length == 0) return;
      final unit = delta / length;
      trace.color = color;
      for (var step = 0.0; step < length; step += 9) {
        canvas.drawLine(
          origin + unit * step,
          origin + unit * math.min(step + 4, length),
          trace,
        );
      }
    }

    for (final target in targets) {
      drawTrace(target, sheet.beam);
    }
    for (final hit in blockedTargets) {
      drawTrace(hit, sheet.stamp);
      canvas.drawCircle(hit, 3.5, Paint()..color = sheet.stamp);
    }
  }

  @override
  bool shouldRepaint(_RadioCoverage oldDelegate) =>
      origin != oldDelegate.origin ||
      radius != oldDelegate.radius ||
      targets != oldDelegate.targets ||
      blockedTargets != oldDelegate.blockedTargets ||
      sheet != oldDelegate.sheet;
}

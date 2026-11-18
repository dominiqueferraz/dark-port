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
                        _board.placementNodes,
                        drag,
                        geometry,
                        sheet,
                      ),
                    ),
                  ),
                _wiring(context, geometry, sheet, routes),
                for (final coverage in radio)
                  IgnorePointer(child: CustomPaint(painter: coverage)),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _SignalAnnotations(
                      geometry: geometry,
                      sheet: sheet,
                      state: state,
                      positions: positions,
                      routes: routes,
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
              _board.device(link.from)!.range,
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
  final List<(Offset, Offset)> radioSpans;
  final List<Offset> jacks;
  final Rect awardBounds;
  final String? inspectedPart;

  @override
  void paint(Canvas canvas, Size size) {
    final step = geometry.tile.shortestSide;
    final radius = (step * .19).clamp(6.0, 9.0);
    final reach = step * .22;
    final segments = [
      ...radioSpans,
      for (final route in routes)
        for (var i = 1; i < route.points.length; i++)
          (route.points[i - 1], route.points[i]),
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
        for (final wall in state.board.radioWalls) geometry.wallBounds(wall),
      ],
      leaderObstacles: [
        for (final jack in jacks) (center: jack, radius: 4.0),
        for (final reading in readouts) (center: reading, radius: step * .18),
      ],
    );
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
        number: index + 1,
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
    for (final (from, to) in spans) {
      if ((to - from).distance < 27) continue;
      final center = (from + to) / 2;
      final side = (to - from).dx.abs() > (to - from).dy.abs()
          ? const Offset(0, 15)
          : const Offset(28, 0);
      for (final note in [center - side, center + side]) {
        final left = note.translate(-23, 0);
        final right = note.translate(23, 0);
        if (![left, note, right].every((p) => annotations.hasRoom(p, 5))) {
          continue;
        }
        paintLettering(canvas, label, note, size: 10, color: sheet.ink);
        return;
      }
    }
  }

  @override
  bool shouldRepaint(_SignalAnnotations oldDelegate) =>
      geometry.tile != oldDelegate.geometry.tile ||
      sheet != oldDelegate.sheet ||
      state != oldDelegate.state ||
      positions != oldDelegate.positions ||
      routes != oldDelegate.routes ||
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
  }

  @override
  bool shouldRepaint(_SignalGrid oldDelegate) =>
      geometry.tile != oldDelegate.geometry.tile ||
      board != oldDelegate.board ||
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

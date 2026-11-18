import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'drafting_theme.dart';
import 'endless_levels.dart';
import 'sheet_style.dart';
import 'solution_stars.dart';

class DrawingPathEntry {
  const DrawingPathEntry({
    required this.key,
    required this.title,
    required this.number,
    required this.kind,
    required this.status,
    required this.icon,
    this.onOpen,
    this.branchHint,
    this.stars = const [],
    this.current = false,
    this.complete = false,
  });

  final Key key;
  final String title;
  final String number;
  final String kind;
  final String status;
  final IconData icon;
  final VoidCallback? onOpen;
  final String? branchHint;
  final List<SolutionStar> stars;
  final bool current;
  final bool complete;
}

/// The horizontal sheet register shared by Tutorial and Endless.
class DrawingPath<T extends Object> extends StatefulWidget {
  const DrawingPath({
    super.key,
    required this.scrollKey,
    required this.main,
    required this.entries,
    this.branches = const {},
    this.headings = const {},
    this.focus,
    this.focusFrom,
  });

  final Key scrollKey;
  final List<T> main;
  final Map<T, DrawingPathEntry> entries;
  final Map<T, T> branches;
  final Map<T, String> headings;
  final T? focus;
  final T? focusFrom;

  @override
  State<DrawingPath<T>> createState() => _DrawingPathState<T>();
}

class _DrawingPathState<T extends Object> extends State<DrawingPath<T>> {
  final _scroll = ScrollController(keepScrollOffset: false);
  bool _positioned = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) {
      final fade = (28 / bounds.width).clamp(0.0, .5);
      return LinearGradient(
        colors: const [
          Color(0x00000000),
          Color(0xff000000),
          Color(0xff000000),
          Color(0x00000000),
        ],
        stops: [0, fade, 1 - fade, 1],
      ).createShader(bounds);
    },
    child: ClipRect(child: LayoutBuilder(builder: _path)),
  );

  Widget _path(BuildContext context, BoxConstraints viewport) {
    final sheet = context.sheet;
    final textScale = MediaQuery.textScalerOf(context).scale(13) / 13;
    final layout = _PathLayout<T>(
      scale: textScale.clamp(1.0, 2.0),
      viewport: viewport.biggest,
      main: widget.main,
      branchParents: widget.branches,
    );
    if (!_positioned) {
      _positioned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final center = layout.centers[widget.focus ?? widget.main.first]!.dx;
        final from = layout.centers[widget.focusFrom]?.dx ?? center;
        _scroll.jumpTo(
          ((center + from) / 2 - viewport.maxWidth / 2).clamp(
            0.0,
            _scroll.position.maxScrollExtent,
          ),
        );
      });
    }

    return SingleChildScrollView(
      child: SizedBox(
        height: layout.height,
        child: Scrollbar(
          controller: _scroll,
          interactive: true,
          thumbVisibility: layout.width > viewport.maxWidth,
          child: SingleChildScrollView(
            key: widget.scrollKey,
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: layout.width,
              height: layout.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PathDrawing(
                        layout,
                        widget.main,
                        widget.branches,
                        widget.entries,
                        sheet,
                      ),
                    ),
                  ),
                  for (final MapEntry(key: id, value: label)
                      in widget.headings.entries)
                    Positioned(
                      left: layout.centers[id]!.dx - layout.square / 2,
                      top: layout.mainY - layout.square / 2 - 36 * layout.scale,
                      child: Text(
                        label,
                        style: draftingLettering(
                          10,
                          color: sheet.faint,
                          spacing: 1.6,
                        ),
                      ),
                    ),
                  for (final MapEntry(key: id, value: center)
                      in layout.centers.entries)
                    Positioned(
                      left: center.dx - layout.labelWidth / 2,
                      top: center.dy - layout.square / 2,
                      width: layout.labelWidth,
                      child: _node(widget.entries[id]!, layout),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _node(DrawingPathEntry entry, _PathLayout<T> layout) {
    final sheet = context.sheet;
    final action = entry.onOpen;
    final unlocked = action != null;
    final status = entry.status;
    final current = entry.current;
    final ink = unlocked ? sheet.ink : sheet.faint;

    return Semantics(
      label: entry.title,
      value: entry.stars.isEmpty
          ? status
          : '$status. ${solutionStarProgress(entry.stars)}',
      hint: entry.branchHint,
      button: true,
      enabled: unlocked,
      onTap: action,
      child: Tooltip(
        message: '${entry.title} · $status',
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: entry.key,
            onTap: action,
            excludeFromSemantics: true,
            child: ExcludeSemantics(
              child: Column(
                children: [
                  // Each lesson is a sheet in the set: its number, its kind,
                  // and its stars or tutorial approval stamp.
                  Ink(
                    width: layout.square,
                    height: layout.square,
                    decoration: BoxDecoration(
                      color: sheet.paper,
                      border: Border.all(
                        color: current ? sheet.beam : ink,
                        width: current ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 5,
                          top: 4,
                          child: Text(
                            entry.kind,
                            style: draftingLettering(
                              7,
                              color: sheet.faint,
                              spacing: .8,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 3,
                          child: Icon(
                            entry.icon,
                            color: current ? sheet.beam : ink,
                            size: 13,
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0, -.05),
                          child: Text(
                            entry.number,
                            style: draftingLettering(
                              layout.compact ? 20 : 24,
                              color: current ? sheet.beam : ink,
                              spacing: 1,
                            ),
                          ),
                        ),
                        if (entry.stars.isNotEmpty)
                          Align(
                            alignment: const Alignment(0, .8),
                            child: SolutionStars(stars: entry.stars, size: 14),
                          )
                        else if (entry.complete)
                          const Align(
                            alignment: Alignment(0, .78),
                            child: _MiniStamp(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      entry.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: draftingLettering(
                        10,
                        color: current ? sheet.beam : ink,
                        spacing: .8,
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

class _MiniStamp extends StatelessWidget {
  const _MiniStamp();

  @override
  Widget build(BuildContext context) {
    final sheet = context.sheet;
    return Transform.rotate(
      angle: -.14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: sheet.approval, width: 1.1),
        ),
        child: Text(
          'APPROVED',
          style: draftingLettering(7, color: sheet.approval, spacing: 1.2),
        ),
      ),
    );
  }
}

class _PathLayout<T extends Object> {
  _PathLayout({
    required this.scale,
    required Size viewport,
    required List<T> main,
    required Map<T, T> branchParents,
  }) : compact = viewport.height < 350 {
    final branchStep = (compact ? 103 : 145) * scale;
    final branches = <T, List<T>>{};
    for (final MapEntry(key: lesson, value: parent) in branchParents.entries) {
      (branches[parent] ??= []).add(lesson);
    }

    final branchRows = branches.values
        .map((lane) => lane.length)
        .fold(0, math.max);
    final pathHeight = (compact ? 135 : 180) * scale + branchRows * branchStep;
    height = math.max(viewport.height, pathHeight);
    mainY = (height - pathHeight) * .42 + (compact ? 63 : 100) * scale;

    final stride = 116 * scale;
    final edge = 76 * scale;
    var x = edge;
    for (final lesson in main) {
      centers[lesson] = Offset(x, mainY);
      final detours = branches[lesson] ?? const [];
      for (var lane = 0; lane < detours.length; lane++) {
        centers[detours[lane]] = Offset(
          x + stride,
          mainY + (lane + 1) * branchStep,
        );
      }
      x += detours.isEmpty ? stride : 2 * stride;
    }

    final last = centers[main.last]!;
    finish = branches.containsKey(main.last)
        ? Offset(x, mainY)
        : last.translate(square / 2 + 24 * scale, 0);
    width = math.max(viewport.width, finish.dx + 10 * scale);
  }

  final bool compact;
  final double scale;
  final centers = <T, Offset>{};
  late final double mainY;
  late final Offset finish;
  late final double width;
  late final double height;
  double get square => (compact ? 68 : 84) * scale;
  double get labelWidth => 114 * scale;
}

class _PathDrawing<T extends Object> extends CustomPainter {
  const _PathDrawing(
    this.layout,
    this.main,
    this.branches,
    this.entries,
    this.sheet,
  );

  final _PathLayout<T> layout;
  final List<T> main;
  final Map<T, T> branches;
  final Map<T, DrawingPathEntry> entries;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = sheet.grid.withValues(alpha: .7);
    const spacing = 24.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height - spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), .8, grid);
      }
    }

    final nodes = layout.centers;
    final halfSquare = layout.square / 2;
    final first = nodes[main.first]!;
    final last = nodes[main.last]!;
    final lead = 24 * layout.scale;
    final start = first.translate(-halfSquare - lead, 0);
    final end = layout.finish;
    canvas.drawLine(start, first, _wire(true));
    canvas.drawLine(last, end, _wire(entries[main.last]!.complete));
    canvas.drawCircle(start, 3, Paint()..color = sheet.ink);
    canvas.drawCircle(
      end,
      3,
      Paint()..color = entries[main.last]!.complete ? sheet.ink : sheet.faint,
    );
    for (var index = 1; index < main.length; index++) {
      final lesson = main[index];
      canvas.drawLine(
        nodes[main[index - 1]]!,
        nodes[lesson]!,
        _wire(entries[lesson]!.onOpen != null),
      );
    }

    for (final MapEntry(key: branch, value: parent) in branches.entries) {
      final origin = nodes[parent]!;
      final detour = nodes[branch]!;
      final nextIndex = main.indexOf(parent) + 1;
      final offset = halfSquare + 12 * layout.scale;
      final split = origin.translate(offset, 0);
      final merge = nextIndex < main.length
          ? nodes[main[nextIndex]]!.translate(-offset, 0)
          : end.translate(-12 * layout.scale, 0);
      final branchWire = _wire(entries[branch]!.onOpen != null);
      final turn = 10 * layout.scale;
      final path = Path()
        ..moveTo(split.dx, split.dy)
        ..lineTo(split.dx, detour.dy - turn)
        ..quadraticBezierTo(split.dx, detour.dy, split.dx + turn, detour.dy)
        ..lineTo(merge.dx - turn, detour.dy)
        ..quadraticBezierTo(merge.dx, detour.dy, merge.dx, detour.dy - turn)
        ..lineTo(merge.dx, merge.dy);
      canvas.drawPath(path, branchWire);
      final junction = Paint()..color = branchWire.color;
      canvas.drawCircle(split, 3.5, junction);
      canvas.drawCircle(merge, 3.5, junction);
    }
  }

  Paint _wire(bool active) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = active ? 1.4 : .9
    ..color = active ? sheet.ink : sheet.faint;

  @override
  bool shouldRepaint(_PathDrawing<T> oldDelegate) =>
      layout != oldDelegate.layout ||
      entries != oldDelegate.entries ||
      sheet != oldDelegate.sheet;
}

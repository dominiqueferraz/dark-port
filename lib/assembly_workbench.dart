part of 'workbench_screen.dart';

String _feedLabel(int index) => String.fromCharCode(65 + index);
String _edgeLabel(AssemblyContact socket) =>
    socket.cell == AssemblyBlueprint.inputs
    ? 'input ${_feedLabel(socket.port)}'
    : 'output ${socket.port + 1}';

String _units(double power) =>
    '${power.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')} u';

class _AssemblyModuleSymbol extends StatelessWidget {
  const _AssemblyModuleSymbol({required this.module, this.selected = false});

  final AssemblyModule module;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final sheet = context.sheet;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: sheet.paper,
        border: Border.all(
          color: selected ? sheet.beam : sheet.ink,
          width: selected ? 2 : 1,
        ),
      ),
      child: FittedBox(
        child: Text(module.symbol, style: draftingLettering(11)),
      ),
    );
  }
}

typedef _JackMark = ({Offset point, Offset outward});

class _AssemblyGrid extends StatelessWidget {
  const _AssemblyGrid({
    required this.design,
    required this.packed,
    this.onInsert,
    required this.feeds,
    required this.output,
    required this.selected,
    required this.selectedPart,
    required this.selectedEdge,
    required this.canEdit,
    required this.size,
    required this.onCell,
    required this.onChangePart,
    required this.onMove,
    required this.canEditJacks,
    required this.onJack,
    required this.onSelectEdge,
    required this.onSocket,
  });

  final AssemblyBlueprint design;
  final bool packed;
  final VoidCallback? onInsert;
  final List<double> feeds;
  final List<double> output;
  final AssemblyContact? selected;
  final int? selectedPart;
  final AssemblyContact? selectedEdge;
  final bool canEdit;
  final Size size;
  final ValueChanged<int> onCell;
  final ValueChanged<int> onChangePart;
  final void Function(int from, int to) onMove;
  final bool canEditJacks;
  final void Function({required bool input, required int delta}) onJack;
  final ValueChanged<AssemblyContact> onSelectEdge;
  final void Function(AssemblyContact, {required bool output}) onSocket;

  Rect get _grid => draftingGridMargins.deflateRect(Offset.zero & size);
  double get _stepX => _grid.width / 5;
  double get _stepY => _grid.height / AssemblyBlueprint.rows;
  double get _span => (_stepX < _stepY ? _stepX : _stepY).clamp(32, 92);
  Rect get _case => Rect.fromLTRB(
    _grid.left + _stepX,
    packed ? _y(0) - _stepY * .34 : _grid.top + 7,
    _grid.right - _stepX,
    packed
        ? _y(math.max(feeds.length, output.length) - 1) + _stepY * .34
        : _grid.bottom - 7,
  );

  double _y(int row) => _grid.top + (row + .5) * _stepY;
  Offset _mount(int cell) => Offset(
    _grid.left + (cell % AssemblyBlueprint.columns + 1.5) * _stepX,
    _y(cell ~/ AssemblyBlueprint.columns),
  );
  Offset _boundary(bool input, int port) =>
      Offset(input ? _case.left : _case.right, _y(port));

  Offset _orient(Offset value, AssemblyOrientation orientation) {
    var point = orientation.flipped ? Offset(-value.dx, value.dy) : value;
    for (var turn = 0; turn < orientation.turns; turn++) {
      point = Offset(-point.dy, point.dx);
    }
    return point;
  }

  _JackMark _contact(AssemblyContact contact, bool output) {
    final (cell, port) = (contact.cell, contact.port);
    if (cell < 0) {
      final input = cell == AssemblyBlueprint.inputs;
      return (
        point: _boundary(input, port),
        outward: Offset.fromDirection(
          (input ? 0 : math.pi) + design.aim(contact).steps * math.pi / 4,
        ),
      );
    }
    final count = design.sockets(cell, output: output);
    final face = Offset(output ? 1 : -1, 0);
    final offset =
        face * (_span * .33) +
        Offset(0, count == 2 ? (port == 0 ? -13 : 13) : 0);
    final orientation = design.orientation(cell);
    return (
      point: _mount(cell) + _orient(offset, orientation),
      outward: _orient(face, orientation),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_grid.isEmpty) return const SizedBox.shrink();
    final sheet = context.sheet;
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _AssemblyDrawing(
            grid: _grid,
            enclosure: _case,
            packed: packed && onInsert == null,
            wires: [
              if (!packed)
                for (final wire in design.wires)
                  (_contact(wire.from, true), _contact(wire.to, false)),
            ],
            edgeMarks: [
              for (var port = 0; port < feeds.length; port++)
                _contact((cell: AssemblyBlueprint.inputs, port: port), true),
              for (var port = 0; port < output.length; port++)
                _contact((cell: AssemblyBlueprint.outputs, port: port), false),
            ],
            sheet: sheet,
          ),
        ),
        if (packed)
          _at(
            _case.center,
            _case.deflate(12).size,
            onInsert != null
                ? Center(
                    child: Tooltip(
                      message: 'Insert fabricated part in socket',
                      child: IconButton.outlined(
                        key: const ValueKey('empty-assembly-socket'),
                        onPressed: onInsert,
                        icon: const Icon(Icons.extension_outlined),
                      ),
                    ),
                  )
                : Semantics(
                    key: const ValueKey('fitted-assembly'),
                    label: '${design.partName}, fitted part',
                    excludeSemantics: true,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Icon(
                            design.mark.icon?.symbol ??
                                Icons.developer_board_outlined,
                            color: sheet.ink,
                            size: 26,
                          ),
                          Text(
                            design.partName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: draftingLettering(14),
                          ),
                        ],
                      ),
                    ),
                  ),
          )
        else
          for (var cell = 0; cell < AssemblyBlueprint.capacity; cell++)
            _at(_mount(cell), Size.square(_span * .78), _cell(context, cell)),
        for (final (i, feed) in feeds.indexed)
          _external(
            context,
            input: true,
            port: i,
            reading: '${_feedLabel(i)} · ${_units(feed)}',
          ),
        for (final (i, reading) in output.indexed)
          _external(
            context,
            input: false,
            port: i,
            reading: '${i + 1} · ${_units(reading)}',
          ),
        if (canEditJacks && feeds.length < AssemblyBlueprint.rows)
          _addJack(context, input: true),
        if (canEditJacks && output.length < AssemblyBlueprint.rows)
          _addJack(context, input: false),
        if (!packed)
          for (final entry in design.modules.entries) ...[
            for (var port = 0; port < entry.value.inputs; port++)
              _socket(context, (cell: entry.key, port: port), false),
            for (var port = 0; port < entry.value.outputs; port++)
              _socket(context, (cell: entry.key, port: port), true),
          ],
      ],
    );
  }

  Widget _cell(BuildContext context, int cell) {
    final sheet = context.sheet;
    final module = design.modules[cell];
    final selected = cell == selectedPart;
    final mark = Semantics(
      button: true,
      label: module?.label ?? 'Add part at mount ${cell + 1}',
      selected: selected,
      child: GestureDetector(
        key: ValueKey('assembly-cell-$cell'),
        behavior: HitTestBehavior.opaque,
        onTap: canEdit ? () => onCell(cell) : null,
        onLongPress: canEdit && module != null
            ? () => onChangePart(cell)
            : null,
        child: Center(
          child: module == null
              ? Icon(Icons.add, size: 14, color: sheet.faint)
              : _housing(context, cell, module, selected: selected),
        ),
      ),
    );
    if (!canEdit) return mark;
    if (module != null) {
      return Draggable<int>(
        data: cell,
        maxSimultaneousDrags: 1,
        feedback: SizedBox.square(
          dimension: _span * .78,
          child: Center(child: _housing(context, cell, module, selected: true)),
        ),
        childWhenDragging: Opacity(opacity: .35, child: mark),
        child: mark,
      );
    }
    return DragTarget<int>(
      onAcceptWithDetails: (details) => onMove(details.data, cell),
      builder: (context, accepted, rejected) => DecoratedBox(
        decoration: BoxDecoration(
          border: accepted.isEmpty ? null : Border.all(color: sheet.beam),
        ),
        child: mark,
      ),
    );
  }

  Widget _housing(
    BuildContext context,
    int cell,
    AssemblyModule module, {
    required bool selected,
  }) {
    final orientation = design.orientation(cell);
    final normal = Size(_span * .66, (_span * .57).clamp(32, 52));
    final turned = orientation.turns.isOdd;
    final rect = turned ? Size(normal.height, normal.width) : normal;
    return Tooltip(
      message:
          '${module.label} · ${orientation.turns * 90}°${orientation.flipped ? ' · flipped' : ''}',
      child: SizedBox(
        width: rect.width,
        height: rect.height,
        child: _AssemblyModuleSymbol(module: module, selected: selected),
      ),
    );
  }

  Widget _external(
    BuildContext context, {
    required bool input,
    required int port,
    required String reading,
  }) {
    final point = _boundary(input, port);
    final contact = (
      cell: input ? AssemblyBlueprint.inputs : AssemblyBlueprint.outputs,
      port: port,
    );
    final isLast = port == (input ? feeds.length : output.length) - 1;
    return Stack(
      children: [
        _at(
          point.translate((input ? -1 : 1) * (_stepX * .5), 0),
          Size(_stepX - 12, 20),
          Tooltip(
            message: 'Select ${_edgeLabel(contact)}',
            child: Semantics(
              selected: selectedEdge == contact,
              button: canEdit,
              child: GestureDetector(
                key: ValueKey('assembly-aim-${contact.cell}-$port'),
                behavior: HitTestBehavior.opaque,
                onTap: canEdit ? () => onSelectEdge(contact) : null,
                child: Center(
                  child: FittedBox(
                    child: Text(
                      reading,
                      style: draftingLettering(
                        11,
                        color: selectedEdge == contact
                            ? context.sheet.beam
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _socket(
          context,
          contact,
          input,
          onHold: canEditJacks && isLast
              ? () => onJack(input: input, delta: -1)
              : null,
        ),
      ],
    );
  }

  Widget _addJack(BuildContext context, {required bool input}) => _at(
    _boundary(input, input ? feeds.length : output.length),
    const Size.square(44),
    consoleButton(
      tooltip: input ? 'Add input' : 'Add output',
      onPressed: () => onJack(input: input, delta: 1),
      icon: Container(
        width: 21,
        height: 21,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.sheet.paper,
          border: Border.all(color: context.sheet.ink),
        ),
        child: const Icon(Icons.add, size: 15),
      ),
    ),
  );

  Widget _socket(
    BuildContext context,
    AssemblyContact socket,
    bool output, {
    VoidCallback? onHold,
  }) {
    final sheet = context.sheet;
    final mark = _contact(socket, output);
    final wired = design.wires.any(
      (wire) => (output ? wire.from : wire.to) == socket,
    );
    final active = (output && socket == selected) || socket == selectedEdge;
    final name = switch (socket.cell) {
      AssemblyBlueprint.inputs => 'Feed ${_feedLabel(socket.port)}',
      AssemblyBlueprint.outputs => 'Output ${socket.port + 1}',
      _ =>
        '${design.modules[socket.cell]!.label} ${output ? 'output' : 'input'} ${socket.port + 1}',
    };
    return _at(
      mark.point,
      Size.square(socket.cell < 0 ? 38 : 24),
      Semantics(
        label: name,
        selected: active,
        button: true,
        child: GestureDetector(
          key: ValueKey(
            'assembly-${output ? 'out' : 'in'}-${socket.cell}-${socket.port}',
          ),
          behavior: HitTestBehavior.opaque,
          onTap: canEdit ? () => onSocket(socket, output: output) : null,
          onLongPress: onHold,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: socket.cell < 0 ? BoxShape.rectangle : BoxShape.circle,
                color: active
                    ? sheet.beam
                    : wired
                    ? sheet.ink
                    : sheet.paper,
                border: Border.all(color: active ? sheet.beam : sheet.ink),
              ),
              child: SizedBox.square(dimension: socket.cell < 0 ? 13 : 9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _at(Offset center, Size size, Widget child) => Positioned(
    left: center.dx - size.width / 2,
    top: center.dy - size.height / 2,
    width: size.width,
    height: size.height,
    child: child,
  );
}

class _AssemblyDrawing extends CustomPainter {
  const _AssemblyDrawing({
    required this.grid,
    required this.enclosure,
    required this.packed,
    required this.wires,
    required this.edgeMarks,
    required this.sheet,
  });

  final Rect grid;
  final Rect enclosure;
  final bool packed;
  final List<(_JackMark, _JackMark)> wires;
  final List<_JackMark> edgeMarks;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    paintDraftingGrid(
      canvas,
      grid: grid,
      tile: Size(grid.width / 5, grid.height / 3),
      columns: 5,
      rows: 3,
      sheet: sheet,
      size: 9,
    );
    final rim = Paint()
      ..color = sheet.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    if (packed) canvas.drawRect(enclosure, Paint()..color = sheet.paper);
    canvas.drawRect(enclosure, rim);
    canvas.drawRect(enclosure.deflate(3), rim..strokeWidth = .65);
    canvas.save();
    canvas.clipRect(enclosure);
    final routeArea = enclosure.deflate(3);
    Offset control(_JackMark mark, double bend) {
      final point = mark.point + mark.outward * bend;
      return Offset(
        point.dx.clamp(routeArea.left, routeArea.right),
        point.dy.clamp(routeArea.top, routeArea.bottom),
      );
    }

    for (final (from, to) in wires) {
      final bend = ((to.point - from.point).distance * .4).clamp(12.0, 65.0);
      final start = control(from, 12);
      final end = control(to, 12);
      final a = control(from, bend + 12);
      final b = control(to, bend + 12);
      canvas.drawPath(
        Path()
          ..moveTo(from.point.dx, from.point.dy)
          ..lineTo(start.dx, start.dy)
          ..cubicTo(a.dx, a.dy, b.dx, b.dy, end.dx, end.dy)
          ..lineTo(to.point.dx, to.point.dy),
        Paint()
          ..color = sheet.beam
          ..strokeWidth = 1.65
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();
    final direction = Paint()
      ..color = sheet.ink
      ..strokeWidth = 1.2;
    for (final mark in edgeMarks) {
      final face = -mark.outward;
      final tip = mark.point + face * 18;
      final side = Offset(-face.dy, face.dx);
      canvas.drawLine(mark.point, tip, direction);
      canvas.drawLine(tip - face * 4 + side * 3, tip, direction);
      canvas.drawLine(tip - face * 4 - side * 3, tip, direction);
    }
  }

  @override
  bool shouldRepaint(_AssemblyDrawing oldDelegate) =>
      oldDelegate.grid != grid ||
      oldDelegate.enclosure != enclosure ||
      oldDelegate.packed != packed ||
      oldDelegate.wires != wires ||
      oldDelegate.edgeMarks != edgeMarks ||
      oldDelegate.sheet != sheet;
}

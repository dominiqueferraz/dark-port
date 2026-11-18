import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'assembly.dart';
import 'board_history.dart';
import 'drafting_controls.dart';
import 'drafting_grid.dart';
import 'drafting_parts.dart';
import 'drafting_theme.dart';
import 'fabrication_controls.dart';
import 'fabrication_socket.dart';
import 'optical_bay.dart';
import 'optical_deck.dart';
import 'part_symbols.dart';
import 'puzzle_console.dart';
import 'sheet_style.dart';
import 'socket_aim.dart';
import 'solution_stars.dart';
import 'splitter_blueprint.dart';
import 'workbench_boards.dart';
import 'workbench_part_dialog.dart';
import 'workbench_part_mark.dart';

part 'assembly_workbench.dart';

enum _OutputJack { a, b }

enum _OpticalSelection { output, input, splitter, laser }

class WorkbenchScreen extends StatefulWidget {
  const WorkbenchScreen({
    super.key,
    required this.blueprints,
    required this.onSave,
    this.opticalSocket,
    this.startWithBlueprints = false,
    this.assemblies = const {},
    this.onSaveAssembly,
    this.fixture,
    this.assembly,
    this.assemblyInstalled = false,
    this.brief,
    this.onAssemblyChange,
    this.onBack,
  });

  final Set<SplitterBlueprint> blueprints;
  final Future<bool> Function(SplitterBlueprint) onSave;
  final FabricationSocket<SplitterBlueprint>? opticalSocket;
  final bool startWithBlueprints;
  final Set<AssemblyBlueprint> assemblies;
  final Future<bool> Function(AssemblyBlueprint)? onSaveAssembly;
  final AssemblyFixture? fixture;
  final AssemblyBlueprint? assembly;
  final bool assemblyInstalled;
  final PuzzleBrief? brief;
  final void Function(AssemblyBlueprint, {required bool installed})?
  onAssemblyChange;
  final VoidCallback? onBack;

  @override
  State<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends State<WorkbenchScreen> {
  late final _splitters = {...widget.blueprints};
  late final _assemblies = {...widget.assemblies};
  late bool _teaching =
      widget.opticalSocket != null &&
      !widget.startWithBlueprints &&
      !_tutorialComplete;
  late bool _useSplitter = widget.opticalSocket != null;
  late bool _showBlueprints = widget.startWithBlueprints;
  late Object? _selectedBlueprint = _blueprints.firstOrNull;

  bool get _tutorialComplete => _splitters.any((design) {
    final board = aimedWorkbenchBench(
      workbenchDiagonalLatch.board,
      design.inputDirection(),
    );
    return traceOptics(board, [workbenchSocket.fit(design)]).solves(board);
  });

  bool get _freeBench =>
      widget.onSaveAssembly != null && widget.fixture == null;

  FabricationSocket<Object>? get _socketRequirement =>
      widget.opticalSocket ?? widget.fixture?.socket;

  Iterable<Object> get _blueprints sync* {
    if (widget.fixture == null) yield* _splitters;
    if (widget.opticalSocket == null) {
      yield* _assemblies.where(
        (design) => _socketRequirement?.accepts(design) ?? true,
      );
    }
  }

  bool get _showSplitter => _showBlueprints
      ? (_selectedBlueprint == null
            ? _useSplitter
            : _selectedBlueprint is SplitterBlueprint)
      : _useSplitter;

  SplitterBlueprint? get _previewSplitter =>
      _selectedBlueprint is SplitterBlueprint
      ? _selectedBlueprint as SplitterBlueprint
      : null;

  SplitterPort _a = SplitterPort.straight;
  SplitterPort _b = SplitterPort.straight;
  _OutputJack? _filterOn;
  _OutputJack _port = _OutputJack.b;
  _OpticalSelection _focus = _OpticalSelection.output;
  SocketAim _inputAim = SocketAim.straight;
  int _turns = 0;
  BeamDirection _laserDirection = BeamDirection.north;
  final _fitted = _OutputJack.values.toSet();
  SplitterBlueprint? _tested;
  WorkbenchPartMark _splitterMark = unmarkedWorkbenchPart;
  bool _saving = false;
  String? _message;

  late var _design = _forSheet(widget.assembly ?? AssemblyBlueprint.blank);
  late AssemblyBlueprint? _mountedAssembly = widget.assemblyInstalled
      ? widget.assembly
      : null;
  late bool _puzzleView = widget.fixture != null;
  final _history = BoardHistory<AssemblyBlueprint>();
  AssemblyContact? _source;
  AssemblyContact? _edge;
  int? _part;
  late var _mask = (1 << _feeds.length) - 1;

  void _startTutorial() => setState(() {
    _useSplitter = true;
    _teaching = true;
    _showBlueprints = false;
    _a = SplitterPort.straight;
    _b = SplitterPort.straight;
    _filterOn = null;
    _port = _OutputJack.b;
    _focus = _OpticalSelection.output;
    _inputAim = SocketAim.straight;
    _turns = 0;
    _laserDirection = BeamDirection.north;
    _fitted.addAll(_OutputJack.values);
    _tested = null;
    _splitterMark = unmarkedWorkbenchPart;
    _message = null;
  });

  bool get _canTest => !_saving && _fitted.length == 2 && _a != _b;

  void _editPorts(VoidCallback edit) => setState(() {
    edit();
    _tested = null;
    _message = null;
  });

  void _selectPort(_OutputJack port) {
    if (_fitted.contains(port)) {
      setState(() {
        _port = port;
        _focus = _OpticalSelection.output;
      });
    } else {
      _editPorts(() {
        _port = port;
        _focus = _OpticalSelection.output;
        _fitted.add(port);
      });
    }
  }

  void _test() => setState(() {
    _tested = SplitterBlueprint(
      _a,
      _b,
      mark: _splitterMark,
      inputAim: _inputAim,
      turns: _turns,
      filteredPort: switch (_filterOn) {
        _OutputJack.a => _a,
        _OutputJack.b => _b,
        null => null,
      },
    );
    _message = null;
  });

  Future<void> _customizeAndSave(Object candidate) async {
    final (mark, defaultName) = switch (candidate) {
      SplitterBlueprint() => (
        candidate.mark,
        candidate.filteredPort == null
            ? 'Workbench splitter'
            : 'Filtered splitter',
      ),
      AssemblyBlueprint() => (candidate.mark, candidate.label),
      _ => throw ArgumentError.value(candidate),
    };
    final customized = await showDialog<WorkbenchPartMark>(
      context: context,
      builder: (context) =>
          WorkbenchPartDialog(mark: mark, defaultName: defaultName),
    );
    if (!mounted || customized == null) return;
    final design = switch (candidate) {
      SplitterBlueprint() => candidate.withMark(customized),
      AssemblyBlueprint() => candidate.withMark(customized),
      _ => throw ArgumentError.value(candidate),
    };
    final fromBuild = !_showBlueprints;
    setState(() {
      _saving = true;
      _message = null;
      _source = null;
    });
    final saved = switch (design) {
      SplitterBlueprint() => await widget.onSave(design),
      AssemblyBlueprint() => await widget.onSaveAssembly!(design),
      _ => throw ArgumentError.value(design),
    };
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) {
        switch (design) {
          case SplitterBlueprint():
            _splitters.add(design);
            if (fromBuild) {
              _splitterMark = design.mark;
              _tested = design;
            }
          case AssemblyBlueprint():
            _assemblies.add(design);
            if (fromBuild && widget.fixture == null) _design = design;
        }
        _selectedBlueprint = design;
        _message = _teaching
            ? 'Tutorial complete. Blueprint saved.'
            : 'Blueprint saved.';
        _teaching = false;
        _showBlueprints = true;
      } else {
        _message = 'The blueprint could not be saved. Try again.';
      }
    });
  }

  void _setLibrary(bool show) {
    if (!show && widget.opticalSocket != null && !_tutorialComplete) {
      _startTutorial();
      return;
    }
    setState(() {
      _puzzleView = false;
      _showBlueprints = show;
      _source = null;
      _message = null;
      if (show) _selectedBlueprint ??= _blueprints.firstOrNull;
    });
  }

  void _showPuzzle() => setState(() {
    _puzzleView = true;
    _showBlueprints = false;
    _source = null;
    _message = null;
  });

  void _loadBlueprint() {
    switch (_selectedBlueprint) {
      case final SplitterBlueprint design:
        setState(() {
          _useSplitter = true;
          _a = design.first;
          _b = design.second;
          _filterOn = switch (design.filteredPort) {
            null => null,
            final port => port == _a ? _OutputJack.a : _OutputJack.b,
          };
          _port = _OutputJack.b;
          _focus = _OpticalSelection.output;
          _inputAim = design.inputAim;
          _turns = design.turns;
          _laserDirection = design.inputDirection();
          _splitterMark = design.mark;
          _fitted.addAll(_OutputJack.values);
          _tested = design;
        });
      case final AssemblyBlueprint design:
        _commit(_forSheet(design));
        setState(() => _useSplitter = false);
    }
    _setLibrary(false);
  }

  List<double> get _feeds => widget.fixture?.feeds ?? const [100, 80, 60];
  bool get _solved =>
      _mountedAssembly != null && widget.fixture!.solves(_mountedAssembly!);
  bool get _canEdit => !_saving && !_showBlueprints && !_puzzleView;
  AssemblyBlueprint _forSheet(AssemblyBlueprint design) {
    final fixture = widget.fixture;
    return fixture == null
        ? design
        : design.withJacks(fixture.feeds.length, fixture.targets.length);
  }

  void _jacks({required bool input, required int delta}) {
    _commit(
      _design.withJacks(
        _design.inputCount + (input ? delta : 0),
        _design.outputCount + (input ? 0 : delta),
      ),
    );
  }

  void _orient(int step, {bool flip = false}) {
    final cell = _part!;
    final orientation = _design.orientation(cell);
    _commit(
      _design.orient(cell, (
        turns: orientation.turns + step,
        flipped: flip ? !orientation.flipped : orientation.flipped,
      )),
    );
  }

  void _tapCell(int cell) {
    if (_design.modules.containsKey(cell)) {
      setState(() {
        _part = cell;
        _edge = null;
        _source = null;
        _message = null;
      });
    } else {
      _choosePart(cell);
    }
  }

  void _selectEdge(AssemblyContact contact) => setState(() {
    _edge = contact;
    _part = null;
    _source = null;
    _message = null;
  });

  void _commit(AssemblyBlueprint next, {bool record = true}) {
    if (_design == next) return;
    if (record) _history.record(_design);
    setState(() {
      _design = next;
      if (!next.modules.containsKey(_part)) _part = null;
      if (_edge case final edge? when !next.hasEdgeSocket(edge)) _edge = null;
      _source = null;
      _message = null;
    });
    if (_mountedAssembly == null) {
      widget.onAssemblyChange?.call(next, installed: false);
    }
  }

  void _fitAssembly(AssemblyBlueprint design) {
    if (_socketRequirement?.accepts(design) != true) return;
    setState(() {
      _design = design;
      _mountedAssembly = design;
      _mask = (1 << _feeds.length) - 1;
      _puzzleView = true;
      _showBlueprints = false;
      _source = null;
      _edge = null;
      _part = null;
      _message = null;
    });
    widget.onAssemblyChange?.call(design, installed: true);
  }

  Future<void> _choosePart(int mount) async {
    final current = _design.modules[mount];
    final choice = await showDialog<({AssemblyModule? module, bool splitter})>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: context.sheet.paper,
        title: Text(current == null ? 'Add part' : 'Change part'),
        children: [
          if (_freeBench && !_useSplitter)
            _partOption(
              const OpticalPartSymbol.optic(
                OpticKind.workbenchSplitter,
                fitted: true,
              ),
              'Optical splitter',
              'Splits a light pulse between two aimable outputs.',
              () => Navigator.pop(context, (module: null, splitter: true)),
            ),
          for (final module in AssemblyModule.values)
            _partOption(
              _AssemblyModuleSymbol(module: module),
              module.label,
              module.rule,
              () => Navigator.pop(context, (module: module, splitter: false)),
              key: ValueKey('assembly-module-${module.name}'),
            ),
          if (_useSplitter)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(context, (module: null, splitter: false)),
              child: _iconLabel(
                Icons.arrow_back,
                _design == AssemblyBlueprint.blank
                    ? 'Return to empty mounts'
                    : 'Return to assembly',
                size: 14,
              ),
            )
          else if (current != null)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(context, (module: null, splitter: false)),
              child: _iconLabel(
                Icons.remove_circle_outline,
                'Remove module',
                size: 14,
              ),
            ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice.splitter) {
      setState(() {
        _useSplitter = true;
        _showBlueprints = false;
        _focus = _OpticalSelection.splitter;
        _source = null;
        _message = null;
      });
      return;
    }
    if (_useSplitter && choice.module == null) {
      setState(() {
        _useSplitter = false;
        _showBlueprints = false;
        _message = null;
      });
      return;
    }
    _commit(_design.place(mount, choice.module));
    setState(() {
      _useSplitter = false;
      _showBlueprints = false;
      _part = choice.module == null ? null : mount;
      _edge = null;
      _message = null;
    });
  }

  Widget _partOption(
    Widget symbol,
    String name,
    String description,
    VoidCallback onPressed, {
    Key? key,
  }) => SimpleDialogOption(
    key: key,
    onPressed: onPressed,
    child: Row(
      spacing: 12,
      children: [
        SizedBox(width: 42, height: 30, child: symbol),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: draftingLettering(16)),
              Text(description, style: draftingLettering(12)),
            ],
          ),
        ),
      ],
    ),
  );

  int get _nextMount => [
    4,
    3,
    5,
    1,
    7,
    0,
    2,
    6,
    8,
  ].firstWhere((cell) => !_design.modules.containsKey(cell), orElse: () => 4);

  void _socket(AssemblyContact contact, {required bool output}) {
    if (output) {
      setState(() {
        _source = _source == contact ? null : contact;
        _message = null;
      });
      return;
    }
    if (_source case final source?) {
      final next = _design.connect(source, contact);
      if (next == null) {
        setState(
          () => _message =
              'Choose an input that keeps the circuit free of loops.',
        );
      } else {
        _commit(next);
        if (_source != null) setState(() => _source = null);
      }
    } else if (_design.wires.any((wire) => wire.to == contact)) {
      _commit(_design.disconnect(contact));
    } else {
      setState(() => _message = 'Choose an output socket first.');
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && (widget.fixture == null || _puzzleView),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_saving && widget.fixture != null && !_puzzleView) {
        _showPuzzle();
      }
    },
    child: DraftingScaffold(
      resizeToAvoidBottomInset: false,
      child: DraftingSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConsoleHeader(
              title: _puzzleView
                  ? widget.brief!.title.toUpperCase()
                  : _teaching
                  ? 'WORKBENCH TUTORIAL'
                  : 'WORKBENCH',
              caption: _puzzleView || widget.brief?.sheet == null
                  ? null
                  : '${widget.brief!.sheet} · ${widget.brief!.title}',
              onBack: _saving
                  ? null
                  : widget.fixture != null && !_puzzleView
                  ? _showPuzzle
                  : widget.onBack ?? () => Navigator.pop(context),
              backLabel: _puzzleView
                  ? 'Back to puzzles'
                  : widget.fixture != null || widget.opticalSocket != null
                  ? 'Return to puzzle'
                  : 'Return to title',
              action: _headerActions(),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _showSplitter ? _splitterBench() : _assemblyBench(),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _splitterBench() {
    final design = _showBlueprints ? _previewSplitter : _tested;
    final board = aimedWorkbenchBench(
      _teaching ? workbenchDiagonalLatch.board : workbenchTestBoard,
      _showBlueprints
          ? design?.inputDirection() ?? _laserDirection
          : _laserDirection,
    );
    final layout = [
      design == null ? workbenchSocket : workbenchSocket.fit(design),
    ];
    final trace = traceOptics(board, layout);
    final solved = _teaching && trace.solves(board);
    final canSave =
        !_saving &&
        _tested != null &&
        trace.segments.any((beam) => beam.fromOptic == workbenchSocket.id) &&
        (_teaching ? solved : !_splitters.contains(_tested));

    return _bench(
      preview: DraftingPlayfield(
        aspectRatio: board.floor.width / board.floor.height,
        builder: (context, size) => _opticalEnclosure(
          OpticalDeckGeometry(board, size),
          layout,
          trace,
          solved,
        ),
      ),
      controls: () => _builder(trace, solved),
      tools: _portTools,
      onTest: _canTest ? _test : null,
      onSave: canSave ? () => _customizeAndSave(_tested!) : null,
    );
  }

  Widget _assemblyBench() {
    final preview = _puzzleView
        ? _mountedAssembly ?? _forSheet(AssemblyBlueprint.blank)
        : _showBlueprints && _selectedBlueprint is AssemblyBlueprint
        ? _selectedBlueprint as AssemblyBlueprint
        : _design;
    final feeds = _feeds.take(preview.inputCount).toList();
    final active = [
      for (final (index, feed) in feeds.indexed)
        if (_mask & (1 << index) != 0) feed else 0.0,
    ];
    final output = preview.evaluate(active, preview.outputCount);
    final grid = LayoutBuilder(
      builder: (context, constraints) => _AssemblyGrid(
        design: preview,
        packed: _puzzleView,
        onInsert: _puzzleView && _mountedAssembly == null
            ? () => _setLibrary(true)
            : null,
        feeds: active,
        output: output,
        selected: _source,
        selectedPart: _showBlueprints ? null : _part,
        selectedEdge: _showBlueprints ? null : _edge,
        canEdit: _canEdit,
        size: constraints.biggest,
        onCell: _tapCell,
        onChangePart: _choosePart,
        onMove: (from, to) {
          _commit(_design.move(from, to));
          setState(() {
            _part = to;
            _edge = null;
          });
        },
        canEditJacks: widget.fixture == null && _canEdit,
        onJack: _jacks,
        onSelectEdge: _selectEdge,
        onSocket: _socket,
      ),
    );
    return _bench(
      preview: grid,
      controls: () => _tests(feeds, output),
      tools: _assemblyTools,
      onSave:
          !_saving &&
              _design.modules.isNotEmpty &&
              _design.wires.isNotEmpty &&
              !_assemblies.contains(_design)
          ? () => _customizeAndSave(_design)
          : null,
    );
  }

  Widget _bench({
    required Widget preview,
    required Widget Function() controls,
    required Widget Function() tools,
    VoidCallback? onTest,
    required VoidCallback? onSave,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final panel = _panel(
        controls: controls,
        tools: tools,
        onTest: onTest,
        onSave: onSave,
        scroll: useConsoleColumns(constraints),
      );
      if (useConsoleColumns(constraints)) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: preview),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: panel),
          ],
        );
      }
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(aspectRatio: 1.6, child: preview),
            panel,
          ],
        ),
      );
    },
  );

  Widget _opticalEnclosure(
    OpticalDeckGeometry geometry,
    List<Optic> layout,
    OpticalTrace trace,
    bool solved,
  ) {
    final center = geometry.project(workbenchSocket.position);
    final half = (geometry.tile.shortestSide * 1.26).clamp(24.0, 64.0);
    final enclosure = Rect.fromCenter(
      center: center,
      width: half * 2,
      height: half * 2,
    );
    final preview = _showBlueprints ? _previewSplitter : null;
    final a = preview?.first ?? _a;
    final b = preview?.second ?? _b;
    final forward = preview?.forward ?? BeamDirection.north.turn(_turns * 2);
    Offset wallPoint(Offset direction) =>
        center +
        direction * (half / math.max(direction.dx.abs(), direction.dy.abs()));

    Offset output(SplitterPort port, _OutputJack jack) {
      final direction = geometry.heading(forward.turn(port.steps));
      final along = wallPoint(direction);
      if (a != b) return along;
      const spacing = 28.0;
      final shift = jack == _OutputJack.a ? 0.0 : spacing;
      if (direction.dy.abs() >= direction.dx.abs()) {
        final start = (along.dx - spacing / 2).clamp(
          enclosure.left + 5,
          enclosure.right - spacing - 5,
        );
        return Offset(start + shift, along.dy);
      }
      final start = (along.dy - spacing / 2).clamp(
        enclosure.top + 5,
        enclosure.bottom - spacing - 5,
      );
      return Offset(along.dx, start + shift);
    }

    final marks = {
      _OutputJack.a: output(a, _OutputJack.a),
      _OutputJack.b: output(b, _OutputJack.b),
    };
    final inward = preview?.inputDirection() ?? forward.turn(_inputAim.steps);
    final input = wallPoint(-geometry.heading(inward));
    final laser = geometry.source(geometry.level.sources.first);
    final missesInput = geometry.level.direction != inward;
    final rejectedAt = missesInput
        ? geometry.unproject(
            wallPoint(-geometry.heading(geometry.level.direction)),
          )
        : null;
    final displayTrace = rejectedAt == null
        ? trace
        : OpticalTrace([
            for (final beam in trace.segments)
              if (beam.toOptic == workbenchSocket.id)
                (
                  from: beam.from,
                  to: rejectedAt,
                  strength: beam.strength,
                  receiver: beam.receiver,
                  fromOptic: beam.fromOptic,
                  toOptic: beam.toOptic,
                  blocked: beam.blocked,
                  source: beam.source,
                )
              else
                beam,
          ], trace.lit);
    final filter = _showBlueprints
        ? switch (preview?.filteredPort) {
            final port? => port == a ? _OutputJack.a : _OutputJack.b,
            null => null,
          }
        : _filterOn;
    return Stack(
      fit: StackFit.expand,
      children: [
        OpticalDeck(
          geometry: geometry,
          layout: layout,
          trace: displayTrace,
          held: null,
          dropSpot: null,
          validDrop: false,
          opened: solved,
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _OpticalEnclosureDrawing(
              enclosure,
              input,
              layout.single.blueprint == null
                  ? [
                      for (final entry in marks.entries)
                        if (_fitted.contains(entry.key)) entry.value,
                    ]
                  : const [],
              filter == null ? null : Offset.lerp(center, marks[filter], .62),
              context.sheet,
            ),
          ),
        ),
        _pin(input, 'IN'),
        if (!_showBlueprints) ...[
          _selectBenchItem(center, _OpticalSelection.splitter, 'Splitter'),
          _selectBenchItem(laser, _OpticalSelection.laser, 'Test laser'),
        ],
        for (final entry in marks.entries)
          _pin(
            entry.value,
            _showBlueprints || _fitted.contains(entry.key)
                ? entry.key.name.toUpperCase()
                : '+',
            port: entry.key,
          ),
      ],
    );
  }

  Widget _pin(Offset point, String label, {_OutputJack? port}) {
    final sheet = context.sheet;
    final selected =
        !_showBlueprints &&
        (port == null
            ? _focus == _OpticalSelection.input
            : _focus == _OpticalSelection.output && _port == port);
    return Positioned(
      left: point.dx - 17,
      top: point.dy - 17,
      width: 34,
      height: 34,
      child: Semantics(
        label: port == null
            ? 'Optical input'
            : label == '+'
            ? 'Add optical output ${port.name.toUpperCase()}'
            : 'Select optical output ${port.name.toUpperCase()}',
        selected: selected,
        button: !_showBlueprints,
        child: GestureDetector(
          key: _showBlueprints
              ? null
              : ValueKey('optical-port-${port?.name ?? 'input'}'),
          behavior: HitTestBehavior.opaque,
          onTap: _showBlueprints || _saving
              ? null
              : () => port == null
                    ? setState(() => _focus = _OpticalSelection.input)
                    : _selectPort(port),
          child: Center(
            child: Container(
              width: label == 'IN' ? 23 : 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? sheet.ink : sheet.paper,
                border: Border.all(color: sheet.ink),
              ),
              child: Text(
                label,
                style: draftingLettering(
                  10,
                  color: selected ? sheet.paper : sheet.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectBenchItem(
    Offset point,
    _OpticalSelection selection,
    String label,
  ) => Positioned(
    left: point.dx - 21,
    top: point.dy - 21,
    width: 42,
    height: 42,
    child: Semantics(
      button: true,
      label: 'Select $label',
      selected: selection == _focus,
      child: GestureDetector(
        key: ValueKey('optical-${selection.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: _saving ? null : () => setState(() => _focus = selection),
        child: selection == _focus
            ? DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: context.sheet.beam),
                ),
              )
            : const SizedBox.expand(),
      ),
    ),
  );

  Widget? _headerActions() {
    if (_teaching) return null;
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        if (!_puzzleView)
          Semantics(
            selected: _showBlueprints,
            child: _action(
              'Blueprints',
              Icons.description_outlined,
              _saving ? null : () => _setLibrary(true),
              selected: _showBlueprints,
            ),
          ),
        if (widget.brief case final brief?)
          SolutionStars(stars: brief.stars)
        else
          _action(
            'Tutorial',
            Icons.school_outlined,
            _saving ? null : _startTutorial,
          ),
      ],
    );
  }

  Widget _panel({
    required Widget Function() controls,
    required Widget Function() tools,
    required VoidCallback? onTest,
    required VoidCallback? onSave,
    required bool scroll,
  }) {
    final body = _showBlueprints ? _blueprintList() : controls();
    final selected = _selectedBlueprint;
    final socket = _socketRequirement;
    final canLoad =
        !_saving && selected != null && (socket?.accepts(selected) ?? true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_teaching && !_puzzleView) ...[
          Row(
            spacing: 6,
            children: [
              Expanded(
                child: Semantics(
                  selected: !_showBlueprints,
                  child: _action(
                    'Build',
                    Icons.build_outlined,
                    _saving ? null : () => _setLibrary(false),
                    selected: !_showBlueprints,
                    compact: true,
                  ),
                ),
              ),
              if (_freeBench)
                Expanded(
                  child: _action(
                    'Add part',
                    Icons.add_box_outlined,
                    _saving ? null : () => _choosePart(_nextMount),
                    compact: true,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
        ],
        if (scroll)
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey(_showBlueprints),
              child: body,
            ),
          )
        else
          body,
        if (_saving) const LinearProgressIndicator(minHeight: 2),
        if (_showBlueprints)
          Row(
            spacing: 6,
            children: [
              Expanded(
                child: _action(
                  'Customize',
                  Icons.edit_outlined,
                  _saving || selected == null
                      ? null
                      : () => _customizeAndSave(selected),
                ),
              ),
              Expanded(
                child: _action(
                  socket == null ? 'Load blueprint' : 'Fit to puzzle',
                  socket == null
                      ? Icons.download_outlined
                      : Icons.extension_outlined,
                  !canLoad
                      ? null
                      : switch (selected) {
                          AssemblyBlueprint() when socket != null =>
                            () => _fitAssembly(selected),
                          SplitterBlueprint() when socket != null =>
                            () => Navigator.pop(context, selected),
                          _ => _loadBlueprint,
                        },
                ),
              ),
            ],
          )
        else if (_puzzleView)
          FabricationControls(
            empty: _mountedAssembly == null,
            onWorkbench: () => _setLibrary(false),
            onInsert: () => _setLibrary(true),
          )
        else ...[
          tools(),
          Row(
            spacing: 6,
            children: [
              if (_useSplitter)
                Expanded(
                  child: _action('Test', Icons.play_arrow_outlined, onTest),
                ),
              Expanded(
                flex: 2,
                child: _action('Save blueprint', Icons.save_outlined, onSave),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _assemblyTools() {
    final socket = _edge;
    final cell = _part;
    VoidCallback? turn(int step) {
      if (!_canEdit) return null;
      if (socket == null) return cell == null ? null : () => _orient(step);
      final aim = _design.aim(socket).turn(step);
      return aim == null ? null : () => _commit(_design.aimSocket(socket, aim));
    }

    return _orientationTools(
      socket == null ? 'part' : _edgeLabel(socket),
      turn,
      flip: socket != null || !_canEdit || cell == null
          ? null
          : () => _orient(0, flip: true),
      history:
          _design.modules.isNotEmpty || _history.canUndo || _history.canRedo
          ? ConsoleTools(
              onUndo: !_saving && _history.canUndo
                  ? () => _commit(_history.undo(_design), record: false)
                  : null,
              onRedo: !_saving && _history.canRedo
                  ? () => _commit(_history.redo(_design), record: false)
                  : null,
              onReset: _saving
                  ? null
                  : () => _commit(_forSheet(AssemblyBlueprint.blank)),
            )
          : null,
    );
  }

  Widget _orientationTools(
    String selected,
    VoidCallback? Function(int) turn, {
    String? flipLabel,
    VoidCallback? flip,
    Widget? extra,
    Widget? history,
  }) => SizedBox(
    height: consoleButtonSize.height,
    child: Row(
      children: [
        Expanded(
          child: consoleButton(
            tooltip: 'Turn $selected left',
            onPressed: turn(-1),
            icon: const Icon(Icons.rotate_left),
          ),
        ),
        Expanded(
          child: consoleButton(
            tooltip: 'Turn $selected right',
            onPressed: turn(1),
            icon: const Icon(Icons.rotate_right),
          ),
        ),
        Expanded(
          child: consoleButton(
            tooltip: flipLabel ?? 'Flip $selected',
            onPressed: flip,
            icon: const Icon(Icons.flip),
          ),
        ),
        if (extra != null) Expanded(child: extra),
        if (history != null) ...[
          const DraftingCellDivider(),
          Expanded(flex: 3, child: history),
        ],
      ],
    ),
  );

  Widget _tests(List<double> feeds, List<double> output) {
    final fixture = widget.fixture;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        if (widget.brief case final brief?)
          PuzzleTitleBlock(
            brief: brief,
            status: _solved
                ? DraftingStatus.approved
                : DraftingStatus.inProgress,
            canHint: !_saving,
          ),
        if (fixture == null && _design.modules.isEmpty)
          Text(
            'Tap a mount or choose Add part. Fit sockets on the enclosure edge.',
            style: draftingLettering(12),
          ),
        if (_puzzleView || feeds.isNotEmpty || output.isNotEmpty)
          DraftingPartsList(
            rows: [
              if (_puzzleView)
                DraftingPartRow(
                  number: '1',
                  name: _mountedAssembly?.partName ?? fixture!.socket.label,
                  state: _mountedAssembly == null ? 'EMPTY' : 'FITTED',
                  symbol: Icon(
                    _mountedAssembly?.mark.icon?.symbol ??
                        Icons.developer_board_outlined,
                    size: 16,
                  ),
                ),
              for (final (index, feed) in feeds.indexed) _feedRow(index, feed),
              for (final (index, value) in output.indexed)
                DraftingPartRow(
                  key: ValueKey('assembly-output-$index'),
                  number: '${index + 1}',
                  name: 'OUTPUT',
                  state: fixture == null
                      ? _units(value)
                      : '${_units(value)} / ${_units(fixture.targetsFor(_mask)[index])}',
                  tone: value > 0 ? PartTone.lit : PartTone.plain,
                  symbol: const Icon(Icons.output, size: 16),
                ),
            ],
          ),
        if (_message ??
                (_source == null ? null : 'Choose an input socket.') ??
                (!_puzzleView && fixture?.solves(_design) == true
                    ? 'The blueprint meets the fixture tests. Save it, then fit it to the puzzle.'
                    : null)
            case final message?)
          Semantics(
            liveRegion: true,
            child: Text(message, style: draftingLettering(12)),
          ),
      ],
    );
  }

  Widget _feedRow(int index, double feed) {
    final active = _mask & (1 << index) != 0;
    return _selectableReading(
      key: ValueKey('assembly-feed-$index'),
      toggled: active,
      onTap: () => setState(() => _mask ^= 1 << index),
      child: DraftingPartRow(
        number: _feedLabel(index),
        name: 'TEST INPUT',
        state: _units(active ? feed : 0),
        tone: active ? PartTone.lit : PartTone.plain,
        symbol: Icon(
          active ? Icons.power_outlined : Icons.power_off_outlined,
          size: 16,
        ),
      ),
    );
  }

  Widget _selectableReading({
    Key? key,
    bool selected = false,
    bool? toggled,
    required VoidCallback onTap,
    required DraftingPartRow child,
  }) => Semantics(
    key: key,
    button: true,
    selected: toggled == null ? selected : null,
    toggled: toggled,
    child: Material(
      color: selected
          ? context.sheet.ink.withValues(alpha: .09)
          : Colors.transparent,
      child: InkWell(onTap: _saving ? null : onTap, child: child),
    ),
  );

  Widget _builder(OpticalTrace trace, bool tutorialSolved) {
    final tested = _tested;
    final branches = trace.segments
        .where((beam) => beam.fromOptic == workbenchSocket.id)
        .toList();
    final power = {
      if (tested != null)
        for (final (index, beam) in branches.indexed)
          tested.ports[index]: lightUnits(beam.strength * 100),
    };
    final status =
        _message ??
        (_fitted.length < 2
            ? 'Fit both outputs on the enclosure before testing.'
            : _a == _b
            ? 'Turn one output so the ports face different directions.'
            : tested != null && branches.isEmpty
            ? 'No pulse reached the input. Aim the test laser along the input’s sightline.'
            : _teaching && branches.isNotEmpty
            ? tutorialSolved
                  ? 'Both latches lit at 50 u each. Save the blueprint.'
                  : 'A latch is dark. Turn a port and test again.'
            : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_teaching && status != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _status(status),
          ),
        if (_teaching) ...[
          Text(
            'Select an output and aim it at a latch. The input must face the test laser.',
            style: draftingLettering(12, spacing: .2),
          ),
          const SizedBox(height: 6),
        ],
        DraftingPartsList(
          rows: [
            _selectableReading(
              selected: _focus == _OpticalSelection.laser,
              onTap: () => setState(() => _focus = _OpticalSelection.laser),
              child: const DraftingPartRow(
                number: '1',
                name: 'TEST LASER',
                state: '100 u',
                symbol: OpticalPartSymbol.source(),
              ),
            ),
            _selectableReading(
              selected: _focus == _OpticalSelection.input,
              onTap: () => setState(() => _focus = _OpticalSelection.input),
              child: DraftingPartRow(
                number: 'IN',
                name: 'INPUT',
                state: tested == null
                    ? '—'
                    : branches.isEmpty
                    ? '0 u'
                    : '100 u',
                tone: branches.isEmpty ? PartTone.plain : PartTone.lit,
                symbol: const Icon(Icons.input, size: 16),
              ),
            ),
            for (final (jack, port) in [
              (_OutputJack.a, _a),
              (_OutputJack.b, _b),
            ])
              _selectableReading(
                key: ValueKey('optical-reading-${jack.name}'),
                selected: _focus == _OpticalSelection.output && jack == _port,
                onTap: () => _selectPort(jack),
                child: DraftingPartRow(
                  number: jack.name.toUpperCase(),
                  name: 'OUTPUT',
                  state: !_fitted.contains(jack)
                      ? 'EMPTY'
                      : tested == null
                      ? '—'
                      : '${power[port] ?? '0'} u',
                  tone: power.containsKey(port) ? PartTone.lit : PartTone.plain,
                  symbol: Icon(
                    _fitted.contains(jack)
                        ? Icons.output
                        : Icons.add_box_outlined,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        if (!_teaching) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: 16,
                color: context.sheet.ink,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Half-power filter',
                  style: draftingLettering(12, spacing: .2),
                ),
              ),
              _filterButton('A', _OutputJack.a),
              const SizedBox(width: 5),
              _filterButton('B', _OutputJack.b),
            ],
          ),
        ],
        if (_teaching && status != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _status(status),
          ),
      ],
    );
  }

  Widget _filterButton(String label, _OutputJack jack) {
    final fitted = _filterOn == jack;
    return Semantics(
      selected: fitted,
      child: Tooltip(
        message: fitted
            ? 'Remove filter from Port $label'
            : 'Clip filter to Port $label',
        child: SizedBox(
          height: 32,
          child: _action(
            label,
            Icons.filter_alt_outlined,
            _saving || !_fitted.contains(jack)
                ? null
                : () => setState(() {
                    _filterOn = fitted ? null : jack;
                    _tested = null;
                    _message = null;
                  }),
            selected: fitted,
          ),
        ),
      ),
    );
  }

  Widget _portTools() {
    final jack = _port;
    final label = jack.name.toUpperCase();
    final port = jack == _OutputJack.a ? _a : _b;
    final available = !_saving && _fitted.contains(jack);
    VoidCallback? turn(int step) {
      if (_saving) return null;
      switch (_focus) {
        case _OpticalSelection.input:
          final aim = _inputAim.turn(step);
          return aim == null ? null : () => _editPorts(() => _inputAim = aim);
        case _OpticalSelection.splitter:
          return () => _editPorts(() => _turns = (_turns + step) % 4);
        case _OpticalSelection.laser:
          return () =>
              _editPorts(() => _laserDirection = _laserDirection.turn(step));
        case _OpticalSelection.output:
          break;
      }
      final index = port.index + step;
      if (!available || index < 0 || index >= SplitterPort.values.length) {
        return null;
      }
      return () => _editPorts(() {
        if (jack == _OutputJack.a) {
          _a = SplitterPort.values[index];
        } else {
          _b = SplitterPort.values[index];
        }
      });
    }

    final selected = switch (_focus) {
      _OpticalSelection.output => 'Port $label',
      _OpticalSelection.input => 'input',
      _OpticalSelection.splitter => 'splitter',
      _OpticalSelection.laser => 'test laser',
    };

    return _orientationTools(
      selected,
      turn,
      flipLabel: 'Flip splitter',
      flip: _saving
          ? null
          : () => _editPorts(() {
              _a = _a.opposite;
              _b = _b.opposite;
              _inputAim = _inputAim.mirrored;
            }),
      extra: !_teaching && _focus == _OpticalSelection.output
          ? consoleButton(
              tooltip: 'Remove optical output $label',
              onPressed: !available
                  ? null
                  : () => _editPorts(() {
                      _fitted.remove(jack);
                      if (_filterOn == jack) _filterOn = null;
                    }),
              icon: const Icon(Icons.remove_circle_outline),
            )
          : null,
    );
  }

  Widget _blueprintList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_message case final message?)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _status(message),
        ),
      if (_blueprints.isEmpty)
        _status(
          _socketRequirement == null
              ? 'Saved designs appear here.'
              : 'No compatible parts saved. Open Build to fabricate one.',
        ),
      for (final design in _blueprints)
        switch (design) {
          SplitterBlueprint() => _splitterRow(design),
          AssemblyBlueprint() => _blueprintRow(
            design,
            design.partName,
            Icon(
              design.mark.icon?.symbol ?? Icons.developer_board_outlined,
              size: 28,
            ),
          ),
          _ => throw StateError('Unknown blueprint: $design'),
        },
    ],
  );

  Widget _splitterRow(SplitterBlueprint design) {
    const compass = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final label = [
      design.mark.nameOr('Optical splitter'),
      '${_directionLabel(design.first)} + ${_directionLabel(design.second).toLowerCase()}',
      if (design.inputAim != SocketAim.straight || design.turns != 0)
        'Input ${compass[design.inputDirection().turn(4).index]} · case ${compass[design.forward.index]}',
      if (design.filteredPort case final port?)
        'Filter: ${_directionLabel(port).toLowerCase()}',
    ].join('\n');
    return _blueprintRow(
      design,
      label,
      design.mark.icon != null
          ? Icon(design.mark.icon!.symbol, size: 28)
          : _PortDiagram(
              ports: design.ports,
              filteredPort: design.filteredPort,
              height: 40,
            ),
    );
  }

  Widget _blueprintRow<T extends Object>(
    T design,
    String label,
    Widget symbol,
  ) {
    final sheet = context.sheet;
    final selected = _selectedBlueprint == design;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: OutlinedButton(
        key: ValueKey(design),
        onPressed: _saving
            ? null
            : () => setState(() {
                _selectedBlueprint = design;
                _message = null;
              }),
        style: OutlinedButton.styleFrom(
          foregroundColor: sheet.ink,
          side: BorderSide(color: selected ? sheet.ink : sheet.fineRule),
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(44, 48),
        ),
        child: Semantics(
          selected: selected,
          child: Row(
            children: [
              SizedBox(width: 40, child: symbol),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: draftingLettering(12, spacing: .2)),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(
    String label,
    IconData icon,
    VoidCallback? onPressed, {
    bool selected = false,
    bool compact = false,
  }) {
    final sheet = context.sheet;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? sheet.paper : sheet.ink,
        backgroundColor: selected ? sheet.ink : null,
        shape: const RoundedRectangleBorder(),
        minimumSize: Size(44, compact ? 38 : 44),
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      child: _iconLabel(icon, label),
    );
  }

  Widget _iconLabel(IconData icon, String label, {double size = 12}) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 5,
    children: [
      Icon(icon, size: 16),
      Flexible(child: Text(label, style: draftingLettering(size, spacing: .2))),
    ],
  );

  Widget _status(String text) => Semantics(
    liveRegion: true,
    child: Text(text, style: draftingLettering(12, spacing: .2)),
  );
}

String _directionLabel(SplitterPort port) => switch (port) {
  SplitterPort.left90 => 'Left',
  SplitterPort.left45 => 'Diagonal left',
  SplitterPort.straight => 'Straight',
  SplitterPort.right45 => 'Diagonal right',
  SplitterPort.right90 => 'Right',
};

class _PortDiagram extends StatelessWidget {
  const _PortDiagram({
    required this.ports,
    required this.height,
    this.filteredPort,
  });

  final List<SplitterPort> ports;
  final SplitterPort? filteredPort;
  final double height;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(height * 1.35, height),
    painter: _PortDiagramPainter(ports, filteredPort, context.sheet),
  );
}

class _PortDiagramPainter extends CustomPainter {
  const _PortDiagramPainter(this.ports, this.filteredPort, this.sheet);

  final List<SplitterPort> ports;
  final SplitterPort? filteredPort;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height * .69);
    final radius = size.height * .51;
    final rule = Paint()
      ..color = sheet.faint
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    final beam = Paint()
      ..color = sheet.ink
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: radius),
      math.pi,
      math.pi,
      false,
      rule,
    );
    for (final port in SplitterPort.values) {
      final heading = _heading(port);
      canvas.drawLine(
        pivot + heading * (radius - 3),
        pivot + heading * (radius + 2),
        rule,
      );
    }
    canvas.drawLine(pivot, pivot + Offset(0, size.height * .22), rule);
    for (final port in ports) {
      final heading = _heading(port);
      final tip = pivot + heading * (radius - 6);
      final side = Offset(-heading.dy, heading.dx);
      canvas.drawLine(pivot, tip, beam);
      canvas.drawLine(tip, tip - heading * 4 + side * 3, beam);
      canvas.drawLine(tip, tip - heading * 4 - side * 3, beam);
      if (port == filteredPort) {
        final clip = pivot + heading * ((radius - 6) / 2);
        final window = Rect.fromCenter(center: clip, width: 6, height: 6);
        canvas.drawRect(window, Paint()..color = sheet.paper);
        canvas.drawRect(window, rule..color = sheet.ink);
      }
    }
    canvas.drawCircle(pivot, 2.7, beam);
  }

  Offset _heading(SplitterPort port) =>
      Offset.fromDirection(-math.pi / 2 + port.steps * math.pi / 4);

  @override
  bool shouldRepaint(_PortDiagramPainter oldDelegate) =>
      sheet != oldDelegate.sheet ||
      filteredPort != oldDelegate.filteredPort ||
      ports.length != oldDelegate.ports.length ||
      ports.indexed.any((entry) => oldDelegate.ports[entry.$1] != entry.$2);
}

class _OpticalEnclosureDrawing extends CustomPainter {
  const _OpticalEnclosureDrawing(
    this.enclosure,
    this.input,
    this.directions,
    this.filter,
    this.sheet,
  );

  final Rect enclosure;
  final Offset input;
  final List<Offset> directions;
  final Offset? filter;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = sheet.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(enclosure, rule);
    canvas.drawRect(enclosure.deflate(3), rule..strokeWidth = .65);
    for (final port in [if (directions.isNotEmpty) input, ...directions]) {
      final vector = port - enclosure.center;
      if (vector.distance < 14) continue;
      final direction = vector / vector.distance;
      final guide = Paint()
        ..color = sheet.faint
        ..strokeWidth = 1;
      for (var step = 15.0; step < vector.distance - 6; step += 7) {
        canvas.drawLine(
          enclosure.center + direction * step,
          enclosure.center + direction * (step + 3),
          guide,
        );
      }
    }
    if (filter case final point?) {
      final mark = Rect.fromCenter(center: point, width: 10, height: 10);
      canvas.drawRect(mark, Paint()..color = sheet.paper);
      canvas.drawRect(mark, rule..strokeWidth = 1.3);
    }
  }

  @override
  bool shouldRepaint(_OpticalEnclosureDrawing oldDelegate) =>
      enclosure != oldDelegate.enclosure ||
      input != oldDelegate.input ||
      directions != oldDelegate.directions ||
      filter != oldDelegate.filter ||
      sheet != oldDelegate.sheet;
}

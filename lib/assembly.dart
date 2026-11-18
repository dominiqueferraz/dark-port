import 'dart:convert';
import 'dart:math' as math;

import 'fabrication_socket.dart';
import 'socket_aim.dart';
import 'workbench_part_mark.dart';

enum AssemblyModule {
  interlock(
    'Interlock',
    'AND',
    2,
    1,
    'Forwards its first input while both inputs are powered.',
  ),
  fanout(
    'Fan-out',
    'SPLIT',
    1,
    2,
    'Divides its input equally between two outputs.',
  ),
  pad('25 u pad', '−25', 1, 1, 'Removes 25 u from its input, down to zero.');

  const AssemblyModule(
    this.label,
    this.symbol,
    this.inputs,
    this.outputs,
    this.rule,
  );

  final String label;
  final String symbol;
  final int inputs;
  final int outputs;
  final String rule;

  double deliver(List<double> incoming) => switch (this) {
    interlock => incoming[1] > 0 ? incoming[0] : 0,
    fanout => incoming[0] / 2,
    pad => math.max(0, incoming[0] - 25),
  };
}

typedef AssemblyContact = ({int cell, int port});
typedef AssemblyWire = ({AssemblyContact from, AssemblyContact to});
typedef AssemblyOrientation = ({int turns, bool flipped});

class AssemblyBlueprint {
  AssemblyBlueprint._(
    Map<int, AssemblyModule> modules,
    Iterable<AssemblyWire> wires, {
    this.inputCount = rows,
    this.outputCount = rows,
    Map<int, AssemblyOrientation> orientations = const {},
    Map<AssemblyContact, SocketAim> aims = const {},
    this.mark = unmarkedWorkbenchPart,
  }) : modules = Map.unmodifiable(modules),
       wires = List.unmodifiable(wires),
       _orientations = Map.unmodifiable(orientations),
       _aims = Map.unmodifiable(aims);

  static final empty = AssemblyBlueprint._({}, []);
  static final blank = empty.withJacks(0, 0);
  static const columns = 3;
  static const rows = 3;
  static const capacity = columns * rows;
  static const inputs = -1;
  static const outputs = -2;

  final Map<int, AssemblyModule> modules;
  final List<AssemblyWire> wires;
  final int inputCount;
  final int outputCount;
  final Map<int, AssemblyOrientation> _orientations;
  final Map<AssemblyContact, SocketAim> _aims;
  final WorkbenchPartMark mark;

  AssemblyOrientation orientation(int cell) =>
      _orientations[cell] ?? (turns: 0, flipped: false);
  SocketAim aim(AssemblyContact socket) => _aims[socket] ?? SocketAim.straight;

  bool hasEdgeSocket(AssemblyContact socket) =>
      socket.port >= 0 &&
      socket.port <
          switch (socket.cell) {
            inputs => inputCount,
            outputs => outputCount,
            _ => 0,
          };

  AssemblyBlueprint aimSocket(AssemblyContact socket, SocketAim aim) {
    if (!hasEdgeSocket(socket) || aim == this.aim(socket)) return this;
    return _edited(
      aims: {..._aims}
        ..remove(socket)
        ..addAll({if (aim != SocketAim.straight) socket: aim}),
    );
  }

  AssemblyBlueprint _edited({
    Map<int, AssemblyModule>? modules,
    Iterable<AssemblyWire>? wires,
    Map<int, AssemblyOrientation>? orientations,
    Map<AssemblyContact, SocketAim>? aims,
    WorkbenchPartMark? mark,
  }) => AssemblyBlueprint._(
    modules ?? this.modules,
    wires ?? this.wires,
    inputCount: inputCount,
    outputCount: outputCount,
    orientations: orientations ?? _orientations,
    aims: aims ?? _aims,
    mark: mark ?? this.mark,
  );

  AssemblyBlueprint withMark(WorkbenchPartMark mark) => _edited(mark: mark);

  AssemblyBlueprint withJacks(int inputs, int outputs) {
    RangeError.checkValueInInterval(inputs, 0, rows, 'inputs');
    RangeError.checkValueInInterval(outputs, 0, rows, 'outputs');
    if (inputs == inputCount && outputs == outputCount) return this;
    return AssemblyBlueprint._(
      modules,
      wires.where(
        (wire) =>
            (wire.from.cell != AssemblyBlueprint.inputs ||
                wire.from.port < inputs) &&
            (wire.to.cell != AssemblyBlueprint.outputs ||
                wire.to.port < outputs),
      ),
      inputCount: inputs,
      outputCount: outputs,
      mark: mark,
      orientations: _orientations,
      aims: {
        for (final entry in _aims.entries)
          if (entry.key.port <
              (entry.key.cell == AssemblyBlueprint.inputs ? inputs : outputs))
            entry.key: entry.value,
      },
    );
  }

  int sockets(int cell, {required bool output}) => switch (cell) {
    inputs => output ? inputCount : 0,
    outputs => output ? 0 : outputCount,
    _ => output ? modules[cell]?.outputs ?? 0 : modules[cell]?.inputs ?? 0,
  };

  AssemblyBlueprint place(int cell, AssemblyModule? module) {
    if (cell < 0 || cell >= capacity || module == modules[cell]) return this;
    return _edited(
      modules: {...modules}
        ..remove(cell)
        ..addAll({cell: ?module}),
      wires: wires.where(
        (wire) => wire.from.cell != cell && wire.to.cell != cell,
      ),
      orientations: {..._orientations}..remove(cell),
    );
  }

  AssemblyBlueprint orient(int cell, AssemblyOrientation value) {
    if (!modules.containsKey(cell)) return this;
    final turns = value.turns % 4;
    return _edited(
      orientations: {..._orientations}
        ..remove(cell)
        ..addAll({
          if (turns != 0 || value.flipped)
            cell: (turns: turns, flipped: value.flipped),
        }),
    );
  }

  AssemblyBlueprint move(int from, int to) {
    final module = modules[from];
    if (module == null || to < 0 || to >= capacity || modules.containsKey(to)) {
      return this;
    }
    AssemblyContact moved(AssemblyContact contact) =>
        contact.cell == from ? (cell: to, port: contact.port) : contact;
    return _edited(
      modules: {...modules, to: module}..remove(from),
      orientations: {..._orientations, to: ?_orientations[from]}..remove(from),
      wires: [
        for (final wire in wires) (from: moved(wire.from), to: moved(wire.to)),
      ],
    );
  }

  AssemblyBlueprint disconnect(AssemblyContact input) =>
      _edited(wires: wires.where((wire) => wire.to != input));

  AssemblyBlueprint? connect(AssemblyContact from, AssemblyContact to) {
    if (from.port < 0 ||
        from.port >= sockets(from.cell, output: true) ||
        to.port < 0 ||
        to.port >= sockets(to.cell, output: false)) {
      return null;
    }
    final links = [
      for (final wire in wires)
        if (wire.from != from && wire.to != to) wire,
    ];
    bool reachesSource(int cell) =>
        cell == from.cell ||
        links.any(
          (wire) => wire.from.cell == cell && reachesSource(wire.to.cell),
        );
    if (reachesSource(to.cell)) return null;
    return _edited(wires: [...links, (from: from, to: to)]);
  }

  bool fits(int inputCount, int outputCount) => wires.every(
    (wire) =>
        (wire.from.cell != inputs || wire.from.port < inputCount) &&
        (wire.to.cell != outputs || wire.to.port < outputCount),
  );

  String get label => modules.values.map((module) => module.label).join(' + ');
  String get partName => mark.nameOr(label);

  List<double> evaluate(List<double> feeds, int outputCount) {
    final wired = {for (final wire in wires) wire.to: wire.from};
    final cache = <AssemblyContact, double>{};

    double delivered(AssemblyContact socket) {
      final source = wired[socket];
      if (source == null) return 0;
      if (source.cell == inputs) {
        return source.port < feeds.length ? feeds[source.port] : 0;
      }
      if (cache[source] case final value?) return value;
      final module = modules[source.cell]!;
      final value = module.deliver([
        for (var port = 0; port < module.inputs; port++)
          delivered((cell: source.cell, port: port)),
      ]);
      return cache[source] = value;
    }

    return [
      for (var port = 0; port < outputCount; port++)
        delivered((cell: outputs, port: port)),
    ];
  }

  late final _signature = jsonEncode(toJson());

  @override
  int get hashCode => _signature.hashCode;

  @override
  bool operator ==(Object other) =>
      other is AssemblyBlueprint && other._signature == _signature;

  Map<String, Object> toJson() {
    final cells = modules.keys.toList()..sort();
    final links = wires.toList()
      ..sort((a, b) {
        final byCell = a.from.cell.compareTo(b.from.cell);
        return byCell != 0 ? byCell : a.from.port.compareTo(b.from.port);
      });
    final aimed = _aims.keys.toList()
      ..sort((a, b) {
        final byCell = a.cell.compareTo(b.cell);
        return byCell != 0 ? byCell : a.port.compareTo(b.port);
      });
    return {
      if (mark != unmarkedWorkbenchPart) 'part': mark.toJson(),
      if (inputCount != rows || outputCount != rows)
        'jacks': [inputCount, outputCount],
      if (aimed.isNotEmpty)
        'aims': [
          for (final socket in aimed)
            [socket.cell, socket.port, _aims[socket]!.steps],
        ],
      'modules': [
        for (final cell in cells)
          [
            cell,
            modules[cell]!.name,
            if (_orientations[cell] case (:final turns, :final flipped)) ...[
              turns,
              flipped,
            ],
          ],
      ],
      'wires': [
        for (final wire in links)
          [wire.from.cell, wire.from.port, wire.to.cell, wire.to.port],
      ],
    };
  }

  factory AssemblyBlueprint.fromJson(Object? json) {
    if (json case {'modules': final List cells, 'wires': final List links}) {
      var design = empty;
      if (json.containsKey('jacks')) {
        if (json['jacks'] case [final int input, final int output]
            when input >= 0 && input <= rows && output >= 0 && output <= rows) {
          design = design.withJacks(input, output);
        } else {
          throw const FormatException('Invalid Workbench sockets.');
        }
      }
      if (json.containsKey('aims')) {
        final rows = json['aims'];
        if (rows is! List) {
          throw const FormatException('Invalid Workbench socket directions.');
        }
        final seen = <AssemblyContact>{};
        for (final row in rows) {
          if (row case [final int cell, final int port, final int steps]) {
            final socket = (cell: cell, port: port);
            final aim = SocketAim.fromSteps(steps);
            if (aim != null &&
                design.hasEdgeSocket(socket) &&
                seen.add(socket)) {
              design = design.aimSocket(socket, aim);
              continue;
            }
          }
          throw const FormatException('Invalid Workbench socket direction.');
        }
      }
      for (final row in cells) {
        final entry = switch (row) {
          [final int cell, final String name] => (
            cell,
            name,
            (turns: 0, flipped: false),
          ),
          [
            final int cell,
            final String name,
            final int turns,
            final bool flipped,
          ]
              when turns >= 0 && turns < 4 =>
            (cell, name, (turns: turns, flipped: flipped)),
          _ => null,
        };
        if (entry case (final cell, final name, final orientation)
            when cell >= 0 &&
                cell < capacity &&
                !design.modules.containsKey(cell)) {
          final module = AssemblyModule.values
              .where((item) => item.name == name)
              .firstOrNull;
          if (module != null) {
            design = design.place(cell, module).orient(cell, orientation);
            continue;
          }
        }
        throw const FormatException('Invalid Workbench module.');
      }
      for (final row in links) {
        if (row case [
          final int from,
          final int port,
          final int to,
          final int socket,
        ]) {
          final next = design.connect(
            (cell: from, port: port),
            (cell: to, port: socket),
          );
          if (next != null && next.wires.length == design.wires.length + 1) {
            design = next;
            continue;
          }
        }
        throw const FormatException('Invalid Workbench connection.');
      }
      return design.withMark(readWorkbenchPartMark(json['part']));
    }
    throw const FormatException('Invalid Workbench assembly.');
  }
}

class AssemblyFixture {
  const AssemblyFixture({
    required this.feeds,
    required this.targets,
    this.targetsByMask = const {},
  });

  final List<double> feeds;
  final List<double> targets;
  final Map<int, List<double>> targetsByMask;

  FabricationSocket<AssemblyBlueprint> get socket =>
      FabricationSocket('Assembly socket', matches: _matchesPorts);

  bool _matchesPorts(AssemblyBlueprint design) =>
      design.inputCount == feeds.length && design.outputCount == targets.length;

  bool accepts(AssemblyBlueprint design) => socket.accepts(design);

  List<double> inputsFor(int mask) => [
    for (final (index, feed) in feeds.indexed)
      mask & (1 << index) == 0 ? 0 : feed,
  ];

  List<double> targetsFor(int mask) =>
      targetsByMask[mask] ??
      (mask == (1 << feeds.length) - 1
          ? targets
          : List.filled(targets.length, 0));

  bool solves(AssemblyBlueprint design) {
    if (!accepts(design)) return false;
    final all = (1 << feeds.length) - 1;
    for (var mask = 0; mask <= all; mask++) {
      final readings = design.evaluate(inputsFor(mask), targets.length);
      final expected = targetsFor(mask);
      for (final (index, reading) in readings.indexed) {
        if ((reading - expected[index]).abs() > 1e-9) return false;
      }
    }
    return true;
  }
}

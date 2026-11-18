import 'fabrication_socket.dart';
import 'socket_aim.dart';
import 'workbench_part_mark.dart';

const splitterFabricationSocket = FabricationSocket<SplitterBlueprint>(
  'Splitter socket',
);

enum SplitterPort {
  left90(-2, '−90°'),
  left45(-1, '−45°'),
  straight(0, '0°'),
  right45(1, '+45°'),
  right90(2, '+90°');

  const SplitterPort(this.steps, this.label);

  /// Clockwise eighth-turns from the incoming beam.
  final int steps;
  final String label;

  SplitterPort get opposite => values[values.length - index - 1];
}

class SplitterBlueprint {
  const SplitterBlueprint._(
    this.first,
    this.second,
    this.filteredPort,
    this.inputAim,
    this.turns,
    this.mark,
  );

  factory SplitterBlueprint(
    SplitterPort a,
    SplitterPort b, {
    SplitterPort? filteredPort,
    SocketAim inputAim = SocketAim.straight,
    int turns = 0,
    WorkbenchPartMark mark = unmarkedWorkbenchPart,
  }) {
    if (a == b) throw ArgumentError('Choose two different output directions.');
    if (filteredPort != null && filteredPort != a && filteredPort != b) {
      throw ArgumentError('The filter must be fitted to one of the outputs.');
    }
    final (first, second) = a.index < b.index ? (a, b) : (b, a);
    return SplitterBlueprint._(
      first,
      second,
      filteredPort,
      inputAim,
      turns % 4,
      mark,
    );
  }

  factory SplitterBlueprint.fromJson(Object? value) {
    var aim = SocketAim.straight;
    var turns = 0;
    var mark = unmarkedWorkbenchPart;
    Object? ports = value;
    if (value is Map) {
      mark = readWorkbenchPartMark(value['part']);
      if (value
          case {
            'ports': final List saved,
            'inputAim': final int steps,
            'turns': final int rotation,
          }
          when rotation >= 0 && rotation < 4) {
        ports = saved;
        turns = rotation;
        aim =
            SocketAim.fromSteps(steps) ??
            (throw const FormatException(
              'Input points into the enclosure wall.',
            ));
      } else {
        throw const FormatException('Invalid splitter orientation.');
      }
    }
    final (a, b, filter) = switch (ports) {
      [final String a, final String b] => (a, b, null),
      [final String a, final String b, final String filter] => (a, b, filter),
      _ => throw const FormatException('Invalid splitter blueprint.'),
    };
    final first = SplitterPort.values
        .where((port) => port.name == a)
        .firstOrNull;
    final second = SplitterPort.values
        .where((port) => port.name == b)
        .firstOrNull;
    if (first != null &&
        second != null &&
        first != second &&
        (filter == null || filter == a || filter == b)) {
      return SplitterBlueprint(
        first,
        second,
        filteredPort: filter == null
            ? null
            : filter == a
            ? first
            : second,
        inputAim: aim,
        turns: turns,
        mark: mark,
      );
    }
    throw const FormatException('Invalid splitter blueprint.');
  }

  final SplitterPort first;
  final SplitterPort second;
  final SplitterPort? filteredPort;
  final SocketAim inputAim;
  final int turns;
  final WorkbenchPartMark mark;

  SplitterBlueprint withMark(WorkbenchPartMark mark) =>
      SplitterBlueprint._(first, second, filteredPort, inputAim, turns, mark);

  String get partName => mark.nameOr(
    filteredPort == null ? 'Workbench splitter' : 'Filtered splitter',
  );

  List<SplitterPort> get ports => [first, second];
  SplitterBlueprint get mirrored => SplitterBlueprint(
    second.opposite,
    first.opposite,
    filteredPort: filteredPort?.opposite,
    inputAim: inputAim.mirrored,
    turns: turns,
    mark: mark,
  );
  double shareFor(SplitterPort port) => port == filteredPort ? .25 : .5;

  String get label => '${first.label} / ${second.label}';
  Object toJson() {
    final ports = [
      first.name,
      second.name,
      if (filteredPort case final port?) port.name,
    ];
    if (inputAim == SocketAim.straight &&
        turns == 0 &&
        mark == unmarkedWorkbenchPart) {
      return ports;
    }
    return {
      'ports': ports,
      'inputAim': inputAim.steps,
      'turns': turns,
      if (mark != unmarkedWorkbenchPart) 'part': mark.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is SplitterBlueprint &&
      first == other.first &&
      second == other.second &&
      filteredPort == other.filteredPort &&
      inputAim == other.inputAim &&
      turns == other.turns &&
      mark == other.mark;

  @override
  int get hashCode =>
      Object.hash(first, second, filteredPort, inputAim, turns, mark);
}

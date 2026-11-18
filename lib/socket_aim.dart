// A socket may turn to either side of its outward wall normal.
enum SocketAim {
  left(-1),
  straight(0),
  right(1);

  const SocketAim(this.steps);

  final int steps;

  SocketAim? turn(int delta) {
    final next = index + delta;
    return next >= 0 && next < values.length ? values[next] : null;
  }

  SocketAim get mirrored => values[values.length - index - 1];

  static SocketAim? fromSteps(Object? value) =>
      values.where((aim) => value is int && aim.steps == value).firstOrNull;
}

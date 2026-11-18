/// The physical interface of a mount. Puzzle goals are evaluated separately.
class FabricationSocket<T extends Object> {
  const FabricationSocket(this.label, {this.matches});

  final String label;
  final bool Function(T)? matches;

  bool accepts(Object part) => part is T && (matches?.call(part) ?? true);
}

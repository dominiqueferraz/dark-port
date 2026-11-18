class BoardHistory<T> {
  final _past = <T>[];
  final _future = <T>[];

  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;

  void record(T previous) {
    _past.add(previous);
    _future.clear();
  }

  T undo(T current) {
    _future.add(current);
    return _past.removeLast();
  }

  T redo(T current) {
    _past.add(current);
    return _future.removeLast();
  }
}

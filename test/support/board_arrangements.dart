import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/signal_board.dart';
import 'package:dark_port/signal_board_state.dart';
import 'package:flutter_test/flutter_test.dart';

SignalLink _link(String from, String to, int output) =>
    (from: from, to: to, output: output, input: 0);

Iterable<SignalBoardState> wiredArrangements(SignalBoard board) sync* {
  final moving = board.devices.where((device) => !device.fixed).toList();
  final outputs = [
    for (final part in board.devices)
      for (var output = 0; output < part.outputs; output++) (part.id, output),
  ];

  Iterable<SignalBoardState> wire(
    Map<String, SignalPoint> positions,
    int index,
    Map<SignalLink, LeadType> leads,
  ) sync* {
    final links = leads.keys.toList();
    if (index == outputs.length) {
      yield SignalBoardState(
        board,
        positions: positions,
        links: links,
        leadTypes: leads,
      );
      return;
    }
    yield* wire(positions, index + 1, leads);
    final (source, output) = outputs[index];
    for (final target in board.devices.where((part) => part.hasInput)) {
      if (links.any((link) => link.to == target.id)) continue;
      final link = _link(source, target.id, output);
      for (final type in LeadType.values) {
        if (board.linkIssue(
              links,
              link,
              positions: positions,
              type: type,
              leadTypes: leads,
            ) ==
            null) {
          yield* wire(positions, index + 1, {...leads, link: type});
        }
      }
    }
  }

  Iterable<SignalBoardState> move(
    int index,
    Map<String, SignalPoint> positions,
  ) sync* {
    if (index == moving.length) {
      yield* wire(positions, 0, {});
      return;
    }
    final part = moving[index];
    expect(part.canFlip, isFalse);
    for (final mark in board.mountsFor(part.id)) {
      if (board.canMove(part.id, mark.position, positions)) {
        yield* move(index + 1, {...positions, part.id: mark.position});
      }
    }
  }

  yield* move(0, board.initialPositions);
}

Iterable<List<Optic>> opticalArrangements(
  OpticalLevel board, [
  List<Optic> layout = const [],
]) sync* {
  if (layout.length == board.initial.length) {
    yield layout;
    return;
  }
  final optic = board.initial[layout.length];
  if (optic.fixed) {
    yield* opticalArrangements(board, [...layout, optic]);
    return;
  }
  for (final mark in board.mounts[optic.id]!) {
    final moved = optic.at(mark.position);
    if (board.canPlace(moved, layout)) {
      yield* opticalArrangements(board, [...layout, moved]);
      if (moved.converter == null) {
        yield* opticalArrangements(board, [...layout, moved.rotate()]);
      }
    }
  }
}

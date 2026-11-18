import 'signal_board.dart';

/// An immutable wired board snapshot for play, history, previews or storage.
class SignalBoardState {
  SignalBoardState(
    this.board, {
    List<SignalLink>? links,
    Map<String, SignalPoint>? positions,
    Set<String>? flipped,
    Map<String, int> losses = const {},
  }) : links = List.unmodifiable(links ?? board.initialLinks),
       positions = Map.unmodifiable(positions ?? board.initialPositions),
       flipped = Set.unmodifiable(flipped ?? board.initialFlipped),
       losses = Map.unmodifiable(losses);

  final SignalBoard board;
  final List<SignalLink> links;
  final Map<String, SignalPoint> positions;
  final Set<String> flipped;
  final Map<String, int> losses;

  late final Map<SignalLink, SignalDelivery> deliveries = board.evaluate(
    links,
    positions: positions,
    flipped: flipped,
    losses: losses,
  );
  late final bool alarmFailed = board.interruptsAlarm(deliveries);
  late final bool solved = board.solves(deliveries);

  SignalBoardState copyWith({
    List<SignalLink>? links,
    Map<String, SignalPoint>? positions,
    Set<String>? flipped,
    Map<String, int>? losses,
  }) => SignalBoardState(
    board,
    links: links ?? this.links,
    positions: positions ?? this.positions,
    flipped: flipped ?? this.flipped,
    losses: losses ?? this.losses,
  );
}

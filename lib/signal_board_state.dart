import 'signal_board.dart';

/// An immutable wired board snapshot for play, history, previews or storage.
class SignalBoardState {
  SignalBoardState(
    this.board, {
    List<SignalLink>? links,
    Map<String, SignalPoint>? positions,
    Set<String>? flipped,
    Map<String, int> losses = const {},
    Map<SignalLink, LeadType> leadTypes = const {},
  }) : links = List.unmodifiable(links ?? board.initialLinks),
       positions = Map.unmodifiable(positions ?? board.initialPositions),
       flipped = Set.unmodifiable(flipped ?? board.initialFlipped),
       losses = Map.unmodifiable(losses),
       leadTypes = Map.unmodifiable({
         for (final link in links ?? board.initialLinks)
           if (leadTypes[link] case final type? when type != LeadType.patch)
             link: type,
       });

  final SignalBoard board;
  final List<SignalLink> links;
  final Map<String, SignalPoint> positions;
  final Set<String> flipped;
  final Map<String, int> losses;
  final Map<SignalLink, LeadType> leadTypes;

  LeadType leadType(SignalLink link) => leadTypes[link] ?? LeadType.patch;

  late final Map<SignalLink, SignalDelivery> deliveries = board.evaluate(
    links,
    positions: positions,
    flipped: flipped,
    losses: losses,
    leadTypes: leadTypes,
  );
  late final bool alarmFailed = board.interruptsAlarm(deliveries);
  late final bool solved = board.solves(deliveries);

  SignalBoardState copyWith({
    List<SignalLink>? links,
    Map<String, SignalPoint>? positions,
    Set<String>? flipped,
    Map<String, int>? losses,
    Map<SignalLink, LeadType>? leadTypes,
  }) => SignalBoardState(
    board,
    links: links ?? this.links,
    positions: positions ?? this.positions,
    flipped: flipped ?? this.flipped,
    losses: losses ?? this.losses,
    leadTypes: leadTypes ?? this.leadTypes,
  );
}

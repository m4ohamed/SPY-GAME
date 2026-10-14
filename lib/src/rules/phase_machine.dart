import '../enums.dart';

/// The only legal phase transitions of a room. The server must check every
/// transition against this table before writing a new phase.
abstract final class PhaseMachine {
  static const Map<GamePhase, Set<GamePhase>> _next = {
    GamePhase.lobby: {GamePhase.reveal},
    GamePhase.reveal: {GamePhase.clues, GamePhase.lobby},
    GamePhase.clues: {GamePhase.discussion, GamePhase.lobby},
    GamePhase.discussion: {GamePhase.vote, GamePhase.lobby},
    // vote -> vote is the single revote after a tie, vote -> clues starts the
    // next round, vote -> spyGuess gives a caught spy a chance to win.
    GamePhase.vote: {
      GamePhase.vote,
      GamePhase.clues,
      GamePhase.spyGuess,
      GamePhase.result,
      GamePhase.lobby,
    },
    GamePhase.spyGuess: {GamePhase.result, GamePhase.lobby},
    GamePhase.result: {GamePhase.lobby},
  };

  static Set<GamePhase> allowedNext(GamePhase from) =>
      _next[from] ?? const <GamePhase>{};

  static bool canTransition(GamePhase from, GamePhase to) =>
      allowedNext(from).contains(to);
}

/// The game modes supported by the engine.
enum GameModeType {
  /// Spies get a word similar to the civilians' word and do not know they are
  /// spies. Played over several rounds.
  undercover,

  /// The spy gets no word and knows it. Played over a single round, and a
  /// caught spy may still win by guessing the civilians' word.
  imposter,
}

/// Phases of a room. Only the server moves a room between phases.
enum GamePhase {
  lobby,
  reveal,
  clues,
  discussion,
  vote,
  spyGuess,
  result,
}

enum PlayerRole { civilian, spy }

enum GameWinner { civilians, spies }

/// Why a game ended. Useful for the result screen text.
enum GameEndReason {
  allSpiesCaught,
  spiesReachedParity,
  spyNotCaught,
  spyGuessedWord,
  spyGuessFailed,
  roundLimitReached,
}

enum WordLanguage { ar, en }

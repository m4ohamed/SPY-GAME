import 'dart:math';

import '../entities/word_entry.dart';
import '../enums.dart';
import '../rules/answer_matcher.dart';
import 'game_mode.dart';

/// Civilians share one word, spies get a similar one and do not know they are
/// spies. Players give clues, discuss, and vote out one player per round until
/// every spy is gone or the spies reach parity with the civilians.
class UndercoverMode extends GameMode {
  const UndercoverMode();

  @override
  GameModeType get type => GameModeType.undercover;

  @override
  int get minPlayers => 4;

  @override
  int get maxPlayers => 12;

  @override
  int get maxRounds => 8;

  @override
  bool get revealsRoleToPlayer => false;

  @override
  bool get spyReceivesWord => true;

  @override
  bool get grantsSpyGuess => false;

  @override
  bool isEligible(WordEntry entry) {
    final similar = entry.similarWord;
    return entry.hasSimilarWord &&
        similar != null &&
        !AnswerMatcher.matches(entry.word, similar);
  }

  /// One spy per four players, at least one, always fewer than half.
  @override
  int defaultSpyCount(int playerCount) =>
      min(maxSpyCount(playerCount), max(1, playerCount ~/ 4));

  /// Randomly decides which of the two words the civilians get, so a word
  /// pair is not predictable from its order.
  @override
  WordPair pickWords(WordEntry entry, Random random) {
    final similar = entry.similarWord;
    if (similar == null) {
      throw ArgumentError.value(
        entry.id,
        'entry',
        'Undercover needs a similar word',
      );
    }
    final swap = random.nextBool();
    return (
      civilianWord: swap ? similar : entry.word,
      spyWord: swap ? entry.word : similar,
    );
  }

  @override
  EliminationResult onElimination(RoundSnapshot snapshot) {
    final aliveSpies = snapshot.aliveSpyCount;
    final aliveCivilians = snapshot.aliveCivilianCount;

    if (aliveSpies == 0) {
      return const GameOver(
        GameOutcome(
          winner: GameWinner.civilians,
          reason: GameEndReason.allSpiesCaught,
        ),
      );
    }
    if (aliveSpies >= aliveCivilians) {
      return const GameOver(
        GameOutcome(
          winner: GameWinner.spies,
          reason: GameEndReason.spiesReachedParity,
        ),
      );
    }
    if (snapshot.round >= maxRounds) {
      return const GameOver(
        GameOutcome(
          winner: GameWinner.spies,
          reason: GameEndReason.roundLimitReached,
        ),
      );
    }
    return const NextRound();
  }
}

import 'dart:math';

import '../entities/word_entry.dart';
import '../enums.dart';
import 'game_mode.dart';

/// Civilians share one word, the single imposter gets none and knows it.
/// One round only: if the imposter is voted out they get one guess at the
/// word, otherwise the imposter wins.
class ImposterMode extends GameMode {
  const ImposterMode();

  @override
  GameModeType get type => GameModeType.imposter;

  @override
  int get minPlayers => 3;

  @override
  int get maxPlayers => 12;

  @override
  int get maxRounds => 1;

  @override
  bool get revealsRoleToPlayer => true;

  @override
  bool get spyReceivesWord => false;

  @override
  bool get grantsSpyGuess => true;

  @override
  bool isEligible(WordEntry entry) => entry.word.trim().isNotEmpty;

  @override
  int defaultSpyCount(int playerCount) => 1;

  /// Imposter mode always has exactly one imposter.
  @override
  int maxSpyCount(int playerCount) => 1;

  @override
  WordPair pickWords(WordEntry entry, Random random) =>
      (civilianWord: entry.word, spyWord: null);

  @override
  EliminationResult onElimination(RoundSnapshot snapshot) {
    final eliminated = snapshot.eliminatedUid;
    if (eliminated == null || !snapshot.spyUids.contains(eliminated)) {
      return const GameOver(
        GameOutcome(
          winner: GameWinner.spies,
          reason: GameEndReason.spyNotCaught,
        ),
      );
    }
    return AwaitSpyGuess(eliminated);
  }
}

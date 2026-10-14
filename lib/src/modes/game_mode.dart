import 'dart:math';

import '../entities/player_secret.dart';
import '../entities/room_settings.dart';
import '../entities/word_entry.dart';
import '../enums.dart';
import '../rules/answer_matcher.dart';

/// The words dealt for one game. [spyWord] is null when spies get no word.
typedef WordPair = ({String civilianWord, String? spyWord});

/// A problem found by [GameMode.validateSettings].
enum SettingsIssue {
  wrongMode,
  tooFewPlayers,
  tooManyPlayers,
  invalidSpyCount,
  invalidDuration,
}

/// The final result of a game.
class GameOutcome {
  const GameOutcome({required this.winner, required this.reason});

  final GameWinner winner;
  final GameEndReason reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameOutcome && other.winner == winner && other.reason == reason;

  @override
  int get hashCode => Object.hash(winner, reason);
}

/// The state of a round right after its vote was resolved.
class RoundSnapshot {
  RoundSnapshot({
    required this.round,
    required Set<String> spyUids,
    required Set<String> aliveUids,
    required this.eliminatedUid,
  })  : assert(
          eliminatedUid == null || !aliveUids.contains(eliminatedUid),
          'aliveUids must already exclude the eliminated player',
        ),
        spyUids = Set<String>.unmodifiable(spyUids),
        aliveUids = Set<String>.unmodifiable(aliveUids);

  /// The round that just finished, starting at 1.
  final int round;

  /// Every spy of the game, alive or not.
  final Set<String> spyUids;

  /// Players still alive after the elimination was applied.
  final Set<String> aliveUids;

  /// Who was eliminated, or null when nobody was (no votes or a second tie).
  final String? eliminatedUid;

  int get aliveSpyCount => spyUids.where(aliveUids.contains).length;

  int get aliveCivilianCount => aliveUids.length - aliveSpyCount;

  bool get eliminatedWasSpy {
    final uid = eliminatedUid;
    return uid != null && spyUids.contains(uid);
  }
}

/// What happens after a round's vote.
sealed class EliminationResult {
  const EliminationResult();
}

/// The game continues with another round.
final class NextRound extends EliminationResult {
  const NextRound();
}

/// A caught spy gets one guess at the civilians' word.
final class AwaitSpyGuess extends EliminationResult {
  const AwaitSpyGuess(this.spyUid);

  final String spyUid;
}

/// The game is over.
final class GameOver extends EliminationResult {
  const GameOver(this.outcome);

  final GameOutcome outcome;
}

/// The contract every game mode implements.
///
/// Modes are pure and deterministic given their inputs, so they can be
/// unit-tested. In production the server deals the cards with a secure random
/// source and mirrors these rules, because clients must never learn roles.
abstract class GameMode {
  const GameMode();

  GameModeType get type;

  int get minPlayers;

  int get maxPlayers;

  /// Hard cap on rounds; spies win if it is reached with spies still alive.
  int get maxRounds;

  /// Whether the player's own secret includes their role. False when the
  /// spy must not know they are the spy.
  bool get revealsRoleToPlayer;

  /// Whether spies receive a word at all.
  bool get spyReceivesWord;

  /// Whether a caught spy may try to win by guessing the civilians' word.
  bool get grantsSpyGuess;

  /// Whether [entry] can be used in this mode.
  bool isEligible(WordEntry entry);

  /// Spy count used when the host does not override it.
  int defaultSpyCount(int playerCount);

  /// Upper bound for the spy count: always fewer spies than half the players.
  int maxSpyCount(int playerCount) => (playerCount - 1) ~/ 2;

  /// Chooses which word the civilians get and which the spies get.
  WordPair pickWords(WordEntry entry, Random random);

  /// Decides what happens after a round's vote was resolved.
  EliminationResult onElimination(RoundSnapshot snapshot);

  /// The spy count for a room: the host's override or the default.
  int resolveSpyCount(RoomSettings settings, int playerCount) =>
      settings.spyCountOverride ?? defaultSpyCount(playerCount);

  /// Returns every problem with [settings] for [playerCount] players. An empty
  /// list means the settings are valid.
  List<SettingsIssue> validateSettings(
    RoomSettings settings,
    int playerCount,
  ) {
    final issues = <SettingsIssue>[];
    if (settings.mode != type) issues.add(SettingsIssue.wrongMode);
    if (playerCount < minPlayers) issues.add(SettingsIssue.tooFewPlayers);
    if (playerCount > maxPlayers) issues.add(SettingsIssue.tooManyPlayers);
    final override = settings.spyCountOverride;
    if (override != null &&
        (override < 1 || override > maxSpyCount(playerCount))) {
      issues.add(SettingsIssue.invalidSpyCount);
    }
    if (!settings.durationsInRange) issues.add(SettingsIssue.invalidDuration);
    return issues;
  }

  /// Deals roles and words. Throws [ArgumentError] on invalid input.
  SecretAssignment assignSecrets({
    required List<String> playerUids,
    required WordEntry word,
    required int spyCount,
    required Random random,
  }) {
    if (!isEligible(word)) {
      throw ArgumentError.value(word.id, 'word', 'not usable in $type mode');
    }
    if (playerUids.toSet().length != playerUids.length) {
      throw ArgumentError.value(playerUids, 'playerUids', 'contains duplicates');
    }
    if (playerUids.length < minPlayers || playerUids.length > maxPlayers) {
      throw RangeError.range(
        playerUids.length,
        minPlayers,
        maxPlayers,
        'playerUids',
        'player count out of range for $type mode',
      );
    }
    final maxSpies = maxSpyCount(playerUids.length);
    if (spyCount < 1 || spyCount > maxSpies) {
      throw ArgumentError.value(
        spyCount,
        'spyCount',
        'must be between 1 and $maxSpies',
      );
    }

    final shuffled = List<String>.of(playerUids)..shuffle(random);
    final spyUids = shuffled.take(spyCount).toSet();
    final words = pickWords(word, random);

    final secrets = <String, PlayerSecret>{};
    for (final uid in playerUids) {
      final isSpy = spyUids.contains(uid);
      final PlayerRole? role = revealsRoleToPlayer
          ? (isSpy ? PlayerRole.spy : PlayerRole.civilian)
          : null;
      final String? wordForPlayer =
          isSpy ? (spyReceivesWord ? words.spyWord : null) : words.civilianWord;
      secrets[uid] = PlayerSecret(role: role, word: wordForPlayer);
    }

    return SecretAssignment(
      secrets: secrets,
      spyUids: spyUids,
      civilianWord: words.civilianWord,
      spyWord: spyReceivesWord ? words.spyWord : null,
    );
  }

  /// Whether a caught spy's [guess] matches the civilians' word.
  bool isSpyGuessCorrect(String guess, String civilianWord) =>
      AnswerMatcher.matches(guess, civilianWord);

  /// The outcome after a caught spy's guess. Throws [StateError] in modes
  /// that do not grant a guess.
  GameOutcome resolveSpyGuess({required bool correct}) {
    if (!grantsSpyGuess) {
      throw StateError('$type mode does not grant a spy guess');
    }
    return correct
        ? const GameOutcome(
            winner: GameWinner.spies,
            reason: GameEndReason.spyGuessedWord,
          )
        : const GameOutcome(
            winner: GameWinner.civilians,
            reason: GameEndReason.spyGuessFailed,
          );
  }
}

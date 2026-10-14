import '../enums.dart';
import '../utils/equality.dart';

/// Host-configurable settings for a room.
class RoomSettings {
  RoomSettings({
    required this.mode,
    this.spyCountOverride,
    this.language = WordLanguage.ar,
    List<String> categoryIds = const <String>[],
    this.clueSeconds = defaultClueSeconds,
    this.discussionSeconds = defaultDiscussionSeconds,
    this.voteSeconds = defaultVoteSeconds,
    this.spyGuessSeconds = defaultSpyGuessSeconds,
    this.revealSeconds = defaultRevealSeconds,
  }) : categoryIds = List<String>.unmodifiable(categoryIds);

  static const int defaultClueSeconds = 30;
  static const int defaultDiscussionSeconds = 150;
  static const int defaultVoteSeconds = 45;
  static const int defaultSpyGuessSeconds = 30;
  static const int defaultRevealSeconds = 15;

  /// Allowed range for every duration setting.
  static const int minSeconds = 5;
  static const int maxSeconds = 600;

  final GameModeType mode;

  /// Null means "use the mode's default spy count for the player count".
  final int? spyCountOverride;

  final WordLanguage language;

  /// Word categories to draw from. Empty means every category.
  final List<String> categoryIds;

  /// Time each player gets for their clue (per turn, not per round).
  final int clueSeconds;
  final int discussionSeconds;
  final int voteSeconds;
  final int spyGuessSeconds;
  final int revealSeconds;

  bool get durationsInRange => [
        clueSeconds,
        discussionSeconds,
        voteSeconds,
        spyGuessSeconds,
        revealSeconds,
      ].every((seconds) => seconds >= minSeconds && seconds <= maxSeconds);

  /// How long [phase] lasts, or null for phases without a timer.
  Duration? durationFor(GamePhase phase) {
    switch (phase) {
      case GamePhase.reveal:
        return Duration(seconds: revealSeconds);
      case GamePhase.clues:
        return Duration(seconds: clueSeconds);
      case GamePhase.discussion:
        return Duration(seconds: discussionSeconds);
      case GamePhase.vote:
        return Duration(seconds: voteSeconds);
      case GamePhase.spyGuess:
        return Duration(seconds: spyGuessSeconds);
      case GamePhase.lobby:
      case GamePhase.result:
        return null;
    }
  }

  RoomSettings copyWith({
    GameModeType? mode,
    int? spyCountOverride,
    bool clearSpyCountOverride = false,
    WordLanguage? language,
    List<String>? categoryIds,
    int? clueSeconds,
    int? discussionSeconds,
    int? voteSeconds,
    int? spyGuessSeconds,
    int? revealSeconds,
  }) {
    return RoomSettings(
      mode: mode ?? this.mode,
      spyCountOverride: clearSpyCountOverride
          ? null
          : (spyCountOverride ?? this.spyCountOverride),
      language: language ?? this.language,
      categoryIds: categoryIds ?? this.categoryIds,
      clueSeconds: clueSeconds ?? this.clueSeconds,
      discussionSeconds: discussionSeconds ?? this.discussionSeconds,
      voteSeconds: voteSeconds ?? this.voteSeconds,
      spyGuessSeconds: spyGuessSeconds ?? this.spyGuessSeconds,
      revealSeconds: revealSeconds ?? this.revealSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomSettings &&
          other.mode == mode &&
          other.spyCountOverride == spyCountOverride &&
          other.language == language &&
          listsEqual(other.categoryIds, categoryIds) &&
          other.clueSeconds == clueSeconds &&
          other.discussionSeconds == discussionSeconds &&
          other.voteSeconds == voteSeconds &&
          other.spyGuessSeconds == spyGuessSeconds &&
          other.revealSeconds == revealSeconds;

  @override
  int get hashCode => Object.hash(
        mode,
        spyCountOverride,
        language,
        Object.hashAll(categoryIds),
        clueSeconds,
        discussionSeconds,
        voteSeconds,
        spyGuessSeconds,
        revealSeconds,
      );
}

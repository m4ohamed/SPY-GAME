import '../enums.dart';
import '../utils/equality.dart';

/// Everything that becomes public when a game ends. Written by the server into
/// the room document at the result phase, never earlier.
class GameReveal {
  GameReveal({
    required Set<String> spyUids,
    required this.civilianWord,
    required this.winner,
    required this.reason,
    this.spyWord,
    Map<String, int> tally = const <String, int>{},
    this.eliminatedUid,
    this.spyGuess,
  })  : spyUids = Set<String>.unmodifiable(spyUids),
        tally = Map<String, int>.unmodifiable(tally);

  final Set<String> spyUids;
  final String civilianWord;

  /// The spies' word in Undercover mode; null in Imposter mode.
  final String? spyWord;

  final GameWinner winner;
  final GameEndReason reason;

  /// Votes received per player in the deciding vote.
  final Map<String, int> tally;

  /// Who was eliminated in the deciding vote, if anyone.
  final String? eliminatedUid;

  /// The text the caught spy guessed, if a guess was made.
  final String? spyGuess;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameReveal &&
          setsEqual(other.spyUids, spyUids) &&
          other.civilianWord == civilianWord &&
          other.spyWord == spyWord &&
          other.winner == winner &&
          other.reason == reason &&
          mapsEqual(other.tally, tally) &&
          other.eliminatedUid == eliminatedUid &&
          other.spyGuess == spyGuess;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(spyUids),
        civilianWord,
        spyWord,
        winner,
        reason,
        hashMap(tally),
        eliminatedUid,
        spyGuess,
      );
}

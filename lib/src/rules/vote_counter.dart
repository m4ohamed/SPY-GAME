import '../utils/equality.dart';

/// Why a single vote is not accepted.
enum VoteRejection {
  voterNotAlive,
  selfVote,
  targetNotAlive,
  targetNotCandidate,
}

/// The outcome of counting votes.
///
/// Exactly one of these holds: a single player was eliminated
/// ([eliminatedUid] is set), there is a tie ([tiedUids] has two or more
/// players), or no valid vote was cast ([hasVotes] is false).
class VoteResult {
  VoteResult({
    required Map<String, int> tally,
    this.eliminatedUid,
    List<String> tiedUids = const <String>[],
  })  : tally = Map<String, int>.unmodifiable(tally),
        tiedUids = List<String>.unmodifiable(tiedUids);

  /// Valid votes received per target.
  final Map<String, int> tally;

  final String? eliminatedUid;

  /// Leaders of a tied vote, sorted by uid. Empty when there is no tie.
  final List<String> tiedUids;

  bool get isTie => tiedUids.length > 1;

  bool get hasVotes => tally.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoteResult &&
          mapsEqual(other.tally, tally) &&
          other.eliminatedUid == eliminatedUid &&
          listsEqual(other.tiedUids, tiedUids);

  @override
  int get hashCode =>
      Object.hash(hashMap(tally), eliminatedUid, Object.hashAll(tiedUids));
}

/// Pure vote rules. The server's `castVote` function must mirror them.
abstract final class VoteCounter {
  /// Returns why the vote is rejected, or null when it is valid.
  ///
  /// [candidateUids] restricts who can receive votes (used in a revote). Null
  /// means every alive player can receive votes.
  static VoteRejection? validateVote({
    required String voterUid,
    required String targetUid,
    required Set<String> aliveUids,
    Set<String>? candidateUids,
  }) {
    if (!aliveUids.contains(voterUid)) return VoteRejection.voterNotAlive;
    if (voterUid == targetUid) return VoteRejection.selfVote;
    if (!aliveUids.contains(targetUid)) return VoteRejection.targetNotAlive;
    if (candidateUids != null && !candidateUids.contains(targetUid)) {
      return VoteRejection.targetNotCandidate;
    }
    return null;
  }

  /// Counts [votes] (voter uid -> target uid), ignoring invalid ones.
  static VoteResult count({
    required Map<String, String> votes,
    required Set<String> aliveUids,
    Set<String>? candidateUids,
  }) {
    final tally = <String, int>{};
    votes.forEach((voterUid, targetUid) {
      final rejection = validateVote(
        voterUid: voterUid,
        targetUid: targetUid,
        aliveUids: aliveUids,
        candidateUids: candidateUids,
      );
      if (rejection == null) {
        tally[targetUid] = (tally[targetUid] ?? 0) + 1;
      }
    });

    if (tally.isEmpty) {
      return VoteResult(tally: tally);
    }

    final top = tally.values.reduce((a, b) => a > b ? a : b);
    final leaders = tally.entries
        .where((entry) => entry.value == top)
        .map((entry) => entry.key)
        .toList()
      ..sort();

    if (leaders.length == 1) {
      return VoteResult(tally: tally, eliminatedUid: leaders.first);
    }
    return VoteResult(tally: tally, tiedUids: leaders);
  }
}

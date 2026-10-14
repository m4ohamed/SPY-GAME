import '../enums.dart';
import '../utils/equality.dart';
import 'game_reveal.dart';
import 'room_settings.dart';

/// Public room state. Contains no roles, words, or individual votes.
class Room {
  Room({
    required this.id,
    required this.code,
    required this.hostUid,
    required this.settings,
    required this.createdAt,
    this.phase = GamePhase.lobby,
    this.round = 0,
    List<String> turnOrder = const <String>[],
    this.turnUid,
    this.voteCount = 0,
    this.voteAttempt = 1,
    List<String> voteCandidateUids = const <String>[],
    this.phaseEndsAt,
    this.reveal,
  })  : turnOrder = List<String>.unmodifiable(turnOrder),
        voteCandidateUids = List<String>.unmodifiable(voteCandidateUids);

  /// Random internal id (Firestore auto-id). Not the join code.
  final String id;

  /// Short code players type to join.
  final String code;

  final String hostUid;
  final RoomSettings settings;
  final DateTime createdAt;
  final GamePhase phase;

  /// 0 in the lobby, then 1 for the first round.
  final int round;

  /// Alive players in the order they give clues this round.
  final List<String> turnOrder;

  /// The player whose clue turn it is, only during the clue phase.
  final String? turnUid;

  /// How many valid votes were cast in the current vote.
  final int voteCount;

  /// 1 for the first vote of a round, 2 for the single revote after a tie.
  final int voteAttempt;

  /// Players that can receive votes in a revote. Empty means every alive player.
  final List<String> voteCandidateUids;

  /// Server timestamp at which the current phase ends, if it has a timer.
  final DateTime? phaseEndsAt;

  /// Set only when the phase is [GamePhase.result].
  final GameReveal? reveal;

  bool get isInLobby => phase == GamePhase.lobby;

  bool get isFinished => phase == GamePhase.result;

  bool get hasActiveGame => !isInLobby && !isFinished;

  bool get isRevote => voteAttempt > 1;

  bool isHost(String uid) => uid == hostUid;

  bool isTurnOf(String uid) => phase == GamePhase.clues && turnUid == uid;

  Room copyWith({
    String? hostUid,
    RoomSettings? settings,
    GamePhase? phase,
    int? round,
    List<String>? turnOrder,
    String? turnUid,
    bool clearTurnUid = false,
    int? voteCount,
    int? voteAttempt,
    List<String>? voteCandidateUids,
    DateTime? phaseEndsAt,
    bool clearPhaseEndsAt = false,
    GameReveal? reveal,
    bool clearReveal = false,
  }) {
    return Room(
      id: id,
      code: code,
      createdAt: createdAt,
      hostUid: hostUid ?? this.hostUid,
      settings: settings ?? this.settings,
      phase: phase ?? this.phase,
      round: round ?? this.round,
      turnOrder: turnOrder ?? this.turnOrder,
      turnUid: clearTurnUid ? null : (turnUid ?? this.turnUid),
      voteCount: voteCount ?? this.voteCount,
      voteAttempt: voteAttempt ?? this.voteAttempt,
      voteCandidateUids: voteCandidateUids ?? this.voteCandidateUids,
      phaseEndsAt: clearPhaseEndsAt ? null : (phaseEndsAt ?? this.phaseEndsAt),
      reveal: clearReveal ? null : (reveal ?? this.reveal),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Room &&
          other.id == id &&
          other.code == code &&
          other.hostUid == hostUid &&
          other.settings == settings &&
          other.createdAt == createdAt &&
          other.phase == phase &&
          other.round == round &&
          listsEqual(other.turnOrder, turnOrder) &&
          other.turnUid == turnUid &&
          other.voteCount == voteCount &&
          other.voteAttempt == voteAttempt &&
          listsEqual(other.voteCandidateUids, voteCandidateUids) &&
          other.phaseEndsAt == phaseEndsAt &&
          other.reveal == reveal;

  @override
  int get hashCode => Object.hash(
        id,
        code,
        hostUid,
        settings,
        createdAt,
        phase,
        round,
        Object.hashAll(turnOrder),
        turnUid,
        voteCount,
        voteAttempt,
        Object.hashAll(voteCandidateUids),
        phaseEndsAt,
        reveal,
      );
}

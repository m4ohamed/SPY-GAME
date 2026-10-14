/// Why a room operation failed. [reason] is the machine-readable string the
/// Cloud Functions send in `HttpsError.details.reason`.
enum RoomFailure {
  invalidName('invalid-name'),
  invalidCode('invalid-code'),
  invalidMode('invalid-mode'),
  invalidSettings('invalid-settings'),
  roomNotFound('room-not-found'),
  roomFull('room-full'),
  gameInProgress('game-in-progress'),
  nameTaken('name-taken'),
  notHost('not-host'),
  notInRoom('not-in-room'),
  cannotKickSelf('cannot-kick-self'),
  notEnoughPlayers('not-enough-players'),
  noWordsAvailable('no-words-available'),
  invalidClue('invalid-clue'),
  invalidGuess('invalid-guess'),
  wrongPhase('wrong-phase'),
  notYourTurn('not-your-turn'),
  alreadyVoted('already-voted'),
  notAlive('not-alive'),
  cannotVoteSelf('cannot-vote-self'),
  invalidTarget('invalid-target'),
  clueRevealsWord('clue-reveals-word'),
  unauthenticated('unauthenticated'),
  network('network'),
  unknown('unknown');

  const RoomFailure(this.reason);

  final String reason;

  /// Maps a server reason to a failure, or [unknown] for anything else.
  static RoomFailure fromReason(String? reason) {
    for (final failure in RoomFailure.values) {
      if (failure.reason == reason) return failure;
    }
    return RoomFailure.unknown;
  }
}

/// Thrown by [RoomRepository] methods and emitted as a stream error by its
/// watchers.
class RoomException implements Exception {
  const RoomException(this.failure, [this.message]);

  final RoomFailure failure;
  final String? message;

  @override
  String toString() =>
      'RoomException(${failure.name}${message == null ? '' : ': $message'})';
}

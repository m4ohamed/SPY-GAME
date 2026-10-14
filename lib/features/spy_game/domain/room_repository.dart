import 'package:spy_game_domain/spy_game_domain.dart';

/// The room a create or join call ended up in.
class RoomJoinResult {
  const RoomJoinResult({required this.roomId, required this.code});

  final String roomId;
  final String code;
}

/// The answer to a `tick` call.
class TickResult {
  const TickResult({required this.advanced, this.retryAfter});

  /// True when this call moved the game to its next step.
  final bool advanced;

  /// When the call came too early, how long to wait before trying again.
  final Duration? retryAfter;
}

/// Lobby and game operations. Every method throws a `RoomException` on failure, and
/// the watchers emit it as a stream error.
abstract interface class RoomRepository {
  /// The signed-in user's uid, or null before the first call signs them in.
  String? get currentUid;

  Future<RoomJoinResult> createRoom({
    required GameModeType mode,
    required String displayName,
    RoomSettings? settings,
  });

  Future<RoomJoinResult> joinRoom({
    required String code,
    required String displayName,
  });

  Future<void> leaveRoom(String roomId);

  /// Host only, lobby only.
  Future<void> kickPlayer({
    required String roomId,
    required String targetUid,
  });

  /// Host only, lobby only.
  Future<void> updateSettings({
    required String roomId,
    required RoomSettings settings,
  });

  /// Host only. Deals roles and words on the server and moves the room from
  /// the lobby to the reveal phase.
  Future<void> startGame(String roomId);

  /// Host only. Abandons the current game and returns everyone to the lobby.
  Future<void> cancelGame(String roomId);

  /// Asks the server to move the game on after the current phase's timer
  /// ran out. Safe to call from every client: the server ignores calls for a
  /// step the room already left and calls that come before the deadline.
  Future<TickResult> tick(Room room);

  /// The current speaker's clue.
  Future<void> submitClue({required String roomId, required String text});

  /// The caller's vote. One vote per vote step.
  Future<void> castVote({required String roomId, required String targetUid});

  /// The caught spy's single guess at the civilians' word.
  Future<void> submitSpyGuess({required String roomId, required String text});

  /// "I am still here." Call it every 15 seconds while a room is open. The
  /// server flags silent players as disconnected, removes long-silent players
  /// from a lobby, and hands the host role to a connected player when the
  /// host is gone.
  Future<void> heartbeat(String roomId);

  /// Tells the server this device's OneSignal subscription id for the room,
  /// so the player can be notified when it is their turn.
  Future<void> registerPush({
    required String roomId,
    required String subscriptionId,
  });

  /// The current time on the server's clock, for countdowns.
  DateTime serverNow();

  /// Emits null when the room document no longer exists. Emits a
  /// `RoomException(RoomFailure.notInRoom)` error when the user is not (or no
  /// longer) a member.
  Stream<Room?> watchRoom(String roomId);

  /// Players ordered by join time.
  Stream<List<Player>> watchPlayers(String roomId);

  /// Every clue given so far, oldest first.
  Stream<List<Clue>> watchClues(String roomId);

  /// The signed-in player's own role and word. Emits null while nothing has
  /// been dealt (for example in the lobby).
  Stream<PlayerSecret?> watchMySecret(String roomId);
}

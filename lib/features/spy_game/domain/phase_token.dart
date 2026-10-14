import 'package:spy_game_domain/spy_game_domain.dart';

/// Identifies one step of the game (phase, round, whose turn, which vote
/// attempt). The client sends it with `tick` so the server ignores the call if
/// the room has already moved on.
///
/// Must match `phaseToken` in `spy_game_functions/src/engine.ts`.
String phaseToken(Room room) =>
    '${room.phase.name}|${room.round}|${room.turnUid ?? ''}|${room.voteAttempt}';

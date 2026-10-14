import '../enums.dart';
import '../utils/equality.dart';

/// What one player is allowed to know. Stored in `secrets/{uid}` and readable
/// only by that player.
///
/// [role] is null when the mode hides the role from the player (in Undercover
/// the spy must not know they are the spy). [word] is null when the player
/// receives no word (the spy in Imposter mode).
class PlayerSecret {
  const PlayerSecret({this.role, this.word});

  final PlayerRole? role;
  final String? word;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerSecret && other.role == role && other.word == word;

  @override
  int get hashCode => Object.hash(role, word);
}

/// The full result of dealing a game: every player's secret plus the data the
/// server keeps for the final reveal. This object must never reach clients.
class SecretAssignment {
  SecretAssignment({
    required Map<String, PlayerSecret> secrets,
    required Set<String> spyUids,
    required this.civilianWord,
    this.spyWord,
  })  : secrets = Map<String, PlayerSecret>.unmodifiable(secrets),
        spyUids = Set<String>.unmodifiable(spyUids);

  final Map<String, PlayerSecret> secrets;
  final Set<String> spyUids;
  final String civilianWord;
  final String? spyWord;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecretAssignment &&
          mapsEqual(other.secrets, secrets) &&
          setsEqual(other.spyUids, spyUids) &&
          other.civilianWord == civilianWord &&
          other.spyWord == spyWord;

  @override
  int get hashCode => Object.hash(
        hashMap(secrets),
        Object.hashAllUnordered(spyUids),
        civilianWord,
        spyWord,
      );
}

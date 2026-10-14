import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

T _parseEnum<T extends Enum>(List<T> values, Object? raw, String field) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unknown $field: $raw');
}

DateTime _epoch() => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

DateTime? _dateTime(Object? raw) => raw is Timestamp ? raw.toDate() : null;

List<String> _stringList(Object? raw) =>
    raw is List ? raw.whereType<String>().toList() : const <String>[];

int _int(Object? raw, int fallback) => raw is num ? raw.toInt() : fallback;

RoomSettings settingsFromMap(Map<String, dynamic> map) {
  final override = map['spyCountOverride'];
  return RoomSettings(
    mode: _parseEnum(GameModeType.values, map['mode'], 'mode'),
    spyCountOverride: override is num ? override.toInt() : null,
    language: _parseEnum(
      WordLanguage.values,
      map['language'] ?? WordLanguage.ar.name,
      'language',
    ),
    categoryIds: _stringList(map['categoryIds']),
    clueSeconds: _int(map['clueSeconds'], RoomSettings.defaultClueSeconds),
    discussionSeconds: _int(
      map['discussionSeconds'],
      RoomSettings.defaultDiscussionSeconds,
    ),
    voteSeconds: _int(map['voteSeconds'], RoomSettings.defaultVoteSeconds),
    spyGuessSeconds: _int(
      map['spyGuessSeconds'],
      RoomSettings.defaultSpyGuessSeconds,
    ),
    revealSeconds: _int(
      map['revealSeconds'],
      RoomSettings.defaultRevealSeconds,
    ),
  );
}

/// The payload shape the Cloud Functions accept for settings.
Map<String, Object?> settingsToMap(RoomSettings settings) {
  return <String, Object?>{
    'mode': settings.mode.name,
    'spyCountOverride': settings.spyCountOverride,
    'language': settings.language.name,
    'categoryIds': settings.categoryIds.toList(),
    'clueSeconds': settings.clueSeconds,
    'discussionSeconds': settings.discussionSeconds,
    'voteSeconds': settings.voteSeconds,
    'spyGuessSeconds': settings.spyGuessSeconds,
    'revealSeconds': settings.revealSeconds,
  };
}

GameReveal revealFromMap(Map<String, dynamic> map) {
  final tallyRaw = map['tally'];
  final tally = <String, int>{};
  if (tallyRaw is Map) {
    tallyRaw.forEach((key, value) {
      if (key is String && value is num) {
        tally[key] = value.toInt();
      }
    });
  }
  return GameReveal(
    spyUids: _stringList(map['spyUids']).toSet(),
    civilianWord: map['civilianWord'] as String,
    spyWord: map['spyWord'] as String?,
    winner: _parseEnum(GameWinner.values, map['winner'], 'winner'),
    reason: _parseEnum(GameEndReason.values, map['reason'], 'reason'),
    tally: tally,
    eliminatedUid: map['eliminatedUid'] as String?,
    spyGuess: map['spyGuess'] as String?,
  );
}

Room roomFromMap(String id, Map<String, dynamic> data) {
  final settingsRaw = data['settings'];
  if (settingsRaw is! Map) {
    throw const FormatException('Room settings are missing');
  }
  final revealRaw = data['reveal'];
  return Room(
    id: id,
    code: data['code'] as String,
    hostUid: data['hostUid'] as String,
    settings: settingsFromMap(Map<String, dynamic>.from(settingsRaw)),
    createdAt: _dateTime(data['createdAt']) ?? _epoch(),
    phase: _parseEnum(GamePhase.values, data['phase'], 'phase'),
    round: _int(data['round'], 0),
    turnOrder: _stringList(data['turnOrder']),
    turnUid: data['turnUid'] as String?,
    voteCount: _int(data['voteCount'], 0),
    voteAttempt: _int(data['voteAttempt'], 1),
    voteCandidateUids: _stringList(data['voteCandidateUids']),
    phaseEndsAt: _dateTime(data['phaseEndsAt']),
    reveal: revealRaw is Map
        ? revealFromMap(Map<String, dynamic>.from(revealRaw))
        : null,
  );
}

/// A player's own secret. [PlayerSecret.role] is absent in modes that hide
/// the role (Undercover) and [PlayerSecret.word] is absent for the Imposter.
PlayerSecret secretFromMap(Map<String, dynamic> data) {
  final role = data['role'];
  return PlayerSecret(
    role: role == null ? null : _parseEnum(PlayerRole.values, role, 'role'),
    word: data['word'] as String?,
  );
}

Clue clueFromMap(String id, Map<String, dynamic> data) {
  return Clue(
    id: id,
    round: _int(data['round'], 1),
    authorUid: data['authorUid'] as String? ?? '',
    text: data['text'] as String? ?? '',
    createdAt: _dateTime(data['createdAt']) ?? _epoch(),
  );
}

Player playerFromMap(String uid, Map<String, dynamic> data) {
  return Player(
    uid: uid,
    displayName: data['displayName'] as String? ?? '',
    joinedAt: _dateTime(data['joinedAt']) ?? _epoch(),
    alive: data['alive'] as bool? ?? true,
    hasVoted: data['hasVoted'] as bool? ?? false,
    connected: data['connected'] as bool? ?? true,
  );
}

/// Public per-player state inside a room. Never contains role or word.
class Player {
  const Player({
    required this.uid,
    required this.displayName,
    required this.joinedAt,
    this.alive = true,
    this.hasVoted = false,
    this.connected = true,
  });

  final String uid;
  final String displayName;
  final DateTime joinedAt;
  final bool alive;
  final bool hasVoted;
  final bool connected;

  Player copyWith({
    String? displayName,
    bool? alive,
    bool? hasVoted,
    bool? connected,
  }) {
    return Player(
      uid: uid,
      displayName: displayName ?? this.displayName,
      joinedAt: joinedAt,
      alive: alive ?? this.alive,
      hasVoted: hasVoted ?? this.hasVoted,
      connected: connected ?? this.connected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          other.uid == uid &&
          other.displayName == displayName &&
          other.joinedAt == joinedAt &&
          other.alive == alive &&
          other.hasVoted == hasVoted &&
          other.connected == connected;

  @override
  int get hashCode =>
      Object.hash(uid, displayName, joinedAt, alive, hasVoted, connected);
}

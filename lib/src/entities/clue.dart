/// A public clue a player gave during the clue phase of a round.
class Clue {
  const Clue({
    required this.id,
    required this.round,
    required this.authorUid,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final int round;
  final String authorUid;
  final String text;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Clue &&
          other.id == id &&
          other.round == round &&
          other.authorUid == authorUid &&
          other.text == text &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, round, authorUid, text, createdAt);
}

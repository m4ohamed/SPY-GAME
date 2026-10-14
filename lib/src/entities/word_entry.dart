import '../enums.dart';

/// One playable word. [similarWord] is a close alternative used by Undercover
/// mode; entries without one can still be used by Imposter mode.
class WordEntry {
  const WordEntry({
    required this.id,
    required this.categoryId,
    required this.language,
    required this.word,
    this.similarWord,
  });

  final String id;
  final String categoryId;
  final WordLanguage language;
  final String word;
  final String? similarWord;

  bool get hasSimilarWord {
    final similar = similarWord;
    return similar != null && similar.trim().isNotEmpty;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordEntry &&
          other.id == id &&
          other.categoryId == categoryId &&
          other.language == language &&
          other.word == word &&
          other.similarWord == similarWord;

  @override
  int get hashCode => Object.hash(id, categoryId, language, word, similarWord);
}

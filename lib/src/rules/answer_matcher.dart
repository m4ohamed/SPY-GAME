/// Compares a typed guess with the real word, forgiving the usual Arabic
/// spelling variations. The server's `spyGuess` function must mirror this.
abstract final class AnswerMatcher {
  /// Arabic diacritics (U+064B to U+065F), superscript alef, and tatweel.
  static final RegExp _diacritics = RegExp('[\u064B-\u065F\u0670\u0640]');

  static final RegExp _nonWordChars = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  static final RegExp _whitespace = RegExp(r'\s+');

  static const String _definiteArticle = 'ال';

  static const Map<String, String> _charMap = {
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ٱ': 'ا',
    'ة': 'ه',
    'ى': 'ي',
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  /// A comparison key: lower-cased, diacritics removed, alef/teh marbuta/alef
  /// maqsura unified, Arabic digits converted, punctuation and spaces dropped,
  /// and a leading "ال" removed from each word.
  static String canonicalKey(String input) {
    final lowered = input.toLowerCase().replaceAll(_diacritics, '');
    final mapped = lowered.split('').map((c) => _charMap[c] ?? c).join();
    final cleaned = mapped.replaceAll(_nonWordChars, ' ');
    return cleaned
        .split(_whitespace)
        .where((token) => token.isNotEmpty)
        .map(_stripArticle)
        .join();
  }

  /// True when [guess] and [answer] are the same word after normalization.
  /// An empty key never matches.
  static bool matches(String guess, String answer) {
    final guessKey = canonicalKey(guess);
    return guessKey.isNotEmpty && guessKey == canonicalKey(answer);
  }

  static String _stripArticle(String token) =>
      token.startsWith(_definiteArticle) && token.length > 3
          ? token.substring(2)
          : token;
}

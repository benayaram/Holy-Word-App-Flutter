import 'dart:math';

/// Service that processes verse text for the 5-level memory battle engine.
/// Level 1: Read (full text)
/// Level 2: Fill Blanks (~30% hidden)
/// Level 3: Half Hidden (~50% hidden)
/// Level 4: First Letters (only first letter of each word)
/// Level 5: Full Recall (empty, user types from memory)
class MemoryBattleService {
  final Random _random = Random();

  /// Level 1: Returns the full verse text unchanged
  String getLevel1Text(String verseText) => verseText;

  /// Level 2: Replace ~30% of words with underscores
  String getLevel2Text(String verseText) {
    final words = verseText.split(' ');
    if (words.length <= 2) return verseText;

    final hideCount = (words.length * 0.3).ceil();
    final indices = _getRandomIndices(words.length, hideCount);

    return words.asMap().entries.map((e) {
      if (indices.contains(e.key)) {
        return '_' * e.value.replaceAll(RegExp(r'[^\w]'), '').length +
            _getTrailingPunctuation(e.value);
      }
      return e.value;
    }).join(' ');
  }

  /// Level 3: Hide ~50% of words
  String getLevel3Text(String verseText) {
    final words = verseText.split(' ');
    if (words.length <= 2) return '___';

    final hideCount = (words.length * 0.5).ceil();
    final indices = _getRandomIndices(words.length, hideCount);

    return words.asMap().entries.map((e) {
      if (indices.contains(e.key)) {
        return '_' * e.value.replaceAll(RegExp(r'[^\w]'), '').length +
            _getTrailingPunctuation(e.value);
      }
      return e.value;
    }).join(' ');
  }

  /// Level 4: Show only first letter of each word
  String getLevel4Text(String verseText) {
    final words = verseText.split(' ');
    return words.map((word) {
      if (word.isEmpty) return '';
      final clean = word.replaceAll(RegExp(r'[^\w]'), '');
      if (clean.isEmpty) return word;
      final firstChar = clean[0];
      final underscores = '_' * (clean.length - 1);
      return '$firstChar$underscores${_getTrailingPunctuation(word)}';
    }).join(' ');
  }

  /// Level 5: Empty string (user must recall from memory)
  String getLevel5Text(String verseText) => '';

  /// Get the display text for a given level
  String getTextForLevel(String verseText, int level) {
    switch (level) {
      case 1: return getLevel1Text(verseText);
      case 2: return getLevel2Text(verseText);
      case 3: return getLevel3Text(verseText);
      case 4: return getLevel4Text(verseText);
      case 5: return getLevel5Text(verseText);
      default: return verseText;
    }
  }

  /// Validate user's typed answer against the original verse
  /// Returns accuracy percentage (0-100)
  int validateRecall(String original, String userInput) {
    final origWords = _normalizeText(original).split(' ').where((w) => w.isNotEmpty).toList();
    final userWords = _normalizeText(userInput).split(' ').where((w) => w.isNotEmpty).toList();

    if (origWords.isEmpty) return 0;
    if (userWords.isEmpty) return 0;

    int matchCount = 0;
    int maxLen = origWords.length;

    for (int i = 0; i < maxLen && i < userWords.length; i++) {
      if (origWords[i] == userWords[i]) {
        matchCount++;
      } else {
        // Partial match (Levenshtein-like)
        final similarity = _wordSimilarity(origWords[i], userWords[i]);
        if (similarity > 0.7) matchCount++;
      }
    }

    return ((matchCount / maxLen) * 100).round();
  }

  /// Check if the user passed a level (accuracy >= threshold)
  bool isLevelPassed(int level, int accuracy) {
    switch (level) {
      case 1: return true; // Just reading
      case 2: return accuracy >= 70;
      case 3: return accuracy >= 75;
      case 4: return accuracy >= 80;
      case 5: return accuracy >= 85;
      default: return false;
    }
  }

  /// Level metadata
  static const List<Map<String, dynamic>> levelInfo = [
    {'level': 1, 'name': 'Read', 'nameTe': 'చదవండి', 'icon': 'visibility',
     'description': 'Read the full verse carefully'},
    {'level': 2, 'name': 'Fill Blanks', 'nameTe': 'ఖాళీలు నింపండి', 'icon': 'edit',
     'description': '30% of words are hidden'},
    {'level': 3, 'name': 'Half Hidden', 'nameTe': 'సగం దాచబడింది', 'icon': 'visibility_off',
     'description': '50% of words are hidden'},
    {'level': 4, 'name': 'First Letters', 'nameTe': 'మొదటి అక్షరాలు', 'icon': 'text_fields',
     'description': 'Only first letter of each word shown'},
    {'level': 5, 'name': 'Full Recall', 'nameTe': 'పూర్తి జ్ఞాపకం', 'icon': 'psychology',
     'description': 'Type the entire verse from memory'},
  ];

  // === Private helpers ===

  Set<int> _getRandomIndices(int length, int count) {
    final indices = <int>{};
    while (indices.length < count && indices.length < length) {
      indices.add(_random.nextInt(length));
    }
    return indices;
  }

  String _getTrailingPunctuation(String word) {
    final match = RegExp(r'[^\w]+$').firstMatch(word);
    return match?.group(0) ?? '';
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _wordSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    final distance = _levenshtein(a, b);
    return 1.0 - (distance / maxLen);
  }

  int _levenshtein(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final List<List<int>> d = List.generate(
      s.length + 1,
      (i) => List.generate(t.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s.length; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= t.length; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return d[s.length][t.length];
  }
}

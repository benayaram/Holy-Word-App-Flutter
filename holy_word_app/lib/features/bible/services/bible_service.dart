import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_word_app/core/services/database_service.dart';
import 'package:holy_word_app/core/providers/language_provider.dart';

final bibleServiceProvider = Provider<BibleService>((ref) {
  final languageCode = ref.watch(languageProvider);
  return BibleService(languageCode);
});

class BibleService {
  final _dbService = DatabaseService();
  final String _languageCode;

  BibleService(this._languageCode);

  String get _dbName => _languageCode == 'te' ? 'bsi_te.db' : 'KJV.db';
  bool get _isTelugu => _languageCode == 'te';

  static const List<String> _teluguBooks = [
    "ఆదికాండము",
    "నిర్గమకాండము",
    "లేవీయకాండము",
    "అరణ్యకాండము",
    "ద్వితీయోపదేశకాండము",
    "యెహోషువ",
    "న్యాయాధిపతులు",
    "రూతు",
    "1 సమూయేలు",
    "2 సమూయేలు",
    "1 రాజులు",
    "2 రాజులు",
    "1 దినవృత్తాంతములు",
    "2 దినవృత్తాంతములు",
    "ఎజ్రా",
    "నెహెమీయా",
    "ఎస్తేరు",
    "యోబు",
    "కీర్తనలు",
    "సామెతలు",
    "ప్రసంగి",
    "పరమగీతము",
    "యెషయా",
    "యిర్మీయా",
    "విలాపవాక్యములు",
    "యెహేజ్కేలు",
    "దానియేలు",
    "హోషేయ",
    "యోవేలు",
    "ఆమోసు",
    "ఒబద్యా",
    "యోనా",
    "మీకా",
    "నహూము",
    "హబకూకు",
    "జెఫన్యా",
    "హగ్గయి",
    "జెకర్యా",
    "మలాకీ",
    "మత్తయి",
    "మార్కు",
    "లూకా",
    "యోహాను",
    "అపొస్తలుల కార్యములు",
    "రోమీయులకు",
    "1 కొరింథీయులకు",
    "2 కొరింథీయులకు",
    "గలతీయులకు",
    "ఎఫెసీయులకు",
    "ఫిలిప్పీయులకు",
    "కొలొస్సయులకు",
    "1 థెస్సలొనీకయులకు",
    "2 థెస్సలొనీకయులకు",
    "1 తిమోతికి",
    "2 తిమోతికి",
    "తీతుకు",
    "ఫిలేమోనుకు",
    "హెబ్రీయులకు",
    "యాకోబు",
    "1 పేతురు",
    "2 పేతురు",
    "1 యోహాను",
    "2 యోహాను",
    "3 యోహాను",
    "యూదా",
    "ప్రకటన"
  ];

  Future<List<Map<String, dynamic>>> getBooks() async {
    if (_isTelugu) {
      // Return hardcoded list with IDs
      return List.generate(_teluguBooks.length, (index) {
        return {
          'id': index + 1,
          'name': _teluguBooks[index],
        };
      });
    } else {
      // English: KJV_books table
      return await _dbService.query(_dbName, 'KJV_books', orderBy: 'id');
    }
  }

  Future<List<int>> getChapters(int bookId) async {
    if (_isTelugu) {
      if (bookId < 1 || bookId > _teluguBooks.length) return [];
      final bookName = _teluguBooks[bookId - 1];
      // Telugu: column 'b' is book name, 'c' is chapter
      final result = await _dbService.rawQuery(
        _dbName,
        'SELECT DISTINCT c FROM verse WHERE b = ? ORDER BY c',
        [bookName],
      );
      return result.map((e) => e['c'] as int).toList();
    } else {
      // English: KJV_verses table
      final result = await _dbService.rawQuery(
        _dbName,
        'SELECT DISTINCT chapter FROM KJV_verses WHERE book_id = ? ORDER BY chapter',
        [bookId],
      );
      return result.map((e) => e['chapter'] as int).toList();
    }
  }

  Future<List<Map<String, dynamic>>> getVerses(int bookId, int chapter) async {
    if (_isTelugu) {
      if (bookId < 1 || bookId > _teluguBooks.length) return [];
      final bookName = _teluguBooks[bookId - 1];
      // Telugu: columns 'b', 'c', 'v', 't'
      final result = await _dbService.query(
        _dbName,
        'verse',
        where: 'b = ? AND c = ?',
        whereArgs: [bookName, chapter],
        orderBy: 'v',
      );
      // Map to standard format expected by UI
      return result
          .map((e) => {
                'verse': e['v'],
                'text': e['t'],
                'book_id': bookId, // Inject ID related to query
                'chapter': chapter,
              })
          .toList();
    } else {
      // English: KJV_verses table
      final result = await _dbService.query(
        _dbName,
        'KJV_verses',
        where: 'book_id = ? AND chapter = ?',
        whereArgs: [bookId, chapter],
        orderBy: 'verse',
      );
      // Standard format from KJV results matches expectation mostly,
      // but ensure consistency
      return result;
    }
  }

  Future<List<Map<String, dynamic>>> searchVerses(String query) async {
    if (_isTelugu) {
      final result = await _dbService.rawQuery(
        _dbName,
        "SELECT * FROM verse WHERE t LIKE ? LIMIT 20",
        ['%$query%'],
      );
      // Map to standard format
      return result.map((e) {
        // We need to reverse lookup ID from name 'b' if we want to provide book_id
        final bookName = e['b'] as String;
        final bookId = _teluguBooks.indexOf(bookName) + 1;
        return {
          'verse': e['v'],
          'text': e['t'],
          'book_id': bookId,
          'chapter': e['c'],
          // Add book_name for UI convenience if needed
          'book_name': bookName,
        };
      }).toList();
    } else {
      final result = await _dbService.rawQuery(
        _dbName,
        "SELECT v.*, b.name as book_name FROM KJV_verses v JOIN KJV_books b ON v.book_id = b.id WHERE v.text LIKE ? LIMIT 20",
        ['%$query%'],
      );
      // KJV results now include book_name
      return result;
    }
  }

  Future<List<Map<String, dynamic>>> getCrossReferences(
      int bookId, int chapter, int verse) async {
    // Cross References DB uses Telugu Book Names in 'source_book' column
    // regardless of the app language.
    if (bookId < 1 || bookId > _teluguBooks.length) return [];
    final teluguBookName = _teluguBooks[bookId - 1];

    final refs = await _dbService.rawQuery(
        'cross_references.db',
        'SELECT * FROM cross_references WHERE source_book = ? AND source_chapter = ? AND source_verse = ?',
        [teluguBookName, chapter, verse]);
    return refs;
  }
}

import 'package:flutter/material.dart';
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

  String get _dbName => _languageCode == 'telugu' ? 'bsi_te.db' : 'KJV.db';
  bool get _isTelugu => _languageCode == 'telugu';

  static const List<String> _teluguBooks = [
    "ఆదికాండము",
    "నిర్గమకాండము",
    "లేవీయకాండము",
    "సంఖ్యాకాండము",
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

  static const List<String> _englishBooks = [
    "Genesis",
    "Exodus",
    "Leviticus",
    "Numbers",
    "Deuteronomy",
    "Joshua",
    "Judges",
    "Ruth",
    "1 Samuel",
    "2 Samuel",
    "1 Kings",
    "2 Kings",
    "1 Chronicles",
    "2 Chronicles",
    "Ezra",
    "Nehemiah",
    "Esther",
    "Job",
    "Psalms",
    "Proverbs",
    "Ecclesiastes",
    "Song of Solomon",
    "Isaiah",
    "Jeremiah",
    "Lamentations",
    "Ezekiel",
    "Daniel",
    "Hosea",
    "Joel",
    "Amos",
    "Obadiah",
    "Jonah",
    "Micah",
    "Nahum",
    "Habakkuk",
    "Zephaniah",
    "Haggai",
    "Zechariah",
    "Malachi",
    "Matthew",
    "Mark",
    "Luke",
    "John",
    "Acts",
    "Romans",
    "1 Corinthians",
    "2 Corinthians",
    "Galatians",
    "Ephesians",
    "Philippians",
    "Colossians",
    "1 Thessalonians",
    "2 Thessalonians",
    "1 Timothy",
    "2 Timothy",
    "Titus",
    "Philemon",
    "Hebrews",
    "James",
    "1 Peter",
    "2 Peter",
    "1 John",
    "2 John",
    "3 John",
    "Jude",
    "Revelation"
  ];

  Future<List<Map<String, dynamic>>> getBooks() async {
    final books = _isTelugu ? _teluguBooks : _englishBooks;
    return List.generate(books.length, (index) {
      return {
        'id': index + 1,
        'name': books[index],
      };
    });
  }

  Future<List<int>> getChapters(int bookId) async {
    if (_isTelugu) {
      // Telugu DB 'bsi_te.db' uses 'id' schema: 1001001 (Book 1, Chap 1, Verse 1)
      // Book ID range: bookId * 1000000 to (bookId + 1) * 1000000
      final startId = bookId * 1000000;
      final endId = (bookId + 1) * 1000000;

      // Query IDs in the book range
      final res = await _dbService.rawQuery(
          _dbName,
          'SELECT id FROM verse WHERE id >= ? AND id < ?', // 'verse' table found via inspection
          [startId, endId]);

      // Extract distinct chapters from IDs
      final chapters = res
          .map((r) {
            final id = r['id'] as int;
            return (id % 1000000) ~/ 1000;
          })
          .toSet()
          .toList();
      chapters.sort();
      return chapters;
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
      // ID calculation for specific chapter
      final startId = bookId * 1000000 + chapter * 1000;
      final endId = startId + 1000; // Max 999 verses

      final res = await _dbService.rawQuery(
          _dbName,
          'SELECT id, t FROM verse WHERE id >= ? AND id < ? ORDER BY id',
          [startId, endId]);

      return res.map((r) {
        final id = r['id'] as int;
        final verseNum = id % 1000;
        return {
          'verse': verseNum,
          'text': r['t'] as String,
          'telugu_text': r['t'] as String, // For UI consistency
        };
      }).toList();
    } else {
      // English: KJV_verses table
      final result = await _dbService.query(
        _dbName,
        'KJV_verses',
        where: 'book_id = ? AND chapter = ?',
        whereArgs: [bookId, chapter],
        orderBy: 'verse',
      );
      return result;
    }
  }

  Future<Map<String, String>> getParallelVerses(
      int bookId, int chapter, List<int> verseNumbers) async {
    try {
      // Determine target DB (opposite of current)
      final useTeluguDb = !_isTelugu;
      // If App Language is Telugu (_isTelugu = true), we want English text. So target is English (useTeluguDb = false).
      // If App Language is English (_isTelugu = false), we want Telugu text. So target is Telugu (useTeluguDb = true).

      final targetDbName = useTeluguDb ? 'bsi_te.db' : 'KJV.db';

      List<String> texts = [];
      String bookName = '';

      if (useTeluguDb) {
        // Fetch Telugu Verses
        // ID calculation
        for (var vNum in verseNumbers) {
          final id = bookId * 1000000 + chapter * 1000 + vNum;
          final res = await _dbService
              .rawQuery(targetDbName, 'SELECT t FROM verse WHERE id = ?', [id]);
          if (res.isNotEmpty) {
            texts.add('${res.first['t']}');
          }
        }
        // Get Telugu Book Name
        if (bookId >= 1 && bookId <= _teluguBooks.length) {
          bookName = _teluguBooks[bookId - 1];
        }
      } else {
        // Fetch English Verses
        final placeholders = List.filled(verseNumbers.length, '?').join(',');
        final res = await _dbService.rawQuery(
            targetDbName,
            'SELECT text FROM KJV_verses WHERE book_id = ? AND chapter = ? AND verse IN ($placeholders) ORDER BY verse',
            [bookId, chapter, ...verseNumbers]);

        for (var r in res) {
          texts.add('${r['text']}');
        }

        // Get English Book Name
        if (bookId >= 1 && bookId <= _englishBooks.length) {
          bookName = _englishBooks[bookId - 1];
        }
      }

      // Combine verses
      String fullText = texts.join('\n');

      // Construct reference (e.g., "Genesis 1:1" or "ఆదికాండము 1:1")
      // Use the *target* language book name
      // Logic: If verseNumbers has mutliple, handle range. Simplified for now as singular or comma separated is common,
      // but usually this is called with 'verseNumbers' list.
      // Let's format: "Book Chapter:Verse" (start) - end??
      // The calling screen usually formats the reference.
      // For now, let's just return the Book Name so the screen can construct it,
      // or construct a simple one. The screen calls it 'verseReference'.
      // Let's replicate standard format: "$bookName $chapter:${verseNumbers.first}"

      // Better: Just return the Book Name so the UI can format it if needed,
      // OR return the full reference string.
      // The UI uses `widget.verseReference`.
      // Let's return the simplified reference using the *Parallel* language book name.

      String verseRef = "";
      if (verseNumbers.isNotEmpty) {
        if (verseNumbers.length == 1) {
          verseRef = "$bookName $chapter:${verseNumbers.first}";
        } else {
          verseRef =
              "$bookName $chapter:${verseNumbers.first}-${verseNumbers.last}"; // Simplified range
        }
      }

      return {'text': fullText, 'reference': verseRef};
    } catch (e) {
      debugPrint("Error fetching parallel verses: $e");
      return {'text': "", 'reference': ""};
    }
  }

  Future<List<Map<String, dynamic>>> searchVerses(String query) async {
    if (_isTelugu) {
      final result = await _dbService.rawQuery(
        _dbName,
        "SELECT id, t FROM verse WHERE t LIKE ? LIMIT 20",
        ['%$query%'],
      );

      return result.map((e) {
        final id = e['id'] as int;
        final bookId = id ~/ 1000000;
        final chapter = (id % 1000000) ~/ 1000;
        final verse = id % 1000;
        final bookName = (bookId >= 1 && bookId <= _teluguBooks.length)
            ? _teluguBooks[bookId - 1]
            : 'Unknown';

        return {
          'verse': verse,
          'text': e['t'],
          'book_id': bookId,
          'chapter': chapter,
          'book_name': bookName,
        };
      }).toList();
    } else {
      final result = await _dbService.rawQuery(
        _dbName,
        "SELECT v.*, b.name as book_name FROM KJV_verses v JOIN KJV_books b ON v.book_id = b.id WHERE v.text LIKE ? LIMIT 20",
        ['%$query%'],
      );
      return result;
    }
  }

  Future<List<Map<String, dynamic>>> getCrossReferences(
      int bookId, int chapter, int verse) async {
    if (bookId < 1 || bookId > _teluguBooks.length) return [];
    final teluguBookName = _teluguBooks[bookId - 1];

    final refs = await _dbService.rawQuery(
        'cross_references.db',
        'SELECT * FROM cross_references WHERE source_book = ? AND source_chapter = ? AND source_verse = ?',
        [teluguBookName, chapter, verse]);

    // Enhance refs with text and BookID
    final List<Map<String, dynamic>> enhancedRefs = [];

    for (var r in refs) {
      final refBookName = r['reference_book'] as String;
      final refChapter = r['reference_chapter'] as int;
      final refVerse = r['reference_verse'] as int;
      String? refText = r['reference_text'] as String?;

      // Find Book ID
      int? refBookId;

      // Normalize Ref Book Name (Handle I/II/III vs 1/2/3)
      var cleanRefBook = refBookName.trim();
      cleanRefBook = cleanRefBook.replaceAll(RegExp(r'^I\s'), '1 ');
      cleanRefBook = cleanRefBook.replaceAll(RegExp(r'^II\s'), '2 ');
      cleanRefBook = cleanRefBook.replaceAll(RegExp(r'^III\s'), '3 ');

      // 1. Try Telugu Exact Match
      var teluguIndex = _teluguBooks.indexOf(cleanRefBook);
      if (teluguIndex != -1) {
        refBookId = teluguIndex + 1;
      }
      // 2. Try English Exact/Case-Insensitive Match
      else {
        final englishIndex = _englishBooks
            .indexWhere((b) => b.toLowerCase() == cleanRefBook.toLowerCase());
        if (englishIndex != -1) {
          refBookId = englishIndex + 1;
        } else {
          // 3. Try standard variations
          if (cleanRefBook.toLowerCase() == 'psalm') cleanRefBook = 'Psalms';
          if (cleanRefBook.toLowerCase() == 'song of songs')
            cleanRefBook = 'Song of Solomon';

          final retryIndex = _englishBooks
              .indexWhere((b) => b.toLowerCase() == cleanRefBook.toLowerCase());
          if (retryIndex != -1) refBookId = retryIndex + 1;
        }
      }

      // If we found a Book ID and Text is missing, fetch it
      if (refBookId != null && (refText == null || refText.isEmpty)) {
        try {
          // Fetch using CURRENT app language (to match user preference)
          final rawVerses = await getVerses(refBookId, refChapter);
          final verses = List<Map<String, dynamic>>.from(rawVerses);

          final matchedVerse = verses.firstWhere((v) {
            final vNum = v['verse'];
            // Handle potential type mismatch if DB returns string
            final vInt =
                vNum is int ? vNum : int.tryParse(vNum.toString()) ?? 0;
            return vInt == refVerse;
          }, orElse: () => <String, dynamic>{});

          if (matchedVerse.isNotEmpty) {
            refText = matchedVerse['text'] ?? matchedVerse['telugu_text'];
          }
        } catch (e) {
          debugPrint('Error fetching ref text: $e');
        }
      }

      // Localize Book Name for Display
      String displayBookName = refBookName;
      if (refBookId != null) {
        if (_isTelugu) {
          if (refBookId > 0 && refBookId <= _teluguBooks.length) {
            displayBookName = _teluguBooks[refBookId - 1];
          }
        } else {
          if (refBookId > 0 && refBookId <= _englishBooks.length) {
            displayBookName = _englishBooks[refBookId - 1];
          }
        }
      }

      enhancedRefs.add({
        ...r,
        'reference_book': displayBookName, // Overwritten with localized name
        'reference_text': refText,
        'reference_book_id': refBookId, // Store ID for navigation
      });
    }

    return enhancedRefs;
  }

  // --- User Data Methods ---

  Future<Map<String, dynamic>> getRandomVerse({String? language}) async {
    try {
      bool useTelugu = _isTelugu;
      bool fetchDual = false;
      if (language == 'Telugu') useTelugu = true;
      if (language == 'English') useTelugu = false;
      if (language == 'Both') {
        useTelugu = _isTelugu; // Base on app language
        fetchDual = true;
      }

      Map<String, dynamic> result = {};

      if (useTelugu) {
        // Telugu DB: 'verse' table, explicit DB name to avoid ambiguity if _dbName relies on toggle
        final res = await _dbService.rawQuery(
          'bsi_te.db',
          'SELECT id, t FROM verse ORDER BY RANDOM() LIMIT 1',
          [],
        );
        if (res.isEmpty) return {};

        final row = res.first;
        final id = row['id'] as int;
        final text = row['t'] as String;

        // Decode ID
        final bookId = id ~/ 1000000;
        final chapter = (id % 1000000) ~/ 1000;
        final verseNum = id % 1000;

        final bookName = (bookId >= 1 && bookId <= _teluguBooks.length)
            ? _teluguBooks[bookId - 1]
            : 'Unknown';

        result = {
          'text': text,
          'reference': '$bookName $chapter:$verseNum',
          'book_id': bookId,
          'chapter': chapter,
          'verse': verseNum,
        };
      } else {
        // English DB
        final res = await _dbService.rawQuery(
          'KJV.db',
          'SELECT v.*, b.name as book_name FROM KJV_verses v JOIN KJV_books b ON v.book_id = b.id ORDER BY RANDOM() LIMIT 1',
          [],
        );

        if (res.isEmpty) return {};
        final row = res.first;

        result = {
          'text': row['text'],
          'reference': '${row['book_name']} ${row['chapter']}:${row['verse']}',
          'book_id': row['book_id'] as int,
          'chapter': row['chapter'] as int,
          'verse': row['verse'] as int,
        };
      }

      // If Dual, fetch secondary
      if (fetchDual && result.isNotEmpty) {
        final bookId = result['book_id'] as int;
        final chapter = result['chapter'] as int;
        final verse = result['verse'] as int;

        String secondaryText = '';
        String secondaryRef = '';

        if (useTelugu) {
          // Need English
          final res = await _dbService.rawQuery(
              'KJV.db',
              'SELECT v.*, b.name as book_name FROM KJV_verses v JOIN KJV_books b ON v.book_id = b.id WHERE v.book_id = ? AND v.chapter = ? AND v.verse = ?',
              [bookId, chapter, verse]);
          if (res.isNotEmpty) {
            secondaryText = res.first['text'];
            secondaryRef = '${res.first['book_name']} $chapter:$verse';
          }
        } else {
          // Need Telugu
          final id = bookId * 1000000 + chapter * 1000 + verse;
          final res = await _dbService
              .rawQuery('bsi_te.db', 'SELECT t FROM verse WHERE id = ?', [id]);
          if (res.isNotEmpty) {
            secondaryText = res.first['t'];
            final tBook = (bookId >= 1 && bookId <= _teluguBooks.length)
                ? _teluguBooks[bookId - 1]
                : 'Unknown';
            secondaryRef = '$tBook $chapter:$verse';
          }
        }
        result['secondary_text'] = secondaryText;
        result['secondary_reference'] = secondaryRef;
      }

      return result;
    } catch (e) {
      debugPrint('Error getting random verse: $e');
      return {};
    }
  }

  Future<void> saveNote(
      String reference, String verseText, String noteContent) async {
    await _dbService.insert('holy_word_user.db', 'notes', {
      'reference': reference,
      'verse_text': verseText,
      'note_content': noteContent,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveHighlight(
      int bookId, int chapter, int verse, int color) async {
    await _dbService.insert('holy_word_user.db', 'highlights', {
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'color': color,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

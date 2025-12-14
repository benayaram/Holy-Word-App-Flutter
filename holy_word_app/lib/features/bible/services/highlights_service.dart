import 'package:holy_word_app/core/services/database_service.dart';

class HighlightsService {
  final _dbService = DatabaseService();

  Future<int> addHighlight(
      int bookId, int chapter, int verse, int color) async {
    return await _dbService.insert('holy_word_user.db', 'highlights', {
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'color': color,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHighlights(
      int bookId, int chapter) async {
    return await _dbService.query(
      'holy_word_user.db',
      'highlights',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
    );
  }

  Future<List<Map<String, dynamic>>> getAllHighlights() async {
    // We might want to join with book names here or do it in UI
    // For now, raw query
    return await _dbService.query(
      'holy_word_user.db',
      'highlights',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> deleteHighlight(int id) async {
    return await _dbService.delete(
      'holy_word_user.db',
      'highlights',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Method to remove highlight by unique verse constraint if needed
  Future<int> removeHighlight(int bookId, int chapter, int verse) async {
    return await _dbService.delete('holy_word_user.db', 'highlights',
        where: 'book_id = ? AND chapter = ? AND verse = ?',
        whereArgs: [bookId, chapter, verse]);
  }
}

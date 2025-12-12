import 'package:holy_word_app/core/services/database_service.dart';

class NotesService {
  final _dbService = DatabaseService();

  Future<int> addNote(
      String verseText, String reference, String content) async {
    return await _dbService.insert('holy_word_user.db', 'notes', {
      'verse_text': verseText,
      'reference': reference,
      'note_content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    return await _dbService.query('holy_word_user.db', 'notes',
        orderBy: 'created_at DESC');
  }

  Future<int> deleteNote(int id) async {
    return await _dbService
        .delete('holy_word_user.db', 'notes', where: 'id = ?', whereArgs: [id]);
  }
}

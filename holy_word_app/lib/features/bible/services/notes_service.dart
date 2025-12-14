import 'package:holy_word_app/core/services/database_service.dart';

class NotesService {
  final _dbService = DatabaseService();

  // --- V2 Methods (Multi-verse Notes) ---

  Future<int> createNote(String title, String content) async {
    return await _dbService.insert('holy_word_user.db', 'notes_v2', {
      'title': title,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> addVerseToNote(int noteId, int bookId, int chapter, int verse,
      String verseText, String reference) async {
    return await _dbService.insert('holy_word_user.db', 'note_verses', {
      'note_id': noteId,
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'verse_text': verseText,
      'reference': reference,
    });
  }

  Future<List<Map<String, dynamic>>> getNotesV2() async {
    return await _dbService.query('holy_word_user.db', 'notes_v2',
        orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>> getNoteDetails(int noteId) async {
    final notes = await _dbService.query('holy_word_user.db', 'notes_v2',
        where: 'id = ?', whereArgs: [noteId]);

    if (notes.isEmpty) return {};

    final verses = await _dbService.query('holy_word_user.db', 'note_verses',
        where: 'note_id = ?', whereArgs: [noteId], orderBy: 'id ASC');

    return {
      ...notes.first,
      'verses': verses,
    };
  }

  Future<int> deleteNoteV2(int id) async {
    // Delete verses first (though cascade might handle it if supported, better explicit here for sqflite safety)
    await _dbService.delete('holy_word_user.db', 'note_verses',
        where: 'note_id = ?', whereArgs: [id]);
    return await _dbService.delete('holy_word_user.db', 'notes_v2',
        where: 'id = ?', whereArgs: [id]);
  }

  // Method to check if a verse is in any note (for icons)
  Future<List<Map<String, dynamic>>> getAllNoteVerses() async {
    return await _dbService.query('holy_word_user.db', 'note_verses');
  }

  // --- Legacy Methods (Keeping for backward compat or migration if needed) ---
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

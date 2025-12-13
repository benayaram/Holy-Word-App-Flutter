import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath =
      join(Directory.current.path, 'assets', 'database', 'bsi_te.db');
  print('Opening database at: $dbPath');

  if (!File(dbPath).existsSync()) {
    print('Error: Database file not found at $dbPath');
    return;
  }

  final db = await openDatabase(dbPath, readOnly: true);

  try {
    print('\n--- Tables ---');
    final tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    for (var t in tables) {
      print(t['name']);
    }

    print(
        '\n--- Schema of Verse Table (guessing name "verse" or "verses") ---');
    // Try to find the verse table
    String? verseTable;
    for (var t in tables) {
      final name = t['name'] as String;
      if (name.toLowerCase().contains('verse') ||
          name.toLowerCase().contains('bible')) {
        verseTable = name;
        break;
      }
    }

    // If not found, guessed on commonly used names
    verseTable ??= 'verse';

    print('Inspecting table: $verseTable');
    final columns = await db.rawQuery("PRAGMA table_info($verseTable)");
    for (var c in columns) {
      print(c);
    }

    print('\n--- Sample Data ---');
    final rows = await db.query(verseTable, limit: 3);
    for (var r in rows) {
      print(r);
    }

    print('\n--- Distinct Book Names (First 5) ---');
    // Assuming column 'b' or 'book' or similar based on previous findings
    // In logs user saw "text" and "verse" working but book names not matching?
    // Let's see what columns we have first.

    // If table has 'b' column (as per comments in service)
    // final books = await db.rawQuery('SELECT DISTINCT b FROM $verseTable LIMIT 5');
    // print(books);
  } catch (e) {
    print('Error inspecting DB: $e');
  } finally {
    await db.close();
  }
}

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Check 'cross_references.db'
  final dbPath =
      join(Directory.current.path, 'assets', 'database', 'cross_references.db');
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

    // Expecting 'cross_references' table
    final tableName = 'cross_references';
    print('\n--- Schema of $tableName ---');
    final columns = await db.rawQuery("PRAGMA table_info($tableName)");
    for (var c in columns) {
      print(c);
    }

    print('\n--- Sample Data ---');
    final rows = await db.query(tableName, limit: 3);
    for (var r in rows) {
      print(r);
    }
  } catch (e) {
    print('Error inspecting DB: $e');
  } finally {
    await db.close();
  }
}

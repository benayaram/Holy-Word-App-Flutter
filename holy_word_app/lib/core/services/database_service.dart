import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static final Map<String, Database> _databases = {};
  static final Map<String, Future<Database>> _initFutures = {};

  Future<Database> getDatabase(String dbName) async {
    if (_databases.containsKey(dbName)) return _databases[dbName]!;

    // Prevent race conditions by caching the future
    if (_initFutures.containsKey(dbName)) return _initFutures[dbName]!;

    final future = _initDatabase(dbName);
    _initFutures[dbName] = future;

    try {
      final db = await future;
      _databases[dbName] = db;
      _initFutures.remove(dbName);
      return db;
    } catch (e) {
      _initFutures.remove(dbName);
      rethrow;
    }
  }

  Future<Database> _initDatabase(String dbName) async {
    debugPrint('DatabaseService: Initializing $dbName');
    var path = dbName;

    if (!kIsWeb) {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, dbName);
      debugPrint('DatabaseService: Resolved path to $path');
    }

    // For user data (notes)...
    if (dbName == 'holy_word_user.db') {
      // ... existing user db logic ...
      final db =
          await openDatabase(path, version: 3, onCreate: (db, version) async {
        await _createTables(db);
      }, onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      });
      await _createTables(db);
      return db;
    }

    // Bible Database Logic
    var exists = await databaseExists(path);
    debugPrint('DatabaseService: Exists? $exists');

    if (!exists) {
      debugPrint('DatabaseService: Database does not exist. Copying...');
      await _copyDatabase(dbName, path);
    } else {
      // Verify Integrity
      debugPrint('DatabaseService: Database exists. Verifying integrity...');
      try {
        final db = await openDatabase(path, readOnly: true);
        // Debug: List ALL tables
        final allTables = await db
            .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        debugPrint('DatabaseService: All tables in DB: $allTables');

        final result = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='verse'");
        debugPrint('DatabaseService: Verification result: $result');

        if (result.isEmpty) {
          debugPrint(
              'DatabaseService: CORRUPT! Table verse missing. Resetting...');
          await db.close();
          await _deleteDbFiles(path); // Custom delete
          await _copyDatabase(dbName, path);
        } else {
          debugPrint('DatabaseService: Database is valid.');
          // Debug: Check columns
          final columns = await db.rawQuery('PRAGMA table_info(verse)');
          debugPrint('DatabaseService: Columns in verse table: $columns');

          // Debug: Check sample data to see format of 'b' (Book ID)
          final sampleRows =
              await db.rawQuery('SELECT b, c, v, t FROM verse LIMIT 3');
          debugPrint('DatabaseService: Sample rows: $sampleRows');

          return db;
        }
      } catch (e) {
        debugPrint(
            'DatabaseService: Error opening/verifying ($e). Resetting...');
        await _deleteDbFiles(path);
        await _copyDatabase(dbName, path);
      }
    }

    debugPrint('DatabaseService: Opening final database instance.');
    return await openDatabase(path, readOnly: true);
  }

  Future<void> _deleteDbFiles(String path) async {
    try {
      await deleteDatabase(path);
      // Explicitly try deleting journal files just in case
      final shm = File('$path-shm');
      final wal = File('$path-wal');
      if (await shm.exists()) await shm.delete();
      if (await wal.exists()) await wal.delete();
      debugPrint('DatabaseService: Deleted database files.');
    } catch (e) {
      debugPrint('DatabaseService: Error deleting database files: $e');
    }
  }

  Future<void> _copyDatabase(String dbName, String path) async {
    debugPrint('DatabaseService: Start copying $dbName to $path');
    try {
      if (!kIsWeb) {
        await Directory(dirname(path)).create(recursive: true);
      }

      ByteData data = await rootBundle.load('assets/database/$dbName');
      debugPrint(
          'DatabaseService: Asset loaded. Size: ${data.lengthInBytes} bytes');

      Uint8List bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      if (kIsWeb) {
        await databaseFactory.writeDatabaseBytes(path, bytes);
      } else {
        await File(path).writeAsBytes(bytes, flush: true);
      }
      debugPrint('DatabaseService: Copy successful.');
    } catch (e) {
      debugPrint('DatabaseService: COPY FAILED! $e');
      throw Exception("Error copying database $dbName: $e");
    }
  }

  Future<void> _createTables(Database db) async {
    // Create each table separately to ensure reliability
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_text TEXT NOT NULL,
        reference TEXT NOT NULL,
        note_content TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes_v2 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        verse_text TEXT NOT NULL,
        reference TEXT NOT NULL,
        FOREIGN KEY(note_id) REFERENCES notes_v2(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS highlights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        color INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        unique(book_id, chapter, verse)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS plan_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id TEXT NOT NULL,
        day_index INTEGER NOT NULL,
        is_completed INTEGER DEFAULT 0,
        completed_date TEXT,
        unique(plan_id, day_index)
      );
    ''');
  }

  // Generic query method
  Future<List<Map<String, dynamic>>> query(String dbName, String table,
      {String? where,
      List<Object?>? whereArgs,
      String? orderBy,
      int? limit}) async {
    if (kIsWeb) {
      // Allow Web Execution
    }
    final db = await getDatabase(dbName);
    return await db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  // Raw query method
  Future<List<Map<String, dynamic>>> rawQuery(String dbName, String sql,
      [List<Object?>? arguments]) async {
    if (kIsWeb) {
      // Allow Web Execution
    }
    final db = await getDatabase(dbName);
    return await db.rawQuery(sql, arguments);
  }

  // Insert method
  Future<int> insert(
      String dbName, String table, Map<String, dynamic> values) async {
    if (kIsWeb) {
      // Allow Web Execution
    }
    final db = await getDatabase(dbName);
    return await db.insert(table, values);
  }

  // Update method
  Future<int> update(String dbName, String table, Map<String, dynamic> values,
      {String? where, List<Object?>? whereArgs}) async {
    if (kIsWeb) {
      // Allow Web Execution
    }
    final db = await getDatabase(dbName);
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  // Delete method
  Future<int> delete(String dbName, String table,
      {String? where, List<Object?>? whereArgs}) async {
    if (kIsWeb) {
      // Allow Web Execution
    }
    final db = await getDatabase(dbName);
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}

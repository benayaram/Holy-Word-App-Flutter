import 'dart:io';
import 'dart:typed_data';
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
    var path = dbName;

    if (!kIsWeb) {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, dbName);
    }

    // For user data (notes), we don't copy from assets, we create schema
    if (dbName == 'holy_word_user.db') {
      final db =
          await openDatabase(path, version: 3, onCreate: (db, version) async {
        await _createTables(db);
      }, onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      });

      // Robust Check: Ensure tables exist even if migration failed or didn't run
      // This fixes the "no such table" error for existing users instantly.
      await _createTables(db);

      return db;
    }

    // For Bible and Cross Refs, copy from assets if not exists
    var exists = await databaseExists(path);

    if (!exists) {
      try {
        if (!kIsWeb) {
          // Native: Create directory and copy file
          await Directory(dirname(path)).create(recursive: true);
        }

        // Load database from asset
        ByteData data = await rootBundle.load('assets/database/$dbName');
        Uint8List bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

        if (kIsWeb) {
          // Web: Use databaseFactory to write bytes
          await databaseFactory.writeDatabaseBytes(path, bytes);
        } else {
          // Native: Use File API
          await File(path).writeAsBytes(bytes, flush: true);
        }
      } catch (e) {
        throw Exception("Error copying database $dbName: $e");
      }
    }

    return await openDatabase(path, readOnly: true);
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
        created_at TEXT NOT NULL
      )
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

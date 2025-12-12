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

  Future<Database> getDatabase(String dbName) async {
    if (_databases.containsKey(dbName)) return _databases[dbName]!;
    final db = await _initDatabase(dbName);
    _databases[dbName] = db;
    return db;
  }

  Future<Database> _initDatabase(String dbName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    // For user data (notes), we don't copy from assets, we create schema
    if (dbName == 'holy_word_user.db') {
      return await openDatabase(path, version: 1,
          onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            verse_text TEXT NOT NULL,
            reference TEXT NOT NULL,
            note_content TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      });
    }

    // For Bible and Cross Refs, copy from assets if not exists
    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);

        // Load database from asset and copy
        ByteData data = await rootBundle.load('assets/database/$dbName');
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        throw Exception("Error copying database $dbName: $e");
      }
    }

    return await openDatabase(path, readOnly: true);
  }

  // Generic query method
  Future<List<Map<String, dynamic>>> query(String dbName, String table,
      {String? where,
      List<Object?>? whereArgs,
      String? orderBy,
      int? limit}) async {
    if (kIsWeb) return [];
    final db = await getDatabase(dbName);
    return await db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  // Raw query method
  Future<List<Map<String, dynamic>>> rawQuery(String dbName, String sql,
      [List<Object?>? arguments]) async {
    if (kIsWeb) return [];
    final db = await getDatabase(dbName);
    return await db.rawQuery(sql, arguments);
  }

  // Insert method
  Future<int> insert(
      String dbName, String table, Map<String, dynamic> values) async {
    if (kIsWeb) return 0;
    final db = await getDatabase(dbName);
    return await db.insert(table, values);
  }

  // Delete method
  Future<int> delete(String dbName, String table,
      {String? where, List<Object?>? whereArgs}) async {
    if (kIsWeb) return 0;
    final db = await getDatabase(dbName);
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}

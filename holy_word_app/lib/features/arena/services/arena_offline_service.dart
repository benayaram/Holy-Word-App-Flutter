import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:holy_word_app/core/services/database_service.dart';
import '../data/models/quiz_question.dart';

/// Manages offline question caching and connectivity detection.
/// Caches questions in a local SQLite table for offline play.
class ArenaOfflineService {
  static final ArenaOfflineService _instance = ArenaOfflineService._();
  factory ArenaOfflineService() => _instance;
  ArenaOfflineService._();

  final DatabaseService _dbService = DatabaseService();
  static const String _tableName = 'arena_questions_cache';
  static const String _userCacheTable = 'arena_user_cache';
  bool _initialized = false;

  static const String _arenaDbName = 'arena_cache.db';

  /// Initialize the offline cache tables
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final db = await _getDb();
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          difficulty TEXT NOT NULL,
          data TEXT NOT NULL,
          cached_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_userCacheTable (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          cached_at INTEGER NOT NULL
        )
      ''');
      _initialized = true;
      debugPrint('Arena offline cache initialized');
    } catch (e) {
      debugPrint('Arena offline cache init error: $e');
    }
  }

  Future<Database> _getDb() => _dbService.getDatabase(_arenaDbName);

  /// Cache a batch of questions for offline play
  Future<void> cacheQuestions(List<QuizQuestion> questions) async {
    await initialize();
    final db = await _getDb();
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final q in questions) {
      batch.insert(
        _tableName,
        {
          'id': q.id,
          'category': q.category,
          'difficulty': q.difficulty,
          'data': jsonEncode(q.toJson()),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('Cached ${questions.length} questions offline');
  }

  /// Get cached questions for offline play
  Future<List<QuizQuestion>> getCachedQuestions({
    String? category,
    String difficulty = 'normal',
    int limit = 10,
  }) async {
    await initialize();
    final db = await _getDb();
    String where = 'difficulty = ?';
    List<dynamic> args = [difficulty];

    if (category != null) {
      where += ' AND category = ?';
      args.add(category);
    }

    final rows = await db.query(
      _tableName,
      where: where,
      whereArgs: args,
      orderBy: 'RANDOM()',
      limit: limit,
    );

    return rows.map((row) {
      final data = jsonDecode(row['data'] as String);
      return QuizQuestion.fromJson(data);
    }).toList();
  }

  /// Get count of cached questions
  Future<int> getCachedQuestionCount() async {
    await initialize();
    final db = await _getDb();
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Cache arbitrary key-value data
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    await initialize();
    final db = await _getDb();
    await db.insert(
      _userCacheTable,
      {'key': key, 'value': jsonEncode(data), 'cached_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve cached data by key
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    await initialize();
    final db = await _getDb();
    final rows = await db.query(_userCacheTable, where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['value'] as String);
  }

  /// Clear old cached data (older than 7 days)
  Future<void> clearOldCache() async {
    await initialize();
    final db = await _getDb();
    final cutoff = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    await db.delete(_tableName, where: 'cached_at < ?', whereArgs: [cutoff]);
    await db.delete(_userCacheTable, where: 'cached_at < ?', whereArgs: [cutoff]);
  }

  /// Check current connectivity status
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Stream connectivity changes
  Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged.map(
        (results) => !results.contains(ConnectivityResult.none));
  }
}

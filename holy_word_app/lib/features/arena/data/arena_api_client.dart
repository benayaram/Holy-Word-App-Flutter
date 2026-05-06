import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:holy_word_app/core/env_config.dart';
import 'models/arena_user.dart';
import 'models/quiz_question.dart';
import 'models/battle.dart';

/// HTTP API Client for all Arena backend endpoints
class ArenaApiClient {
  final String baseUrl;
  String? _authToken;

  ArenaApiClient({String? baseUrl}) : baseUrl = baseUrl ?? EnvConfig.arenaApiUrl;

  void setAuthToken(String token) => _authToken = token;
  void clearAuthToken() => _authToken = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // ========== AUTH ==========

  Future<ArenaUser> register({String? displayName, String? language, String? churchId}) async {
    final res = await _post('/auth/register', {
      if (displayName != null) 'displayName': displayName,
      if (language != null) 'language': language,
      if (churchId != null) 'churchId': churchId,
    });
    return ArenaUser.fromJson(res['user']);
  }

  Future<void> updateFcmToken(String token) async {
    await _put('/auth/fcm-token', {'token': token});
  }

  // ========== USERS ==========

  Future<ArenaUser> getProfile() async {
    final res = await _get('/users/me');
    return ArenaUser.fromJson(res['user']);
  }

  Future<List<LeaderboardEntry>> getLeaderboard({
    String type = 'global',
    String? churchId,
    int limit = 20,
  }) async {
    final params = {'type': type, 'limit': '$limit'};
    if (churchId != null) params['churchId'] = churchId;
    final res = await _get('/users/leaderboard', params);
    return (res['leaderboard'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  // ========== QUESTIONS ==========

  Future<List<QuizQuestion>> getQuestions({
    String? category,
    String difficulty = 'normal',
    String? type,
    int limit = 10,
  }) async {
    final params = <String, String>{'difficulty': difficulty, 'limit': '$limit'};
    if (category != null) params['category'] = category;
    if (type != null) params['type'] = type;
    final res = await _get('/questions/with-answers', params);
    return (res['questions'] as List).map((q) => QuizQuestion.fromJson(q)).toList();
  }

  Future<QuizResult> submitQuiz(List<Map<String, dynamic>> answers) async {
    final res = await _post('/questions/submit-quiz', {'answers': answers});
    return QuizResult.fromJson(res);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await _get('/questions/categories');
    return List<Map<String, dynamic>>.from(res['categories'] ?? []);
  }

  Future<List<QuizQuestion>> generateAIQuestions({
    required String passage,
    required String reference,
    String category = 'general',
    String difficulty = 'normal',
    int count = 5,
    String language = 'en',
  }) async {
    final res = await _post('/questions/generate', {
      'passage': passage, 'reference': reference,
      'category': category, 'difficulty': difficulty,
      'count': count, 'language': language,
    });
    return (res['questions'] as List).map((q) => QuizQuestion.fromJson(q)).toList();
  }

  // ========== BATTLES ==========

  Future<Map<String, dynamic>> createBattle({
    String type = 'friend',
    String? category,
    String difficulty = 'normal',
  }) async {
    return await _post('/battles/create', {
      'type': type,
      if (category != null) 'category': category,
      'difficulty': difficulty,
    });
  }

  Future<Map<String, dynamic>> joinBattle(String inviteCode) async {
    return await _post('/battles/join', {'inviteCode': inviteCode});
  }

  Future<Map<String, dynamic>> matchmake({
    String? category,
    String difficulty = 'normal',
  }) async {
    return await _post('/battles/matchmake', {
      if (category != null) 'category': category,
      'difficulty': difficulty,
    });
  }

  Future<Battle> getBattle(String battleId) async {
    final res = await _get('/battles/$battleId');
    return Battle.fromJson(res['battle']);
  }

  // ========== TOURNAMENTS ==========

  Future<Map<String, dynamic>> createTournament(String name, String churchId) async {
    return await _post('/tournaments/create', {'name': name, 'churchId': churchId});
  }

  Future<Map<String, dynamic>> joinTournament(String code) async {
    return await _post('/tournaments/$code/join', {});
  }

  Future<Map<String, dynamic>> getTournament(String id) async {
    return await _get('/tournaments/$id');
  }

  Future<Map<String, dynamic>> startTournament(String id) async {
    return await _post('/tournaments/$id/start', {});
  }

  // ========== SERMONS ==========

  Future<List<SermonQuiz>> getPendingSermons() async {
    final res = await _get('/sermons/pending');
    return (res['quizzes'] as List).map((q) => SermonQuiz.fromJson(q)).toList();
  }

  Future<Map<String, dynamic>> getSermonQuiz(String id) async {
    return await _get('/sermons/$id');
  }

  Future<Map<String, dynamic>> submitSermon(String id, List<int> answers) async {
    return await _post('/sermons/$id/submit', {'answers': answers});
  }

  Future<Map<String, dynamic>> createSermonQuiz({
    required String title,
    required List<String> keyPoints,
    required String churchId,
    String language = 'en',
  }) async {
    return await _post('/sermons/create', {
      'title': title, 'keyPoints': keyPoints,
      'churchId': churchId, 'language': language,
    });
  }

  // ========== MEMORY ==========

  Future<Map<String, dynamic>> getMemoryProgress() async {
    return await _get('/memory/progress');
  }

  Future<Map<String, dynamic>> saveMemoryProgress({
    required int bookId, required int chapter, required int verse,
    required String reference, required String verseText,
    required int level, int? timeMs, String language = 'en',
  }) async {
    return await _post('/memory/progress', {
      'bookId': bookId, 'chapter': chapter, 'verse': verse,
      'reference': reference, 'verseText': verseText,
      'level': level, if (timeMs != null) 'timeMs': timeMs,
      'language': language,
    });
  }

  Future<List<LeaderboardEntry>> getMemoryLeaderboard({String? churchId}) async {
    final params = <String, String>{};
    if (churchId != null) params['churchId'] = churchId;
    final res = await _get('/memory/leaderboard', params);
    return (res['leaderboard'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  // ========== HELPERS ==========

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    debugPrint('GET $uri');
    final res = await http.get(uri, headers: _headers);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('POST $uri');
    final res = await http.post(uri, headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.put(uri, headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    final errorBody = jsonDecode(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      message: errorBody['error'] ?? 'Unknown error',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

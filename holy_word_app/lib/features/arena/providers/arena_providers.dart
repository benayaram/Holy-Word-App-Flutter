import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../data/arena_api_client.dart';
import '../data/arena_websocket_client.dart';
import '../data/models/arena_user.dart';
import '../data/models/quiz_question.dart';
import '../data/models/battle.dart';

// ========== CORE PROVIDERS ==========

/// API Client singleton
final arenaApiClientProvider = Provider<ArenaApiClient>((ref) {
  return ArenaApiClient();
});

/// WebSocket Client singleton
final arenaWsClientProvider = Provider<ArenaWebSocketClient>((ref) {
  final client = ArenaWebSocketClient();
  ref.onDispose(() => client.dispose());
  return client;
});

/// Firebase Auth state
final firebaseAuthProvider = StreamProvider<fb.User?>((ref) {
  return fb.FirebaseAuth.instance.authStateChanges();
});

/// Is user authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  return authState.value != null;
});

// ========== USER PROVIDERS ==========

/// Current Arena User Profile
final arenaUserProvider =
    AsyncNotifierProvider<ArenaUserNotifier, ArenaUser?>(() => ArenaUserNotifier());

class ArenaUserNotifier extends AsyncNotifier<ArenaUser?> {
  @override
  Future<ArenaUser?> build() async {
    final authState = ref.watch(firebaseAuthProvider);
    final user = authState.value;
    if (user == null) return null;

    final api = ref.read(arenaApiClientProvider);
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to obtain authentication token');
    }
    api.setAuthToken(token);
    try {
      return await api.getProfile();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        debugPrint('ArenaUserNotifier: User profile not found in MongoDB (404). Auto-registering...');
        return await api.register(
          displayName: user.displayName ?? (user.isAnonymous ? 'Guest Player' : 'User'),
        );
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<ArenaUser> register({String? displayName, String? language}) async {
    final api = ref.read(arenaApiClientProvider);
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('Not authenticated');

    final token = await fbUser.getIdToken();
    if (token == null) throw Exception('Failed to obtain authentication token');
    api.setAuthToken(token);

    final user = await api.register(
      displayName: displayName ?? fbUser.displayName,
      language: language,
    );
    state = AsyncData(user);
    return user;
  }
}

// ========== QUIZ PROVIDERS ==========

/// Quiz state for solo play
final quizStateProvider =
    NotifierProvider<QuizStateNotifier, QuizState>(QuizStateNotifier.new);

class QuizState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final List<int?> userAnswers;
  final List<int> timeSpentMs;
  final bool isLoading;
  final bool isCompleted;
  final QuizResult? result;
  final String? error;

  QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.userAnswers = const [],
    this.timeSpentMs = const [],
    this.isLoading = false,
    this.isCompleted = false,
    this.result,
    this.error,
  });

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;
  int get answeredCount => userAnswers.where((a) => a != null).length;
  bool get isLastQuestion => currentIndex >= questions.length - 1;

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    List<int?>? userAnswers,
    List<int>? timeSpentMs,
    bool? isLoading,
    bool? isCompleted,
    QuizResult? result,
    String? error,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      timeSpentMs: timeSpentMs ?? this.timeSpentMs,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      result: result ?? this.result,
      error: error,
    );
  }
}

class QuizStateNotifier extends Notifier<QuizState> {
  @override
  QuizState build() {
    return QuizState();
  }

  Future<void> loadQuestions({
    String? category,
    String difficulty = 'normal',
    String? type,
    int count = 10,
  }) async {
    state = QuizState(isLoading: true);
    try {
      final api = ref.read(arenaApiClientProvider);
      final questions = await api.getQuestions(
        category: category,
        difficulty: difficulty,
        type: type,
        limit: count,
      );
      state = QuizState(
        questions: questions,
        userAnswers: List.filled(questions.length, null),
        timeSpentMs: List.filled(questions.length, 0),
      );
    } catch (e) {
      state = QuizState(error: e.toString());
    }
  }

  void answerQuestion(int answer, int timeMs) {
    if (state.currentIndex >= state.questions.length) return;

    final newAnswers = List<int?>.from(state.userAnswers);
    newAnswers[state.currentIndex] = answer;
    final newTimes = List<int>.from(state.timeSpentMs);
    newTimes[state.currentIndex] = timeMs;

    state = state.copyWith(userAnswers: newAnswers, timeSpentMs: newTimes);
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  Future<void> submitQuiz() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(arenaApiClientProvider);
      final answers = <Map<String, dynamic>>[];
      for (int i = 0; i < state.questions.length; i++) {
        if (state.userAnswers[i] != null) {
          answers.add({
            'questionId': state.questions[i].id,
            'answer': state.userAnswers[i],
            'timeMs': state.timeSpentMs[i],
          });
        }
      }
      final result = await api.submitQuiz(answers);
      state = state.copyWith(isCompleted: true, isLoading: false, result: result);

      // Refresh user profile to get updated XP
      ref.read(arenaUserProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = QuizState();
  }
}

// ========== LEADERBOARD PROVIDER ==========

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>(
  (ref, type) async {
    final api = ref.read(arenaApiClientProvider);
    final user = ref.watch(arenaUserProvider).value;
    // Guard: don't send null churchId for church leaderboard
    final churchId = (type == 'church') ? user?.churchId : null;
    if (type == 'church' && churchId == null) {
      return [];
    }
    return api.getLeaderboard(
      type: type,
      churchId: churchId,
    );
  },
);

// ========== CATEGORY PROVIDER ==========

final questionCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(arenaApiClientProvider);
  return api.getCategories();
});

// ========== MEMORY VERSE PROVIDERS ==========

final memoryProgressProvider = FutureProvider<List<MemoryVerse>>((ref) async {
  final api = ref.read(arenaApiClientProvider);
  final res = await api.getMemoryProgress();
  return (res['verses'] as List).map((v) => MemoryVerse.fromJson(v)).toList();
});

// ========== SERMON PROVIDERS ==========

final pendingSermonsProvider = FutureProvider<List<SermonQuiz>>((ref) async {
  final api = ref.read(arenaApiClientProvider);
  return api.getPendingSermons();
});

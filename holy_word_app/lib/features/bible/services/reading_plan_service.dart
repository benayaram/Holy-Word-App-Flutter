import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/services/database_service.dart';

class ReadingPlanService {
  final DatabaseService _dbService = DatabaseService();

  // Load a plan from JSON assets
  Future<Map<String, dynamic>> loadPlan(String planId) async {
    try {
      final String response = await rootBundle
          .loadString('assets/database/readingplans/$planId.json');
      return json.decode(response);
    } catch (e) {
      throw Exception('Failed to load plan: $e');
    }
  }

  // Get progress for a specific plan
  Future<List<Map<String, dynamic>>> getPlanProgress(String planId) async {
    return await _dbService.query(
      'holy_word_user.db',
      'plan_progress',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'day_index ASC',
    );
  }

  // Mark a day as complete
  Future<void> markDayComplete(String planId, int dayIndex) async {
    // Check if already exists
    final existing = await _dbService.query(
      'holy_word_user.db',
      'plan_progress',
      where: 'plan_id = ? AND day_index = ?',
      whereArgs: [planId, dayIndex],
    );

    if (existing.isEmpty) {
      await _dbService.insert('holy_word_user.db', 'plan_progress', {
        'plan_id': planId,
        'day_index': dayIndex,
        'is_completed': 1,
        'completed_date': DateTime.now().toIso8601String(),
      });
    } else {
      await _dbService.update(
        'holy_word_user.db',
        'plan_progress',
        {
          'is_completed': 1,
          'completed_date': DateTime.now().toIso8601String(),
        },
        where: 'plan_id = ? AND day_index = ?',
        whereArgs: [planId, dayIndex],
      );
    }
  }

  // Mark a day as incomplete (optional, but good for UX)
  Future<void> markDayIncomplete(String planId, int dayIndex) async {
    await _dbService.update(
      'holy_word_user.db',
      'plan_progress',
      {
        'is_completed': 0,
        'completed_date': null,
      },
      where: 'plan_id = ? AND day_index = ?',
      whereArgs: [planId, dayIndex],
    );
  }

  // Get Next Unread Day Logic
  Future<int> getNextUnreadDayIndex(String planId) async {
    final progress = await getPlanProgress(planId);

    // Sort handled by SQL query now
    // final sortedProgress = List<Map<String, dynamic>>.from(progress);

    int expectedDay = 0;
    for (var p in progress) {
      if (p['is_completed'] == 1) {
        if (p['day_index'] == expectedDay) {
          expectedDay++;
        }
      }
    }
    // If expectedDay is 365, return 364 (finished)
    return expectedDay;
  }

  // Get Current Streak
  Future<int> getCurrentStreak(String planId) async {
    final progress = await getPlanProgress(planId);

    // Filter for completed days with valid dates
    final completed = progress
        .where((p) => p['is_completed'] == 1 && p['completed_date'] != null)
        .toList();

    if (completed.isEmpty) return 0;

    // Extract dates and obscure time
    Set<String> dates = {};
    for (var p in completed) {
      try {
        final date = DateTime.parse(p['completed_date']);
        dates.add("${date.year}-${date.month}-${date.day}");
      } catch (e) {
        // Ignore invalid dates
      }
    }

    if (dates.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr =
        "${yesterday.year}-${yesterday.month}-${yesterday.day}";

    // Check if streak is active (completed today or yesterday)
    // If neither, broken.
    // However, if I completed today, start counting.
    // If I didn't complete today, but completed yesterday, start counting from yesterday.

    DateTime currentCheck;
    if (dates.contains(today)) {
      currentCheck = now;
    } else if (dates.contains(yesterdayStr)) {
      currentCheck = yesterday;
    } else {
      return 0;
    }

    // Count backwards
    while (true) {
      final key =
          "${currentCheck.year}-${currentCheck.month}-${currentCheck.day}";
      if (dates.contains(key)) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Reset Plan Progress (Delete all records for this plan)
  Future<void> resetPlanProgress(String planId) async {
    await _dbService.delete(
      'holy_word_user.db',
      'plan_progress',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
  }
}

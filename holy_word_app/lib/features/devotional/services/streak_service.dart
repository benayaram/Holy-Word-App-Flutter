import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService();
});

class StreakService {
  static const String _lastVisitKey = 'last_visit_date';
  static const String _streakCountKey = 'streak_count';

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakCountKey) ?? 0;
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisitStr = prefs.getString(_lastVisitKey);
    final today = DateTime.now();
    final todayStr = _formatDate(today);

    if (lastVisitStr == todayStr) {
      // Already visited today
      return;
    }

    int currentStreak = prefs.getInt(_streakCountKey) ?? 0;

    if (lastVisitStr != null) {
      final lastVisit = DateTime.parse(lastVisitStr);
      final difference = today.difference(lastVisit).inDays;

      if (difference == 1) {
        // Consecutive day
        currentStreak++;
      } else if (difference > 1) {
        // Streak broken
        currentStreak = 1;
      }
    } else {
      // First visit
      currentStreak = 1;
    }

    await prefs.setString(_lastVisitKey, todayStr);
    await prefs.setInt(_streakCountKey, currentStreak);
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}

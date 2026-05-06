/// Battle Model
class Battle {
  final String id;
  final String type; // friend, random, ai
  final String status; // waiting, active, completed
  final BattlePlayer? player1;
  final BattlePlayer? player2;
  final int player1Score;
  final int player2Score;
  final String? winnerId;
  final String? inviteCode;
  final int questionCount;
  final String category;
  final String difficulty;
  final DateTime? createdAt;
  final DateTime? completedAt;

  Battle({
    required this.id,
    required this.type,
    required this.status,
    this.player1,
    this.player2,
    this.player1Score = 0,
    this.player2Score = 0,
    this.winnerId,
    this.inviteCode,
    this.questionCount = 10,
    this.category = 'mixed',
    this.difficulty = 'normal',
    this.createdAt,
    this.completedAt,
  });

  bool get isWaiting => status == 'waiting';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isTie => isCompleted && winnerId == null;

  bool isWinner(String userId) => winnerId == userId;

  factory Battle.fromJson(Map<String, dynamic> json) => Battle(
        id: json['id'] ?? '',
        type: json['type'] ?? 'friend',
        status: json['status'] ?? 'waiting',
        player1: json['player1'] != null ? BattlePlayer.fromJson(json['player1']) : null,
        player2: json['player2'] != null ? BattlePlayer.fromJson(json['player2']) : null,
        player1Score: json['player1Score'] ?? 0,
        player2Score: json['player2Score'] ?? 0,
        winnerId: json['winnerId'],
        inviteCode: json['inviteCode'],
        questionCount: json['questionCount'] ?? 10,
        category: json['category'] ?? 'mixed',
        difficulty: json['difficulty'] ?? 'normal',
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
      );
}

class BattlePlayer {
  final String id;
  final String displayName;
  final String? photoUrl;
  final String? level;

  BattlePlayer({required this.id, required this.displayName, this.photoUrl, this.level});

  factory BattlePlayer.fromJson(Map<String, dynamic> json) => BattlePlayer(
        id: json['id'] ?? json['firebaseUid'] ?? '',
        displayName: json['displayName'] ?? 'Anonymous',
        photoUrl: json['photoUrl'],
        level: json['level'],
      );
}

/// Leaderboard Entry
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int xp;
  final String level;
  final int battleWins;
  final int winStreak;
  final int versesMemorized;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.xp = 0,
    this.level = 'Seeker',
    this.battleWins = 0,
    this.winStreak = 0,
    this.versesMemorized = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: json['rank'] ?? 0,
        userId: json['userId'] ?? '',
        displayName: json['displayName'] ?? 'Anonymous',
        photoUrl: json['photoUrl'],
        xp: json['xp'] ?? 0,
        level: json['level'] ?? 'Seeker',
        battleWins: json['battleWins'] ?? 0,
        winStreak: json['winStreak'] ?? 0,
        versesMemorized: json['versesMemorized'] ?? 0,
      );
}

/// Memory Verse Progress
class MemoryVerse {
  final String id;
  final int bookId;
  final int chapter;
  final int verse;
  final String reference;
  final String verseText;
  final int currentLevel;
  final List<int> completedLevels;
  final int? bestTimeMs;
  final String language;

  MemoryVerse({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.reference,
    required this.verseText,
    this.currentLevel = 0,
    this.completedLevels = const [],
    this.bestTimeMs,
    this.language = 'en',
  });

  bool get isFullyMemorized => currentLevel >= 5;

  String get levelName {
    switch (currentLevel) {
      case 0: return 'Not Started';
      case 1: return 'Read';
      case 2: return 'Fill Blanks';
      case 3: return 'Half Hidden';
      case 4: return 'First Letters';
      case 5: return 'Full Recall';
      default: return 'Unknown';
    }
  }

  factory MemoryVerse.fromJson(Map<String, dynamic> json) => MemoryVerse(
        id: json['id'] ?? '',
        bookId: json['bookId'] ?? 0,
        chapter: json['chapter'] ?? 0,
        verse: json['verse'] ?? 0,
        reference: json['reference'] ?? '',
        verseText: json['verseText'] ?? '',
        currentLevel: json['currentLevel'] ?? 0,
        completedLevels: List<int>.from(json['completedLevels'] ?? []),
        bestTimeMs: json['bestTimeMs'],
        language: json['language'] ?? 'en',
      );

  Map<String, dynamic> toJson() => {
        'bookId': bookId, 'chapter': chapter, 'verse': verse,
        'reference': reference, 'verseText': verseText,
        'currentLevel': currentLevel, 'completedLevels': completedLevels,
        'bestTimeMs': bestTimeMs, 'language': language,
      };
}

/// Sermon Quiz
class SermonQuiz {
  final String id;
  final String title;
  final int keyPointCount;
  final int questionCount;
  final int completedCount;
  final bool userCompleted;
  final int? userScore;
  final DateTime? createdAt;

  SermonQuiz({
    required this.id,
    required this.title,
    this.keyPointCount = 0,
    this.questionCount = 0,
    this.completedCount = 0,
    this.userCompleted = false,
    this.userScore,
    this.createdAt,
  });

  factory SermonQuiz.fromJson(Map<String, dynamic> json) => SermonQuiz(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        keyPointCount: json['keyPointCount'] ?? 0,
        questionCount: json['questionCount'] ?? 0,
        completedCount: json['completedCount'] ?? 0,
        userCompleted: json['userCompleted'] ?? false,
        userScore: json['userScore'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );
}

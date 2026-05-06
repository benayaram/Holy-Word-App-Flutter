/// Arena User Profile Model
class ArenaUser {
  final String id;
  final String firebaseUid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String language;
  final int xp;
  final String level;
  final int battleWins;
  final int battleLosses;
  final int winStreak;
  final int bestWinStreak;
  final int versesMemorized;
  final int quizzesCompleted;
  final int totalCorrectAnswers;
  final int totalAnswers;
  final String? churchId;
  final bool isPastor;
  final List<ArenaBadge> badges;
  final ArenaStats? stats;

  ArenaUser({
    required this.id,
    required this.firebaseUid,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.language = 'en',
    this.xp = 0,
    this.level = 'Seeker',
    this.battleWins = 0,
    this.battleLosses = 0,
    this.winStreak = 0,
    this.bestWinStreak = 0,
    this.versesMemorized = 0,
    this.quizzesCompleted = 0,
    this.totalCorrectAnswers = 0,
    this.totalAnswers = 0,
    this.churchId,
    this.isPastor = false,
    this.badges = const [],
    this.stats,
  });

  int get accuracy =>
      totalAnswers > 0 ? ((totalCorrectAnswers / totalAnswers) * 100).round() : 0;

  double get levelProgress {
    if (level == 'Seeker') return xp / 500;
    if (level == 'Disciple') return (xp - 500) / 1500;
    if (level == 'Elder') return (xp - 2000) / 3000;
    if (level == 'Apostle') return (xp - 5000) / 5000;
    return 1.0;
  }

  String get nextLevel {
    if (level == 'Seeker') return 'Disciple';
    if (level == 'Disciple') return 'Elder';
    if (level == 'Elder') return 'Apostle';
    if (level == 'Apostle') return 'Living Word';
    return 'Living Word';
  }

  int get xpToNextLevel {
    if (level == 'Seeker') return 500 - xp;
    if (level == 'Disciple') return 2000 - xp;
    if (level == 'Elder') return 5000 - xp;
    return 0;
  }

  factory ArenaUser.fromJson(Map<String, dynamic> json) {
    return ArenaUser(
      id: json['id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      displayName: json['displayName'] ?? 'Anonymous',
      email: json['email'],
      photoUrl: json['photoUrl'],
      language: json['language'] ?? 'en',
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 'Seeker',
      battleWins: json['battleWins'] ?? 0,
      battleLosses: json['battleLosses'] ?? 0,
      winStreak: json['winStreak'] ?? 0,
      bestWinStreak: json['bestWinStreak'] ?? 0,
      versesMemorized: json['versesMemorized'] ?? 0,
      quizzesCompleted: json['quizzesCompleted'] ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] ?? 0,
      totalAnswers: json['totalAnswers'] ?? 0,
      churchId: json['churchId'],
      isPastor: json['isPastor'] ?? false,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((b) => ArenaBadge.fromJson(b))
              .toList() ??
          [],
      stats: json['stats'] != null ? ArenaStats.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firebaseUid': firebaseUid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'language': language,
        'xp': xp,
        'level': level,
        'battleWins': battleWins,
        'battleLosses': battleLosses,
        'winStreak': winStreak,
        'versesMemorized': versesMemorized,
      };
}

class ArenaBadge {
  final String type;
  final String name;
  final DateTime date;

  ArenaBadge({required this.type, required this.name, required this.date});

  factory ArenaBadge.fromJson(Map<String, dynamic> json) => ArenaBadge(
        type: json['type'] ?? '',
        name: json['name'] ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      );
}

class ArenaStats {
  final int totalBattles;
  final int versesInProgress;
  final int versesFullyMemorized;
  final int accuracy;

  ArenaStats({
    this.totalBattles = 0,
    this.versesInProgress = 0,
    this.versesFullyMemorized = 0,
    this.accuracy = 0,
  });

  factory ArenaStats.fromJson(Map<String, dynamic> json) => ArenaStats(
        totalBattles: json['totalBattles'] ?? 0,
        versesInProgress: json['versesInProgress'] ?? 0,
        versesFullyMemorized: json['versesFullyMemorized'] ?? 0,
        accuracy: json['accuracy'] ?? 0,
      );
}

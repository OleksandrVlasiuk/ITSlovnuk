class UserStatistics {
  final int todayViews;
  final int totalViews;
  final int averagePerDay;
  final int streak;
  final int longestStreak;
  final String lastActiveDate;
  final String firstActiveDate;
  final String lastSessionDate;
  final int totalCardsViewed;
  final double averageCardsPerSession;
  final int maxCardsPerSession;
  final int totalSessions;
  final Map<String, dynamic> activeDays;
  final Map<String, dynamic> deckUsage;

  UserStatistics({
    required this.todayViews,
    required this.totalViews,
    required this.averagePerDay,
    required this.streak,
    required this.longestStreak,
    required this.lastActiveDate,
    required this.firstActiveDate,
    required this.lastSessionDate,
    required this.totalCardsViewed,
    required this.averageCardsPerSession,
    required this.maxCardsPerSession,
    required this.totalSessions,
    required this.activeDays,
    required this.deckUsage,
  });

  factory UserStatistics.fromMap(Map<String, dynamic> map) {
    return UserStatistics(
      todayViews: map['todayViews'] ?? 0,
      totalViews: map['totalViews'] ?? 0,
      averagePerDay: map['averagePerDay'] ?? 0,
      streak: map['streak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActiveDate: map['lastActiveDate'] ?? '',
      firstActiveDate: map['firstActiveDate'] ?? '',
      lastSessionDate: map['lastSessionDate'] ?? '',
      totalCardsViewed: map['totalCardsViewed'] ?? 0,
      averageCardsPerSession: (map['averageCardsPerSession'] ?? 0).toDouble(),
      maxCardsPerSession: map['maxCardsPerSession'] ?? 0,
      totalSessions: map['totalSessions'] ?? 0,
      activeDays: Map<String, dynamic>.from(map['activeDays'] ?? {}),
      deckUsage: Map<String, dynamic>.from(map['deckUsage'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'todayViews': todayViews,
      'totalViews': totalViews,
      'averagePerDay': averagePerDay,
      'streak': streak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate,
      'firstActiveDate': firstActiveDate,
      'lastSessionDate': lastSessionDate,
      'totalCardsViewed': totalCardsViewed,
      'averageCardsPerSession': averageCardsPerSession,
      'maxCardsPerSession': maxCardsPerSession,
      'totalSessions': totalSessions,
      'activeDays': activeDays,
      'deckUsage': deckUsage,
    };
  }
}

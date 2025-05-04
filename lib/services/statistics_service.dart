import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_statistics.dart';

class StatisticsService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> updateStatistics({
    required int viewedCount,
    required String deckId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateTime.now();

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('statistics')
        .doc('general');

    final docSnapshot = await docRef.get();
    Map<String, dynamic> data = docSnapshot.data() ?? {};

    int todayViews = (data['todayViews'] ?? 0) + viewedCount;
    int totalViews = (data['totalViews'] ?? 0) + viewedCount;
    int totalCardsViewed = (data['totalCardsViewed'] ?? 0) + viewedCount;
    int totalSessions = (data['totalSessions'] ?? 0) + 1;
    double averageCardsPerSession = totalCardsViewed / totalSessions;
    int maxCardsPerSession = data['maxCardsPerSession'] ?? 0;
    if (viewedCount > maxCardsPerSession) {
      maxCardsPerSession = viewedCount;
    }

    Map<String, dynamic> activeDays = Map<String, dynamic>.from(data['activeDays'] ?? {});
    activeDays[today] = (activeDays[today] ?? 0) + viewedCount;
    int averagePerDay = (totalViews / activeDays.length).round();

    String? lastActiveDate = data['lastActiveDate'];
    int streak = data['streak'] ?? 0;
    int longestStreak = data['longestStreak'] ?? streak;

    if (lastActiveDate != null) {
      final last = DateTime.tryParse(lastActiveDate);
      if (last != null) {
        final diff = now.difference(last).inDays;
        if (diff == 1) {
          streak += 1;
        } else if (diff > 1) {
          streak = 1;
        }
        if (streak > longestStreak) longestStreak = streak;
      }
    } else {
      streak = 1;
      longestStreak = 1;
    }

    Map<String, dynamic> deckUsage = Map<String, dynamic>.from(data['deckUsage'] ?? {});
    deckUsage[deckId] = (deckUsage[deckId] ?? 0) + 1;

    final firstActiveDate = data['firstActiveDate'] ?? today;
    final lastSessionDate = today;

    await docRef.set({
      'todayViews': todayViews,
      'totalViews': totalViews,
      'totalCardsViewed': totalCardsViewed,
      'totalSessions': totalSessions,
      'averageCardsPerSession': averageCardsPerSession,
      'maxCardsPerSession': maxCardsPerSession,
      'averagePerDay': averagePerDay,
      'activeDays': activeDays,
      'deckUsage': deckUsage,
      'streak': streak,
      'longestStreak': longestStreak,
      'lastActiveDate': today,
      'firstActiveDate': firstActiveDate,
      'lastSessionDate': lastSessionDate,
    }, SetOptions(merge: true));
  }

  Future<UserStatistics> fetchStatistics() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Користувач не авторизований');
    }

    final docSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('statistics')
        .doc('general')
        .get();

    final data = docSnapshot.data();

    if (data == null) {
      return UserStatistics(
        todayViews: 0,
        totalViews: 0,
        averagePerDay: 0,
        streak: 0,
        longestStreak: 0,
        lastActiveDate: '',
        firstActiveDate: '',
        lastSessionDate: '',
        totalCardsViewed: 0,
        averageCardsPerSession: 0,
        maxCardsPerSession: 0,
        totalSessions: 0,
        activeDays: {},
        deckUsage: {},
      );
    }

    return UserStatistics.fromMap(data);
  }
}

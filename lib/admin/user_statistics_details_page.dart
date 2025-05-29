import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_statistics.dart';

class UserStatisticsDetailsPage extends StatelessWidget {
  final String userId;
  const UserStatisticsDetailsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        title: const Text('Статистика користувача', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2B2B2B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
          final user = userSnap.data!;
          final email = user['email'] ?? '—';
          final nickname = user['nickname'] ?? '';
          final role = user['role'] ?? 'user';
          final createdAt = (user['createdAt'] as Timestamp?)?.toDate();

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('statistics')
                .doc('general')
                .get(),
            builder: (context, statsSnap) {
              if (!statsSnap.hasData) return const Center(child: CircularProgressIndicator());
              final data = statsSnap.data!.data() as Map<String, dynamic>? ?? {};
              final stats = UserStatistics.fromMap(data);

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('decks')
                    .where('userId', isEqualTo: userId)
                    .get(),
                builder: (context, decksSnap) {
                  final decks = decksSnap.data?.docs ?? [];
                  final publicDecks = decks.where((d) => d['isPublic'] == true && d['isArchived'] != true).length;
                  final privateDecks = decks.where((d) => d['isPublic'] != true && d['isArchived'] != true).length;

                  // Додаткові розрахунки
                  final totalDays = stats.activeDays.keys.length;
                  final sessionSpan = (stats.firstActiveDate.isNotEmpty && stats.lastSessionDate.isNotEmpty)
                      ? DateTime.parse(stats.lastSessionDate)
                      .difference(DateTime.parse(stats.firstActiveDate))
                      .inDays
                      : 0;
                  final averageInterval = stats.totalSessions > 1
                      ? (sessionSpan / (stats.totalSessions - 1)).toStringAsFixed(1)
                      : '—';

                  String mostUsedDeck = '-';
                  int mostUsedCount = 0;
                  stats.deckUsage.forEach((deckId, count) {
                    if (count > mostUsedCount) {
                      mostUsedDeck = deckId;
                      mostUsedCount = count;
                    }
                  });

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // 📌 Інформація про користувача
                        const Text('Інформація про користувача',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _info('Email', email),
                        if (nickname.toString().isNotEmpty) _info('Нікнейм', nickname),
                        _info('Роль', role),
                        if (createdAt != null)
                          _info('Дата реєстрації', DateFormat('dd.MM.yyyy').format(createdAt)),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white38),

                        // 📊 Загальна статистика
                        const Text('Загальна статистика',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _info('Переглянуто сьогодні', stats.todayViews),
                        _info('Загальна кількість переглядів', stats.totalViews),
                        _info('Загальна кількість карток', stats.totalCardsViewed),
                        _info('Кількість сесій', stats.totalSessions),
                        _info('Максимум карток за одну сесію', stats.maxCardsPerSession),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white38),

                        // 📈 Усереднені показники
                        const Text('Усереднені показники',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _info('Середня кількість карток за сесію', stats.averageCardsPerSession.toStringAsFixed(1)),
                        _info('Середня кількість переглядів на день', stats.averagePerDay),
                        _info('Середній інтервал між сесіями (днів)', averageInterval),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white38),

                        // 🔁 Активність
                        const Text('Активність',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _info('Streak (поточний)', stats.streak),
                        _info('Найдовша серія днів', stats.longestStreak),
                        _info('Кількість унікальних активних днів', totalDays),
                        _info('Перша активність', stats.firstActiveDate.isNotEmpty
                            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(stats.firstActiveDate))
                            : '-'),
                        _info('Остання активність', stats.lastSessionDate.isNotEmpty
                            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(stats.lastSessionDate))
                            : '-'),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white38),

                        // 📦 Колоди
                        const Text('Колоди',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _info('Публічні колоди', publicDecks),
                        _info('Приватні колоди', privateDecks),
                        const SizedBox(height: 8),

                        mostUsedDeck != '-'
                            ? FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('decks').doc(mostUsedDeck).get(),
                          builder: (context, deckSnap) {
                            final deckData = deckSnap.data?.data() as Map<String, dynamic>?;
                            final title = deckData?['title'] ?? '-';
                            return _info('Улюблена колода', title);
                          },
                        )
                            : _info('Улюблена колода', '-'),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text('$label:', style: const TextStyle(color: Colors.white70))),
          Text('$value', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

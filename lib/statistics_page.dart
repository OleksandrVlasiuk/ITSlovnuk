//statistics_page.dart
import 'package:flutter/material.dart';
import 'package:it_english_app_clean/services/statistics_service.dart';
import 'package:it_english_app_clean/models/user_statistics.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        automaticallyImplyLeading: false,
        title: const Text(
          'ITСловник',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<UserStatistics>(
        future: StatisticsService().fetchStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data;

          if (stats == null) {
            return const Center(
              child: Text(
                'Даних поки що немає',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          final firstDate = stats.firstActiveDate.isNotEmpty
              ? DateFormat('dd.MM.yyyy').format(DateTime.parse(stats.firstActiveDate))
              : '-';
          final lastDate = stats.lastSessionDate.isNotEmpty
              ? DateFormat('dd.MM.yyyy').format(DateTime.parse(stats.lastSessionDate))
              : '-';
          final totalDays = stats.activeDays.keys.length;

          final sessionSpan = (stats.firstActiveDate.isNotEmpty && stats.lastSessionDate.isNotEmpty)
              ? DateTime.parse(stats.lastSessionDate).difference(DateTime.parse(stats.firstActiveDate)).inDays
              : 0;
          final averageInterval = stats.totalSessions > 1
              ? (sessionSpan / (stats.totalSessions - 1)).toStringAsFixed(1)
              : '—';

          final missedDays = stats.lastSessionDate.isNotEmpty
              ? DateTime.now().difference(DateTime.parse(stats.lastSessionDate)).inDays
              : 0;

          String mostUsedDeck = '-';
          int mostUsedCount = 0;
          stats.deckUsage.forEach((deckId, count) {
            if (count > mostUsedCount) {
              mostUsedDeck = deckId;
              mostUsedCount = count;
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Статистика',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white38, thickness: 0.5),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _statItem('Переглянуто карток сьогодні:', stats.todayViews),
                      _statItem('Середня кількість переглядів на день:', stats.averagePerDay),
                      _statItem('Загальна кількість переглядів:', stats.totalViews),
                      _statItem('Днів підряд з активністю (streak):', stats.streak),
                      _statItem('Усього переглянуто карток:', stats.totalCardsViewed),
                      _statItem('Середня кількість карток за сесію:', stats.averageCardsPerSession.toStringAsFixed(1)),
                      _statItem('Найбільше карток за сесію:', stats.maxCardsPerSession),
                      _statItem('Найдовша серія днів:', stats.longestStreak),
                      _statItem('Кількість унікальних активних днів:', totalDays),
                      _statItem('Середній інтервал між сесіями (днів):', averageInterval),
                      _statItem('Пропущено днів з останньої сесії:', missedDays),
                      _statItem('Перша активність:', firstDate),
                      _statItem('Остання активність:', lastDate),
                      _deckTitleItem('Улюблена колода (deckId):', mostUsedDeck),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statItem(String label, dynamic value) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _deckTitleItem(String label, String deckId) {
    return SizedBox(
      width: 140,
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('decks').doc(deckId).get(),
        builder: (context, snapshot) {
          final deckTitle = snapshot.data?.data()?['title'] ?? '-';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                deckTitle,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }
}
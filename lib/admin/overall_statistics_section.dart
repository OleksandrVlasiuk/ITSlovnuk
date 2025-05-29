import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverallStatisticsSection extends StatefulWidget {
  const OverallStatisticsSection({super.key});

  @override
  State<OverallStatisticsSection> createState() => _OverallStatisticsSectionState();
}

class _OverallStatisticsSectionState extends State<OverallStatisticsSection> {
  bool isLoading = true;
  int userCount = 0;
  int totalViews = 0;
  int totalCards = 0;
  int totalSessions = 0;
  int sumStreak = 0;
  int sumLongestStreak = 0;
  double avgCardsPerSession = 0;
  double avgSessionsPerUser = 0;
  int totalActiveDays = 0;
  Map<String, int> deckUsageCount = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    userCount = users.docs.length;

    for (final user in users.docs) {
      final statsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('statistics')
          .doc('general')
          .get();

      final stats = statsSnap.data();
      if (stats == null) continue;

      totalViews += _safeInt(stats['totalViews']);
      totalCards += _safeInt(stats['totalCardsViewed']);
      totalSessions += _safeInt(stats['totalSessions']);
      sumStreak += _safeInt(stats['streak']);
      sumLongestStreak += _safeInt(stats['longestStreak']);
      avgCardsPerSession += _safeDouble(stats['averageCardsPerSession']);
      totalActiveDays += (stats['activeDays'] as Map?)?.length ?? 0;

      final deckMap = (stats['deckUsage'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final entry in deckMap.entries) {
        final deckId = entry.key;
        final count = _safeInt(entry.value);
        deckUsageCount.update(deckId, (old) => old + count, ifAbsent: () => count);
      }
    }

    // Середні значення
    avgCardsPerSession = userCount > 0 ? avgCardsPerSession / userCount : 0;
    avgSessionsPerUser = userCount > 0 ? totalSessions / userCount : 0;

    setState(() => isLoading = false);
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _safeDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Найпопулярніша колода
    final topDeckId = deckUsageCount.entries.fold<MapEntry<String, int>>(
      const MapEntry('', 0),
          (prev, e) => e.value > prev.value ? e : prev,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Загальні показники',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _info('Кількість користувачів', userCount),
          _info('Загальна кількість сесій', totalSessions),
          _info('Загальна кількість карток', totalCards),
          _info('Загальна кількість переглядів', totalViews),
          const Divider(color: Colors.white38, height: 32),

          const Text('Усереднені значення',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _info('Середній streak', (userCount > 0 ? (sumStreak / userCount).toStringAsFixed(1) : '—')),
          _info('Середній longest streak', (userCount > 0 ? (sumLongestStreak / userCount).toStringAsFixed(1) : '—')),
          _info('Середня кількість сесій на користувача', avgSessionsPerUser.toStringAsFixed(1)),
          _info('Середня кількість карток за сесію', avgCardsPerSession.toStringAsFixed(1)),
          _info('Середня кількість активних днів', (userCount > 0 ? (totalActiveDays / userCount).toStringAsFixed(1) : '—')),

          const Divider(color: Colors.white38, height: 32),
          const Text('Популярні колоди',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          topDeckId.key.isNotEmpty
              ? FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('decks').doc(topDeckId.key).get(),
            builder: (context, snapshot) {
              final title = snapshot.data?.data() != null
                  ? (snapshot.data!.data() as Map<String, dynamic>)['title'] ?? 'Без назви'
                  : 'Без назви';
              return _info('Найпопулярніша колода', '$title (${topDeckId.value} разів)');
            },
          )
              : _info('Найпопулярніша колода', '—'),
        ],
      ),
    );
  }

  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text('$label:', style: const TextStyle(color: Colors.white70))),
          Text('$value', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

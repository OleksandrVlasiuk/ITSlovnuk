import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'user_statistics_filters.dart';
import 'user_statistics_details_page.dart';

class UserStatisticsSection extends StatefulWidget {
  const UserStatisticsSection({super.key});

  @override
  State<UserStatisticsSection> createState() => _UserStatisticsSectionState();
}

class _UserStatisticsSectionState extends State<UserStatisticsSection> {
  Map<String, dynamic> _filters = {};
  bool _filtersExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: UserStatisticsFilters(
              onChanged: (filters) => setState(() => _filters = filters),
            ),
            crossFadeState: _filtersExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = userSnapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final nickname = (data['nickname'] ?? '').toString().toLowerCase();
                  final role = (data['role'] ?? '').toString().toLowerCase();

                  final emailQuery = _filters['email'] ?? '';
                  final nicknameQuery = _filters['nickname'] ?? '';
                  final roleFilter = _filters['role'];

                  final matchesEmail = email.contains(emailQuery);
                  final matchesNickname = nicknameQuery.isEmpty || nickname.contains(nicknameQuery);
                  final matchesRole = roleFilter == null || role == roleFilter;

                  return matchesEmail && matchesNickname && matchesRole;
                }).toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text('Користувачів не знайдено', style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;
                    final userId = user.id;
                    final email = data['email'] ?? '—';
                    final nickname = data['nickname'] ?? '';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('statistics')
                          .doc('general')
                          .get(),
                      builder: (context, statsSnapshot) {
                        final stats = statsSnapshot.data?.data() as Map<String, dynamic>?;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserStatisticsDetailsPage(userId: userId),
                              ),
                            );
                          },
                          child: _userCard(email, nickname, stats, userId),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Фільтри',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
          icon: Icon(
            _filtersExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white,
          ),
          label: Text(
            _filtersExpanded ? 'Згорнути' : 'Розгорнути',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }


  Widget _userCard(String email, String nickname, Map<String, dynamic>? stats, String userId) {
    final lastDateRaw = stats?['lastSessionDate'];
    final formattedDate = (lastDateRaw != null && lastDateRaw.toString().isNotEmpty)
        ? DateFormat('dd.MM.yyyy').format(DateTime.parse(lastDateRaw))
        : '-';

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('decks')
          .where('userId', isEqualTo: userId)
          .get(),
      builder: (context, deckSnapshot) {
        final deckCount = deckSnapshot.data?.docs.length ?? 0;

        return Card(
          color: const Color(0xFF2B2B2B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserStatisticsDetailsPage(userId: userId),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  if (nickname.isNotEmpty)
                    Text(nickname, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      _statBlock('Остання активність', formattedDate),
                      _statBlock('Кількість колод', deckCount),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _statBlock(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 2),
        Text('$value', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

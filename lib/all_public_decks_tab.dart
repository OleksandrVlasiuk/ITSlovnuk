//all_public_decks_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:it_english_app_clean/plan_filters.dart';
import 'package:it_english_app_clean/public_deck_preview_page.dart';
import '../services/deck_service.dart';


class AllPublicDecksTab extends StatefulWidget {
  const AllPublicDecksTab({super.key});

  @override
  State<AllPublicDecksTab> createState() => _AllPublicDecksTabState();
}

class _AllPublicDecksTabState extends State<AllPublicDecksTab> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  List<String> userCopiedDeckIds = [];

  String titleSearch = '';
  String nicknameSearch = '';
  String sort = 'published_desc';
  DateTime? startDate;
  DateTime? endDate;
  int? minCards;
  int? maxCards;

  @override
  void initState() {
    super.initState();
    _loadUserDecks();
  }

  Future<void> _loadUserDecks() async {
    final decks = await DeckService().getUserDecks(userId);
    setState(() {
      userCopiedDeckIds = decks.map((d) => d.copiedFrom).whereType<String>().toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: PlanFilters(
            titleSearch: titleSearch,
            nicknameSearch: nicknameSearch,
            sort: sort,
            isRecommendedTab: false,
            onChanged: ({
              String? title,
              String? nickname,
              String? sort,
              DateTime? startDate,
              DateTime? endDate,
              int? minCards,
              int? maxCards,
            }) {
              setState(() {
                titleSearch = title ?? titleSearch;
                nicknameSearch = nickname ?? nicknameSearch;
                this.sort = sort ?? this.sort;
                this.startDate = startDate;
                this.endDate = endDate;
                this.minCards = minCards;
                this.maxCards = maxCards;
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('published_decks')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

              docs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = (data['title'] ?? '').toString().toLowerCase();
                final cardCount = data['sessionCardCount'] ?? 0;
                final publishedAt = (data['publishedAt'] as Timestamp).toDate();

                if (!title.contains(titleSearch.toLowerCase())) return false;
                if (minCards != null && cardCount < minCards!) return false;
                if (maxCards != null && cardCount > maxCards!) return false;
                if (startDate != null && publishedAt.isBefore(startDate!)) return false;
                if (endDate != null && publishedAt.isAfter(endDate!)) return false;

                return true;
              }).toList();

              docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                switch (sort) {
                  case 'added_desc':
                    return ((dataB['addedCount'] ?? 0) as int)
                        .compareTo((dataA['addedCount'] ?? 0) as int);
                  case 'title_asc':
                    return (dataA['title'] ?? '').toString().compareTo((dataB['title'] ?? '').toString());
                  case 'published_desc':
                  default:
                    return ((dataB['publishedAt'] as Timestamp).toDate())
                        .compareTo((dataA['publishedAt'] as Timestamp).toDate());
                }
              });

              if (docs.isEmpty) {
                return const Center(
                  child: Text('Нічого не знайдено', style: TextStyle(color: Colors.white70)),
                );
              }

              return FutureBuilder<Map<String, Map<String, String>>>(
                future: _fetchUserInfos(docs), // оновлений метод, що повертає role + nickname
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userInfos = userSnapshot.data!;
                  final nicknameQuery = nicknameSearch.trim().toLowerCase();

                  final regularDecks = <QueryDocumentSnapshot>[];
                  final adminDecks = <QueryDocumentSnapshot>[];

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = data['userId'];
                    final info = userInfos[userId] ?? {'role': 'user', 'nickname': ''};
                    final isAdmin = info['role'] == 'admin';
                    final nickname = info['nickname'] ?? '';

                    if (isAdmin) {
                      if (nicknameQuery.isEmpty || 'itсловник'.contains(nicknameQuery)) {
                        adminDecks.add(doc);
                      }
                    } else {
                      if (nicknameQuery.isEmpty || nickname.contains(nicknameQuery)) {
                        regularDecks.add(doc);
                      }
                    }
                  }

                  final filteredDocs = [...regularDecks, ...adminDecks];

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final publishedDeckId = doc.id;

                      final title = data['title'] ?? 'Без назви';
                      final cardCount = data['cardCount'] ?? 0;
                      final addedCount = data['addedCount'] ?? 0;
                      final publishedAt = (data['publishedAt'] as Timestamp).toDate();
                      final authorId = data['userId'];
                      final info = userInfos[authorId] ?? {'role': 'user', 'nickname': 'невідомо'};
                      final isAdmin = info['role'] == 'admin';
                      final authorDisplayName = isAdmin ? 'ITСловник' : info['nickname'] ?? 'невідомо';
                      final alreadyAdded = userCopiedDeckIds.contains(publishedDeckId);

                      return Card(
                        color: const Color(0xFF333333),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PublicDeckPreviewPage(deckId: publishedDeckId),
                              ),
                            );
                          },
                          title: Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Автор: $authorDisplayName\nКарток: $cardCount  |  Додали: $addedCount\nОпубліковано: ${_formatDate(publishedAt)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check, color: Colors.green)
                              : IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                            onPressed: () async {
                              await DeckService().addPublicDeckToUser(publishedDeckId, userId);
                              await _loadUserDecks();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Колода додана до ваших')),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );

            },
          ),
        ),
      ],
    );
  }

  Future<Map<String, Map<String, String>>> _fetchUserInfos(List<QueryDocumentSnapshot> docs) async {
    final userIds = docs.map((doc) => (doc.data() as Map<String, dynamic>)['userId'] as String).toSet();
    final snapshots = await Future.wait(
      userIds.map((id) => FirebaseFirestore.instance.collection('users').doc(id).get()),
    );

    final result = <String, Map<String, String>>{};
    for (final snap in snapshots) {
      if (!snap.exists || snap.data() == null) continue;
      final data = snap.data()!;
      final role = (data['role'] ?? 'user').toString();
      final nickname = (data['nickname'] ?? '').toString().trim().toLowerCase();
      result[snap.id] = {'role': role, 'nickname': nickname};
    }

    return result;
  }



  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
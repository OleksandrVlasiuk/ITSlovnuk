//deck_managment_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../deck_change_page.dart';
import 'card_managment_section.dart';
import '../services/deck_service.dart';
import 'package:intl/intl.dart';

import 'deck_moderation_filters.dart';

class DeckManagmentSection extends StatelessWidget {
  const DeckManagmentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Очікують'))),
              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Відхилені'))),
              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Усі публічні'))),
              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Приховані'))),
            ],
          ),
          const SizedBox(height: 5),
          const Expanded(
            child: TabBarView(
              children: [
                DeckModerationList(filter: 'pending'),
                DeckModerationList(filter: 'rejected'),
                DeckModerationList(filter: 'allPublic'),
                DeckModerationList(filter: 'hidden'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeckModerationList extends StatefulWidget {
  final String filter;

  const DeckModerationList({super.key, required this.filter});

  @override
  State<DeckModerationList> createState() => _DeckModerationListState();
}


class _DeckModerationListState extends State<DeckModerationList> {
  Map<String, dynamic> _filters = {};

  Stream<QuerySnapshot> _deckStream() {
    final firestore = FirebaseFirestore.instance;
    if (widget.filter == 'allPublic') {
      return firestore
          .collection('published_decks')
          .where('isActive', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .snapshots();
    }
    if (widget.filter == 'hidden') {
      return firestore
          .collection('published_decks')
          .where('isActive', isEqualTo: false)
          .orderBy('publishedAt', descending: true)
          .snapshots();
    }
    final decks = firestore.collection('decks');
    switch (widget.filter) {
      case 'pending':
        return decks.where('moderationStatus', isEqualTo: 'pending')
            .snapshots();
      case 'rejected':
        return decks.where('moderationStatus', isEqualTo: 'rejected')
            .snapshots();
      default:
        return const Stream.empty();
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  String _submissionLabel(Map<String, dynamic> data) {
    final isPublic = data['isPublic'] ?? false;
    final publicationMode = data['publicationMode'] ?? 'temporary';
    if (!isPublic) return 'Первинна публікація';
    if (publicationMode == 'permanent') return 'Запит на вічну публікацію';
    return 'Оновлення публікації';
  }

  Future<bool> _confirmAction(BuildContext context, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Підтвердження"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Скасувати"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Так"),
              ),
            ],
          ),
    ) ??
        false;
  }

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> decks) {
    final titleQuery = _filters['title']?.toString().toLowerCase() ?? '';
    final emailQuery = _filters['email']?.toString().toLowerCase() ?? '';
    final third = _filters['third'];
    final sortDate = _filters['sortDate'];
    final DateTime? startDate = _filters['startDate'];
    final DateTime? endDate = _filters['endDate'];

    List<QueryDocumentSnapshot> filtered = decks.where((deck) {
      final data = deck.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final type = _submissionLabel(data);

      final matchesTitle = titleQuery.isEmpty || title.contains(titleQuery);

      bool matchesThird = true;
      if (widget.filter == 'pending') {
        matchesThird = third == null || third == type;
      } else if (widget.filter == 'allPublic' || widget.filter == 'hidden') {
        final pubMode = data['publicationMode'] ?? 'temporary';
        matchesThird = third == null || third == pubMode;
      }

      // Email фільтрується в FutureBuilder, тому завжди true
      return matchesTitle && matchesThird;
    }).toList();

    // 🔽 Сортування та фільтрація для rejected
    if (widget.filter == 'rejected') {
      if (startDate != null || endDate != null) {
        filtered = filtered.where((deck) {
          final moderated = (deck.data() as Map<String, dynamic>)['moderatedAt'];
          if (moderated == null) return false;
          final time = (moderated as Timestamp).toDate();
          final afterStart = startDate == null || time.isAfter(startDate.subtract(const Duration(days: 1)));
          final beforeEnd = endDate == null || time.isBefore(endDate.add(const Duration(days: 1)));
          return afterStart && beforeEnd;
        }).toList();
      }

      if (sortDate != null) {
        filtered.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['moderatedAt']?.toDate();
          final bTime = (b.data() as Map<String, dynamic>)['moderatedAt']?.toDate();
          if (aTime == null || bTime == null) return 0;
          return sortDate == 'asc' ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
        });
      }
    }

    // 🔽 Сортування для публічних і прихованих
    if (widget.filter == 'allPublic' || widget.filter == 'hidden') {
      if (startDate != null || endDate != null) {
        filtered = filtered.where((deck) {
          final published = (deck.data() as Map<String, dynamic>)['publishedAt'];
          if (published == null) return false;
          final time = (published as Timestamp).toDate();
          final afterStart = startDate == null || time.isAfter(startDate.subtract(const Duration(days: 1)));
          final beforeEnd = endDate == null || time.isBefore(endDate.add(const Duration(days: 1)));
          return afterStart && beforeEnd;
        }).toList();
      }

      if (sortDate != null) {
        filtered.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['publishedAt']?.toDate();
          final bTime = (b.data() as Map<String, dynamic>)['publishedAt']?.toDate();
          if (aTime == null || bTime == null) return 0;
          return sortDate == 'asc' ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
        });
      }
    }


    return filtered;
  }




  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
      DeckModerationFilters(
      filter: widget.filter,
      onChanged: (filters) => setState(() => _filters = filters),
    ),
      Expanded(
        child:
        StreamBuilder<QuerySnapshot>(
      stream: _deckStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
                'Немає колод.', style: TextStyle(color: Colors.white70)),
          );
        }

        final decks = _applyFilters(snapshot.data!.docs);

        if (decks.isEmpty) {
          return const Center(
            child: Text(
              'Колод не знайдено',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            final data = deck.data() as Map<String, dynamic>;

            final title = data['title'] ?? 'Без назви';
            final userId = data['userId'] ?? '';
            final moderatedAt = data.containsKey('moderatedAt') ? _formatDate(
                data['moderatedAt']) : '';
            final publishedAt = data.containsKey('publishedAt') ? _formatDate(
                data['publishedAt']) : '';
            final submissionType = _submissionLabel(data);

            final isPending = widget.filter == 'pending';
            final isRejected = widget.filter == 'rejected';
            final isPublicDeck = widget.filter == 'allPublic' || widget.filter == 'hidden';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnapshot) {
                String userEmail = 'Невідомо';
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  userEmail = (userData['email'] ?? '').toString().toLowerCase();

                  final emailFilter = _filters['email']?.toString().toLowerCase() ?? '';
                  if (emailFilter.isNotEmpty && !userEmail.contains(emailFilter)) {
                    return const SizedBox.shrink(); // ❌ не відображати цю колоду
                  }
                }

                final isDraft = widget.filter == 'pending' || widget.filter == 'rejected';
                final realDeckId = isDraft ? deck.id : (data['deckId'] ?? deck.id);

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    final isDraft = widget.filter == 'pending' || widget.filter == 'rejected';
                    final collection = isDraft ? 'decks' : 'published_decks';
                    final realDeckId = deck.id;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CardManagmentSection(
                          deckId: realDeckId,
                          collection: collection,
                        ),
                      ),
                    );
                  },

                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    color: const Color(0xFF333333),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ліва частина — текст
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isPending && submissionType == 'Оновлення публікації')
                                      FutureBuilder<Map<String, dynamic>>(
                                        future: DeckService().getDeckChanges(deck.id),
                                        builder: (context, snapshot) {
                                          final hasChanges = snapshot.data?['hasChanges'] == true;
                                          if (!snapshot.hasData || !hasChanges) return const SizedBox.shrink();
                                          return TextButton(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => DeckChangesPage(changes: snapshot.data!),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              '(переглянути зміни)',
                                              style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                Text('Автор: $userEmail', style: const TextStyle(color: Colors.grey)),
                                if (isPending || isRejected) ...[
                                  Text('Id: ${deck.id}', style: const TextStyle(color: Colors.grey)),
                                  Text('Тип подачі: $submissionType', style: const TextStyle(color: Colors.orangeAccent)),
                                  if (moderatedAt.isNotEmpty)
                                    Text('Перевірено: $moderatedAt', style: const TextStyle(color: Colors.grey)),
                                  if (publishedAt.isNotEmpty)
                                    Text('Опубліковано: $publishedAt', style: const TextStyle(color: Colors.grey)),
                                ],
                                if (isPublicDeck) ...[
                                  Text('Id: ${deck.id}', style: const TextStyle(color: Colors.grey)),
                                  Text(
                                    'Тип: ${data['publicationMode'] == 'permanent' ? 'Назавжди' : 'Тимчасова'}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'Опубліковано: ${_formatDate(data['publishedAt'])}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Права частина — кнопки дій
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPending) ...[
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  tooltip: 'Схвалити',
                                  onPressed: () async {
                                    final confirmed = await _confirmAction(context, "Схвалити колоду?");
                                    if (confirmed) await DeckService().approveDeck(deck.id);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  tooltip: 'Відхилити',
                                  onPressed: () async {
                                    final controller = TextEditingController();
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Причина відхилення"),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            hintText: "Наприклад: замало карток, неприйнятні слова",
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text("Скасувати"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text("Відхилити"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      final reason = controller.text.trim();
                                      await DeckService().rejectDeck(deck.id, reason);
                                    }
                                  },
                                ),
                              ],
                              if (isRejected)
                                IconButton(
                                  icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
                                  tooltip: 'Повернути в очікування',
                                  onPressed: () async {
                                    final confirmed = await _confirmAction(context, "Повернути колоду в очікування?");
                                    if (confirmed) {
                                      await FirebaseFirestore.instance.collection('decks').doc(deck.id).update({
                                        'moderationStatus': 'pending',
                                        'moderatedAt': null,
                                        'moderationNote': null,
                                      });
                                    }
                                  },
                                ),
                              if (widget.filter == 'allPublic') ...[
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Видалити з публічних',
                                  onPressed: () async {
                                    final confirmed = await _confirmAction(context, "Видалити колоду з публічних?");
                                    if (confirmed) {
                                      final firestore = FirebaseFirestore.instance;
                                      final deckId = deck['deckId']; // <- справжній ID приватної колоди
                                      // 1. Видаляємо публічну версію
                                      await firestore.collection('published_decks').doc(deck.id).delete();
                                      // 2. Оновлюємо відповідну чернетку
                                      await firestore.collection('decks').doc(deckId).update({
                                        'isPublic': false,
                                        'publishedAt': null,
                                        'moderationStatus': null,
                                        'moderationNote': null,
                                        'moderatedAt': null,
                                        'publicationMode': 'temporary',
                                      });

                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility_off, color: Colors.orangeAccent),
                                  tooltip: 'Приховати з публікації',
                                  onPressed: () async {
                                    final confirmed = await _confirmAction(context, "Приховати колоду з публікації?");
                                    if (confirmed) {
                                      await FirebaseFirestore.instance
                                          .collection('published_decks')
                                          .doc(deck.id)
                                          .update({'isActive': false});
                                    }
                                  },
                                ),
                              ],
                              if (widget.filter == 'hidden')
                                IconButton(
                                  icon: const Icon(Icons.undo, color: Colors.greenAccent),
                                  tooltip: 'Повернути в публікацію',
                                  onPressed: () async {
                                    final confirmed = await _confirmAction(context, "Повернути колоду в публікацію?");
                                    if (confirmed) {
                                      await FirebaseFirestore.instance
                                          .collection('published_decks')
                                          .doc(deck.id)
                                          .update({'isActive': true});
                                    }
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
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
    ]
    );
  }
}

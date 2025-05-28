//deck_managment_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../deck_change_page.dart';
import 'card_managment_section.dart';
import '../services/deck_service.dart';
import 'package:intl/intl.dart';

import 'deck_moderation_filters.dart';

bool isSameOrAfter(DateTime a, DateTime b) =>
    a.year > b.year ||
        (a.year == b.year && a.month > b.month) ||
        (a.year == b.year && a.month == b.month && a.day >= b.day);

bool isSameOrBefore(DateTime a, DateTime b) =>
    a.year < b.year ||
        (a.year == b.year && a.month < b.month) ||
        (a.year == b.year && a.month == b.month && a.day <= b.day);


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
  bool _filtersExpanded = false;
  final GlobalKey<DeckModerationFiltersState> _filtersKey = GlobalKey();

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
    final moderationStatus = data['moderationStatus'] ?? '';

    if (publicationMode == 'permanent' && moderationStatus != 'approved') {
      return 'Вічна публікація';
    }


    if (!isPublic) return 'Первинна публікація';
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
    final third = _filters['third'];
    final sortDate = _filters['sortDate'];

    final DateTime? startSubmitted = widget.filter == 'pending' ? _filters['startDate'] : null;
    final DateTime? endSubmitted = widget.filter == 'pending' ? _filters['endDate'] : null;

    final DateTime? startModerated = widget.filter == 'rejected' ? _filters['startDate'] : null;
    final DateTime? endModerated = widget.filter == 'rejected' ? _filters['endDate'] : null;

    final DateTime? startPublished = (widget.filter == 'allPublic' || widget.filter == 'hidden') ? _filters['startDate'] : null;
    final DateTime? endPublished = (widget.filter == 'allPublic' || widget.filter == 'hidden') ? _filters['endDate'] : null;

    List<QueryDocumentSnapshot> filtered = decks.where((deck) {
      final data = deck.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final type = _submissionLabel(data);
      final pubMode = data['publicationMode'] ?? 'temporary';

      final matchesTitle = titleQuery.isEmpty || title.contains(titleQuery);
      bool matchesThird = true;

      if (widget.filter == 'pending' || widget.filter == 'rejected') {
        matchesThird = third == null || third == type;
      } else if (widget.filter == 'allPublic' || widget.filter == 'hidden') {
        matchesThird = third == null || third == pubMode;
      }


      return matchesTitle && matchesThird;
    }).toList();


    if (widget.filter == 'pending') {
      if (startSubmitted != null || endSubmitted != null) {
        filtered = filtered.where((deck) {
          final submitted = (deck.data() as Map<String, dynamic>)['submittedAt'];
          if (submitted == null) return false;
          final time = (submitted as Timestamp).toDate();
          final afterStart = startSubmitted == null || isSameOrAfter(time, startSubmitted);
          final beforeEnd = endSubmitted == null || isSameOrBefore(time, endSubmitted);
          return afterStart && beforeEnd;
        }).toList();
      }

      if (sortDate != null) {
        filtered.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['submittedAt']?.toDate();
          final bTime = (b.data() as Map<String, dynamic>)['submittedAt']?.toDate();
          if (aTime == null || bTime == null) return 0;
          return sortDate == 'asc' ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
        });
      }
    }



    if (widget.filter == 'rejected') {
      if (startModerated != null || endModerated != null) {
        filtered = filtered.where((deck) {
          final moderated = (deck.data() as Map<String, dynamic>)['moderatedAt'];
          if (moderated == null) return false;
          final time = (moderated as Timestamp).toDate();
          final afterStart = startModerated == null || isSameOrAfter(time, startModerated);
          final beforeEnd = endModerated == null || isSameOrBefore(time, endModerated);
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

    if (widget.filter == 'allPublic' || widget.filter == 'hidden') {
      if (startPublished != null || endPublished != null) {
        filtered = filtered.where((deck) {
          final published = (deck.data() as Map<String, dynamic>)['publishedAt'];
          if (published == null) return false;
          final time = (published as Timestamp).toDate();
          final afterStart = startPublished == null || isSameOrAfter(time, startPublished);
          final beforeEnd = endPublished == null || isSameOrBefore(time, endPublished);
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            ),

            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  DeckModerationFilters(
                    key: _filtersKey, // ⬅️ підключаємо глобальний ключ
                    filter: widget.filter,
                    onChanged: (filters) => setState(() => _filters = filters),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        _filtersKey.currentState?.clearAll(); // ⬅️ очищення ззовні
                      },
                      icon: const Icon(Icons.clear, size: 18, color: Colors.white60),
                      label: const Text(
                        'Очистити фільтри',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: _filtersExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
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

            final baseTitle = data['title'] ?? 'Без назви';
            final addedCount = data['addedCount'] ?? 0;

            final isPending = widget.filter == 'pending';
            final isRejected = widget.filter == 'rejected';
            final isPublicDeck = widget.filter == 'allPublic' || widget.filter == 'hidden';

            final title = baseTitle;

            final userId = data['userId'] ?? '';
            final moderatedAt = data.containsKey('moderatedAt') ? _formatDate(
                data['moderatedAt']) : '';
            final submissionType = _submissionLabel(data);
            final submittedAt = data.containsKey('submittedAt') ? _formatDate(data['submittedAt']) : '';



            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnapshot) {
                String userEmail = 'Невідомо';
                String role = 'user'; // за замовчуванням

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  userEmail = (userData['email'] ?? '').toString().toLowerCase();
                  role = (userData['role'] ?? 'user').toString().toLowerCase();

                  final emailFilter = _filters['email']?.toString().toLowerCase() ?? '';
                  if (emailFilter.isNotEmpty && !userEmail.contains(emailFilter)) {
                    return const SizedBox.shrink();
                  }

                  final roleFilter = _filters['role']?.toString().toLowerCase();
                  if (roleFilter != null && role != roleFilter) {
                    return const SizedBox.shrink();
                  }
                }

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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Назва + дата подачі (разом, але з різним стилем)
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (isPublicDeck)
                                              TextSpan(
                                                text: '  (додано: $addedCount)',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                          ],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Переглянути зміни (праворуч)
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
                                Row(
                                  children: [
                                    const Text('Автор: ', style: TextStyle(color: Colors.grey)),
                                    // Email (обрізатиметься, якщо довгий)
                                    Expanded(
                                      child: Text(
                                        userEmail,
                                        style: const TextStyle(color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Роль (кольоровий бейджик)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: role == 'admin' ? Colors.orange : Colors.blueGrey,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        role,
                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),

                                if (isPending || isRejected) ...[
                                  Text('Id: ${deck.id}', style: const TextStyle(color: Colors.grey)),
                                  Text('Тип подачі: $submissionType', style: const TextStyle(color: Colors.orangeAccent)),
                                  if (moderatedAt.isNotEmpty && isRejected)
                                    Text('Перевірено: $moderatedAt', style: const TextStyle(color: Colors.grey)),
                                  if (submittedAt.isNotEmpty && isPending)
                                    Text('Подано: $submittedAt', style: const TextStyle(color: Colors.grey)),

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
                                      final reason = controller.text.trim().isEmpty ? 'Відсутня' : controller.text.trim();
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

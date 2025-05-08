import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'card_managment_section.dart';
import '../services/deck_service.dart';
import 'package:intl/intl.dart';

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
              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Схвалені'))),
              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Відхилені'))),
              Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Усі публічні'))),
            ],
          ),
          const SizedBox(height: 5),
          const Expanded(
            child: TabBarView(
              children: [
                DeckModerationList(filter: 'pending'),
                DeckModerationList(filter: 'approved'),
                DeckModerationList(filter: 'rejected'),
                DeckModerationList(filter: 'allPublic'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeckModerationList extends StatelessWidget {
  final String filter;
  const DeckModerationList({super.key, required this.filter});

  Stream<QuerySnapshot> _deckStream() {
    final decks = FirebaseFirestore.instance.collection('decks');
    switch (filter) {
      case 'pending':
        return decks.where('moderationStatus', isEqualTo: 'pending').snapshots();
      case 'approved':
        return decks.where('moderationStatus', isEqualTo: 'approved').snapshots();
      case 'rejected':
        return decks.where('moderationStatus', isEqualTo: 'rejected').snapshots();
      case 'allPublic':
        return decks.where('isPublic', isEqualTo: true).snapshots();
      default:
        return const Stream.empty();
    }
  }

  Future<void> _approve(String deckId) async {
    await DeckService().approveDeck(deckId);
  }

  Future<void> _rejectWithReason(BuildContext context, String deckId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Причина відхилення"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Наприклад: замало карток, неприйнятні слова"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Скасувати")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Відхилити"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = controller.text.trim();
      await DeckService().rejectDeck(deckId, reason);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _deckStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Немає колод.', style: TextStyle(color: Colors.white70)),
          );
        }

        final decks = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            final data = deck.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Без назви';
            final userId = data['userId'] ?? '';
            final cardCount = data['cardCount'] ?? 0;
            final isPublic = data['isPublic'] ?? false;
            final moderatedAt = data.containsKey('moderatedAt') ? _formatDate(data['moderatedAt']) : '';
            final publishedAt = data.containsKey('publishedAt') ? _formatDate(data['publishedAt']) : '';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnapshot) {
                String userEmail = 'Невідомо';
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  userEmail = userData['email'] ?? 'Невідомо';
                }

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  color: const Color(0xFF333333),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('Автор: $userEmail', style: const TextStyle(color: Colors.grey)),
                                  Text('Id: $userId', style: const TextStyle(color: Colors.grey)),
                                  Text('Карток: $cardCount', style: const TextStyle(color: Colors.grey)),
                                  if (moderatedAt.isNotEmpty)
                                    Text('Перевірено: $moderatedAt', style: const TextStyle(color: Colors.grey)),
                                  if (publishedAt.isNotEmpty)
                                    Text('Опубліковано: $publishedAt', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (filter == 'pending')
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    tooltip: 'Схвалити',
                                    onPressed: () => _approve(deck.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    tooltip: 'Відхилити',
                                    onPressed: () => _rejectWithReason(context, deck.id),
                                  ),
                                ],
                              )
                            else if (filter == 'allPublic')
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.orange),
                                tooltip: 'Зробити приватною',
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('decks').doc(deck.id).update({
                                    'isPublic': false,
                                    'moderationStatus': null,
                                    'moderatedAt': null,
                                    'publishedAt': null,
                                  });
                                },
                              )
                            else
                              const Icon(Icons.info_outline, color: Colors.white24),
                          ],
                        ),
                        if (isPublic)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              child: const Text('Перейти до карток', style: TextStyle(color: Colors.orange)),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CardManagmentSection(deckId: deck.id)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );

              },
            );
          },
        );
      },
    );
  }
}



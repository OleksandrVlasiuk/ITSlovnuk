// cards_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'copied_deck_page.dart';
import 'models/deck.dart';
import 'services/deck_service.dart';
import 'deck_page.dart';
import 'user_decks_filters.dart'; // додай цей


class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  late Future<List<Deck>> _decksFuture;
  String titleSearch = '';
  String deckTypeFilter = 'all'; // 'all', 'own', 'copied'
  String sortDirection = 'desc'; // 'asc', 'desc'
  DateTime? startDate;
  DateTime? endDate;
  int? minCards;
  int? maxCards;
  Map<String, String> authorRoles = {};



  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  void _loadDecks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _decksFuture = DeckService().getUserDecks(user.uid).then((allDecks) async {
        final copiedDecks = allDecks.where((d) => d.copiedFrom != null).toList();
        final nicknames = copiedDecks
            .map((d) => d.originalUserNickname?.trim().toLowerCase())
            .whereType<String>()
            .toSet();

        // Завантажуємо ролі за нікнеймами
        final roleMap = <String, String>{};
        for (final nickname in nicknames) {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('nickname', isEqualTo: nickname)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            final data = query.docs.first.data();
            final role = data['role'] ?? 'user';
            roleMap[nickname.trim().toLowerCase()] = role;
          }
        }

        final isITSlovnykSearch = titleSearch.trim().toLowerCase().contains('itсловник');

        return allDecks.where((deck) {
          final titleMatch = deck.title.toLowerCase().contains(titleSearch.toLowerCase());

          final isCopied = deck.copiedFrom != null;
          final typeMatch = switch (deckTypeFilter) {
            'own' => !isCopied,
            'copied' => isCopied,
            _ => true,
          };

          final cardCountMatch = (minCards == null || deck.cardCount >= minCards!) &&
              (maxCards == null || deck.cardCount <= maxCards!);

          final createdOrCopiedDate = isCopied ? deck.copiedAt ?? deck.createdAt : deck.createdAt;
          final dateMatch = (startDate == null || !createdOrCopiedDate.isBefore(startDate!)) &&
              (endDate == null || !createdOrCopiedDate.isAfter(endDate!));

          final nicknameKey = deck.originalUserNickname?.trim().toLowerCase();
          final isAdminDeck = isCopied && nicknameKey != null && roleMap[nicknameKey] == 'admin';

          if (isITSlovnykSearch) {
            return isAdminDeck;
          }

          return titleMatch && typeMatch && cardCountMatch && dateMatch;
        }).toList()
          ..sort((a, b) {
            final dateA = a.copiedFrom != null ? a.copiedAt ?? a.createdAt : a.createdAt;
            final dateB = b.copiedFrom != null ? b.copiedAt ?? b.createdAt : b.createdAt;
            return sortDirection == 'asc' ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
          });
      });
    }
  }




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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Колоди карток',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            UserDecksFilters(
              titleSearch: titleSearch,
              deckTypeFilter: deckTypeFilter,
              sortDirection: sortDirection,
              startDate: startDate,
              endDate: endDate,
              minCards: minCards,
              maxCards: maxCards,
              onChanged: ({
                String? title,
                String? deckType,
                String? sortDirection,
                DateTime? startDate,
                DateTime? endDate,
                int? minCards,
                int? maxCards,
              }) {
                setState(() {
                  titleSearch = title ?? '';
                  deckTypeFilter = deckType ?? 'all';
                  this.sortDirection = sortDirection ?? 'desc';
                  this.startDate = startDate;
                  this.endDate = endDate;
                  this.minCards = minCards;
                  this.maxCards = maxCards;
                  _loadDecks();
                });
              },
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Deck>>(
                future: _decksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Помилка: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Немає колод.', style: TextStyle(color: Colors.white70)));
                  }

                  final decks = snapshot.data!;
                  return ListView.builder(
                    itemCount: decks.length,
                    itemBuilder: (context, index) {
                      final deck = decks[index];
                      return _buildDeckTile(context, deck);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_deck');
          if (result == true) {
            setState(() {
              _loadDecks();
            });
          }
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildDeckTile(BuildContext context, Deck deck) {
    final isCopied = deck.copiedFrom != null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: const Color(0xFF333333),
      child: ListTile(
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              deck.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 5),
            if (isCopied)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Text(

                  authorRoles[deck.originalUserNickname?.trim().toLowerCase()] == 'admin'
                      ? 'ITСловник'
                      : deck.originalUserNickname ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),


          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.style, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${deck.cardCount} карток', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Перегляд: ${_formatAgo(deck.lastViewed)}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  isCopied
                      ? 'Додано: ${_formatDate(deck.copiedAt ?? deck.createdAt)}'
                      : 'Створено: ${_formatDate(deck.createdAt)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => deck.copiedFrom != null
                  ? CopiedDeckPage(deckId: deck.id, title: deck.title)
                  : DeckPage(deckId: deck.id, title: deck.title),
            ),
          );

          if (result == true) {
            setState(() {
              _loadDecks();
            });
          }
        },

      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} с тому';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} хв тому';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} год тому';
    } else {
      return '${difference.inDays} днів тому';
    }
  }
}

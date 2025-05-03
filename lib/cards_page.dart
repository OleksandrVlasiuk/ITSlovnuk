// cards_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/deck.dart';
import 'services/deck_service.dart';
import 'deck_page.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  late Future<List<Deck>> _decksFuture;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  void _loadDecks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _decksFuture = DeckService().getUserDecks(user.uid);
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: const Color(0xFF333333),
      child: ListTile(
        title: Text(deck.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                Text('Створено: ${_formatDate(deck.createdAt)}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeckPage(deckId: deck.id, title: deck.title),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/deck_service.dart';
import 'admin/card_managment_list_section.dart';
import '../models/deck.dart';

class PublicDeckPreviewPage extends StatefulWidget {
  final String deckId;

  const PublicDeckPreviewPage({super.key, required this.deckId});

  @override
  State<PublicDeckPreviewPage> createState() => _PublicDeckPreviewPageState();
}

class _PublicDeckPreviewPageState extends State<PublicDeckPreviewPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = true;
  bool alreadyAdded = false;
  DateTime? copiedAt;

  String title = '';
  String authorEmail = 'невідомо';
  int cardCount = 0;
  int addedCount = 0;
  DateTime? publishedAt;
  List<Map<String, String>> cards = [];

  @override
  void initState() {
    super.initState();
    _loadDeck();
  }

  Future<void> _loadDeck() async {
    final doc = await FirebaseFirestore.instance.collection('published_decks').doc(widget.deckId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    title = data['title'] ?? 'Без назви';
    cardCount = data['cardCount'] ?? 0;
    addedCount = data['addedCount'] ?? 0;
    publishedAt = (data['publishedAt'] as Timestamp).toDate();
    final authorId = data['userId'] ?? '';

    final authorDoc = await FirebaseFirestore.instance.collection('users').doc(authorId).get();
    authorEmail = authorDoc.data()?['email'] ?? 'невідомо';

    final userDecks = await DeckService().getUserDecks(userId);
    Deck? existingDeck;
    for (final deck in userDecks) {
      if (deck.copiedFrom == widget.deckId) {
        existingDeck = deck;
        break;
      }
    }

    alreadyAdded = existingDeck != null;
    copiedAt = existingDeck?.copiedAt;

    final cardsSnapshot = await FirebaseFirestore.instance
        .collection('published_decks')
        .doc(widget.deckId)
        .collection('cards')
        .orderBy('createdAt', descending: true)
        .get();

    cards = cardsSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'front': data['term']?.toString() ?? '',
        'backEng': data['definitionEng']?.toString() ?? '',
        'backUkr': data['definitionUkr']?.toString() ?? '',
      };
    }).toList();

    setState(() => isLoading = false);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text('Перегляд колоди', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Автор: $authorEmail', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            Text(
              'Карток: $cardCount | Додали: $addedCount',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            Text('Опубліковано: ${_formatDate(publishedAt)}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Картки', style: TextStyle(color: Colors.white, fontSize: 18)),
                if (cards.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CardManagmentListSection(
                            cards: cards,
                            deckTitle: title,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      '${cards.length} >',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            cards.isEmpty
                ? const Text("Немає карток", style: TextStyle(color: Colors.white38))
                : SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length > 5 ? 5 : cards.length,
                itemBuilder: (context, index) {
                  return _buildCard(cards[index]['front'] ?? '');
                },
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: alreadyAdded
                  ? Text(
                'Колода вже додана до ваших\n${copiedAt != null ? "Додано: ${_formatDate(copiedAt)}" : ''}',
                style: const TextStyle(color: Colors.greenAccent),
                textAlign: TextAlign.center,
              )
                  : ElevatedButton.icon(
                onPressed: () async {
                  await DeckService().addPublicDeckToUser(widget.deckId, userId);
                  await _loadDeck();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Колода додана до ваших')),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text('Додати до моїх колод', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String word) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.indigo.shade700, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          word,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
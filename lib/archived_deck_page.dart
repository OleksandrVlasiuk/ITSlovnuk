import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'archived_cards_list_page.dart';

class ArchivedDeckPage extends StatefulWidget {
  final String deckId;
  final String title;

  const ArchivedDeckPage({super.key, required this.deckId, required this.title});

  @override
  State<ArchivedDeckPage> createState() => _ArchivedDeckPageState();
}

class _ArchivedDeckPageState extends State<ArchivedDeckPage> {
  List<Map<String, String>> cards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('decks')
        .doc(widget.deckId)
        .collection('cards')
        .orderBy('createdAt', descending: true)
        .get();

    cards = snapshot.docs.map((doc) => {
      'front': (doc['term'] ?? '').toString(),
      'backEng': (doc['definitionEng'] ?? '').toString(),
      'backUkr': (doc['definitionUkr'] ?? '').toString(),
    }).toList();

    setState(() => isLoading = false);
  }

  Future<void> _confirmUnarchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Розархівувати колоду?"),
        content: const Text("Колода знову стане активною."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Скасувати"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Розархівувати", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('decks').doc(widget.deckId).update({
        'isArchived': false,
        'archivedAt': null,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Колоду розархівовано'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text('ITСловник', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Рядок з кнопкою та кількістю карток
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _confirmUnarchive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Розархівувати"),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArchivedCardsListPage(cards: cards, deckTitle: widget.title),
                      ),
                    );
                  },
                  child: Text(
                    "${cards.length}/${cards.length} >",
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

            const Text("Картки", style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 8),

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

            if (cards.length > 5)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ArchivedCardsListPage(cards: cards, deckTitle: widget.title),
                      ),
                    );
                  },
                  child: Text(
                    "Переглянути всі",
                    style: const TextStyle(color: Colors.white),
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

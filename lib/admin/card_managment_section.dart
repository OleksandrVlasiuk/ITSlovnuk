import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CardManagmentSection extends StatefulWidget {
  final String deckId;

  const CardManagmentSection({super.key, required this.deckId});

  @override
  State<CardManagmentSection> createState() => _CardManagmentSectionState();
}

class _CardManagmentSectionState extends State<CardManagmentSection> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        title: const Text('Картки колоди'),
        backgroundColor: const Color(0xFF2B2B2B),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('decks')
                  .doc(widget.deckId)
                  .collection('cards')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final cards = snapshot.data!.docs.where((doc) {
                  final word = (doc['english'] as String).toLowerCase();
                  final translation = (doc['ukrainian'] as String).toLowerCase();
                  return word.contains(_searchQuery.toLowerCase()) ||
                      translation.contains(_searchQuery.toLowerCase());
                }).toList();

                if (cards.isEmpty) {
                  return const Center(child: Text('Немає карток', style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Card(
                      color: card['isApproved'] == true ? Colors.green[100] : Colors.orange[100],
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(card['english'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(card['ukrainian']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveCard(card.id),
                              tooltip: 'Схвалити',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editCard(card),
                              tooltip: 'Редагувати',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCard(card.id),
                              tooltip: 'Видалити',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Пошук за словом або перекладом...',
          filled: true,
          fillColor: Colors.white24,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintStyle: const TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  void _approveCard(String cardId) {
    FirebaseFirestore.instance
        .collection('decks')
        .doc(widget.deckId)
        .collection('cards')
        .doc(cardId)
        .update({'isApproved': true});
  }

  void _deleteCard(String cardId) {
    FirebaseFirestore.instance
        .collection('decks')
        .doc(widget.deckId)
        .collection('cards')
        .doc(cardId)
        .delete();
  }

  void _editCard(QueryDocumentSnapshot card) {
    final englishController = TextEditingController(text: card['english']);
    final ukrainianController = TextEditingController(text: card['ukrainian']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text('Редагувати картку', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: englishController,
              decoration: const InputDecoration(labelText: 'English', labelStyle: TextStyle(color: Colors.white)),
              style: const TextStyle(color: Colors.white),
            ),
            TextField(
              controller: ukrainianController,
              decoration: const InputDecoration(labelText: 'Українська', labelStyle: TextStyle(color: Colors.white)),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('decks')
                  .doc(widget.deckId)
                  .collection('cards')
                  .doc(card.id)
                  .update({
                'english': englishController.text.trim(),
                'ukrainian': ukrainianController.text.trim()
              });
              Navigator.pop(context);
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }
}

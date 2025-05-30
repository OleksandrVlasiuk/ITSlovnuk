import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CardsListPage extends StatefulWidget {
  final String deckId;
  final String deckTitle;

  const CardsListPage({super.key, required this.deckId, required this.deckTitle});

  @override
  State<CardsListPage> createState() => _CardsListPageState();
}

class _CardsListPageState extends State<CardsListPage> {
  List<DocumentSnapshot> cards = [];
  bool isLoading = true;
  bool isCopied = false;
  bool updated = false;

  @override
  void initState() {
    super.initState();
    _checkIfCopied().then((_) => _loadCards());
  }

  Future<void> _checkIfCopied() async {
    final deckDoc = await FirebaseFirestore.instance
        .collection('decks')
        .doc(widget.deckId)
        .get();

    final data = deckDoc.data();
    if (data != null && data.containsKey('copiedFrom') && data['copiedFrom'] != null) {
      setState(() {
        isCopied = true;
      });
    }
  }


  Future<void> _loadCards() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('decks')
        .doc(widget.deckId)
        .collection('cards')
        .orderBy('createdAt', descending: false)
        .get();

    setState(() {
      cards = snapshot.docs;
      isLoading = false;
    });
  }

  bool _isNew(Timestamp createdAt) {
    final now = DateTime.now();
    return now.difference(createdAt.toDate()).inHours < 24;
  }

  Future<void> _editCard(DocumentSnapshot card) async {
    if (isCopied) return;
    final termController = TextEditingController(text: card['term']);
    final defUkrController = TextEditingController(text: card['definitionUkr'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редагувати картку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: termController,
              decoration: const InputDecoration(labelText: 'Англійське слово'),
            ),
            TextField(
              controller: defUkrController,
              decoration: const InputDecoration(labelText: 'Український переклад'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('decks')
                  .doc(widget.deckId)
                  .collection('cards')
                  .doc(card.id)
                  .update({
                'term': termController.text.trim(),
                'definitionUkr': defUkrController.text.trim(),
              });
              Navigator.pop(context, true);
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );

    if (result == true) {
      updated = true;
      _loadCards();
    }
  }

  Future<void> _deleteCard(String cardId) async {
    if (isCopied) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Підтвердження"),
        content: const Text("Видалити цю картку?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Скасувати"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Видалити"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('decks')
          .doc(widget.deckId)
          .collection('cards')
          .doc(cardId)
          .delete();

      await FirebaseFirestore.instance
          .collection('decks')
          .doc(widget.deckId)
          .update({
        'cardCount': FieldValue.increment(-1),
      });

      updated = true;
      _loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (updated) {
          Navigator.pop(context, true);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C2C2C),
          title: Text(widget.deckTitle, style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : cards.isEmpty
            ? const Center(
          child: Text(
            'Немає карток у цій колоді.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3 / 4,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final isNew = _isNew(card['createdAt']);

              return GestureDetector(
                onTap: () {
                  if (!isCopied) _editCard(card);
                },
                onLongPress: () {
                  if (!isCopied) _deleteCard(card.id);
                },
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blueGrey, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card['term'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Colors.black45),
                          const SizedBox(height: 8),
                          Text(
                            card['definitionUkr'] ?? '',
                            style: const TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (isNew)
                      const Positioned(
                        top: 6,
                        left: 8,
                        child: Icon(Icons.horizontal_rule, size: 16, color: Colors.blueAccent),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

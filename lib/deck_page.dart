import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:it_english_app_clean/services/deck_service.dart';
import 'add_card_page.dart';
import 'cards_list_page.dart';
import 'learning_session_page.dart';

class DeckPage extends StatefulWidget {
  final String deckId;
  final String title;

  const DeckPage({super.key, required this.deckId, required this.title});

  @override
  State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  List<Map<String, String>> cards = [];
  bool isLoading = true;
  bool updated = false;
  String title = '';
  int sessionCount = 5;

  @override
  void initState() {
    super.initState();
    title = widget.title;
    _loadCards();
    _loadDeckInfo();
  }

  Future<void> _loadDeckInfo() async {
    final doc = await FirebaseFirestore.instance.collection('decks').doc(widget.deckId).get();
    setState(() {
      title = doc['title'] ?? title;
      sessionCount = doc['sessionCardCount'] ?? 5;
    });
  }

  Future<void> _loadCards() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('decks')
        .doc(widget.deckId)
        .collection('cards')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      cards = snapshot.docs
          .map((doc) => {
        'front': (doc['term'] ?? '').toString(),
        'backEng': (doc['definitionEng'] ?? '').toString(),
        'backUkr': (doc['definitionUkr'] ?? '').toString(),
        'id': doc.id.toString(),
      })
          .toList();

      isLoading = false;
    });
  }

  Future<void> _editDeckSettings() async {
    final titleController = TextEditingController(text: title);
    final countController = TextEditingController(text: sessionCount.toString());

    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Редагувати колоду"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Назва колоди'),
            ),
            TextField(
              controller: countController,
              decoration: const InputDecoration(labelText: 'Карток на сесію'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              final newCount = int.tryParse(countController.text.trim()) ?? sessionCount;

              await FirebaseFirestore.instance.collection('decks').doc(widget.deckId).update({
                'title': newTitle,
                'sessionCardCount': newCount,
              });

              setState(() {
                title = newTitle;
                sessionCount = newCount;
                updated = true;
              });
              Navigator.pop(context, true);
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, updated);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C2C2C),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, updated),
          ),
          title: const Text(
            'ITСловник',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (cards.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('У цій колоді ще немає карток')),
                        );
                        return;
                      }

                      await DeckService().updateLastViewed(widget.deckId);

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LearningSessionPage(
                            deckId: widget.deckId,
                            deckTitle: title,
                            sessionCount: sessionCount,
                          ),
                        ),
                      );

                      if (result == true) {
                        await _loadDeckInfo();
                        setState(() {
                          updated = true;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text("Перегляд", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CardsListPage(
                            deckId: widget.deckId,
                            deckTitle: title,
                          ),
                        ),
                      );

                      if (result == true) {
                        await DeckService().updateCardCount(widget.deckId);
                        setState(() {
                          updated = true;
                          _loadCards();
                        });
                      }
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
              const SizedBox(height: 20),
              const Text("Картки", style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: cards.isEmpty
                    ? const Center(child: Text("Немає карток", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    return _buildCard(
                      cards[index]['front'] ?? '',
                      isNew: index == 0,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text("Налаштування", style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 12),
              _buildSettingItem("Редагувати назву та кількість >", _editDeckSettings),
              _buildSettingItem("Додати в архів >", () {}),
              _buildSettingItem("Нова картка >", () async {
                final newCard = await Navigator.push<Map<String, String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddCardPage(deckId: widget.deckId),
                  ),
                );

                if (newCard != null) {
                  updated = true;
                  _loadCards();
                }
              }),
              _buildSettingItem("Карток на сесію : $sessionCount", null),
              _buildSettingItem("Назва : $title", null),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Підтвердження"),
                      content: const Text("Ви дійсно хочете видалити цю колоду та всі її картки?"),
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
                    await DeckService().deleteDeckWithCards(widget.deckId);
                    if (mounted) Navigator.pop(context, true);
                  }
                },
                child: const Text("Видалити колоду"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String word, {bool isNew = false}) {
    return Stack(
      children: [
        Container(
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
        ),
        if (isNew)
          Positioned(
            top: 6,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'New',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingItem(String title, VoidCallback? onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      dense: true,
    );
  }
}

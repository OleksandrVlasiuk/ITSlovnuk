import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cards_list_page.dart';
import 'learning_session_page.dart';
import 'services/deck_service.dart';

class CopiedDeckPage extends StatefulWidget {
  final String deckId;
  final String title;

  const CopiedDeckPage({super.key, required this.deckId, required this.title});

  @override
  State<CopiedDeckPage> createState() => _CopiedDeckPageState();
}

class _CopiedDeckPageState extends State<CopiedDeckPage> {
  List<Map<String, String>> cards = [];
  bool isLoading = true;
  String title = '';
  int sessionCount = 5;

  @override
  void initState() {
    super.initState();
    title = widget.title;
    _loadDeckInfo();
    _loadCards();
  }

  Future<void> _loadDeckInfo() async {
    final doc = await FirebaseFirestore.instance.collection('decks').doc(widget.deckId).get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      sessionCount = data['sessionCardCount'] ?? 5;
    });
  }

  Future<void> _loadCards() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('decks')
        .doc(widget.deckId)
        .collection('cards')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      cards = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'front': '${data['term'] ?? ''}',
          'backEng': '${data['definitionEng'] ?? ''}',
          'backUkr': '${data['definitionUkr'] ?? ''}',
          'id': doc.id,
        };
      }).toList().cast<Map<String, String>>();
      isLoading = false;
    });

  }

  Future<void> _editSessionCount() async {
    final countController = TextEditingController(text: sessionCount.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Карток на сесію"),
        content: TextField(
          controller: countController,
          decoration: const InputDecoration(labelText: 'Кількість'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () {
              final newCount = int.tryParse(countController.text.trim()) ?? sessionCount;
              setState(() {
                sessionCount = newCount;
              });
              FirebaseFirestore.instance.collection('decks').doc(widget.deckId).update({
                'sessionCardCount': newCount,
              });
              Navigator.pop(context, true);
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Перегляд колоди', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () async {
                      if (cards.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('У цій колоді ще немає карток')),
                        );
                        return;
                      }

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
                        setState(() {});
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Перегляд", style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 6),
                          Text("($sessionCount карток на сесію)",
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Картки", style: TextStyle(color: Colors.white70, fontSize: 18)),
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
                      _loadCards();
                    }
                  },
                  child: Text(
                    "${cards.length} >",
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
            SizedBox(
              height: 150,
              child: cards.isEmpty
                  ? const Center(
                child: Text("Немає карток", style: TextStyle(color: Colors.white38)),
              )
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return _buildCard(cards[index]['front'] ?? '', isNew: index == 0);
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text("Налаштування", style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 10),
            const Divider(color: Colors.white24),
            _buildSettingItem("Карток на сесію >", _editSessionCount),
            const Divider(color: Colors.white24),
            _buildSettingItem("Додати в архів >", () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Підтвердження"),
                  content: const Text("Ви дійсно хочете архівувати цю колоду?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Скасувати"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Архівувати"),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await DeckService().archiveDeck(widget.deckId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Колоду архівовано')),
                  );
                  Navigator.pop(context, true);
                }
              }
            }),
            const Divider(color: Colors.white24),
            const SizedBox(height: 26),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
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
                    if (context.mounted) Navigator.pop(context, true);
                  }
                },
                child: const Text("Видалити колоду"),
              ),
            ),
            const SizedBox(height: 16),

          ],
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
            border: Border.all(color: Colors.white12, width: 5),
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

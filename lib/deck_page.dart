//deck_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:it_english_app_clean/services/deck_service.dart';
import 'add_card_page.dart';
import 'cards_list_page.dart';
import 'deck_moderation_button.dart';
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
  String? moderationStatus;
  String? moderationNote;
  DateTime? moderatedAt;
  DateTime? publishedAt;
  bool isLoading = true;
  bool updated = false;
  String title = '';
  int sessionCount = 5;
  static const int _minCardsForModeration = 5;
  String? publicationMode; // "temporary" | "permanent"
  String? lastSubmissionType;



  @override
  void initState() {
    super.initState();
    title = widget.title;
    _loadCards();
    _loadDeckInfo();
    _loadPublicationInfo();
  }

  Future<void> _loadDeckInfo() async {
    final doc = await FirebaseFirestore.instance.collection('decks').doc(widget.deckId).get();
    final data = doc.data();

    if (data == null) return;

    setState(() {
      title = data['title'] ?? title;
      sessionCount = data['sessionCardCount'] ?? 5;
      moderationStatus = data.containsKey('moderationStatus') ? data['moderationStatus'] : null;
      moderationNote = data.containsKey('moderationNote') ? data['moderationNote'] : null;
      moderatedAt = data['moderatedAt'] != null ? (data['moderatedAt'] as Timestamp).toDate() : null;
      publishedAt = data['publishedAt'] != null ? (data['publishedAt'] as Timestamp).toDate() : null;
      publicationMode = data['publicationMode']; // ← якщо ще не було
      lastSubmissionType = data['lastSubmissionType']; // ← додай ось це
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
            'Перегляд колоди',
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                      child: Row(
                        children: [
                          const Text("Перегляд", style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 6),
                          Text(
                            "($sessionCount карток на сесію)",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),



              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 10),
              const Divider(color: Colors.white24),
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
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Колоду архівовано')),
                    );
                    Navigator.pop(context, true);
                  }
                }
              }),
              const Divider(color: Colors.white24),
              _buildSettingItem("Редагувати назву та кількість >", _editDeckSettings),
              const Divider(color: Colors.white24),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: DeckModerationButton(
                      deckId: widget.deckId,
                      cardCount: cards.length,
                      moderationStatus: moderationStatus,
                      moderationNote: moderationNote,
                      moderatedAt: moderatedAt,
                      publishedAt: publishedAt,
                      publicationMode: publicationMode,
                      lastSubmissionType: lastSubmissionType,
                      onStatusChanged: () async {
                        await _loadDeckInfo();
                        await _loadPublicationInfo();
                        setState(() => updated = true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
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
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red,foregroundColor: Colors.white,),
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
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("Видалити колоду"),
                      ),
                    ),
                  ),
                ],
              ),


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

  Future<void> _loadPublicationInfo() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('published_decks')
        .where('deckId', isEqualTo: widget.deckId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      setState(() {
        publicationMode = data['publicationMode'] ?? 'temporary';
      });
    }
  }

}

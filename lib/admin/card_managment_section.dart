//card_managment_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../deck_change_page.dart';
import '../services/deck_service.dart';
import 'card_managment_list_section.dart';

class CardManagmentSection extends StatefulWidget {
  final String deckId;
  final String collection; // 'decks' або 'published_decks'

  const CardManagmentSection({
    super.key,
    required this.deckId,
    required this.collection,
  });

  @override
  State<CardManagmentSection> createState() => _CardManagmentSectionState();


}

class _CardManagmentSectionState extends State<CardManagmentSection> {
  List<Map<String, String>> cards = [];
  bool isLoading = true;

  String title = '';
  String userEmail = '';
  String role = 'user';
  String moderationStatus = '';
  String publicationMode = '';
  DateTime? submittedAt;
  DateTime? publishedAt;
  bool isActive = true;
  bool wasEverPublished = false;
  String moderatedBy = '';
  DateTime? moderatedAt;
  String adminNote = '';
  int addedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDeckInfoAndCards();
  }

  Future<void> _loadDeckInfoAndCards() async {
    final doc = await FirebaseFirestore.instance
        .collection(widget.collection)
        .doc(widget.deckId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      title = data['title'] ?? 'Без назви';
      moderationStatus = data['moderationStatus'] ?? '';
      publicationMode = data['publicationMode'] ?? '';
      submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
      publishedAt = (data['publishedAt'] as Timestamp?)?.toDate();
      moderatedAt = (data['moderatedAt'] as Timestamp?)?.toDate();

      if (widget.collection == 'published_decks') {
        isActive = data['isActive'] ?? true;
        moderatedBy = data['moderatedBy'] ?? '';
        adminNote = data['adminNote'] ?? '';
      } else {
        wasEverPublished = data['isPublic'] ?? false;
      }

      final userId = data['userId'] ?? '';
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      userEmail = userData?['email'] ?? 'Невідомо';
      role = userData?['role'] ?? 'user';
    }

    final cardsSnapshot = await FirebaseFirestore.instance
        .collection(widget.collection)
        .doc(widget.deckId)
        .collection('cards')
        .orderBy('createdAt', descending: true)
        .get();

    cards = cardsSnapshot.docs.map((doc) => {
      'front': (doc['term'] ?? '').toString(),
      'backEng': (doc['definitionEng'] ?? '').toString(),
      'backUkr': (doc['definitionUkr'] ?? '').toString(),
    }).toList();

    setState(() => isLoading = false);
  }

  String _formatStatus() {
    if (widget.collection == 'published_decks') {
      return isActive ? 'Опублікована (активна)' : 'Опублікована (прихована)';
    }

    if (moderationStatus == 'pending') {
      if (publicationMode == 'permanent') return 'Очікує вічної публікації';
      if (wasEverPublished) return 'Очікує оновлення';
      return 'Очікує первинної публікації';
    }

    if (moderationStatus == 'rejected') return 'Відхилена';
    if (moderationStatus.isEmpty) return 'Не подано';

    return moderationStatus;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.collection == 'decks' &&
                    moderationStatus == 'pending' &&
                    wasEverPublished &&
                    publicationMode != 'permanent')
                  FutureBuilder<Map<String, dynamic>>(
                    future: DeckService().getDeckChanges(widget.deckId),
                    builder: (context, snapshot) {
                      final hasChanges = snapshot.data?['hasChanges'] == true;
                      if (!snapshot.hasData || !hasChanges) return const SizedBox.shrink();
                      return TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeckChangesPage(changes: snapshot.data!),
                            ),
                          );
                        },
                        child: const Text(
                          "(переглянути зміни)",
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 14),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('ID колоди: ${widget.deckId}', style: const TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Автор: ', style: TextStyle(color: Colors.white70 , fontSize: 16)),
                Expanded(
                  child: Text(
                    userEmail,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'admin' ? Colors.orange : Colors.blueGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
            Text('Статус: ${_formatStatus()}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            if (widget.collection == 'published_decks') ...[
              Text('Тип публікації: ${publicationMode == 'permanent' ? 'Назавжди' : 'Тимчасова'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              if (moderatedBy.isNotEmpty)
                Text('Модератор: $moderatedBy',
                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
              if (adminNote.isNotEmpty)
                Text('Коментар: $adminNote',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 16)),
            ],
            if (widget.collection == 'decks')
              if ((moderationStatus == 'pending' || moderationStatus == 'rejected') && wasEverPublished && publishedAt != null)
                Text('Опубліковано раніше: ${_formatDate(publishedAt)}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            if (widget.collection == 'decks' && (moderationStatus == 'pending' || moderationStatus == 'rejected') && submittedAt != null)
              Text('Подано: ${_formatDate(submittedAt)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
            if (widget.collection == 'decks' && moderationStatus == 'rejected' && moderatedAt != null)
              Text('Перевірено: ${_formatDate(moderatedAt)}', style: const TextStyle(color: Colors.white70, fontSize: 16)),



            if (publishedAt != null && widget.collection == 'published_decks')
              Text('Опубліковано: ${_formatDate(publishedAt)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Картки", style: TextStyle(color: Colors.white70, fontSize: 18)),
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
            const SizedBox(height: 50),
            _buildActionButtons(),
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

  Widget _buildActionButtons() {
    if (widget.collection == 'decks') {
      if (moderationStatus == 'pending') {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _confirmAction("Схвалити цю колоду?");
                    if (confirmed) {
                      await DeckService().approveDeck(widget.deckId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Колоду схвалено")),
                      );
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Схвалити"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final controller = TextEditingController();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Причина відхилення"),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: "Поясніть причину...",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Скасувати"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Відхилити"),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && controller.text.trim().isNotEmpty) {
                      await DeckService().rejectDeck(widget.deckId, controller.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Колоду відхилено")),
                      );
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("Відхилити"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        );
      }

      if (moderationStatus == 'rejected') {
        return Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await _confirmAction("Повернути в очікування?");
              if (confirmed) {
                await FirebaseFirestore.instance.collection('decks').doc(widget.deckId).update({
                  'moderationStatus': 'pending',
                  'moderatedAt': null,
                  'moderationNote': null,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Статус змінено на 'Очікує'")),
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Повернути в очікування"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
    }

    if (widget.collection == 'published_decks') {
      if (isActive) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await _confirmAction("Видалити з публічних?");
                if (confirmed) {
                  await FirebaseFirestore.instance
                      .collection('published_decks')
                      .doc(widget.deckId)
                      .delete();
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text("Видалити"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent ,
                foregroundColor: Colors.white,
              ),

            ),
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await _confirmAction("Приховати з публікації?");
                if (confirmed) {
                  await FirebaseFirestore.instance
                      .collection('published_decks')
                      .doc(widget.deckId)
                      .update({'isActive': false});
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.visibility_off),
              label: const Text("Приховати"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange,
                foregroundColor: Colors.white),
            ),
          ],
        );
      } else {
        return Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await _confirmAction("Повернути в публікацію?");
              if (confirmed) {
                await FirebaseFirestore.instance
                    .collection('published_decks')
                    .doc(widget.deckId)
                    .update({'isActive': true});
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.undo),
            label: const Text("Повернути"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.white),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  Future<bool> _confirmAction(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Підтвердження"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Скасувати"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Так"),
          ),
        ],
      ),
    ) ?? false;
  }


}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/deck.dart';
import 'services/deck_service.dart';
import 'archived_deck_page.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late Future<List<Deck>> _archivedDecksFuture;

  @override
  void initState() {
    super.initState();
    _loadArchivedDecks();
  }

  void _loadArchivedDecks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _archivedDecksFuture = DeckService().getArchivedDecks(user.uid);
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
              'Архівовані колоди',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Deck>>(
                future: _archivedDecksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Помилка: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Архів порожній', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    );
                  }

                  final archivedDecks = snapshot.data!;
                  return ListView.builder(
                    itemCount: archivedDecks.length,
                    itemBuilder: (context, index) {
                      final deck = archivedDecks[index];
                      return _buildArchivedDeckTile(context, deck);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedDeckTile(BuildContext context, Deck deck) {
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
                const Icon(Icons.archive, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Заархівовано: ${_formatDate(deck.archivedAt!)}', style: const TextStyle(color: Colors.grey)),
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
              builder: (_) => ArchivedDeckPage(deckId: deck.id, title: deck.title),
            ),
          );
          if (result == true) {
            setState(() {
              _loadArchivedDecks();
            });
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

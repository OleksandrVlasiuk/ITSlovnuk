import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/deck.dart';
import 'services/deck_service.dart';
import 'archived_deck_page.dart';
import 'user_decks_filters.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late Future<List<Deck>> _archivedDecksFuture;
  List<Deck> _allArchivedDecks = [];

  // Фільтри
  String _titleSearch = '';
  String _deckType = 'all';
  String _sort = 'desc';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _minCards;
  int? _maxCards;

  @override
  void initState() {
    super.initState();
    _loadArchivedDecks();
  }

  void _loadArchivedDecks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _archivedDecksFuture = DeckService().getArchivedDecks(user.uid);
      _archivedDecksFuture.then((decks) {
        setState(() {
          _allArchivedDecks = decks;
        });
      });
    }
  }

  List<Deck> get filteredDecks {
    List<Deck> decks = [..._allArchivedDecks];

    // Назва
    if (_titleSearch.isNotEmpty) {
      decks = decks.where((deck) => deck.title.toLowerCase().contains(_titleSearch.toLowerCase())).toList();
    }

    // Тип
    if (_deckType == 'own') {
      decks = decks.where((deck) => deck.copiedFrom == null).toList();
    } else if (_deckType == 'copied') {
      decks = decks.where((deck) => deck.copiedFrom != null).toList();
    }

    // Дата створення
    if (_startDate != null) {
      decks = decks.where((deck) => deck.createdAt.isAfter(_startDate!.subtract(const Duration(days: 1)))).toList();
    }
    if (_endDate != null) {
      decks = decks.where((deck) => deck.createdAt.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }

    // Кількість карток
    if (_minCards != null) {
      decks = decks.where((deck) => deck.cardCount >= _minCards!).toList();
    }
    if (_maxCards != null) {
      decks = decks.where((deck) => deck.cardCount <= _maxCards!).toList();
    }

    // Сортування
    decks.sort((a, b) {
      final compare = a.archivedAt!.compareTo(b.archivedAt!);
      return _sort == 'asc' ? compare : -compare;
    });

    return decks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        automaticallyImplyLeading: false,
        title: const Text('ITСловник', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Архівовані колоди',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            UserDecksFilters(
              titleSearch: _titleSearch,
              deckTypeFilter: _deckType,
              sortDirection: _sort,
              startDate: _startDate,
              endDate: _endDate,
              minCards: _minCards,
              maxCards: _maxCards,
              onChanged: ({
                String? title,
                String? deckType,
                String? sortDirection,
                DateTime? startDate,
                DateTime? endDate,
                int? minCards,
                int? maxCards,
              }) {
                setState(() {
                  _titleSearch = title ?? '';
                  _deckType = deckType ?? 'all';
                  _sort = sortDirection ?? 'desc';
                  _startDate = startDate;
                  _endDate = endDate;
                  _minCards = minCards;
                  _maxCards = maxCards;
                });
              },
            ),
            const SizedBox(height: 10),
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

                  if (filteredDecks.isEmpty) {
                    return const Center(
                      child: Text('Немає колод за заданими фільтрами', style: TextStyle(color: Colors.white70)),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDecks.length,
                    itemBuilder: (context, index) {
                      final deck = filteredDecks[index];
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
    final isCopied = deck.copiedFrom != null;
    final nickname = deck.originalUserNickname?.trim();
    final showBadge = isCopied && nickname != null && nickname.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: const Color(0xFF333333),
      child: ListTile(
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20, // відстань між назвою і бейджиком
          children: [
            Text(
              deck.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            if (showBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  nickname!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
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
                Text(
                  isCopied
                      ? 'Додано: ${_formatDate(deck.copiedAt ?? deck.createdAt)}'
                      : 'Створено: ${_formatDate(deck.createdAt)}',
                  style: const TextStyle(color: Colors.grey),
                ),
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
            _loadArchivedDecks();
          }
        },
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

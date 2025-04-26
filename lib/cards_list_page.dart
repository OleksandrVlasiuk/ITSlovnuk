import 'package:flutter/material.dart';

class CardsListPage extends StatelessWidget {
  final String deckTitle;
  final List<Map<String, String>> cards; // приклад структури картки

  const CardsListPage({super.key, required this.deckTitle, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        title: Text(deckTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2C2C2C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            color: const Color(0xFF333333),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(card['front'] ?? '', style: const TextStyle(color: Colors.white)),
              subtitle: Text(card['back'] ?? '', style: const TextStyle(color: Colors.white70)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      // TODO: Реалізувати редагування
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      // TODO: Реалізувати видалення
                    },
                  ),
                ],
              ),
              onTap: () {
                // також можна відкрити повноекранний перегляд
              },
            ),
          );
        },
      ),
    );
  }
}



//deck_change_page.dart
import 'package:flutter/material.dart';


class DeckChangesPage extends StatelessWidget {
  final Map<String, dynamic> changes;

  const DeckChangesPage({super.key, required this.changes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Зміни в колоді"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (changes['titleChanged'] == true)
              const ListTile(
                leading: Icon(Icons.edit, color: Colors.orange),
                title: Text("Змінено назву колоди", style: TextStyle(color: Colors.white)),
              ),
            if (changes['addedCards'].isNotEmpty)
              ..._buildCardList("➕ Додані картки", changes['addedCards'], Colors.greenAccent),
            if (changes['modifiedCards'].isNotEmpty)
              ..._buildCardList("✏️ Змінені картки", changes['modifiedCards'], Colors.amberAccent),
            if (changes['removedCards'].isNotEmpty)
              ..._buildCardList("➖ Видалені картки", changes['removedCards'], Colors.redAccent),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardList(String title, List cards, Color color) {
    return [
      const SizedBox(height: 12),
      Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...cards.map<Widget>((card) {
        return Card(
          color: const Color(0xFF2C2C2C),
          child: ListTile(
            title: Text(card['term'] ?? '', style: const TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((card['definitionEng'] ?? '').toString().isNotEmpty)
                  Text("Eng: ${card['definitionEng']}", style: const TextStyle(color: Colors.grey)),
                if ((card['definitionUkr'] ?? '').toString().isNotEmpty)
                  Text("Ukr: ${card['definitionUkr']}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      }).toList(),
    ];
  }
}

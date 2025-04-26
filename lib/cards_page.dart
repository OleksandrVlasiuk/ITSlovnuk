// lib/cards_page.dart
import 'package:flutter/material.dart';
import 'deck_page.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        automaticallyImplyLeading: false, // <--- Ось тут ключ
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
              'Колоди карток',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDeckTile(context, 'English Deck IT', 152, 10, '10хв'),
            _buildDeckTile(context, 'English Golden words', 3000, 360, '2год'),
            _buildDeckTile(context, 'English Phrasal Verbs', 416, 5, '3год'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // дія додавання нової колоди
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      // !!! Тут вже НЕ має бути BottomNavigationBar
    );
  }

  Widget _buildDeckTile(BuildContext context, String title, int cards, int learned, String timeAgo) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: const Color(0xFF333333),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            const Icon(Icons.style, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('$cards', style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 12),
            const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('$learned', style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(timeAgo, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeckPage(title: title),
            ),
          );
        },
      ),
    );
  }
}

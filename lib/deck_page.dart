//deck_page.dart
import 'package:flutter/material.dart';
import 'add_card_page.dart';

class DeckPage extends StatefulWidget {
  final String title;

  const DeckPage({super.key, required this.title});

  @override
  State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  List<Map<String, String>> cards = [
    {'front': 'implementation'},
    {'front': 'blunder'},
    {'front': 'compile'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ITСловник'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("Перегляд", style: TextStyle(color: Colors.white)),
                ),
                const Spacer(),
                Text("${cards.length}/${cards.length} >", style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Картки", style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return _buildCard(cards[index]['front'] ?? '');
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text("Налаштування", style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 12),
            _buildSettingItem("Додати в архів >", () {}),
            _buildSettingItem("Нова картка >", () async {
              final newCard = await Navigator.push<Map<String, String>>(
                context,
                MaterialPageRoute(builder: (_) => const AddCardPage()),
              );

              if (newCard != null && newCard['front'] != null) {
                setState(() {
                  cards.insert(0, newCard);
                });
              }
            }),
            _buildSettingItem("Карток на сесію : 5", null),
            _buildSettingItem("Назва : ${widget.title}", null),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
              ),
              onPressed: () {},
              child: const Text("Видалити колоду"),
            )
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCard(String word) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurpleAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Center(
        child: Text(word, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildSettingItem(String title, VoidCallback? onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF2C2C2C),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.view_module), label: 'Картки'),
        BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Мій план'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Статистика'),
        BottomNavigationBarItem(icon: Icon(Icons.archive), label: 'Архів'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профіль'),
      ],
    );
  }
}
//add_card_page.dart
import 'package:flutter/material.dart';

class AddCardPage extends StatelessWidget {
  const AddCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController frontEngController = TextEditingController();
    final TextEditingController backEngController = TextEditingController();
    final TextEditingController backUkrController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text('ITСловник', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Створення нової картки',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildCardForm(
                  title: 'Передня сторона',
                  controller1: frontEngController,
                  label1: 'анг',
                ),
                const SizedBox(width: 12),
                _buildCardForm(
                  title: 'Задня сторона',
                  controller1: backEngController,
                  label1: 'анг',
                  controller2: backUkrController,
                  label2: 'укр',
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final newCard = {
                  'front': frontEngController.text,
                  'backEng': backEngController.text,
                  'backUkr': backUkrController.text,
                };
                Navigator.pop(context, newCard);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Додати'),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2B2B2B),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Картки'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Мій план'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Статистика'),
          BottomNavigationBarItem(icon: Icon(Icons.archive), label: 'Архів'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профіль'),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Навігація між сторінками
        },
      ),
    );
  }

  Widget _buildCardForm({
    required String title,
    required TextEditingController controller1,
    required String label1,
    TextEditingController? controller2,
    String? label2,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: controller1,
              decoration: InputDecoration(labelText: label1),
            ),
            if (controller2 != null && label2 != null) ...[
              const SizedBox(height: 10),
              TextField(
                controller: controller2,
                decoration: InputDecoration(labelText: label2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
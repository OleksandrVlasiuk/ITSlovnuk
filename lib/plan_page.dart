// lib/plan_page.dart
import 'package:flutter/material.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

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
        child: ListView(
          children: [
            const Text(
              'Рекомендовані колоди',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDeckTile('Frontend Starter', 'Колода для новачків у Frontend'),
            _buildDeckTile('Backend Essentials', 'Основні поняття для бекендерів'),
            _buildDeckTile('DevOps Basics', 'Базові знання DevOps'),
            _buildDeckTile('Database Pro', 'Поглиблене про бази даних'),
            const SizedBox(height: 32),
            const Text(
              'Публічні колоди користувачів',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDeckTile('React Mastery', 'Публічна колода користувача Oleg'),
            _buildDeckTile('AI Terminology', 'Штучний інтелект словами'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckTile(String title, String description) {
    return Card(
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          onPressed: () {
            // TODO: Реалізувати додавання до своїх колод
          },
        ),
      ),
    );
  }
}

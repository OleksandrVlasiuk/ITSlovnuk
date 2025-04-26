// lib/profile_page.dart
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Профіль',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildProfileItem('Пошта', 'alex1@gmail.com', () {}),
            const SizedBox(height: 24),
            _buildProfileItem('Змінити пароль', '', () {}),
            const SizedBox(height: 24),
            _buildProfileItem('Видалити профіль', '', () {}, isDanger: true),
            const SizedBox(height: 24),
            _buildProfileItem('Вийти', '', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String title, String value, VoidCallback onTap, {bool isDanger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value.isEmpty ? title : '$title    $value',
              style: TextStyle(
                color: isDanger ? Colors.redAccent : Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }
}



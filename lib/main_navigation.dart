import 'package:flutter/material.dart';
import 'package:it_english_app_clean/plan_page.dart';
import 'cards_page.dart';
import 'statistics_page.dart';
import 'archive_page.dart'; // <-- Додаємо
import 'profile_page.dart'; // <-- Додаємо

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CardsPage(),
    PlanPage(),
    StatisticsPage(),
    ArchivePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF2B2B2B),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        iconSize: 26,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          _buildNavItem(Icons.menu_book_outlined, "Картки", 0),
          _buildNavItem(Icons.book_online_outlined, "Мій план", 1),
          _buildNavItem(Icons.bar_chart_outlined, "Статистика", 2),
          _buildNavItem(Icons.archive_outlined, "Архів", 3),
          _buildNavItem(Icons.person_outline, "Профіль", 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Column(
        children: [
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: _currentIndex == index ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Icon(icon),
        ],
      ),
      label: label,
    );
  }
}

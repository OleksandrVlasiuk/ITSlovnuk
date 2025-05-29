//admin_panel.dart
import 'package:flutter/material.dart';
import 'package:it_english_app_clean/admin/user_statistics_page.dart';
import 'deck_managment_section.dart';
import 'user_managment_section.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
                'Адмін-панель',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Колоди'),
                  Tab(text: 'Користувачі'),
                  Tab(text: 'Статистика'),
                ],
              ),
              const SizedBox(height: 5),
              const Expanded(
                child: TabBarView(
                  children: [
                    DeckManagmentSection(),
                    UserManagmentSection(),
                    AdminStatisticsPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

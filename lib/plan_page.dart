// plan_page.dart
import 'package:flutter/material.dart';
import 'recommended_decks_tab.dart';
import 'all_public_decks_tab.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
                'Пропоновані колоди карток',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Рекомендовані'),
                  Tab(text: 'Усі публічні'),
                ],
              ),
              const SizedBox(height: 4),
              const Expanded(
                child: TabBarView(
                  children: [
                    RecommendedDecksTab(),
                    AllPublicDecksTab(),
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

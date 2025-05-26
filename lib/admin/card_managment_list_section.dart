import 'package:flutter/material.dart';

class CardManagmentListSection extends StatelessWidget {
  final List<Map<String, String>> cards;
  final String deckTitle;

  const CardManagmentListSection({
    super.key,
    required this.cards,
    required this.deckTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(deckTitle, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: cards.isEmpty
          ? const Center(
        child: Text(
          'Немає карток у цій колоді.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 4,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];

            final front = card['front'] ?? '';
            final back = (card['backUkr'] ?? '').isNotEmpty
                ? card['backUkr']!
                : card['backEng'] ?? '';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.indigo.shade700, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    front,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Divider(thickness: 1, color: Colors.black26),
                  const SizedBox(height: 12),
                  Text(
                    back,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

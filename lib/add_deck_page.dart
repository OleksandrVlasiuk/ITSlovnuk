import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/deck_service.dart';
import '../models/deck.dart';

class AddDeckPage extends StatefulWidget {
  const AddDeckPage({super.key});

  @override
  State<AddDeckPage> createState() => _AddDeckPageState();
}

class _AddDeckPageState extends State<AddDeckPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _cardsPerSessionController = TextEditingController();

  void _createDeck() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final cardsPerSession = int.tryParse(_cardsPerSessionController.text.trim()) ?? 5;

    if (title.isEmpty || cardsPerSession <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Будь ласка, введіть коректні дані")),
      );
      return;
    }

    final deckExists = await DeckService().doesDeckExist(user.uid, title);
    if (deckExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Колода з такою назвою вже існує")),
      );
      return;
    }

    final now = DateTime.now();

    await DeckService().createDeck(
      Deck(
        id: '',
        userId: user.uid,
        title: title,
        sessionCardCount: cardsPerSession,
        isArchived: false,
        isPublic: false,
        lastViewed: now,
        createdAt: now,
        cardCount: 0,
      ),
    );

    Navigator.pop(context, true); // Передаємо результат назад
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text("ITСловник", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Створення колоди",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                const Text("Назва :", style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "колода1",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Карток на сесію :", style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cardsPerSessionController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "10",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _createDeck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Створити"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCardPage extends StatefulWidget {
  final String deckId;

  const AddCardPage({super.key, required this.deckId});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final TextEditingController frontEngController = TextEditingController();
  final TextEditingController backEngController = TextEditingController();
  final TextEditingController backUkrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    frontEngController.addListener(() {
      backEngController.text = frontEngController.text;
    });
  }

  @override
  void dispose() {
    frontEngController.dispose();
    backEngController.dispose();
    backUkrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  readOnly1: true,
                  controller2: backUkrController,
                  label2: 'укр',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final term = frontEngController.text.trim();
                  final defEng = backEngController.text.trim();
                  final defUkr = backUkrController.text.trim();

                  if (term.isEmpty || (defEng.isEmpty && defUkr.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Заповніть хоча б 2 поля")),
                    );
                    return;
                  }

                  final docRef = await FirebaseFirestore.instance
                      .collection('decks')
                      .doc(widget.deckId)
                      .collection('cards')
                      .add({
                    'term': term,
                    'definitionEng': defEng,
                    'definitionUkr': defUkr,
                    'createdAt': DateTime.now(),
                  });

                  await docRef.update({'id': docRef.id});

                  Navigator.pop(context, {
                    'front': term,
                    'backEng': defEng,
                    'backUkr': defUkr,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Додати'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm({
    required String title,
    required TextEditingController controller1,
    required String label1,
    bool readOnly1 = false,
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
              readOnly: readOnly1,
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

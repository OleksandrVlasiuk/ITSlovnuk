// deck_importer.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> importDeckFromJson(String userId) async {
  final firestore = FirebaseFirestore.instance;

  // Завантаження JSON-файлу колоди Software Development Tools
  final String jsonString =
  await rootBundle.loadString('assets/software_dev_tools_deck.json');
  final List<dynamic> jsonList = json.decode(jsonString);

  // Створення нової колоди
  final deckRef = await firestore.collection('decks').add({
    'userId': userId,
    'title': 'Software Development Tools',
    'sessionCardCount': 5,
    'isArchived': false,
    'isPublic': false,
    'createdAt': FieldValue.serverTimestamp(),
    'lastViewed': FieldValue.serverTimestamp(),
    'cardCount': jsonList.length,
  });

  // Додавання карток до підколекції
  final batch = firestore.batch();
  for (var card in jsonList) {
    final cardRef = deckRef.collection('cards').doc();
    batch.set(cardRef, {
      'term': card['term'] ?? '',
      'definitionUkr': card['definitionUkr'] ?? '',
      'definitionEng': card['definitionEng'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  print('✅ Колода "Software Development Tools" імпортована');
}

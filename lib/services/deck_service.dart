//deck_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';

class DeckService {
  final _firestore = FirebaseFirestore.instance;

  /// Створити нову колоду
  Future<void> createDeck(Deck deck) async {
    final docRef = await _firestore.collection('decks').add(deck.toMap());
    await docRef.update({'id': docRef.id});
  }

  /// Подати нову колоду на модерацію
  Future<void> submitForModeration(String deckId) async {
    await FirebaseFirestore.instance.collection('decks').doc(deckId).update({
      'moderationStatus': 'pending',
      'moderationNote': null,
      'moderatedAt': null,
      'publishedAt': null,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }


  /// Подати оновлення до вже існуючої публічної колоди
  Future<void> submitUpdateForModeration(String deckId) async {
    await FirebaseFirestore.instance.collection('decks').doc(deckId).update({
      'moderationStatus': 'pending',
      'moderationNote': null,
      'moderatedAt': null,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }


  Future<void> approveDeck(String deckId) async {
    final firestore = FirebaseFirestore.instance;
    final deckRef = firestore.collection('decks').doc(deckId);
    final deckSnap = await deckRef.get();

    if (!deckSnap.exists) return;

    final deckData = deckSnap.data()!;
    final now = DateTime.now();

    // Отримуємо картки ЗАВЧАСНО
    final cardsSnapshot = await deckRef.collection('cards').get();

    // Оновлюємо статус у оригінальній колекції
    await deckRef.update({
      'moderationStatus': 'approved',
      'moderatedAt': now,
      'publishedAt': now,
      'isPublic': true,
    });

    // Готуємо дані для published_decks
    final publishedRef = firestore.collection('published_decks').doc(deckId);
    final publishedSnap = await publishedRef.get();

    final publishedData = {
      'deckId': deckId,
      'userId': deckData['userId'],
      'title': deckData['title'],
      'sessionCardCount': cardsSnapshot.docs.length, // ✅
      'cardCount': cardsSnapshot.docs.length,        // ✅
      'publicationMode': 'temporary',
      'publishedAt': now,
      'isActive': true,
    };

    if (publishedSnap.exists) {
      await publishedRef.update(publishedData);
    } else {
      await publishedRef.set(publishedData);
    }

    // Копіюємо картки
    for (final doc in cardsSnapshot.docs) {
      await publishedRef.collection('cards').doc(doc.id).set(doc.data());
    }
  }




  Future<void> publishPermanently(String deckId) async {
    final snap = await FirebaseFirestore.instance
        .collection('published_decks')
        .doc(deckId)
        .get();

    if (snap.exists && snap.data()?['isActive'] == true) {
      await snap.reference.update({'publicationMode': 'permanent'});
    }
  }


  /// Відхилити колоду з причиною
  Future<void> rejectDeck(String deckId, String reason) async {
    await FirebaseFirestore.instance.collection('decks').doc(deckId).update({
      'moderationStatus': 'rejected',
      'moderationNote': reason,
      'moderatedAt': DateTime.now(),
      // isPublic не змінюється (може бути ще не публічною)
    });
  }


  /// Отримати всі неархівовані колоди користувача
  Future<List<Deck>> getUserDecks(String userId) async {
    final snapshot = await _firestore
        .collection('decks')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => Deck.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Перевірити, чи існує вже колода з такою назвою для користувача
  Future<bool> doesDeckExist(String userId, String title) async {
    final snapshot = await _firestore
        .collection('decks')
        .where('userId', isEqualTo: userId)
        .where('title', isEqualTo: title)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Архівувати колоду
  Future<void> archiveDeck(String deckId) async {
    await _firestore.collection('decks').doc(deckId).update({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Зробити колоду публічною вручну (не через модерацію)
  Future<void> makeDeckPublic(String deckId) async {
    await _firestore.collection('decks').doc(deckId).update({
      'isPublic': true,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Видалити колоду з усіма картками
  Future<void> deleteDeckWithCards(String deckId) async {
    final deckRef = _firestore.collection('decks').doc(deckId);
    final cardsRef = deckRef.collection('cards');

    final batch = _firestore.batch();
    final cardsSnapshot = await cardsRef.get();

    for (final doc in cardsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(deckRef);
    await batch.commit();
  }

  /// Оновити кількість карток у колоді
  Future<void> updateCardCount(String deckId) async {
    final cardsSnapshot = await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .get();

    final newCount = cardsSnapshot.docs.length;

    await _firestore.collection('decks').doc(deckId).update({
      'cardCount': newCount,
    });
  }

  /// Оновити дату останнього перегляду
  Future<void> updateLastViewed(String deckId) async {
    await _firestore.collection('decks').doc(deckId).update({
      'lastViewed': FieldValue.serverTimestamp(),
    });
  }

  /// Отримати всі архівовані колоди користувача
  Future<List<Deck>> getArchivedDecks(String userId) async {
    final snapshot = await _firestore
        .collection('decks')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: true)
        .orderBy('archivedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Deck.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Map<String, dynamic>> getDeckChanges(String deckId) async {
    final firestore = FirebaseFirestore.instance;

    final currentDeckRef = firestore.collection('decks').doc(deckId);
    final currentDeckSnap = await currentDeckRef.get();
    final currentDeckData = currentDeckSnap.data();

    if (currentDeckData == null) {
      throw Exception("Deck not found");
    }

    final currentTitle = currentDeckData['title'];

    // Якщо колода ще не була опублікована — ніяких змін не показуємо
    final publishedSnapshot = await firestore
        .collection('published_decks')
        .where('deckId', isEqualTo: deckId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (publishedSnapshot.docs.isEmpty) {
      return {
        'titleChanged': false, // ← ключова зміна
        'addedCards': [],
        'removedCards': [],
        'modifiedCards': [],
      };
    }

    final publishedDoc = publishedSnapshot.docs.first;
    final publishedDeckData = publishedDoc.data();
    final publishedTitle = publishedDeckData['title'];

    final titleChanged = currentTitle != publishedTitle;

    final currentCardsSnap = await currentDeckRef.collection('cards').get();
    final publishedCardsSnap = await publishedDoc.reference.collection('cards').get();

    final currentCards = { for (var doc in currentCardsSnap.docs) doc.id: doc.data() };
    final publishedCards = { for (var doc in publishedCardsSnap.docs) doc.id: doc.data() };

    final addedCards = <Map<String, dynamic>>[];
    final removedCards = <Map<String, dynamic>>[];
    final modifiedCards = <Map<String, dynamic>>[];

    for (final entry in currentCards.entries) {
      final id = entry.key;
      final currentData = entry.value;

      if (!publishedCards.containsKey(id)) {
        addedCards.add({...currentData, 'id': id});
      } else {
        final publishedData = publishedCards[id];
        if (publishedData != null && !_areCardContentsEqual(currentData, publishedData)) {
          modifiedCards.add({...currentData, 'id': id});
        }
      }
    }

    for (final entry in publishedCards.entries) {
      final id = entry.key;
      if (!currentCards.containsKey(id)) {
        removedCards.add({...entry.value, 'id': id});
      }
    }

    return {
      'titleChanged': titleChanged,
      'addedCards': addedCards,
      'removedCards': removedCards,
      'modifiedCards': modifiedCards,
      'hasChanges': titleChanged || addedCards.isNotEmpty || removedCards.isNotEmpty || modifiedCards.isNotEmpty,
    };

  }


  bool _areCardContentsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a['term'] == b['term'] &&
        a['definitionEng'] == b['definitionEng'] &&
        a['definitionUkr'] == b['definitionUkr'];
  }

  Future<void> addPublicDeckToUser(String publishedDeckId, String userId) async {
    final firestore = FirebaseFirestore.instance;

    final pubSnap = await firestore.collection('published_decks').doc(publishedDeckId).get();
    if (!pubSnap.exists) throw Exception('Колода не знайдена');

    final pubData = pubSnap.data()!;
    final newDeckRef = await firestore.collection('decks').add({
      'title': pubData['title'],
      'userId': userId,
      'sessionCardCount': pubData['sessionCardCount'] ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
      'isArchived': false,
      'isPublic': false,
      'copiedFrom': publishedDeckId,
      'copiedAt': FieldValue.serverTimestamp(),
      'cardCount': 0, // приватна не використовується для перегляду
    });

    await newDeckRef.update({'id': newDeckRef.id});

    final cardsSnap = await firestore
        .collection('published_decks')
        .doc(publishedDeckId)
        .collection('cards')
        .get();

    for (final doc in cardsSnap.docs) {
      await newDeckRef.collection('cards').doc(doc.id).set(doc.data());
    }

    // ✅ Оновлюємо лише в опублікованій колоді
    await firestore.collection('published_decks').doc(publishedDeckId).update({
      'addedCount': FieldValue.increment(1),
      'cardCount': cardsSnap.docs.length
    });
  }



}

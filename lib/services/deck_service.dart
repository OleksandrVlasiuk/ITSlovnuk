import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';

class DeckService {
  final _firestore = FirebaseFirestore.instance;

  /// Створити нову колоду
  Future<void> createDeck(Deck deck) async {
    final docRef = await _firestore.collection('decks').add(deck.toMap());
    await docRef.update({'id': docRef.id});
  }

  /// Подати колоду на модерацію
  Future<void> submitForModeration(String deckId) async {
    await _firestore.collection('decks').doc(deckId).update({
      'moderationStatus': 'pending',
      'moderationNote': null,
      'isPublic': false,
    });
  }

  /// Схвалити колоду
  Future<void> approveDeck(String deckId) async {
    await _firestore.collection('decks').doc(deckId).update({
      'moderationStatus': 'approved',
      'moderationNote': null,
      'isPublic': true,
      'moderatedAt': FieldValue.serverTimestamp(),
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Відхилити колоду з причиною
  Future<void> rejectDeck(String deckId, String reason) async {
    await _firestore.collection('decks').doc(deckId).update({
      'moderationStatus': 'rejected',
      'moderationNote': reason,
      'isPublic': false,
      'moderatedAt': FieldValue.serverTimestamp(),
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
}

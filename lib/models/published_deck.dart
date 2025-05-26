//published_deck.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PublishedDeck {
  final String id;
  final String deckId;
  final String userId;
  final String title;
  final int sessionCardCount;
  final int cardCount;
  final String publicationMode; // 'temporary' або 'permanent'
  final DateTime publishedAt;
  final bool isActive;
  final String? moderatedBy;
  final String? adminNote;

  PublishedDeck({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.title,
    required this.sessionCardCount,
    required this.cardCount,
    required this.publicationMode,
    required this.publishedAt,
    required this.isActive,
    this.moderatedBy,
    this.adminNote,
  });

  factory PublishedDeck.fromMap(String id, Map<String, dynamic> data) {
    return PublishedDeck(
      id: id,
      deckId: data['deckId'],
      userId: data['userId'],
      title: data['title'],
      sessionCardCount: data['sessionCardCount'] ?? 5,
      publicationMode: data['publicationMode'] ?? 'temporary',
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      cardCount: data['cardCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      moderatedBy: data['moderatedBy'],
      adminNote: data['adminNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deckId': deckId,
      'userId': userId,
      'title': title,
      'sessionCardCount': sessionCardCount,
      'publicationMode': publicationMode,
      'publishedAt': publishedAt,
      'cardCount': cardCount,
      'isActive': isActive,
      if (moderatedBy != null) 'moderatedBy': moderatedBy,
      if (adminNote != null) 'adminNote': adminNote,
    };
  }
}

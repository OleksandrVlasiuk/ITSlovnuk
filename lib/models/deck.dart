import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String id;
  final String userId;
  final String title;
  final int sessionCardCount;
  final bool isArchived;
  final bool isPublic;
  final DateTime lastViewed;
  final DateTime createdAt;
  final int cardCount;
  final DateTime? archivedAt;

  Deck({
    required this.id,
    required this.userId,
    required this.title,
    required this.sessionCardCount,
    required this.isArchived,
    required this.isPublic,
    required this.lastViewed,
    required this.createdAt,
    required this.cardCount,
    this.archivedAt,
  });

  factory Deck.fromMap(String id, Map<String, dynamic> data) {
    return Deck(
      id: id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      sessionCardCount: data['sessionCardCount'] ?? 5,
      isArchived: data['isArchived'] ?? false,
      isPublic: data['isPublic'] ?? false,
      lastViewed: data['lastViewed'] != null
          ? (data['lastViewed'] as Timestamp).toDate()
          : (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      cardCount: data['cardCount'] ?? 0,
      archivedAt: data['archivedAt'] != null ? (data['archivedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'sessionCardCount': sessionCardCount,
      'isArchived': isArchived,
      'isPublic': isPublic,
      'lastViewed': lastViewed,
      'createdAt': createdAt,
      'cardCount': cardCount,
      'archivedAt': archivedAt,
    };
  }
}

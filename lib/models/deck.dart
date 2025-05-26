import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String id;
  final String userId;
  final String title;
  final int sessionCardCount;
  final bool isArchived;
  final bool isPublic;
  final String? moderationStatus;
  final String? moderationNote;
  final DateTime lastViewed;
  final DateTime createdAt;
  final int cardCount;
  final DateTime? archivedAt;
  final DateTime? moderatedAt;
  final DateTime? publishedAt;
  final String? copiedFrom;
  final DateTime? copiedAt;

  Deck({
    required this.id,
    required this.userId,
    required this.title,
    required this.sessionCardCount,
    required this.isArchived,
    required this.isPublic,
    this.moderationStatus,
    this.moderationNote,
    required this.lastViewed,
    required this.createdAt,
    required this.cardCount,
    this.archivedAt,
    this.moderatedAt,
    this.publishedAt,
    this.copiedFrom,
    this.copiedAt,
  });

  factory Deck.fromMap(String id, Map<String, dynamic> data) {
    return Deck(
      id: id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      sessionCardCount: data['sessionCardCount'] ?? 5,
      isArchived: data['isArchived'] ?? false,
      isPublic: data['isPublic'] ?? false,
      moderationStatus: data['moderationStatus'],
      moderationNote: data['moderationNote'],
      lastViewed: data['lastViewed'] != null
          ? (data['lastViewed'] as Timestamp).toDate()
          : (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      cardCount: data['cardCount'] ?? 0,
      archivedAt: data['archivedAt'] != null
          ? (data['archivedAt'] as Timestamp).toDate()
          : null,
      moderatedAt: data['moderatedAt'] != null
          ? (data['moderatedAt'] as Timestamp).toDate()
          : null,
      publishedAt: data['publishedAt'] != null
          ? (data['publishedAt'] as Timestamp).toDate()
          : null,
      copiedFrom: data['copiedFrom'],
      copiedAt: data['copiedAt'] != null
          ? (data['copiedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'sessionCardCount': sessionCardCount,
      'isArchived': isArchived,
      'isPublic': isPublic,
      if (moderationStatus != null) 'moderationStatus': moderationStatus,
      if (moderationNote != null) 'moderationNote': moderationNote,
      'lastViewed': lastViewed,
      'createdAt': createdAt,
      'cardCount': cardCount,
      'archivedAt': archivedAt,
      if (moderatedAt != null) 'moderatedAt': moderatedAt,
      if (publishedAt != null) 'publishedAt': publishedAt,
      if (copiedFrom != null) 'copiedFrom': copiedFrom,
      if (copiedAt != null) 'copiedAt': copiedAt,
    };
  }
}

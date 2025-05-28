// deck_moderation_button.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:it_english_app_clean/services/deck_service.dart';

class DeckModerationButton extends StatelessWidget {
  final String deckId;
  final int cardCount;
  final String? moderationStatus;
  final String? moderationNote;
  final DateTime? moderatedAt;
  final DateTime? publishedAt;
  final String? publicationMode;
  final VoidCallback onStatusChanged;
  final String? lastSubmissionType;


  static const int _minCardsForModeration = 5;

  const DeckModerationButton({
    super.key,
    required this.deckId,
    required this.cardCount,
    required this.moderationStatus,
    required this.moderationNote,
    required this.moderatedAt,
    required this.publishedAt,
    required this.publicationMode,
    required this.onStatusChanged,
    required this.lastSubmissionType,

  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _showModerationDialog(context),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text("Публікація / Статус"),
      ),
    );
  }

  Future<void> _showModerationDialog(BuildContext context, {String? overrideStatus}) async {
    final publishedSnap = await FirebaseFirestore.instance
        .collection('published_decks')
        .where('deckId', isEqualTo: deckId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    final isPublished = publishedSnap.docs.isNotEmpty;
    final currentMode = publicationMode ?? 'temporary';
    final status = overrideStatus ?? moderationStatus;

    String formatDate(DateTime date) {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day.$month.$year о $hour:$minute';
    }


    if (!isPublished && status == null) {
      // Нова колода
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
            titlePadding: const EdgeInsets.only(left: 24, top: 24, right: 12),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Подати на модерацію"),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          content: Text('Колода буде перевірена модератором. Необхідно щонайменше $_minCardsForModeration карток.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Скасувати")),
            ElevatedButton(
              onPressed: () async {
                if (cardCount < _minCardsForModeration) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Мінімум $_minCardsForModeration карток для подачі')),
                  );
                  return;
                }
                await DeckService().submitForModeration(deckId);
                Navigator.pop(context);
                onStatusChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Колода подана на модерацію")),
                );
              },
              child: const Text("Подати"),
            ),
          ],
        ),
      );
      return;
    }

    if (status == 'pending') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          titlePadding: const EdgeInsets.only(left: 24, top: 24, right: 12),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Статус модерації"),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("⏳ Колода перебуває на перевірці модератором."),
              const SizedBox(height: 8),
              Text(
                switch (lastSubmissionType) {
                  'permanent' => 'Тип заявки: вічна публікація',
                  'update' => 'Тип заявки: оновлення',
                  'initial' || _ => 'Тип заявки: первинна публікація',
                },
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),

        ),
      );
      return;
    }

    if (status == 'rejected') {
      final publishedSnap = await FirebaseFirestore.instance
          .collection('published_decks')
          .where('deckId', isEqualTo: deckId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      final isPublished = publishedSnap.docs.isNotEmpty;

      String submissionType = switch (lastSubmissionType) {
        'permanent' => 'Запит на вічну публікацію',
        'update' => 'Запит на оновлення',
        'initial' || _ => 'Первинна публікація',
      };


      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          titlePadding: const EdgeInsets.only(left: 24, top: 24, right: 12),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Колода відхилена"),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📝 Тип заявки: $submissionType'),
              const SizedBox(height: 8),
              const Text('Модератор відхилив колоду.'),
              if (moderationNote != null) ...[
                const SizedBox(height: 8),
                Text('Причина: $moderationNote'),
              ],
              if (moderatedAt != null) ...[
                const SizedBox(height: 8),
                Text('Дата перевірки: ${formatDate(moderatedAt!)}'),
              ],
            ],
          ),
          actions: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (!isPublished) ...[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Закрити"),
                    ),
                    const SizedBox(width: 5),
                  ],
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (!isPublished) {
                        if (cardCount < _minCardsForModeration) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Мінімум $_minCardsForModeration карток для подачі')),
                          );
                          return;
                        }
                        await DeckService().submitForModeration(deckId);
                      } else {
                        await DeckService().submitForModeration(
                          deckId,
                          submissionType: lastSubmissionType ?? 'initial',
                        );
                      }
                      onStatusChanged();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Колоду повторно подано на модерацію")),
                      );
                    },
                    child: const Text("Подати повторно"),
                  ),
                  const SizedBox(width: 5),
                  if (isPublished)
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await DeckService().clearRejectionStatusSmart(deckId);
                        _showModerationDialog(context, overrideStatus: 'approved');
                      },
                      icon: const Icon(Icons.more_horiz),
                      label: const Text("Інші дії"),
                    ),
                ],
              ),
            ),
          ],

        ),
      );
      return;
    }


    if (status == 'approved' && isPublished) {
      // Підтягуємо актуальні дані з published_decks
      final pubSnap = await FirebaseFirestore.instance
          .collection('published_decks')
          .doc(deckId)
          .get();

      final pubData = pubSnap.data();
      final effectivePublishedAt = pubData != null
          ? (pubData['publishedAt'] as Timestamp?)?.toDate()
          : publishedAt;

      final effectiveMode = pubData?['publicationMode'] ?? publicationMode ?? 'temporary';

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          titlePadding: const EdgeInsets.only(left: 24, top: 24, right: 12),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Опубліковано"),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Закрити',
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("✅ Колода була успішно опублікована"),
              const SizedBox(height: 10),
              Text(
                effectiveMode == 'permanent'
                    ? "🟢 Публікація назавжди"
                    : "🕓 Тимчасова публікація",
              ),
              const SizedBox(height: 8),
              if (effectivePublishedAt != null)
                Text('Опубліковано: ${formatDate(effectivePublishedAt)}'),
            ],
          ),
          actions: effectiveMode == 'permanent'
              ? []
              : [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final isAdmin = await _checkIfAdmin();
                      await DeckService().publishPermanently(deckId, isAdmin: isAdmin);
                      if (!context.mounted) return;
                      onStatusChanged();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAdmin
                                ? "Колода опублікована назавжди"
                                : "Запит на вічну публікацію подано на перевірку",
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Icon(Icons.lock, size: 16),
                          SizedBox(width: 6),
                          Text("Назавжди"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await DeckService().submitUpdateForModeration(deckId);
                      onStatusChanged();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Оновлення подано на модерацію")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Icon(Icons.update, size: 16),
                          SizedBox(width: 6),
                          Text("Оновити"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      for (final doc in publishedSnap.docs) {
                        await doc.reference.update({'isActive': false});
                      }
                      await FirebaseFirestore.instance.collection('decks').doc(deckId).update({
                        'moderationStatus': null,
                        'publishedAt': null,
                        'moderatedAt': null,
                        'isPublic': false,
                      });
                      onStatusChanged();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Колоду знято з публікації")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16),
                          SizedBox(width: 6),
                          Text("Забрати"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      return;
    }


    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text("Стан колоди"),
        content: Text("Неможливо визначити поточний статус."),
      ),
    );
  }

  Future<bool> _checkIfAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = userSnap.data()?['role'];
    return role == 'admin';
  }

}

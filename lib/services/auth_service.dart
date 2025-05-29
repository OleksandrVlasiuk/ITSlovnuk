//auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> register(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<void> createUserDocument(User user, String nickname) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'createdAt': DateTime.now(),
      'role': 'user',
      'nickname': nickname,
      'isBlocked': false, // рекомендую одразу додати
    });
    // Додатково — реєструємо нікнейм
    await _firestore.collection('nicknames').doc(nickname).set({
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = result.user;

      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      final data = doc.data();

      if (doc.exists && data?['isBlocked'] == true) {
        await _auth.signOut(); // обов’язково — щоб не залишити користувача залогіненим

        final blockReason = data?['blockReason'] ?? 'Без причини';
        final blockedAtRaw = data?['blockedAt'];
        String blockedAtFormatted = '';

        if (blockedAtRaw is Timestamp) {
          final date = blockedAtRaw.toDate();
          blockedAtFormatted =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }

        throw FirebaseAuthException(
          code: 'blocked-user',
          message: 'Акаунт заблоковано.\n📝 Причина: $blockReason\n📅 Дата: $blockedAtFormatted',
        );
      }

      return user;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Користувача з такою поштою не існує або обліковий запис видалено.',
        );
      }
      rethrow;
    }
  }



  Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Якщо документа немає — створюємо з роллю user
        await docRef.set({
          'email': user.email,
          'createdAt': DateTime.now(),
          'role': 'user',
        });
        return false;
      }

      final data = doc.data();
      if (data == null || !data.containsKey('role')) {
        // Якщо документа немає поля role — оновлюємо
        await docRef.update({'role': 'user'});
        return false;
      }

      return data['role'] == 'admin';
    } catch (e) {
      print('🔥 Помилка при перевірці ролі: $e');
      return false; // ⚠️ Безпечна поведінка: не зависаємо
    }
  }


  Future<bool> deleteAccountAndData(BuildContext context, String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack(context, "Користувача не знайдено. Спробуйте увійти ще раз.");
      return false;
    }

    final uid = user.uid;

    try {
      // Отримуємо нікнейм, якщо є
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final nickname = userDoc.data()?['nickname'];
      if (nickname != null) {
        await FirebaseFirestore.instance.collection('nicknames').doc(nickname).delete();
      }
    } catch (e) {
      debugPrint('Не вдалося видалити нікнейм: $e');
    }

    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          _showSnack(context, 'Невірний пароль. Спробуйте ще раз.');
          break;
        case 'user-mismatch':
          _showSnack(context, 'Поточний користувач не збігається. Увійдіть знову.');
          break;
        case 'too-many-requests':
          _showSnack(context, 'Забагато спроб. Спробуйте трохи пізніше.');
          break;
        case 'network-request-failed':
          _showSnack(context, 'Проблема з мережею. Перевірте підключення.');
          break;
        case 'requires-recent-login':
          _showSnack(context, 'Потрібно повторно увійти перед видаленням.');
          break;
        default:
          _showSnack(context, 'Помилка авторизації: ${e.message}');
      }
      return false;
    } catch (e) {
      _showSnack(context, 'Не вдалося повторно авторизуватись: $e');
      return false;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('users').doc(uid).delete();
      await firestore.collection('statistics').doc(uid).delete();

      final decks = await firestore.collection('decks').where('userId', isEqualTo: uid).get();
      for (var d in decks.docs) {
        await d.reference.delete();
      }

      final cards = await firestore.collection('cards').where('userId', isEqualTo: uid).get();
      for (var c in cards.docs) {
        await c.reference.delete();
      }
    } on FirebaseException catch (e) {
      _showSnack(context, 'Помилка видалення з бази: ${e.message}');
      return false;
    } catch (e) {
      _showSnack(context, 'Невідома помилка при очищенні даних: $e');
      return false;
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'permission-denied') {
        _showSnack(context, 'Немає дозволу на видалення акаунта. Можливо, вже видалено.');
      } else {
        _showSnack(context, 'Помилка видалення акаунта: ${e.message}');
      }
      return false;
    } catch (e) {
      _showSnack(context, 'Невідома помилка при видаленні акаунта: $e');
      return false;
    }

    if (context.mounted) {
      _showSnack(context, '✅ Акаунт успішно видалено.');
      return true;
    }

    return false;
  }

  void _showSnack(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> blockUser(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'isBlocked': true,
      'blockedAt': Timestamp.now(),
      'blockReason': reason.isEmpty ? 'Без причини' : reason,
    });
  }

  Future<void> unblockUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isBlocked': false,
      'blockedAt': FieldValue.delete(),
      'blockReason': FieldValue.delete(),
    });
  }

  Future<bool> isNicknameTaken(String nickname) async {
    final doc = await _firestore.collection('nicknames').doc(nickname).get();
    return doc.exists;
  }

  Future<bool> updateNickname(String newNickname) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final uid = user.uid;

    // Перевірка, чи вже зайнятий
    final nicknameTaken = await isNicknameTaken(newNickname);
    if (nicknameTaken) return false;

    final batch = FirebaseFirestore.instance.batch();

    // 1. Видаляємо старий нікнейм
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final oldNickname = userDoc.data()?['nickname'];
    if (oldNickname != null) {
      batch.delete(_firestore.collection('nicknames').doc(oldNickname));
    }

    // 2. Оновлюємо поле nickname у users
    batch.update(_firestore.collection('users').doc(uid), {
      'nickname': newNickname,
    });

    // 3. Додаємо новий нікнейм
    batch.set(_firestore.collection('nicknames').doc(newNickname), {
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return true;
  }



  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

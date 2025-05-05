import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_navigation.dart';
import 'email_verification_screen.dart';
import 'start_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _checkUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1C1C1C),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final user = snapshot.data;

        if (user != null && user.emailVerified) {
          return const MainNavigation(); // 🔓 Успішно авторизований
        } else if (user != null && !user.emailVerified) {
          return EmailVerificationScreen(
            email: user.email ?? '',
            source: 'login',
          ); // ✉️ Пошта не підтверджена
        } else {
          return const StartScreen(); // ❌ Користувач не авторизований
        }
      },
    );
  }

  Future<User?> _checkUser() async {
    await Future.delayed(const Duration(milliseconds: 300)); // трошки затримки для плавності
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // оновлюємо дані
    return FirebaseAuth.instance.currentUser;
  }
}

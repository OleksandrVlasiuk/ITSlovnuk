import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:it_english_app_clean/screens/login_screen.dart';
import 'change_password_page.dart';
import 'firebase_options.dart';
import 'learning_session_page.dart';
import 'screens/start_screen.dart';
import 'add_deck_page.dart';
import 'change_password_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const StartScreen(),
      routes: {
        '/add_deck': (_) => const AddDeckPage(),
        '/change_password': (_) => const ChangePasswordPage(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}

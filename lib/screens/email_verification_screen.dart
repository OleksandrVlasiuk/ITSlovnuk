//email_verification_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String source; // 'register' або 'login'
  final String nickname;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.source = 'register',
    required this.nickname,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isVerified = false;
  bool _isLoading = false;
  String? _message;
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();

    if (widget.source == 'register') {
      _sendInitialVerificationEmail();
    }

    // Перевірка без повідомлення — просто ініціалізація статусу
    _checkVerificationStatus(showMessageIfNotVerified: false);
  }

  Future<void> _sendInitialVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() {
        _secondsRemaining = 5;
      });
      _startTimer();
    } catch (e) {
      debugPrint('Помилка надсилання листа при реєстрації: $e');
    }
  }

  Future<void> _checkVerificationStatus({bool showMessageIfNotVerified = true}) async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      await user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      final isVerified = refreshedUser?.emailVerified ?? false;

      setState(() {
        _isVerified = isVerified;
      });

      if (_isVerified && mounted) {
        await AuthService().createUserDocument(refreshedUser!, widget.nickname);
        Navigator.pushReplacementNamed(context, '/');
      } else if (showMessageIfNotVerified) {
        _showError('Пошта ще не підтверджена. Перевірте свій email.');
      }
    } catch (e) {
      _showError('Не вдалося перевірити статус: $e');
    }
  }

  Future<void> _resendVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await user?.sendEmailVerification();
      setState(() {
        _message = 'Лист підтвердження надіслано повторно';
        _secondsRemaining = 5;
      });
      _startTimer();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        _showError('Забагато спроб. Спробуйте через кілька хвилин.');
      } else {
        _showError('Не вдалося надіслати лист: ${e.message}');
      }
    } catch (e) {
      _showError('Сталася помилка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text('Підтвердження пошти', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Ми надіслали лист для підтвердження на адресу ${widget.email}. '
                  'Перевірте пошту та перейдіть за посиланням.',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: _isLoading || _secondsRemaining > 0
                  ? const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : ElevatedButton(
                onPressed: _resendVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Надіслати лист знову'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _checkVerificationStatus(showMessageIfNotVerified: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
              child: const Text('Я вже підтвердив(ла)'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Якщо ви отримали кілька листів, переконайтесь, що ви відкриваєте останній. '
                  'Старі листи можуть не працювати.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 14),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}

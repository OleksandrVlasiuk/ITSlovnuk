//profile_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:it_english_app_clean/screens/start_screen.dart';
import 'package:it_english_app_clean/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? 'Невідомо';

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        automaticallyImplyLeading: false,
        title: const Text('ITСловник', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Профіль',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Пошта    $email',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProfileItem('Змінити пароль', '', () {
              Navigator.pushNamed(context, '/change_password');
            }),
            const SizedBox(height: 24),
            _buildProfileItem('Видалити профіль', '', () async {
              final passwordController = TextEditingController();
              bool showPassword = false;

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: const Text("Підтвердження"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Введіть пароль для підтвердження видалення акаунта."),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              decoration: InputDecoration(
                                labelText: 'Пароль',
                                suffixIcon: IconButton(
                                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => showPassword = !showPassword),
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Скасувати"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text("Видалити"),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (confirmed == true) {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Пароль не може бути порожнім.")),
                  );
                  return;
                }

                final success = await AuthService().deleteAccountAndData(context, password);
                if (success && context.mounted) {
                  await Future.delayed(const Duration(seconds: 1));
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const StartScreen()),
                        (route) => false,
                  );
                }
              }
            }, isDanger: true),
            const SizedBox(height: 24),
            _buildProfileItem('Вийти', '', () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Підтвердження"),
                  content: const Text("Ви дійсно хочете вийти з акаунта?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Скасувати")),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Вийти"),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const StartScreen()),
                        (route) => false,
                  );
                }
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String title, String value, VoidCallback onTap, {bool isDanger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value.isEmpty ? title : '$title    $value',
              style: TextStyle(
                color: isDanger ? Colors.redAccent : Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }
}

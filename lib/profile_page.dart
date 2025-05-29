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
  String nickname = '';
  bool isLoading = true;
  String role = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = user?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          nickname = data['nickname'] ?? '';
          role = data['role'] ?? 'user';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Помилка при зчитуванні профілю: $e');
      setState(() => isLoading = false);
    }
  }


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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Профіль',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (role == 'admin')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orangeAccent),
                    ),
                    child: const Text(
                      'admin',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Нікнейм    $nickname',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Пошта      $email',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 32),
            _buildProfileItem('Змінити нікнейм', '', _changeNickname),
            const SizedBox(height: 24),
            _buildProfileItem('Змінити пароль', '', () {
              Navigator.pushNamed(context, '/change_password');
            }),
            const SizedBox(height: 24),
            _buildProfileItem('Видалити профіль', '', _confirmDelete, isDanger: true),
            const SizedBox(height: 24),
            _buildProfileItem('Вийти', '', _logout),
          ],
        ),
      ),
    );
  }

  Future<void> _changeNickname() async {
    final controller = TextEditingController(text: nickname);

    final newNickname = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Новий нікнейм'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Введіть новий нікнейм'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Зберегти'),
            ),
          ],
        );
      },
    );

    if (newNickname != null && newNickname != nickname) {
      final regex = RegExp(r'^[a-zA-Z0-9._-]{3,20}$');

      if (newNickname.length < 3 || newNickname.length > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нікнейм має бути від 3 до 20 символів')),
        );
        return;
      }

      if (!regex.hasMatch(newNickname)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нікнейм може містити лише літери, цифри, крапку, дефіс або підкреслення'),
          ),
        );
        return;
      }

      final taken = await AuthService().isNicknameTaken(newNickname);
      if (taken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Цей нікнейм вже зайнятий')),
        );
        return;
      }

      final success = await AuthService().updateNickname(newNickname);
      if (success) {
        setState(() => nickname = newNickname);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нікнейм оновлено')),
        );
      }
    }


  }

  Future<void> _confirmDelete() async {
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
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Скасувати")),
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
  }

  Future<void> _logout() async {
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

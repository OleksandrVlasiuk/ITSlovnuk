import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text('Зміна пароля', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1C1C1C),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                ),
              _buildPasswordField('Старий пароль', _oldPasswordController, _showOldPassword, () {
                setState(() => _showOldPassword = !_showOldPassword);
              }),
              const SizedBox(height: 16),
              _buildPasswordField('Новий пароль', _newPasswordController, _showNewPassword, () {
                setState(() => _showNewPassword = !_showNewPassword);
              }),
              const SizedBox(height: 16),
              _buildPasswordField('Підтвердити новий пароль', _confirmPasswordController, _showConfirmPassword, () {
                setState(() => _showConfirmPassword = !_showConfirmPassword);
              }),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _changePassword(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Змінити пароль'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isVisible, VoidCallback toggle) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
          ),
          onPressed: toggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Поле не може бути порожнім';
        return null;
      },
    );
  }

  bool _validatePasswordRules(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _changePassword(User? user) async {
    if (!_formKey.currentState!.validate()) return;

    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Нові паролі не збігаються');
      return;
    }

    if (!_validatePasswordRules(newPassword)) {
      setState(() => _errorMessage = 'Пароль має містити мінімум 8 символів, 1 велику літеру і 1 цифру');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль успішно змінено')),
        );
        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.message?.toLowerCase().contains('auth credential is incorrect') == true) {
        setState(() => _errorMessage = 'Неправильний старий пароль');
      } else if (e.code == 'weak-password') {
        setState(() => _errorMessage = 'Новий пароль занадто слабкий');
      } else if (e.code == 'requires-recent-login') {
        setState(() => _errorMessage = 'Для зміни пароля потрібно увійти знову');
      } else {
        setState(() => _errorMessage = 'Помилка: ${e.message}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Не вдалося змінити пароль: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

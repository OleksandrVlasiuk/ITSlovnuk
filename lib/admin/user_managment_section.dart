import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagmentSection extends StatefulWidget {
  const UserManagmentSection({super.key});

  @override
  State<UserManagmentSection> createState() => _UserManagmentSectionState();
}

class _UserManagmentSectionState extends State<UserManagmentSection> {
  String? roleFilter;

  @override
  Widget build(BuildContext context) {
    final usersQuery = FirebaseFirestore.instance.collection('users');
    final stream = roleFilter == null
        ? usersQuery.orderBy('createdAt', descending: true).snapshots()
        : usersQuery.where('role', isEqualTo: roleFilter).orderBy('createdAt', descending: true).snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DropdownButton<String?>(
                  dropdownColor: const Color(0xFF2B2B2B),
                  value: roleFilter,
                  hint: const Text('Фільтр за роллю', style: TextStyle(color: Colors.white)),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Усі ролі', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'user', child: Text('User', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'admin', child: Text('Admin', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (value) => setState(() => roleFilter = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;
                    final email = data['email'] ?? '—';
                    final role = data['role'] ?? 'user';
                    final createdAt = data['createdAt']?.toDate().toString().split(' ').first ?? '';

                    return Card(
                      color: const Color(0xFF2B2B2B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _editRoleDialog(user),
                        title: Text(email, style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Роль: $role\nСтворено: $createdAt', style: const TextStyle(color: Colors.white70)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteUser(user.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _editRoleDialog(DocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>;
    final currentRole = data['role'] ?? 'user';
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Редагувати роль для ${data['email']}'),
        content: DropdownButtonFormField<String>(
          value: selectedRole,
          items: const [
            DropdownMenuItem(value: 'user', child: Text('User')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (value) => selectedRole = value ?? currentRole,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () {
              if (selectedRole != currentRole) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Підтвердження'),
                    content: Text('Змінити роль користувача на "$selectedRole"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Скасувати'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // підтвердження
                          Navigator.pop(context); // редагування

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userDoc.id)
                              .update({'role': selectedRole});

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Роль змінено на "$selectedRole"')),
                            );
                          }
                        },
                        child: const Text('Підтвердити'),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Роль не змінено.')),
                );
              }
            },
            child: const Text('Оновити'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Видалити користувача'),
        content: const Text('Це остаточно видалить користувача з Firestore. Продовжити?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Користувача успішно видалено.')),
                );
              }
            },
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }
}
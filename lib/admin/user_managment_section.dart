//user_managment_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'user_moderation_filters.dart';

class UserManagmentSection extends StatefulWidget {
  const UserManagmentSection({super.key});

  @override
  State<UserManagmentSection> createState() => _UserManagmentSectionState();
}

class _UserManagmentSectionState extends State<UserManagmentSection> {
  Map<String, dynamic> _filters = {};
  final GlobalKey<UserModerationFiltersState> _filtersKey = GlobalKey();
  bool _filtersExpanded = false;

  bool isSameOrAfter(DateTime a, DateTime b) =>
      a.year > b.year ||
          (a.year == b.year && a.month > b.month) ||
          (a.year == b.year && a.month == b.month && a.day >= b.day);

  bool isSameOrBefore(DateTime a, DateTime b) =>
      a.year < b.year ||
          (a.year == b.year && a.month < b.month) ||
          (a.year == b.year && a.month == b.month && a.day <= b.day);

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Фільтри',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
                icon: Icon(
                  _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
                label: Text(
                  _filtersExpanded ? 'Згорнути' : 'Розгорнути',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                UserModerationFilters(
                  key: _filtersKey,
                  onChanged: (filters) => setState(() => _filters = filters),
                ),
              ],
            ),
            crossFadeState: _filtersExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const Divider(color: Colors.white38),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<QueryDocumentSnapshot> users = snapshot.data!.docs;

                // Пошук і фільтрація
                final emailQuery = _filters['email']?.toString().toLowerCase() ?? '';
                final roleFilter = _filters['role'];
                final DateTime? startDate = _filters['startDate'];
                final DateTime? endDate = _filters['endDate'];
                final sortDate = _filters['sortDate'];

                users = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final role = data['role'];
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  final matchesEmail = email.contains(emailQuery);
                  final matchesRole = roleFilter == null || role == roleFilter;
                  final matchesStart = startDate == null || (createdAt != null && isSameOrAfter(createdAt, startDate));
                  final matchesEnd = endDate == null || (createdAt != null && isSameOrBefore(createdAt, endDate));

                  return matchesEmail && matchesRole && matchesStart && matchesEnd;
                }).toList();


                // Сортування
                users.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aEmail = (aData['email'] ?? '').toString();
                  final bEmail = (bData['email'] ?? '').toString();

                  final aCreated = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  final bCreated = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);

                  if (sortDate == 'asc') return aCreated.compareTo(bCreated);
                  if (sortDate == 'desc') return bCreated.compareTo(aCreated);

                  return aEmail.compareTo(bEmail); // за замовчуванням за email
                });

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'Користувачів не знайдено',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;
                    final email = data['email'] ?? '—';
                    final role = data['role'] ?? 'user';
                    final createdAt = _formatDate(data['createdAt'] as Timestamp?);

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
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('users').doc(userDoc.id).update({'role': selectedRole});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Роль змінено на "$selectedRole"')),
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserStatisticsFilters extends StatefulWidget {
  final void Function(Map<String, dynamic>) onChanged;

  const UserStatisticsFilters({super.key, required this.onChanged});

  @override
  State<UserStatisticsFilters> createState() => _UserStatisticsFiltersState();
}

class _UserStatisticsFiltersState extends State<UserStatisticsFilters> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  String? _role;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
    _nicknameController.addListener(_onChanged);
  }

  void _onChanged() {
    widget.onChanged({
      'email': _emailController.text.trim().toLowerCase(),
      'nickname': _nicknameController.text.trim().toLowerCase(),
      'role': _role,
    });
  }

  void _clearFilters() {
    _emailController.clear();
    _nicknameController.clear();
    setState(() => _role = null);
    _onChanged();
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder:
      OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    labelText: 'Пошта',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    labelText: 'Нікнейм',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _role,
                  hint: const Text('Роль', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  dropdownColor: Colors.grey[900],
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  isExpanded: true,
                  decoration: _dropdownDecoration(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Усі')),
                    DropdownMenuItem(value: 'admin', child: Text('Адмін')),
                    DropdownMenuItem(value: 'user', child: Text('Користувач')),
                  ],
                  onChanged: (val) {
                    setState(() => _role = val);
                    _onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear, size: 18, color: Colors.white60),
              label: const Text(
                'Очистити фільтри',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

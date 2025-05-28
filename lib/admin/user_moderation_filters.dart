// user_moderation_filters.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserModerationFilters extends StatefulWidget {
  final void Function(Map<String, dynamic>) onChanged;

  const UserModerationFilters({super.key, required this.onChanged});

  @override
  State<UserModerationFilters> createState() => UserModerationFiltersState();
}

class UserModerationFiltersState extends State<UserModerationFilters> {
  final TextEditingController _emailController = TextEditingController();
  String? _role;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _sortDate;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
  }

  void _onChanged() {
    widget.onChanged({
      'email': _emailController.text.trim().toLowerCase(),
      'role': _role,
      'startDate': _startDate,
      'endDate': _endDate,
      'sortDate': _sortDate,
    });
  }

  void _clearFilters() {
    _emailController.clear();
    setState(() {
      _role = null;
      _startDate = null;
      _endDate = null;
      _sortDate = null;
    });
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

  Widget _buildDateSelector(String label, DateTime? date, void Function(DateTime?) onSelected) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onSelected(picked);
          _onChanged();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          date != null ? DateFormat('dd.MM.yyyy').format(date) : label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildDateSelector('Дата від', _startDate, (val) => setState(() => _startDate = val))),
              const SizedBox(width: 6),
              Expanded(child: _buildDateSelector('Дата до', _endDate, (val) => setState(() => _endDate = val))),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortDate,
                  hint: const Text('Сортування', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  dropdownColor: Colors.grey[900],
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  isExpanded: true,
                  decoration: _dropdownDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'desc', child: Text('Спадання')),
                    DropdownMenuItem(value: 'asc', child: Text('Зростання')),
                  ],
                  onChanged: (val) {
                    setState(() => _sortDate = val);
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
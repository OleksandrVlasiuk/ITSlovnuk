//deck_moderation_filters.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeckModerationFilters extends StatefulWidget {
  final String filter;
  final void Function(Map<String, dynamic>) onChanged;

  DeckModerationFilters({
    Key? key, // <- дозволяємо передати зовнішній key (типу GlobalKey<_DeckModerationFiltersState>)
    required this.filter,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<DeckModerationFilters> createState() => DeckModerationFiltersState();
}



class DeckModerationFiltersState extends State<DeckModerationFilters> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String? _thirdFilter;
  String? _sortDateFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _startPublishedDate;
  DateTime? _endPublishedDate;
  bool _isExpanded = false;
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
    _titleController.addListener(_onChanged);
  }

  void _onChanged() {
    widget.onChanged({
      'email': _emailController.text.trim().toLowerCase(),
      'title': _titleController.text.trim().toLowerCase(),
      'third': _thirdFilter?.isEmpty == true ? null : _thirdFilter,
      'sortDate': _sortDateFilter,
      'startDate': widget.filter == 'rejected' || widget.filter == 'pending'
          ? _startDate
          : _startPublishedDate,
      'endDate': widget.filter == 'rejected' || widget.filter == 'pending'
          ? _endDate
          : _endPublishedDate,
      'role': widget.filter == 'allPublic' || widget.filter == 'hidden' ? _roleFilter : null,
    });
  }

  void _clearFilters() {
    _emailController.clear();
    _titleController.clear();
    setState(() {
      _thirdFilter = null;
      _sortDateFilter = null;
      _startDate = null;
      _endDate = null;
      _startPublishedDate = null;
      _endPublishedDate = null;
      _roleFilter = null;
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
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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

  Widget _buildFirstRow() {
    return Row(
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
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              labelText: 'Назва колоди',
              labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(flex: 3, child: _buildThirdFilterCompact()),
        const SizedBox(width: 4),
        if (_isExpanded)
          IconButton(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear, size: 18, color: Colors.white60),
            tooltip: 'Очистити фільтри',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        if (widget.filter == 'allPublic' || widget.filter == 'hidden')
          const SizedBox(width: 6),
        if (widget.filter == 'allPublic' || widget.filter == 'hidden')
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _roleFilter,
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
                setState(() => _roleFilter = val);
                _onChanged();
              },
            ),
          ),

      ],
    );
  }

  Widget _buildThirdFilterCompact() {
    List<DropdownMenuItem<String>> buildItems(List<Map<String, String>> entries) {
      return entries.map((e) => DropdownMenuItem(
        value: e['value'],
        child: Text(e['label']!, style: const TextStyle(fontSize: 12)),
      )).toList();
    }

    switch (widget.filter) {
      case 'pending':
      case 'rejected':
        return DropdownButtonFormField<String>(
          value: _thirdFilter,
          hint: const Text('Тип подачі', style: TextStyle(color: Colors.white70, fontSize: 12)),
          dropdownColor: Colors.grey[900],
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          isExpanded: true,
          decoration: _dropdownDecoration(),
          items: buildItems([
            {'value': '', 'label': 'Усі'},
            {'value': 'Оновлення публікації', 'label': 'Оновлення'},
            {'value': 'Первинна публікація', 'label': 'Публікація'},
            {'value': 'Запит на вічну публікацію', 'label': 'Назавжди'},
          ]),
          onChanged: (val) {
            setState(() => _thirdFilter = val == '' ? null : val);
            _onChanged();
          },
        );

      case 'allPublic':
      case 'hidden':
        return DropdownButtonFormField<String>(
          value: _thirdFilter,
          hint: const Text('Тип публікації', style: TextStyle(color: Colors.white70, fontSize: 12)),
          dropdownColor: Colors.grey[900],
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          isExpanded: true,
          decoration: _dropdownDecoration(),
          items: buildItems([
            {'value': '', 'label': 'Усі'},
            {'value': 'temporary', 'label': 'Тимчасова'},
            {'value': 'permanent', 'label': 'Вічна'},
          ]),
          onChanged: (val) {
            setState(() => _thirdFilter = val == '' ? null : val);
            _onChanged();
          },
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildSecondRow() {
    if (widget.filter == 'rejected' || widget.filter == 'pending') {
      return Row(
        children: [
          Expanded(child: _buildDateSelector('Дата від', _startDate, (val) => setState(() => _startDate = val))),
          const SizedBox(width: 6),
          Expanded(child: _buildDateSelector('Дата до', _endDate, (val) => setState(() => _endDate = val))),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortDateFilter,
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
                setState(() => _sortDateFilter = val);
                _onChanged();
              },
            ),
          ),
        ],
      );
    } else if (widget.filter == 'allPublic' || widget.filter == 'hidden') {
      return Row(
        children: [
          Expanded(child: _buildDateSelector('Дата від', _startPublishedDate, (val) => setState(() => _startPublishedDate = val))),
          const SizedBox(width: 6),
          Expanded(child: _buildDateSelector('Дата до', _endPublishedDate, (val) => setState(() => _endPublishedDate = val))),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortDateFilter,
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
                setState(() => _sortDateFilter = val);
                _onChanged();
              },
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          _buildFirstRow(),
          const SizedBox(height: 4),
          _buildSecondRow(),
        ],
      ),
    );
  }

  void clearAll() {
    _emailController.clear();
    _titleController.clear();
    setState(() {
      _thirdFilter = null;
      _sortDateFilter = null;
      _startDate = null;
      _endDate = null;
      _startPublishedDate = null;
      _endPublishedDate = null;
      _roleFilter = null;
    });
    _onChanged();
  }


}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanFilters extends StatefulWidget {
  final String titleSearch;
  final String emailSearch;
  final String sort;
  final bool isRecommendedTab;
  final void Function({
  String? title,
  String? email,
  String? sort,
  DateTime? startDate,
  DateTime? endDate,
  int? minCards,
  int? maxCards,
  }) onChanged;

  const PlanFilters({
    super.key,
    required this.titleSearch,
    required this.emailSearch,
    required this.sort,
    required this.isRecommendedTab,
    required this.onChanged,
  });

  @override
  State<PlanFilters> createState() => _PlanFiltersState();
}

class _PlanFiltersState extends State<PlanFilters> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _minCardsController = TextEditingController();
  final TextEditingController _maxCardsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _sort;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.titleSearch;
    _emailController.text = widget.emailSearch;
    _sort = widget.sort;
    _titleController.addListener(_onChanged);
    _emailController.addListener(_onChanged);
    _minCardsController.addListener(_onChanged);
    _maxCardsController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emailController.dispose();
    _minCardsController.dispose();
    _maxCardsController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    widget.onChanged(
      title: _titleController.text,
      email: _emailController.text,
      sort: _sort,
      startDate: _startDate,
      endDate: _endDate,
      minCards: int.tryParse(_minCardsController.text),
      maxCards: int.tryParse(_maxCardsController.text),
    );
  }

  void _resetFilters() {
    _titleController.clear();
    _emailController.clear();
    _minCardsController.clear();
    _maxCardsController.clear();
    setState(() {
      _sort = 'published_desc';
      _startDate = null;
      _endDate = null;
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
        if (picked != null && mounted) {
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white),
              label: Text(
                _isExpanded ? 'Згорнути фільтри' : 'Розгорнути фільтри',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            if (_isExpanded)
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Очистити', style: TextStyle(color: Colors.white70)),
              ),
          ],
        ),
        if (_isExpanded) ...[
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    hintText: 'Пошук по назві...',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
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
              if (!widget.isRecommendedTab) ...[
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      hintText: 'Пошук по email...',
                      hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
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
              ]
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDateSelector('Дата від', _startDate, (val) => setState(() => _startDate = val))),
              const SizedBox(width: 6),
              Expanded(child: _buildDateSelector('Дата до', _endDate, (val) => setState(() => _endDate = val))),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _minCardsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dropdownDecoration().copyWith(hintText: 'Мін. карток', hintStyle: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _maxCardsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dropdownDecoration().copyWith(hintText: 'Макс. карток', hintStyle: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sort,
                  hint: const Text('Сортування', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  dropdownColor: Colors.grey[900],
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  isExpanded: true,
                  decoration: _dropdownDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'published_desc', child: Text('Нове')),
                    DropdownMenuItem(value: 'added_desc', child: Text('Популярне')),
                    DropdownMenuItem(value: 'title_asc', child: Text('Назва A-Z')),
                  ],
                  onChanged: (val) {
                    setState(() => _sort = val);
                    _onChanged();
                  },
                ),
              ),
            ],
          )
        ]
      ],
    );
  }
}
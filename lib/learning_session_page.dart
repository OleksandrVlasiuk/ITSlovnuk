// Оновлений LearningSessionPage з передачею deckId у статистику

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:it_english_app_clean/services/statistics_service.dart';

class LearningSessionPage extends StatefulWidget {
  final String deckId;
  final String deckTitle;
  final int sessionCount;

  const LearningSessionPage({
    super.key,
    required this.deckId,
    required this.deckTitle,
    required this.sessionCount,
  });

  @override
  State<LearningSessionPage> createState() => _LearningSessionPageState();
}

class _LearningSessionPageState extends State<LearningSessionPage> {
  List<Map<String, dynamic>> _cards = [];
  int _currentIndex = 0;
  bool _showBack = false;
  bool _isLoading = true;
  bool _sessionFinished = false;
  final List<Map<String, String>> _summary = [];

  @override
  void initState() {
    super.initState();
    _loadSessionCards();
  }

  Future<void> _loadSessionCards() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('decks')
        .doc(widget.deckId)
        .collection('cards')
        .get();

    List<Map<String, dynamic>> allCards = snapshot.docs.map((doc) {
      return {
        'term': doc['term'],
        'definitionUkr': doc['definitionUkr'],
      };
    }).toList();

    allCards.shuffle(Random());
    final sessionCards = allCards.take(widget.sessionCount.clamp(0, allCards.length)).toList();

    setState(() {
      _cards = sessionCards;
      _isLoading = false;
    });
  }

  void _flipCard() {
    setState(() {
      _showBack = true;
    });
  }

  void _nextCard() {
    _summary.add({
      'term': _cards[_currentIndex]['term'],
      'definitionUkr': _cards[_currentIndex]['definitionUkr'],
    });

    if (_currentIndex + 1 < _cards.length) {
      setState(() {
        _currentIndex++;
        _showBack = false;
      });
    } else {
      setState(() {
        _sessionFinished = true;
      });
    }
  }

  void _finishSessionEarly() {
    final viewedCards = <Map<String, String>>[];

    for (int i = 0; i < _currentIndex; i++) {
      viewedCards.add({
        'term': _cards[i]['term'],
        'definitionUkr': _cards[i]['definitionUkr'],
      });
    }

    if (_showBack && _currentIndex < _cards.length) {
      viewedCards.add({
        'term': _cards[_currentIndex]['term'],
        'definitionUkr': _cards[_currentIndex]['definitionUkr'],
      });
    }

    if (viewedCards.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _summary.clear();
      _summary.addAll(viewedCards);
      _sessionFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Перегляд', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessionFinished
          ? _buildSummary()
          : _buildCardView(),
    );
  }

  Widget _buildCardView() {
    final card = _cards[_currentIndex];
    return GestureDetector(
      onTap: _showBack ? _nextCard : _flipCard,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              widget.deckTitle,
              style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Center(
              child: Text(
                card['term'],
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            if (_showBack) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white38),
              const SizedBox(height: 20),
              Text(
                card['definitionUkr'],
                style: const TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            if (!_showBack)
              ElevatedButton(
                onPressed: _flipCard,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                child: const Text('Перевернути'),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: _finishSessionEarly,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Завершити'),
                  ),
                  ElevatedButton(
                    onPressed: _nextCard,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    child: const Text('Продовжити'),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.deckTitle,
            style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Підсумок :', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 12),
          if (_summary.isEmpty)
            const Text(
              'Жодної картки не переглянуто.',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            )
          else
            ..._summary.map((entry) => Text(
              '${entry['term']} - ${entry['definitionUkr']}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            )),
          const Spacer(),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                if (_summary.isNotEmpty) {
                  await StatisticsService().updateStatistics(
                    viewedCount: _summary.length,
                    deckId: widget.deckId,
                  );
                }
                if (mounted) Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              child: const Text('Завершити'),
            ),
          ),
        ],
      ),
    );
  }
}
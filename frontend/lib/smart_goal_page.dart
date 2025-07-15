

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SmartGoalPage extends StatefulWidget {
  const SmartGoalPage({super.key});

  @override
  State<SmartGoalPage> createState() => _SmartGoalPageState();
}

class _SmartGoalPageState extends State<SmartGoalPage> {
  String? _selectedMealGoal;
  String? _selectedCookingTime;
  String? _selectedCost;
  final TextEditingController _includeIngredientsController = TextEditingController();
  final TextEditingController _availableIngredientsController = TextEditingController();
  final TextEditingController _preferenceKeywordsController = TextEditingController();
  final TextEditingController _avoidKeywordsController = TextEditingController();

  final List<String> _mealGoals = ['다이어트', '벌크업', '건강 유지', '맛 중심', '초절약', '아무거나'];
  final List<String> _cookingTimes = ['15분', '30분', '1시간', '시간 무관'];
  final List<String> _costs = ['3,000원 이하', '5,000원 내외', '7,000원 이상'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. 식사 목표 선택'),
            _buildChoiceChips(_mealGoals, _selectedMealGoal, (selected) {
              setState(() => _selectedMealGoal = selected);
            }),
            const SizedBox(height: 24),
            _buildSectionTitle('2. 자원 제약 설정'),
            _buildSubSectionTitle('조리 시간'),
            _buildChoiceChips(_cookingTimes, _selectedCookingTime, (selected) {
              setState(() => _selectedCookingTime = selected);
            }),
            _buildSubSectionTitle('비용'),
            _buildChoiceChips(_costs, _selectedCost, (selected) {
              setState(() => _selectedCost = selected);
            }),
            const SizedBox(height: 24),
            _buildSectionTitle('3. 재료 및 선호도'),
            _buildSubSectionTitle('반드시 포함할 재료 (쉼표로 구분)'),
            TextField(
              controller: _includeIngredientsController,
              decoration: const InputDecoration(
                hintText: '예: 닭가슴살, 계란',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSubSectionTitle('보유 중인 재료 (쉼표로 구분)'),
            TextField(
              controller: _availableIngredientsController,
              decoration: const InputDecoration(
                hintText: '예: 양파, 마늘, 간장',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSubSectionTitle('선호 키워드 (쉼표로 구분)'),
            TextField(
              controller: _preferenceKeywordsController,
              decoration: const InputDecoration(
                hintText: '예: 매콤한, 국물',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSubSectionTitle('기피 키워드 (쉼표로 구분)'),
            TextField(
              controller: _avoidKeywordsController,
              decoration: const InputDecoration(
                hintText: '예: 오이, 가지',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  _getRecommendation();
                },
                child: const Text('최적의 한 끼 추천받기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildChoiceChips(List<String> items, String? selectedItem, ValueChanged<String> onSelected) {
    return Wrap(
      spacing: 8.0,
      children: items.map((item) {
        return ChoiceChip(
          label: Text(item),
          selected: selectedItem == item,
          onSelected: (selected) {
            onSelected(item);
          },
        );
      }).toList(),
    );
  }

  int? _parseCookingTime(String? time) {
    if (time == null) return null;
    if (time.contains('15분')) return 15;
    if (time.contains('30분')) return 30;
    if (time.contains('1시간')) return 60;
    return null;
  }

  int? _parseCost(String? cost) {
    if (cost == null) return null;
    if (cost.contains('3,000원 이하')) return 3000;
    if (cost.contains('5,000원 내외')) return 5000;
    if (cost.contains('7,000원 이상')) return 7000;
    return null;
  }

  List<String> _parseCommaSeparatedText(TextEditingController controller) {
    return controller.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _getRecommendation() async {
    final cookingTimeValue = _parseCookingTime(_selectedCookingTime);
    final costValue = _parseCost(_selectedCost);
    final includeIngredients = _parseCommaSeparatedText(_includeIngredientsController);
    final availableIngredients = _parseCommaSeparatedText(_availableIngredientsController);
    final preferenceKeywords = _parseCommaSeparatedText(_preferenceKeywordsController);
    final avoidKeywords = _parseCommaSeparatedText(_avoidKeywordsController);

    final requestBody = jsonEncode({
      'meal_goal': _selectedMealGoal,
      'cooking_time': cookingTimeValue,
      'cost': costValue,
      'include_ingredients': includeIngredients,
      'available_ingredients': availableIngredients,
      'preference_keywords': preferenceKeywords,
      'avoid_keywords': avoidKeywords,
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/recommend'), // 백엔드 서버 주소
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final recipe = jsonDecode(response.body);
        _showRecommendationDialog(recipe);
      } else if (response.statusCode == 404) {
        final error = jsonDecode(response.body);
        _showErrorDialog(error['detail'] ?? '조건에 맞는 레시피를 찾을 수 없습니다.');
      } else {
        _showErrorDialog('레시피 추천 중 오류가 발생했습니다: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('네트워크 오류가 발생했습니다: $e');
    }
  }

  void _showRecommendationDialog(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(recipe['name'] ?? '추천 레시피'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('설명: ${recipe['description'] ?? '-'}'),
                const SizedBox(height: 8),
                Text('재료: ${ (recipe['ingredients'] as List).join(', ')}'),
                const SizedBox(height: 8),
                Text('조리 시간: ${recipe['cooking_time'] ?? '-'}분'),
                const SizedBox(height: 8),
                Text('예상 비용: ${recipe['cost'] ?? '-'}원'),
                const SizedBox(height: 8),
                Text('태그: ${ (recipe['tags'] as List).join(', ')}'),
                const SizedBox(height: 16),
                Text('조리법:\n${ (recipe['instructions'] as List).join('\n')}'),
                const SizedBox(height: 16),
                if (recipe['source_url'] != null)
                  InkWell(
                    child: Text('원본 출처: ${recipe['source_url']}', style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                    onTap: () => { /* TODO: Open URL */ },
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('오류'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _includeIngredientsController.dispose();
    _availableIngredientsController.dispose();
    _preferenceKeywordsController.dispose();
    _avoidKeywordsController.dispose();
    super.dispose();
  }
}

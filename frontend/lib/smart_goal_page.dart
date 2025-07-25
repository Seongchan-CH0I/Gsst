import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class SmartGoalPage extends StatefulWidget {
  const SmartGoalPage({super.key});

  @override
  State<SmartGoalPage> createState() => _SmartGoalPageState();
}

class _SmartGoalPageState extends State<SmartGoalPage> {
  // --- 상태 변수 ---
  String? _selectedMealGoal;
  String? _selectedCookingTime;
  String? _selectedCost;
  final TextEditingController _includeIngredientsController = TextEditingController();
  final TextEditingController _availableIngredientsController = TextEditingController();
  final TextEditingController _preferenceKeywordsController = TextEditingController();
  final TextEditingController _avoidKeywordsController = TextEditingController();

  bool _isLoading = false;
  List<List<dynamic>> _recipeHistory = [];
  int _historyIndex = -1;

  // --- UI 데이터 ---
  final List<String> _mealGoals = ['다이어트', '벌크업', '건강 유지', '맛 중심', '초절약', '아무거나'];
  final List<String> _cookingTimes = ['15분', '30분', '1시간', '시간 무관'];
  final List<String> _costs = ['5,000원 이하', '10,000원 내외', '10,000원 이상'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
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
                _buildTextField(_includeIngredientsController, '반드시 포함할 재료 (쉼표로 구분)', '예: 닭가슴살, 계란'),
                _buildTextField(_availableIngredientsController, '보유 중인 재료 (쉼표로 구분)', '예: 양파, 마늘, 간장'),
                _buildTextField(_preferenceKeywordsController, '선호 키워드 (쉼표로 구분)', '예: 매콤한, 국물'),
                _buildTextField(_avoidKeywordsController, '기피 키워드 (쉼표로 구분)', '예: 오이, 가지'),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isLoading ? null : _getRecommendation,
                    child: const Text('최적의 한 끼 추천받기'),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("최고의 레시피를 찾고 있어요...", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 위젯 빌더 헬퍼 ---

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );

  Widget _buildSubSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      );

  Widget _buildChoiceChips(List<String> items, String? selectedItem, ValueChanged<String> onSelected) => Wrap(
        spacing: 8.0,
        children: items.map((item) => ChoiceChip(
          label: Text(item),
          selected: selectedItem == item,
          onSelected: (selected) => onSelected(item),
        )).toList(),
      );

  Widget _buildTextField(TextEditingController controller, String label, String hint) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubSectionTitle(label),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    ),
  );

  // --- 데이터 파싱 헬퍼 ---

  int? _parseCookingTime(String? time) {
    if (time == null) return null;
    if (time.contains('15분')) return 15;
    if (time.contains('30분')) return 30;
    if (time.contains('1시간')) return 60;
    return null;
  }

  int? _parseCost(String? cost) {
    if (cost == null) return null;
    if (cost.contains('5,000원 이하')) return 5000;
    if (cost.contains('10,000원 내외')) return 10000;
    if (cost.contains('10,000원 이상')) return 15000; // 임의의 높은 값
    return null;
  }

  List<String> _parseCommaSeparatedText(TextEditingController controller) =>
      controller.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  // --- 핵심 로직: API 호출 및 다이얼로그 표시 ---

  Future<void> _getRecommendation() async {
    setState(() => _isLoading = true);

    final requestBody = jsonEncode({
      'meal_goal': _selectedMealGoal,
      'cooking_time': _parseCookingTime(_selectedCookingTime),
      'cost': _parseCost(_selectedCost),
      'include_ingredients': _parseCommaSeparatedText(_includeIngredientsController),
      'available_ingredients': _parseCommaSeparatedText(_availableIngredientsController),
      'preference_keywords': _parseCommaSeparatedText(_preferenceKeywordsController),
      'avoid_keywords': _parseCommaSeparatedText(_avoidKeywordsController),
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/recipes/recommend'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBody,
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // UTF-8로 디코딩하여 한글 깨짐 방지
        final List<dynamic> recipes = jsonDecode(utf8.decode(response.bodyBytes));
        if (recipes.isNotEmpty) {
          setState(() {
            // 현재 인덱스 이후의 모든 기록을 삭제하고 새로운 결과를 추가
            if (_historyIndex < _recipeHistory.length - 1) {
              _recipeHistory.removeRange(_historyIndex + 1, _recipeHistory.length);
            }
            _recipeHistory.add(recipes);
            _historyIndex = _recipeHistory.length - 1; // 인덱스를 마지막으로 이동
          });
          _showRecommendationDialog();
        } else {
          _showErrorDialog('추천할 레시피를 찾지 못했습니다.');
        }
      } else {
         final error = jsonDecode(utf8.decode(response.bodyBytes));
        _showErrorDialog(error['detail'] ?? '레시피 추천 중 오류가 발생했습니다: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('오류가 발생했습니다: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRecommendationDialog() {
    int currentRecipeIndex = 0; // 다이얼로그 내에서만 사용하는 인덱스

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // 다이얼로그 내에서 상태를 관리하기 위해 StatefulBuilder 사용
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final recipes = _recipeHistory[_historyIndex];
            final recipe = recipes[currentRecipeIndex];
            final isFirstRecipe = currentRecipeIndex == 0;
            final isLastRecipe = currentRecipeIndex == recipes.length - 1;

            return AlertDialog(
              title: Stack(
                alignment: Alignment.center,
                children: [
                  Text("추천 레시피 (${_historyIndex + 1}페이지, ${currentRecipeIndex + 1}/${recipes.length})"),
                  Positioned(
                    right: -10.0,
                    top: -10.0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(recipe['name'] ?? '이름 없음', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Divider(),
                    Text('설명: ${recipe['description'] ?? '-'}'),
                    const SizedBox(height: 8),
                    Text('재료: ${(recipe['ingredients'] as List).join(', ')}'),
                    const SizedBox(height: 8),
                    Text('조리 시간: ${recipe['cooking_time'] ?? '-'}분'),
                    const SizedBox(height: 8),
                    Text('예상 비용: ${recipe['cost'] ?? '-'}원'),
                    const SizedBox(height: 8),
                    Text('태그: ${(recipe['tags'] as List).join(', ')}'),
                    const SizedBox(height: 16),
                    const Text('조리법:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...(recipe['instructions'] as List).map((item) => Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(item),
                    )),
                    const SizedBox(height: 16),
                    if (recipe['source_url'] != null)
                      InkWell(
                        child: Text('원본 레시피 보기', style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                        onTap: () => _launchURL(recipe['source_url']),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 이전 기록 (<<)
                        IconButton(
                          icon: const Icon(Icons.fast_rewind),
                          tooltip: '이전 기록',
                          onPressed: _historyIndex > 0 ? () {
                            Navigator.of(context).pop();
                            setState(() => _historyIndex--);
                            _showRecommendationDialog();
                          } : null, // 비활성화
                        ),
                        // 이전 레시피 (<)
                        IconButton(
                          icon: const Icon(Icons.navigate_before),
                          tooltip: '이전 레시피',
                          onPressed: !isFirstRecipe ? () => setDialogState(() => currentRecipeIndex--) : null,
                        ),
                        // 다음 레시피 (>)
                        IconButton(
                          icon: const Icon(Icons.navigate_next),
                          tooltip: '다음 레시피',
                          onPressed: !isLastRecipe ? () => setDialogState(() => currentRecipeIndex++) : null,
                        ),
                        // 다음 기록 (>>)
                        IconButton(
                          icon: const Icon(Icons.fast_forward),
                          tooltip: '다음 기록',
                          onPressed: _historyIndex < _recipeHistory.length - 1 ? () {
                            Navigator.of(context).pop();
                            setState(() => _historyIndex++);
                            _showRecommendationDialog();
                          } : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('새 추천 받기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        ),
                        onPressed: _isLoading ? null : () {
                          Navigator.of(context).pop();
                          _getRecommendation();
                        },
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      _showErrorDialog('$urlString 링크를 열 수 없습니다.');
    }
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
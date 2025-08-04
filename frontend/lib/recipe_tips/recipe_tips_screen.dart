import 'package:flutter/material.dart';
import 'package:frontend/recipe_tips/recipe_tip_detail_screen.dart';
import 'package:frontend/recipe_tips/recipe_tip_form_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeTipsScreen extends StatefulWidget {
  @override
  _RecipeTipsScreenState createState() => _RecipeTipsScreenState();
}

class _RecipeTipsScreenState extends State<RecipeTipsScreen> {
  List<dynamic> _tips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTips();
  }

  Future<void> _fetchTips() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/tips/'),
      headers: {'Cache-Control': 'no-cache'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> tips = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        _tips = tips;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToForm() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => RecipeTipFormScreen()),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      _fetchTips();
    }
  }

  void _navigateToDetail(int tipId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeTipDetailScreen(tipId: tipId),
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      _fetchTips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('레시피 팁'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTips,
              child: ListView.builder(
                itemCount: _tips.length,
                itemBuilder: (context, index) {
                  final tip = _tips[index];
                  final owner = tip['owner'] ?? {};
                  return ListTile(
                    title: Text(tip['title'] ?? ''),
                    subtitle: Text('작성자: ${owner['name'] ?? '알 수 없음'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      _navigateToDetail(tip['id']);
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToForm,
        child: Icon(Icons.add),
        tooltip: '새 팁 작성',
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/recipe_tips/recipe_tip_form_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeTipDetailScreen extends StatefulWidget {
  final int tipId;

  RecipeTipDetailScreen({required this.tipId});

  @override
  _RecipeTipDetailScreenState createState() => _RecipeTipDetailScreenState();
}

class _RecipeTipDetailScreenState extends State<RecipeTipDetailScreen> {
  late Future<Map<String, dynamic>> _tipFuture;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tipFuture = _fetchTip();
  }

  Future<Map<String, dynamic>> _fetchTip() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/tips/${widget.tipId}'));

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load tip');
    }
  }

  Future<void> _deleteTip() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final response = await http.delete(
      Uri.parse('http://127.0.0.1:8000/api/tips/${widget.tipId}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제에 실패했습니다. 권한이 없거나 오류가 발생했습니다.')),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('팁 삭제'),
          content: Text('정말로 이 팁을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTip();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditScreen(Map<String, dynamic> tip) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeTipFormScreen(tip: tip),
      ),
    );

    if (result == true) {
      setState(() {
        _tipFuture = _fetchTip();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('팁 상세 보기'),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _tipFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _navigateToEditScreen(snapshot.data!);
                  },
                );
              }
              return Container();
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _showDeleteConfirmationDialog,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _tipFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("데이터를 불러오는 데 실패했습니다."));
          } else if (snapshot.hasData) {
            final tip = snapshot.data!;
            final owner = tip['owner'] ?? {};
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip['title'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '작성자: ${owner['name'] ?? '알 수 없음'} | 작성일: ${tip['created_at']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(tip['content'] ?? ''),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text("데이터가 없습니다."));
          }
        },
      ),
    );
  }
}

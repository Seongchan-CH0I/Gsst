import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeTipFormScreen extends StatefulWidget {
  final Map<String, dynamic>? tip;

  RecipeTipFormScreen({this.tip});

  @override
  _RecipeTipFormScreenState createState() => _RecipeTipFormScreenState();
}

class _RecipeTipFormScreenState extends State<RecipeTipFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _storage = const FlutterSecureStorage();
  bool _isSubmitting = false;
  bool get _isEditing => widget.tip != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tip?['title']);
    _contentController = TextEditingController(text: widget.tip?['content']);
  }

  Future<void> _submitTip() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        // Handle not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다.')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final url = _isEditing
          ? 'http://127.0.0.1:8000/api/tips/${widget.tip!['id']}'
          : 'http://127.0.0.1:8000/api/tips/';

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final body = json.encode({
        'title': _titleController.text,
        'content': _contentController.text,
      });

      final response = _isEditing
          ? await http.put(Uri.parse(url), headers: headers, body: body)
          : await http.post(Uri.parse(url), headers: headers, body: body);

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_isEditing ? '수정' : '등록'}에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '레시피 팁 수정' : '새 레시피 팁 작성'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '제목'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력하세요.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(labelText: '내용'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '내용을 입력하세요.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              _isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitTip,
                      child: Text(_isEditing ? '수정하기' : '등록하기'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

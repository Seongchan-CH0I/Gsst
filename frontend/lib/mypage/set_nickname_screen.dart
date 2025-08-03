import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SetNicknameScreen extends StatefulWidget {
  const SetNicknameScreen({Key? key}) : super(key: key);

  @override
  _SetNicknameScreenState createState() => _SetNicknameScreenState();
}

class _SetNicknameScreenState extends State<SetNicknameScreen> {
  //============================================================================
  // 1. State Variables
  //============================================================================
  final _nicknameController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  //============================================================================
  // 2. Logic Methods
  //============================================================================
  Future<void> _setNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _showErrorDialog('닉네임을 입력해주세요.');
      return;
    }

    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        _showErrorDialog('로그인 정보가 없습니다. 다시 로그인해주세요.');
        return;
      }

      final response = await http.put(
        Uri.parse('http://localhost:8000/auth/me/nickname'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'name': nickname}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임이 성공적으로 설정되었습니다.')),
        );
        // 닉네임 설정이 완료되었으므로, 이전 화면으로 돌아가 상태를 갱신합니다.
        // 이 pop은 LoggedOutView에게 로그인 성공 신호를 보냅니다.
        Navigator.of(context).pop(true);
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        _showErrorDialog('닉네임 설정 실패: ${errorData['detail']}');
      }
    } catch (error) {
      _showErrorDialog('닉네임 설정 오류: $error');
    }
  }

  //============================================================================
  // 3. UI Helper Methods
  //============================================================================
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  //============================================================================
  // 4. Widget Build Method
  //============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('닉네임 설정'),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '서비스 이용을 위해 닉네임을 설정해주세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _setNickname,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('닉네임 설정 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

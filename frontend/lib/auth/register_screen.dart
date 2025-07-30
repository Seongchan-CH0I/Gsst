import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  //============================================================================
  // 1. State Variables
  //============================================================================
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  //============================================================================
  // 2. Logic Methods
  //============================================================================

  /// 입력된 정보로 백엔드에 회원가입을 요청합니다.
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:8000/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 201) {
          // 회원가입 성공
          if (!mounted) return; // 위젯이 여전히 마운트 상태인지 확인
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입에 성공했습니다. 로그인해주세요.')),
          );
          Navigator.of(context).pop(); // 로그인 화면으로 돌아가기
        } else {
          // 서버에서 보낸 에러 메시지 표시
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          _showErrorDialog('회원가입 실패: ${errorData['detail']}');
        }
      } catch (error) {
        _showErrorDialog('회원가입 오류: $error');
      }
    }
  }

  //============================================================================
  // 3. UI Helper Methods
  //============================================================================

  /// 에러 메시지를 표시하는 다이얼로그를 띄웁니다.
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
        title: const Text('회원가입'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '계정을 생성하세요',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '이메일을 입력해주세요.';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return '유효한 이메일 형식이 아닙니다.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('가입하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
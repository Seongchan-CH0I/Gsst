import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/auth/register_screen.dart';
import 'package:frontend/mypage/set_nickname_screen.dart'; // 닉네임 설정 화면 import
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //============================================================================
  // 1. State Variables
  //============================================================================
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  //============================================================================
  // 2. Logic Methods (Login, Navigation, etc.)
  //============================================================================

  /// 로그인 성공 후 닉네임 설정 여부에 따라 화면을 이동시키는 헬퍼 함수
  void _handleLoginSuccess(Map<String, dynamic> tokenData) async {
    await _storage.write(key: 'access_token', value: tokenData['access_token']);
    if (!mounted) return;

    if (tokenData['nickname_required'] == true) {
      // 닉네임 설정이 필요한 경우
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SetNicknameScreen()),
      );
    } else {
      // 닉네임 설정이 필요 없는 경우 (기존 사용자)
      Navigator.of(context).pop(true); // 성공 시 true 반환
    }
  }

  /// 일반 이메일/비밀번호로 로그인을 시도합니다.
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:8000/auth/login'),
          body: {
            'username': _emailController.text,
            'password': _passwordController.text,
          },
        );

        if (response.statusCode == 200) {
          final tokenData = jsonDecode(response.body);
          _handleLoginSuccess(tokenData);
        } else {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          _showErrorDialog('로그인 실패: ${errorData['detail']}');
        }
      } catch (error) {
        _showErrorDialog('로그인 오류: $error');
      }
    }
  }

  /// 카카오 SDK를 사용하여 소셜 로그인을 시도합니다.
  Future<void> _loginWithKakao() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
      final response = await http.post(
        Uri.parse('http://localhost:8000/auth/login/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': token.accessToken}),
      );

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        _handleLoginSuccess(tokenData);
      } else {
        _showErrorDialog('카카오 로그인 실패: ${response.body}');
      }
    } catch (error) {
      _showErrorDialog('카카오 로그인 오류: $error');
    }
  }

  /// 백엔드의 개발용 로그인 엔드포인트를 호출합니다.
  void _developerLogin() async {
    final email = _emailController.text;
    if (email.isEmpty) {
      _showErrorDialog('개발자 로그인을 위한 이메일을 입력해주세요.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/auth/dev-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        // 개발자 로그인은 닉네임 설정 로직을 건너뛰고 바로 메인으로 이동
        await _storage.write(key: 'access_token', value: tokenData['access_token']);
        if (!mounted) return;
        Navigator.of(context).pop(true); // 성공 시 true 반환
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        _showErrorDialog('개발자 로그인 실패: ${errorData['detail']}');
      }
    } catch (error) {
      _showErrorDialog('개발자 로그인 오류: $error');
    }
  }

  /// 회원가입 화면으로 이동합니다.
  void _navigateToRegisterScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
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
        title: const Text('로그인'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '다시 오신 것을 환영합니다!',
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
                validator: (value) => (value == null || value.isEmpty) ? '이메일을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? '비밀번호를 입력해주세요.' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('로그인'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loginWithKakao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('카카오로 로그인'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _navigateToRegisterScreen,
                child: const Text('아직 계정이 없으신가요? 회원가입'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _developerLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('개발자로 로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
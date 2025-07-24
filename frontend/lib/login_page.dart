import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/kakao_login_webview.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final storage = new FlutterSecureStorage();

  // .env 파일이나 별도 설정 파일에서 가져오는 것을 권장합니다.
  final String KAKAO_CLIENT_ID = '807d6d35b8f02a32b45a2b425cffa38c';
  final String KAKAO_REDIRECT_URI = 'http://localhost:8080/auth/kakao/callback';

  void _login() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement email/password login logic
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');
    }
  }

  Future<void> _loginWithKakao() async {
    final kakaoLoginUrl = 'https://kauth.kakao.com/oauth/authorize?client_id=$KAKAO_CLIENT_ID&redirect_uri=$KAKAO_REDIRECT_URI&response_type=code';

    // 웹뷰를 띄우고, 결과(인가 코드)를 받음
    final authCode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KakaoLoginWebView(
          kakaoLoginUrl: kakaoLoginUrl,
          redirectUri: KAKAO_REDIRECT_URI,
        ),
      ),
    );

    if (authCode != null) {
      // 인가 코드를 백엔드로 전송하여 JWT 토큰 받기
      try {
        final response = await http.post(
          Uri.parse('http://localhost:8000/auth/login/kakao'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'code': authCode}),
        );

        if (response.statusCode == 200) {
          final tokenData = jsonDecode(response.body);
          await storage.write(key: 'access_token', value: tokenData['access_token']);
          
          // 로그인 성공 후, 이전 페이지(마이페이지)로 돌아가서 상태 갱신
          Navigator.of(context).pop(true); // true를 전달하여 로그인 성공을 알림
        } else {
          _showErrorDialog('카카오 로그인 실패: ${response.body}');
        }
      } catch (e) {
        _showErrorDialog('오류 발생: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('오류'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('확인'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '다시 오신 것을 환영합니다!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? '이메일을 입력해주세요.' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? '비밀번호를 입력해주세요.' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                child: Text('로그인'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loginWithKakao,
                child: Text('카카오로 로그인'),
                 style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to registration page
                },
                child: Text('아직 계정이 없으신가요? 회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
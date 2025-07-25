import 'package:frontend/login_page.dart';  
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final storage = new FlutterSecureStorage();
  String? userName;
  String? userEmail;
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        setState(() {
          isLoggedIn = false;
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:8000/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          userName = data['name'];
          userEmail = data['email'];
          isLoggedIn = true;
          isLoading = false;
        });
      } else {
        await storage.delete(key: 'access_token');
        setState(() {
          isLoggedIn = false;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );

    if (result == true) {
      setState(() {
        isLoading = true;
      });
      _checkLoginStatus();
    }
  }

  Future<void> _logout() async {
    try {
      // 카카오 SDK 로그아웃 (카카오 계정 세션 만료)
      await UserApi.instance.logout();
      print('카카오 로그아웃 성공');
    } catch (error) {
      print('카카오 로그아웃 실패: $error');
    }
    // 앱의 토큰 삭제
    await storage.delete(key: 'access_token');
    setState(() {
      isLoggedIn = false;
      userName = null;
      userEmail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: isLoggedIn
                    ? _buildUserInfoBlock()
                    : _buildLoginButtonBlock(),
              ),
      ),
    );
  }

  Widget _buildUserInfoBlock() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('이름', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 4),
              Text(userName ?? '정보 없음', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('이메일', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 4),
              Text(userEmail ?? '정보 없음', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _logout,
          child: Text('로그아웃'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            minimumSize: Size(double.infinity, 50),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _buildLoginButtonBlock() {
    return ElevatedButton(
      onPressed: _handleLogin,
      child: Text('로그인 하기'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
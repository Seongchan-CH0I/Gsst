import 'package:frontend/login_page.dart';  
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        // 토큰이 유효하지 않은 경우 등
        await storage.delete(key: 'access_token'); // 만료되거나 잘못된 토큰 삭제
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
    final isLoggedIn = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );

    if (isLoggedIn == true) {
      // 로그인 성공 시, 사용자 정보를 다시 불러와 화면을 갱신합니다.
      setState(() {
        isLoading = true;
      });
      _checkLoginStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                children: <Widget>[
                  Spacer(flex: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: isLoggedIn
                        ? _buildUserInfoBlock()
                        : _buildLoginButtonBlock(),
                  ),
                  Spacer(flex: 3),
                ],
              ),
      ),
    );
  }

  Widget _buildUserInfoBlock() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3), // changes position of shadow
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
    );
  }

  Widget _buildLoginButtonBlock() {
    return Container(
      padding: const EdgeInsets.all(24.0),
       decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleLogin,
        child: Text('로그인 하기'),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50), // 버튼의 최소 크기
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
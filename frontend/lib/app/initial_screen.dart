import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/app/main_page.dart';
import 'package:frontend/mypage/set_nickname_screen.dart';
import 'package:http/http.dart' as http;

class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  //============================================================================
  // 1. State Variables
  //============================================================================
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _nicknameRequired = false;

  //============================================================================
  // 2. Lifecycle Methods
  //============================================================================
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  //============================================================================
  // 3. Logic Methods
  //============================================================================
  Future<void> _checkUserStatus() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken != null) {
        final response = await http.get(
          Uri.parse('http://localhost:8000/auth/me'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == 200) {
          final userData = jsonDecode(utf8.decode(response.bodyBytes));
          if (userData['name'] == null || userData['name'].isEmpty) {
            _nicknameRequired = true;
          }
        } else {
          await _storage.delete(key: 'access_token');
        }
      }
    } catch (e) {
      print('Error checking user status: $e');
      await _storage.delete(key: 'access_token');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //============================================================================
  // 4. Widget Build Method
  //============================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_nicknameRequired) {
      return const SetNicknameScreen();
    } else {
      return const MainPage();
    }
  }
}
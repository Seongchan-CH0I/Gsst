import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logged_in_view.dart';
import 'logged_out_view.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({Key? key}) : super(key: key);

  @override
  _MypageScreenState createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  //============================================================================
  // 1. State Variables
  //============================================================================
  final _storage = const FlutterSecureStorage();
  bool _isLoggedIn = false;

  //============================================================================
  // 2. Lifecycle Methods
  //============================================================================
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  //============================================================================
  // 3. Logic Methods
  //============================================================================
  Future<void> _checkLoginStatus() async {
    String? token = await _storage.read(key: 'access_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  //============================================================================
  // 4. Widget Build Method
  //============================================================================
  @override
  Widget build(BuildContext context) {
    return _isLoggedIn
        ? LoggedInView(onLogout: _onLogout)
        : LoggedOutView(onLoginSuccess: _onLoginSuccess);
  }
}
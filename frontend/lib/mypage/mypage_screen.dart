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
  final storage = new FlutterSecureStorage();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    String? token = await storage.read(key: 'access_token');
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

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn
        ? LoggedInView(onLogout: _onLogout)
        : LoggedOutView(onLoginSuccess: _onLoginSuccess);
  }
}
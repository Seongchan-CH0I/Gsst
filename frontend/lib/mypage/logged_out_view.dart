import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class LoggedOutView extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const LoggedOutView({Key? key, required this.onLoginSuccess}) : super(key: key);

  //============================================================================
  // 1. Logic Methods
  //============================================================================

  void _navigateToLogin(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    if (result == true) {
      onLoginSuccess();
    }
  }

  //============================================================================
  // 2. Widget Build Method
  //============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('로그인이 필요합니다.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToLogin(context),
              child: const Text('로그인 페이지로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class LoggedOutView extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const LoggedOutView({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('로그인이 필요합니다.'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
                if (result == true) {
                  onLoginSuccess();
                }
              },
              child: Text('로그인 페이지로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}

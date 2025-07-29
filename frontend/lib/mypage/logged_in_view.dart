import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoggedInView extends StatelessWidget {
  final VoidCallback onLogout;
  final storage = new FlutterSecureStorage();

  LoggedInView({Key? key, required this.onLogout}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await storage.delete(key: 'access_token');
    onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('환영합니다! 로그인되었습니다.'),
            // TODO: Display user information here
          ],
        ),
      ),
    );
  }
}

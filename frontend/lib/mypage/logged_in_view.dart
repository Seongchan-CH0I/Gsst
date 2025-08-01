import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class LoggedInView extends StatefulWidget {
  final VoidCallback onLogout;

  const LoggedInView({Key? key, required this.onLogout}) : super(key: key);

  @override
  _LoggedInViewState createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<LoggedInView> {
  //============================================================================
  // 1. State Variables
  //============================================================================
  final _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  String? _email;
  String? _nickname;
  String? _profileImageUrl; // Store the URL from the backend

  //============================================================================
  // 2. Lifecycle Methods
  //============================================================================
  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  //============================================================================
  // 3. Logic Methods
  //============================================================================
  Future<void> _fetchUserInfo() async {
    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/mypage/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _email = data['email'];
            _nickname = data['name'];
            _profileImageUrl = data['profile_image_url']; // Get profile image URL
          });
        }
      } else {
        _showErrorDialog('사용자 정보 로딩 실패: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog('사용자 정보 로딩 오류: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        String? token = await _storage.read(key: 'access_token');
        if (token == null) {
          _showErrorDialog('로그인 정보가 없습니다. 다시 로그인해주세요.');
          return;
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://127.0.0.1:8000/mypage/me/profile-image'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: image.name,
        ));

        var response = await request.send();

        if (response.statusCode == 200) {
          final responseData = await http.Response.fromStream(response);
          final data = jsonDecode(utf8.decode(responseData.bodyBytes));
          if (mounted) {
            setState(() {
              _profileImageUrl = data['profile_image_url'];
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로필 이미지가 성공적으로 업데이트되었습니다.')),
          );
        } else {
          final responseData = await http.Response.fromStream(response);
          final error = jsonDecode(utf8.decode(responseData.bodyBytes));
          _showErrorDialog('이미지 업로드 실패: ${error['detail'] ?? response.statusCode}');
        }
      } catch (e) {
        _showErrorDialog('이미지 업로드 오류: $e');
      }
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'access_token');
    widget.onLogout();
  }

  //============================================================================
  // 4. UI Helper Methods
  //============================================================================
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('확인'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  //============================================================================
  // 5. Widget Build Method
  //============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage('http://127.0.0.1:8000' + _profileImageUrl!)
                          : const AssetImage('assets/1.png') as ImageProvider, // Placeholder
                      child: _profileImageUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_email != null)
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('이메일'),
                  subtitle: Text(_email!),
                ),
              if (_nickname != null)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('닉네임'),
                  subtitle: Text(_nickname!),
                ),
              const Divider(height: 32),
              // Add more sections here for future features
            ],
          ),
        ),
      ),
    );
  }
}

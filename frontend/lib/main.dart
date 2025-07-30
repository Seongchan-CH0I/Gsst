import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/mypage/mypage_screen.dart';
import 'package:frontend/smart_goal_page.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 추가
import 'package:frontend/mypage/set_nickname_screen.dart'; // 추가
import 'package:http/http.dart' as http; // 추가
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  KakaoSdk.init(
    nativeAppKey: dotenv.env['NATIVE_APP_KEY']!,
    javaScriptAppKey: dotenv.env['JAVASCRIPT_APP_KEY']!,
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // 릴리즈 모드가 아닐 때만 활성화
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true, // DevicePreview를 위해 추가
      locale: DevicePreview.locale(context), // DevicePreview를 위해 추가
      builder: DevicePreview.appBuilder, // DevicePreview를 위해 추가
      title: 'GSST',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const InitialScreen(), // InitialScreen으로 변경
    );
  }
}

// 앱 시작 시 로그인 상태 및 닉네임 유무를 확인하는 초기 화면
class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _nicknameRequired = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken != null) {
        // 토큰이 있으면 사용자 정보 요청
        final response = await http.get(
          Uri.parse('http://localhost:8000/auth/me'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (response.statusCode == 200) {
          final userData = jsonDecode(utf8.decode(response.bodyBytes));
          if (userData['name'] == null || userData['name'].isEmpty) {
            _nicknameRequired = true;
          }
        } else {
          // 토큰이 유효하지 않거나 사용자 정보 조회 실패 시, 로그아웃 상태로 간주
          await _storage.delete(key: 'access_token');
        }
      } else {
        // 토큰이 없으면 로그인 화면으로 이동 (또는 public view)
        // 여기서는 MainPage로 바로 이동하도록 처리 (로그인 화면은 LoginScreen에서 담당)
      }
    } catch (e) {
      // 네트워크 오류 등 예외 처리
      print('Error checking user status: $e');
      await _storage.delete(key: 'access_token'); // 오류 발생 시 토큰 삭제
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    const SmartGoalPage(),
    Center(child: Text('레시피 관련 팁 페이지')),
    const MypageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GSST'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: '스마트 목표 추천',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: '레시피 관련 팁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

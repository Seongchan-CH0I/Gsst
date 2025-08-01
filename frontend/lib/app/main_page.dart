import 'package:flutter/material.dart';
import 'package:frontend/mypage/mypage_screen.dart';
import 'package:frontend/smart_goal_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  //============================================================================
  // 1. State Variables
  //============================================================================
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    SmartGoalPage(),
    Center(child: Text('레시피 관련 팁 페이지')),
    MypageScreen(),
  ];

  //============================================================================
  // 2. Logic Methods
  //============================================================================
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  //============================================================================
  // 3. Widget Build Method
  //============================================================================
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
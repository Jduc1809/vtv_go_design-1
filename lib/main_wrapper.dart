import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'channels_screen.dart';
import 'home_screen.dart';
import 'service_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentNavIndex = 0;

  // The IndexedStack will keep all these screens alive in memory
  final List<Widget> _screens = [
    const HomeScreen(), // Index 0: Trang Chủ
    const ChannelsScreen(), // Index 1: Kênh
    const ServiceScreen(), // Index 2: Cổng Dịch Vụ
    const AccountScreen(), // Index 3: Tài Khoản
  ];

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF141415);

    return Scaffold(
      backgroundColor: bgColor,

      body: IndexedStack(index: _currentNavIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[900]!, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: bgColor,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentNavIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey[800],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_filled),
              ),
              label: 'Trang Chủ',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.ondemand_video),
              ),
              label: 'Truyền Hình',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.construction),
              ),
              label: 'Cổng Dịch Vụ',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline),
              ),
              label: 'Tài Khoản',
            ),
          ],
        ),
      ),
    );
  }
}

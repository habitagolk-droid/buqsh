import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'reports/reports_screen.dart';
import 'wallets/wallets_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    WalletsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surface,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 24),
            selectedIcon: Icon(Icons.home, size: 24),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined, size: 24),
            selectedIcon: Icon(Icons.account_balance_wallet, size: 24),
            label: 'المحافظ',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, size: 24),
            selectedIcon: Icon(Icons.bar_chart, size: 24),
            label: 'التقارير',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 24),
            selectedIcon: Icon(Icons.person, size: 24),
            label: 'البروفايل',
          ),
        ],
      ),
    );
  }
}

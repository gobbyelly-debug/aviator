import 'package:flutter/material.dart';

import 'history_page.dart';
import 'prediction_page.dart';
import 'rules_page.dart';
import 'settings_page.dart';

class AviatorShellPage extends StatefulWidget {
  const AviatorShellPage({super.key});

  @override
  State<AviatorShellPage> createState() => _AviatorShellPageState();
}

class _AviatorShellPageState extends State<AviatorShellPage> {
  int currentNav = 0;

  static const List<Widget> _pages = [
    PredictionPage(),
    HistoryPage(),
    RulesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentNav, children: _pages),
      bottomNavigationBar: NavigationBar(
        height: 78,
        selectedIndex: currentNav,
        onDestinationSelected: (index) {
          setState(() => currentNav = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.gps_fixed_outlined),
            selectedIcon: Icon(Icons.gps_fixed),
            label: 'Predict',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_toggle_off_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Rules',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

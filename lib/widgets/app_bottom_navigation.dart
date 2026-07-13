import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, key: Key('nav-home')),
          selectedIcon: Icon(Icons.home, key: Key('nav-home-selected')),
          label: '首页',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined, key: Key('nav-history')),
          selectedIcon: Icon(Icons.history, key: Key('nav-history-selected')),
          label: '记录',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, key: Key('nav-profile')),
          selectedIcon: Icon(Icons.person, key: Key('nav-profile-selected')),
          label: '我的',
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/interview_service.dart';
import '../services/practice_store.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_page.dart';
import 'practice_history_page.dart';
import 'profile_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({
    super.key,
    required this.interviewService,
  });

  final InterviewService interviewService;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    unawaited(PracticeStore.instance.loadRemoteRecords());
    _pages = [
      HomePage(interviewService: widget.interviewService),
      const PracticeHistoryPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

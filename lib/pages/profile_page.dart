import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '个人中心',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('我的页面骨架已就绪'),
          ],
        ),
      ),
    );
  }
}

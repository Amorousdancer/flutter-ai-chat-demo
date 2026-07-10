import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'OfferLab',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text('AI 面试与职场沟通陪练 App'),
            SizedBox(height: 8),
            Text('项目骨架已就绪'),
          ],
        ),
      ),
    );
  }
}

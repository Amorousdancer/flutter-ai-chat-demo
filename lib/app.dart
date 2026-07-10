import 'package:flutter/material.dart';

import 'pages/main_shell_page.dart';

class OfferLabApp extends StatelessWidget {
  const OfferLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfferLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF36D399),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainShellPage(),
    );
  }
}

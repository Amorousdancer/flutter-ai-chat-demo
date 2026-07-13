import 'package:flutter/material.dart';

import 'pages/main_shell_page.dart';
import 'services/interview_service.dart';
import 'services/real_interview_service.dart';

class OfferLabApp extends StatelessWidget {
  OfferLabApp({
    super.key,
    InterviewService? interviewService,
  }) : interviewService = interviewService ?? RealInterviewService();

  final InterviewService interviewService;

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF36D399),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'OfferLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: baseScheme.copyWith(
          surface: const Color(0xFF0D141B),
          surfaceContainerLow: const Color(0xFF131C24),
          surfaceContainerHigh: const Color(0xFF1B2732),
          outlineVariant: const Color(0xFF273847),
        ),
        scaffoldBackgroundColor: const Color(0xFF091017),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0F1821),
          indicatorColor: baseScheme.primary.withValues(alpha: 0.18),
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
        chipTheme: ChipThemeData(
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF131C24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: baseScheme.outlineVariant,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: baseScheme.outlineVariant,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: baseScheme.primary,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: MainShellPage(
        interviewService: interviewService,
      ),
    );
  }
}

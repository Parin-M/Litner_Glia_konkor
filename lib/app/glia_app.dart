import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../pages/leitner_page.dart';

class GliaApp extends StatelessWidget {
  const GliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'گلیا کنکور | لایتنر هوشمند',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.teal,
        ),
        useMaterial3: true,
      ),
      home: const LeitnerPage(),
    );
  }
}

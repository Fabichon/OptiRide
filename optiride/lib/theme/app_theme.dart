import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF64A9A7);

  static ThemeData light() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );
  static ThemeData dark() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark),
        useMaterial3: true,
      );
}

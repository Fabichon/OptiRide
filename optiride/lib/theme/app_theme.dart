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
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          suffixIconColor: primary,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: primary,
          selectionColor: primary.withValues(alpha: 0.2),
          selectionHandleColor: primary,
        ),
      );
  static ThemeData dark() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          suffixIconColor: primary,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: primary,
          selectionColor: primary.withValues(alpha: 0.2),
          selectionHandleColor: primary,
        ),
      );
}

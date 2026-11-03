import 'package:flutter/material.dart';

/// Shared Sebenza design language (dark, amber accent) matching the web console.
class SebenzaTheme {
  static const bg = Color(0xFF0D0F10);
  static const panel = Color(0xFF15181B);
  static const panel2 = Color(0xFF1C2024);
  static const border = Color(0xFF262C31);
  static const text = Color(0xFFE8E6E3);
  static const muted = Color(0xFF8B929A);
  static const amber = Color(0xFFF0A232);
  static const red = Color(0xFFD95A4E);
  static const green = Color(0xFF4CAF7D);
  static const blue = Color(0xFF5B8DB8);

  static ThemeData dark() => ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
            primary: amber, surface: panel, error: red, onSurface: text),
        appBarTheme: const AppBarTheme(
            backgroundColor: panel, foregroundColor: text, elevation: 0,
            titleTextStyle: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: text)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: panel, selectedItemColor: amber,
            unselectedItemColor: muted, type: BottomNavigationBarType.fixed),
        cardTheme: const CardThemeData(
            color: panel,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                side: BorderSide(color: border))),
        inputDecorationTheme: const InputDecorationTheme(
            filled: true, fillColor: panel2,
            border: OutlineInputBorder(borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: amber)),
            labelStyle: TextStyle(color: muted, fontSize: 12)),
        dividerColor: border,
        snackBarTheme: const SnackBarThemeData(
            backgroundColor: panel2, contentTextStyle: TextStyle(color: text)),
      );
}

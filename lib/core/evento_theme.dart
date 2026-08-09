import 'package:flutter/material.dart';

abstract final class EventoColors {
  static const Color ink = Color(0xFF06111F);
  static const Color panel = Color(0xFF0C1B2B);
  static const Color panelSoft = Color(0xFF10263C);
  static const Color blue = Color(0xFF39A9FF);
  static const Color cyan = Color(0xFF61E5FF);
  static const Color gold = Color(0xFFFFC857);
  static const Color text = Color(0xFFF4F8FC);
  static const Color muted = Color(0xFF9CB0C3);
}

ThemeData buildEventoTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: EventoColors.blue,
    brightness: Brightness.dark,
    surface: EventoColors.panel,
  ).copyWith(
    primary: EventoColors.blue,
    secondary: EventoColors.gold,
    surface: EventoColors.panel,
    onSurface: EventoColors.text,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: EventoColors.ink,
    cardTheme: const CardThemeData(
      color: EventoColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: EventoColors.panelSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF183A57)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: EventoColors.blue, width: 1.5),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF081725),
      indicatorColor: Color(0x332FA9FF),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
    ),
  );
}

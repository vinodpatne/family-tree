import 'package:flutter/material.dart';
import 'design_tokens.dart';

ThemeData buildAppTheme({bool isDark = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: DesignTokens.primaryColor,
    primary: DesignTokens.primaryColor,
    brightness: isDark ? Brightness.dark : Brightness.light,
    surface: isDark ? const Color(0xFF1E293B) : DesignTokens.surfaceColor,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : DesignTokens.surfaceColor,
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF1E293B) : DesignTokens.cardColor,
      elevation: DesignTokens.elevation,
      margin: const EdgeInsets.all(DesignTokens.spacingUnit),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSmall)),
      filled: true,
      fillColor: isDark ? const Color(0xFF334155) : DesignTokens.cardColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSmall)),
        padding: const EdgeInsets.all(DesignTokens.spacingUnit * 2),
      ),
    ),
  );
}

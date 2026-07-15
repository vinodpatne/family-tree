import 'package:flutter/material.dart';
import 'design_tokens.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: DesignTokens.primaryColor,
    primary: DesignTokens.primaryColor,
    surface: DesignTokens.surfaceColor,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: DesignTokens.surfaceColor,
    cardTheme: const CardThemeData(
      color: DesignTokens.cardColor,
      elevation: DesignTokens.elevation,
      margin: EdgeInsets.all(DesignTokens.spacingUnit),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSmall)),
      filled: true,
      fillColor: DesignTokens.cardColor,
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

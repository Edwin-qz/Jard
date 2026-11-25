import 'package:flutter/material.dart';

class AppColors {
  // Global theme controller state
  static bool isDarkMode = true;

  // Adaptive background and surface colors
  // Modo oscuro refinado con tonos gris claro / slate elegante (NO negro opaco ni saturado)
  // Brinda mayor luminosidad, suavidad visual y alto contraste profesional
  static Color get background => isDarkMode ? const Color(0xFF323843) : const Color(0xFFF8FAFC);
  static Color get surface => isDarkMode ? const Color(0xFF3F4653) : const Color(0xFFFFFFFF);
  static Color get surfaceCard => isDarkMode ? const Color(0xFF3F4653) : const Color(0xFFFFFFFF);
  static Color get surfaceElevated => isDarkMode ? const Color(0xFF4B5463) : const Color(0xFFF1F5F9);
  static Color get border => isDarkMode ? const Color(0xFF5A6475) : const Color(0xFFE2E8F0);
  static Color get borderSubtle => isDarkMode ? const Color(0xFF485160) : const Color(0xFFEEF2F6);

  // Natural organic Leaf Green (Verde Hoja natural, cálido y profesional)
  static const Color leafGreen = Color(0xFF2EA043); // Authentic leaf green
  static const Color leafGreenLight = Color(0xFFD2F4D3); // Soft leaf green tint
  static const Color leafGreenDark = Color(0xFF1B6B2E); // Deep forest foliage
  static const Color leafGreenAccent = Color(0xFF34D399); // Fresh leaf tip
  static const Color leafBadgeBg = Color(0xFF163C24); // Harmonious leaf badge bg

  // Backward compatibility aliases (all former mint usages automatically receive the new Leaf Green)
  static const Color mint = leafGreen;
  static const Color mintLight = leafGreenLight;
  static const Color mintDark = leafGreenDark;
  static const Color greenBadge = leafGreen;
  static const Color greenBadgeBg = leafBadgeBg;

  // Harmonious combining accents (Tierra, Sol, Cielo y Flores)
  static const Color cyan = Color(0xFF38BDF8); // Sky / Irrigation water
  static const Color amber = Color(0xFFF59E0B); // Warm sunlight / Earth
  static const Color amberBg = Color(0xFF3D2D14);
  static const Color coral = Color(0xFFEF4444); // Blossom / Warning
  static const Color coralBg = Color(0xFF3E1D1D);
  static const Color error = coral;
  static const Color earth = Color(0xFF8D6E63); // Rich garden soil

  // Text colors - High contrast in both themes!
  static Color get textPrimary => isDarkMode ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A);
  static Color get textSecondary => isDarkMode ? const Color(0xFFADBAC7) : const Color(0xFF475569);
  static Color get textMuted => isDarkMode ? const Color(0xFF768390) : const Color(0xFF64748B);
  static Color get textMint => isDarkMode ? leafGreenAccent : leafGreenDark;

  // Light theme alternative aliases
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF323843),
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.leafGreen,
        onPrimary: Colors.white,
        surface: Color(0xFF3F4653),
        onSurface: Color(0xFFF8FAFC),
        outline: Color(0xFF5A6475),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF3F4653),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF5A6475), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.leafGreen,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF373E49),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5A6475), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5A6475), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.leafGreen, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AppColors.leafGreenDark,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0F172A),
        outline: Color(0xFFE2E8F0),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.leafGreen,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.leafGreenDark, width: 1.5),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// VisorRoute Design System — Stolen and tailored from VenueHub UI/UX
class AppTheme {
  // VenueHub Light Colors
  static const Color lightPrimary = Color(0xFF1E8F4B); // JKUAT Green
  static const Color lightSecondary = Color(0xFFE53935); // JKUAT Red
  static const Color lightTertiary = Color(0xFF1E88E5); // JKUAT Blue
  static const Color lightBackground = Colors.white;
  static const Color lightCard = Colors.white;

  // VenueHub Dark Slate Colors
  static const Color darkPrimary = Color(0xFF2DD4BF); // Teal Accent
  static const Color darkSecondary = Color(0xFFF43F5E); // Rose
  static const Color darkTertiary = Color(0xFF38BDF8); // Sky Blue
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkCardBorder = Color(0xFF334155); // Slate 700

  // Status Pin & Workstation Colors (Red / Amber / Green)
  static const Color statusGreen = Color(0xFF10B981); // Visited / Completed
  static const Color statusAmber = Color(0xFFF59E0B); // In Progress / Pending
  static const Color statusRed = Color(0xFFEF4444); // Unvisited / Overdue

  /// Light Theme Definition
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      dividerColor: Colors.grey.shade200,
      hintColor: Colors.grey.shade500,
      disabledColor: Colors.grey.shade300,
      canvasColor: Colors.grey.shade100,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        tertiary: lightTertiary,
        surface: lightCard,
        background: lightBackground,
        error: lightSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: lightPrimary,
        unselectedItemColor: Colors.grey,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightPrimary, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }

  /// Dark Slate Theme Definition
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      dividerColor: darkCardBorder,
      hintColor: Colors.white38,
      disabledColor: Colors.white24,
      canvasColor: darkCardBorder,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        tertiary: darkTertiary,
        surface: darkCard,
        background: darkBackground,
        error: darkSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: darkPrimary,
        unselectedItemColor: Colors.white54,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPrimary, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}

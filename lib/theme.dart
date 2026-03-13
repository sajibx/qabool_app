import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QaboolTheme {
  // Core colors from Tailwind configuration
  static const Color primary = Color(0xFFD4AF35);
  static const Color maroon = Color(0xFF800000);
  static const Color backgroundLight = Color(0xFFF8F7F6);
  static const Color backgroundDark = Color(0xFF201D12);

  static const Color textLight = Color(0xFF1E293B); // Slate 800
  static const Color textDark = Color(0xFFF1F5F9); // Slate 100

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: maroon,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.manropeTextTheme().apply(
        bodyColor: textLight,
        displayColor: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(
            color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: maroon,
        surface: Color(0xFF0F172A),
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A), // Slate 900
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
            color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

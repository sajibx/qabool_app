import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QaboolTheme {
  // Core colors for Asian marriage theme
  static const Color primary = Color(0xFF8F0D10); // Brand Deep Red
  static const Color accentGold = Color(0xFFD4AF35); // Gold accent
  static const Color backgroundLight = Color(0xFFFDFCFB); 
  static const Color backgroundDark = Color(0xFF1A1616);

  static const Color textLight = Color(0xFF1E293B); // Slate 800
  static const Color textDark = Color(0xFFF1F5F9); // Slate 100

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accentGold,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.montserratTextTheme().apply(
        bodyColor: textLight,
        displayColor: textLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.montserrat(
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
      fontFamily: GoogleFonts.montserrat().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accentGold,
        surface: Color(0xFF0F172A),
      ),
      textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.montserrat(
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

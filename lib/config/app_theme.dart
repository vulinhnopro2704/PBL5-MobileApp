import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color errorColor = Color(0xFFCF6679);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Button Colors
  static const Color forwardButtonColor = Color(0xFF03A9F4);
  static const Color backwardButtonColor = Color(0xFF0288D1);
  static const Color leftButtonColor = Color(0xFF673AB7);
  static const Color rightButtonColor = Color(0xFF673AB7);
  static const Color rotateButtonColor = Color(0xFF9C27B0);
  static const Color grabButtonColor = Color(0xFFFF9800);
  static const Color stopButtonColor = Color(0xFFF44336);

  // Text Styles
  static TextStyle headingStyle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle subheadingStyle = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle bodyStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white70,
  );

  static TextStyle buttonTextStyle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceDark,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // Status indicators
  static const Color connectedColor = Color(0xFF4CAF50);
  static const Color disconnectedColor = Color(0xFFF44336);
  static const Color connectingColor = Color(0xFFFFEB3B);

  // Theme data
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: surfaceDark,
    ),
    cardTheme: CardTheme(
      color: surfaceDark,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: headingStyle,
      titleLarge: subheadingStyle,
      bodyMedium: bodyStyle,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      titleTextStyle: headingStyle,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
  );
}

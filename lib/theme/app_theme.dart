import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF1C2541);
  static const Color accent = Color(0xFF5BC0BE);
  static const Color background = Colors.white;
  static const Color cardBorder = Color(0xFFE0E3E7);
  static const Color inputFill = Color(0xFFF5F7FA);
  static const Color error = Colors.redAccent;

  // Spacing
  static const double spacerHeight = 16.0;
  static const double elementPaddingValue = 24.0;
  static const EdgeInsets elementPadding = EdgeInsets.all(elementPaddingValue);
  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets cardPadding = EdgeInsets.all(24.0);

  // TextStyles
  static TextStyle get headLine1 => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primary,
      );
  static TextStyle get headLine2 => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
      );
  static TextStyle get headLine3Light => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: primary,
      );
  static TextStyle get body => const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      );

  // Spacer widget
  static Widget get spacer => const SizedBox(height: spacerHeight);

  // Card Theme
  static CardThemeData get cardTheme => const CardThemeData(
        elevation: 2,
        margin: cardMargin,
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: cardBorder),
        ),
      );

  // AppBar Theme
  static AppBarTheme get appBarTheme => const AppBarTheme(
        centerTitle: true,
        elevation: 2,
        backgroundColor: background,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: primary,
          fontSize: 20,
        ),
      );

  // ThemeData
  static ThemeData get themeData => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: appBarTheme,
        cardTheme: cardTheme,
        scaffoldBackgroundColor: background,
      );
}

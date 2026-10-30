import 'package:flutter/material.dart';

class AppTheme {
  // =========================================================
  // FINAL MOCKUP COLORS
  // =========================================================

  static const Color creamBackground = Color(0xFFF7F2E8);
  static const Color gold = Color(0xFFF4B400);
  static const Color goldDark = Color(0xFFB67D00);

  static const Color darkText = Color(0xFF4A433D);
  static const Color mutedText = Color(0xFF9B948A);

  static const Color softBlue = Color(0xFFAED3F6);
  static const Color softGreen = Color(0xFFE5F5E4);
  static const Color softPink = Color(0xFFF8E9EB);
  static const Color softYellow = Color(0xFFFFF2C1);
  static const Color softGray = Color(0xFFF2F2F2);
  static const Color softBeige = Color(0xFFE6E4DD);

  static const Color white = Colors.white;
  static const Color redMic = Color(0xFFD84315);
  static const Color redMicShadow = Color(0xFF962B07);

  static const Color successGreen = Color(0xFF55D36A);
  static const Color warningOrange = Color(0xFFFFB74D);
  static const Color dangerRed = Colors.redAccent;

  // =========================================================
  // OLD COMPATIBILITY COLORS
  // =========================================================

  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color midBlue = Color(0xFF42A5F5);
  static const Color lightBlue = Color(0xFFE3F2FD);

  static const Color orange = warningOrange;
  static const Color yellow = Color(0xFFFFD54F);
  static const Color green = Color(0xFF81C784);
  static const Color pink = Color(0xFFF48FB1);
  static const Color purple = Color(0xFFB39DDB);

  static const Color softText = mutedText;
  static const Color greyText = mutedText;
  static const Color background = creamBackground;

  // =========================================================
  // THEME DATA
  // =========================================================

  static ThemeData themeData() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.light,
    ).copyWith(primary: gold, secondary: softBlue, surface: creamBackground);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: creamBackground,
      colorScheme: colorScheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: creamBackground,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: darkText,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: darkText,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: darkText,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: darkText,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: darkText,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: darkText),
        bodyMedium: TextStyle(fontSize: 14, color: mutedText),
        bodySmall: TextStyle(fontSize: 12, color: mutedText),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldDark,
          side: const BorderSide(color: gold, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static const double pageHorizontalPadding = 18;
  static const double pageTopPadding = 16;
  static const double pageBottomNavSpace = 104;

  // =========================================================
  // CATEGORY LABEL
  // =========================================================

  static String getCategoryLabel(String category) {
    switch (category) {
      case 'Hewan':
        return 'Animals';
      case 'Buah':
        return 'Fruits';
      case 'Warna':
        return 'Colors';
      case 'Benda':
        return 'Objects';
      case 'Angka':
        return 'Numbers';
      case 'Tubuh':
        return 'Body';
      case 'Makanan':
        return 'Food';
      case 'Transportasi':
        return 'Transport';
      case 'Animals':
      case 'Fruits':
      case 'Colors':
      case 'Objects':
      case 'Numbers':
      case 'Body':
      case 'Food':
      case 'Transport':
        return category;
      default:
        return category;
    }
  }

  // =========================================================
  // CATEGORY CARD STYLE
  // =========================================================

  static Color getCategoryCardColor(String category) {
    switch (category) {
      case 'Hewan':
      case 'Animals':
        return const Color(0xFFF7EFD8);

      case 'Buah':
      case 'Fruits':
        return const Color(0xFFFCEDEE);

      case 'Warna':
      case 'Colors':
        return const Color(0xFFEDEEF2);

      case 'Benda':
      case 'Objects':
        return const Color(0xFFE9F6E8);

      case 'Angka':
      case 'Numbers':
        return const Color(0xFFE8F0FF);

      case 'Tubuh':
      case 'Body':
        return const Color(0xFFFFF1E6);

      case 'Makanan':
      case 'Food':
        return const Color(0xFFEAF7F3);

      case 'Transportasi':
      case 'Transport':
        return const Color(0xFFEDEBFF);

      default:
        return softGray;
    }
  }

  static Color getCategoryBorderColor(String category) {
    switch (category) {
      case 'Hewan':
      case 'Animals':
        return const Color(0xFFF0D46B);

      case 'Buah':
      case 'Fruits':
        return const Color(0xFFF2D4D8);

      case 'Warna':
      case 'Colors':
        return const Color(0xFFD9DCE5);

      case 'Benda':
      case 'Objects':
        return const Color(0xFFC7E9C8);

      case 'Angka':
      case 'Numbers':
        return const Color(0xFFC7DBFF);

      case 'Tubuh':
      case 'Body':
        return const Color(0xFFFFD1A8);

      case 'Makanan':
      case 'Food':
        return const Color(0xFFBFE7DA);

      case 'Transportasi':
      case 'Transport':
        return const Color(0xFFCFC8FF);

      default:
        return const Color(0xFFE0E0E0);
    }
  }

  // =========================================================
  // OLD CATEGORY COMPATIBILITY
  // Dipakai oleh widget/file lama yang belum full mockup.
  // =========================================================

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Hewan':
      case 'Animals':
        return orange;

      case 'Buah':
      case 'Fruits':
        return pink;

      case 'Warna':
      case 'Colors':
        return purple;

      case 'Benda':
      case 'Objects':
        return green;

      case 'Angka':
      case 'Numbers':
        return primaryBlue;

      case 'Tubuh':
      case 'Body':
        return warningOrange;

      case 'Makanan':
      case 'Food':
        return green;

      case 'Transportasi':
      case 'Transport':
        return purple;

      default:
        return gold;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Hewan':
      case 'Animals':
        return Icons.pets_rounded;

      case 'Buah':
      case 'Fruits':
        return Icons.apple_rounded;

      case 'Warna':
      case 'Colors':
        return Icons.palette_rounded;

      case 'Benda':
      case 'Objects':
        return Icons.menu_book_rounded;

      case 'Angka':
      case 'Numbers':
        return Icons.looks_one_rounded;

      case 'Tubuh':
      case 'Body':
        return Icons.face_rounded;

      case 'Makanan':
      case 'Food':
        return Icons.restaurant_rounded;

      case 'Transportasi':
      case 'Transport':
        return Icons.directions_car_rounded;

      default:
        return Icons.category_rounded;
    }
  }

  // =========================================================
  // RESULT HELPERS
  // =========================================================

  static Color getScoreColor(int score) {
    if (score >= 90) {
      return successGreen;
    }

    if (score >= 50) {
      return warningOrange;
    }

    return dangerRed;
  }

  static String getScoreTitle(int score) {
    if (score >= 90) {
      return 'Hebat!';
    }

    if (score >= 50) {
      return 'Sudah Bagus!';
    }

    return 'Coba Lagi!';
  }
}

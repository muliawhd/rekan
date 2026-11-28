import 'package:material_ui/material_ui.dart';

/// Clean, editorial Lemon Green (Hijau Lemon), White, and Blue design system
/// for Re:kan — flat confident surfaces, crisp borders, and zero AI-slop glow.
abstract final class RekanPalette {
  // Surfaces & neutrals
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);

  // Hijau Lemon (Fresh Citrus Lemon-Lime)
  static const Color lemon = Color(0xFFA3E635);
  static const Color lemonVivid = Color(0xFF84CC16);
  static const Color lemonDark = Color(0xFF4D7C0F);
  static const Color lemonInk = Color(0xFF1A2E05);
  static const Color lemonSoft = Color(0xFFECFCCB);
  static const Color lemonTint = Color(0xFFF7FEE7);

  // Biru (Crisp Cobalt & Sky Blue)
  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF1D4ED8);
  static const Color blueNavy = Color(0xFF1E3A8A);
  static const Color blueSoft = Color(0xFFDBEAFE);
  static const Color blueTint = Color(0xFFEFF6FF);

  // Text & semantics
  static const Color ink = Color(0xFF111827);
  static const Color inkSecondary = Color(0xFF4B5563);
  static const Color muted = Color(0xFF6B7280);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color online = Color(0xFF65A30D);

  // Clean structural shadow (neutral, subtle, non-glowy)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A111827),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static ThemeData get themeData {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lemonVivid,
        brightness: Brightness.light,
      ).copyWith(
        primary: lemonVivid,
        onPrimary: lemonInk,
        secondary: blue,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: muted,
        outline: border,
        error: danger,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: inkSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderStrong, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderStrong, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lemon,
          foregroundColor: lemonInk,
          disabledBackgroundColor: surfaceSubtle,
          disabledForegroundColor: muted,
          elevation: 0,
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surface,
          side: const BorderSide(color: borderStrong, width: 1.2),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

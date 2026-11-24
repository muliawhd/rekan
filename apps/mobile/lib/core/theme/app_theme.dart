import 'package:material_ui/material_ui.dart';

import 're_tokens.dart';

abstract final class AppTheme {
  /// Canonical Academic Neo-Brutalist typography scale (`DESIGN_SYSTEM.md` §4).
  ///
  /// Uses the platform default sans-serif typeface until custom font assets are
  /// explicitly bundled and approved.
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 36,
      height: 1.15,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: ReTokens.ink,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      height: 1.18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: ReTokens.ink,
    ),
    headlineLarge: TextStyle(
      fontSize: 26,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      color: ReTokens.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      color: ReTokens.ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: ReTokens.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.28,
      fontWeight: FontWeight.w700,
      color: ReTokens.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: ReTokens.ink,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: ReTokens.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: ReTokens.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: ReTokens.mutedText,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: ReTokens.mutedText,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: ReTokens.ink,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: ReTokens.ink,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: ReTokens.mutedText,
    ),
  );

  /// Canonical Academic Neo-Brutalist theme for Re:kan user-facing screens.
  static ThemeData get onboarding {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: ReTokens.primaryYellow,
            brightness: Brightness.light,
          ).copyWith(
            primary: ReTokens.primaryYellow,
            onPrimary: ReTokens.ink,
            secondary: ReTokens.accentTeal,
            onSecondary: ReTokens.ink,
            tertiary: ReTokens.accentMagenta,
            onTertiary: ReTokens.ink,
            surface: ReTokens.surface,
            onSurface: ReTokens.ink,
            onSurfaceVariant: ReTokens.mutedText,
            outline: ReTokens.ink,
            error: ReTokens.error,
            onError: ReTokens.surface,
          ),
      scaffoldBackgroundColor: ReTokens.paper,
    );
    return base.copyWith(
      textTheme: base.textTheme.merge(textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: ReTokens.paper,
        foregroundColor: ReTokens.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: ReTokens.standardBorderSide),
        titleTextStyle: TextStyle(
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: ReTokens.ink,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ReTokens.ink,
        thickness: ReTokens.borderStandard,
        space: ReTokens.spaceLg,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReTokens.surface,
        contentPadding: const EdgeInsets.all(ReTokens.spaceMd),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: ReTokens.ink,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: ReTokens.ink,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ReTokens.mutedText,
        ),
        helperStyle: const TextStyle(
          fontSize: 12,
          height: 1.4,
          color: ReTokens.mutedText,
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: ReTokens.error,
        ),
        helperMaxLines: 3,
        errorMaxLines: 3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          borderSide: ReTokens.standardBorderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          borderSide: ReTokens.standardBorderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          borderSide: ReTokens.emphasizedBorderSide,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          borderSide: const BorderSide(
            color: ReTokens.danger,
            width: ReTokens.borderStandard,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          borderSide: const BorderSide(
            color: ReTokens.danger,
            width: ReTokens.borderEmphasized,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          borderSide: const BorderSide(
            color: ReTokens.mutedText,
            width: ReTokens.borderStandard,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ReTokens.primaryYellow,
          foregroundColor: ReTokens.ink,
          disabledBackgroundColor: ReTokens.mutedSurface,
          disabledForegroundColor: ReTokens.mutedText,
          elevation: 0,
          minimumSize: const Size(
            ReTokens.minTouchTarget,
            ReTokens.controlHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ReTokens.spaceLg,
            vertical: ReTokens.spaceMd,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
            side: ReTokens.standardBorderSide,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: ReTokens.surface,
          foregroundColor: ReTokens.ink,
          disabledBackgroundColor: ReTokens.mutedSurface,
          disabledForegroundColor: ReTokens.mutedText,
          elevation: 0,
          minimumSize: const Size(
            ReTokens.minTouchTarget,
            ReTokens.controlHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ReTokens.spaceLg,
            vertical: ReTokens.spaceMd,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
          side: ReTokens.standardBorderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ReTokens.ink,
          minimumSize: const Size(
            ReTokens.controlHeight,
            ReTokens.controlHeight,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Preserved debug validation theme (`AuthValidationPage`).
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245C45)),
    useMaterial3: true,
  );
}

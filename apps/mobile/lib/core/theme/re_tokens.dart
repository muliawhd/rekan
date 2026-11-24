import 'package:material_ui/material_ui.dart';

/// Canonical Academic Neo-Brutalist design tokens for Re:kan.
///
/// Integrates the approved FigCraft variable collections (`Re:kan Colors` and
/// `Re:kan Spacing & Layout`) while preserving compatibility tokens required by
/// existing authentication and foundation modules.
abstract final class ReTokens {
  // ---------------------------------------------------------------------------
  // Canonical Color Tokens (FigCraft: Re:kan Colors · Light (Paper))
  // ---------------------------------------------------------------------------

  /// Primary text, borders, icons, and hard-offset shadows (`#111111`).
  static const Color ink = Color(0xFF111111);

  /// Main warm paper background (`#FFFDF5`).
  static const Color paper = Color(0xFFFFFDF5);

  /// Cards, forms, and primary elevated surfaces (`#FFFFFF`).
  static const Color surface = Color(0xFFFFFFFF);

  /// Secondary sections, neutral chips, and disabled fills (`#F2F0E8`).
  static const Color mutedSurface = Color(0xFFF2F0E8);

  /// Secondary text, metadata, and captions (`#626262`, >= 5.9:1 on paper).
  static const Color mutedText = Color(0xFF626262);

  /// Compatibility alias for [mutedText].
  static const Color muted = mutedText;

  /// Primary CTA fill, active navigation block, and brand emphasis (`#FFE500`).
  /// Always pair with [ink] (`#111111`) foreground text/icons.
  static const Color primaryYellow = Color(0xFFFFE500);

  /// FigCraft variable alias (`color/accentPrimary`) for [primaryYellow].
  static const Color accentPrimary = primaryYellow;

  /// Academic tags, availability indicators, and secondary state (`#16C7C1`).
  /// Pair with [ink] (`#111111`) foreground text/borders.
  static const Color accentTeal = Color(0xFF16C7C1);

  /// Notification badges, unread counts, and special state (`#F22DBB`).
  /// Pair with [ink] (`#111111`) foreground text/borders.
  static const Color accentMagenta = Color(0xFFF22DBB);

  /// Semantic success, verified, and available status (`#1FA86A`).
  static const Color success = Color(0xFF1FA86A);

  /// Semantic warning banner and alert state (`#F2A900`).
  static const Color warning = Color(0xFFF2A900);

  /// Neo-Brutalist destructive accent fill and error border (`#E5484D`).
  /// Pair with [ink] (`#111111`) text/borders on filled surfaces.
  static const Color danger = Color(0xFFE5484D);

  /// Accessible standalone error text color (`#B3261E`, >= 5.8:1 on paper/surface).
  /// Kept separate from [danger] surface fills to satisfy WCAG AA normal-text contrast.
  static const Color error = Color(0xFFB3261E);

  /// Primary container and input border color (`#111111`).
  static const Color outline = ink;

  /// Legacy Iteration A compatibility token retained for unmigrated screens/tests.
  static const Color forest = Color(0xFF245C45);

  // ---------------------------------------------------------------------------
  // Spacing Scale (Base unit: 4 px — 4 / 8 / 12 / 16 / 24 / 32 / 48)
  // ---------------------------------------------------------------------------

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  /// Semantic & compatibility spacing aliases.
  static const double spaceXs = space4;
  static const double spaceSm = space8;
  static const double spaceCompact = space12;
  static const double spaceMd = space16;
  static const double spaceLg = space24;
  static const double spaceXl = space32;
  static const double spaceHero = space48;

  // ---------------------------------------------------------------------------
  // Border System (Neo-Brutalist 2 px standard / 3 px emphasized)
  // ---------------------------------------------------------------------------

  static const double borderStandard = 2.0;
  static const double borderEmphasized = 3.0;

  static const BorderSide standardBorderSide = BorderSide(
    color: ink,
    width: borderStandard,
  );

  static const BorderSide emphasizedBorderSide = BorderSide(
    color: ink,
    width: borderEmphasized,
  );

  static const BoxBorder standardBorder = Border.fromBorderSide(
    standardBorderSide,
  );

  static const BoxBorder emphasizedBorder = Border.fromBorderSide(
    emphasizedBorderSide,
  );

  // ---------------------------------------------------------------------------
  // Corner Radius System (0 / 6 / 10 / 16 / 999)
  // ---------------------------------------------------------------------------

  static const double radiusNone = 0.0;
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 16.0;
  static const double radiusFull = 999.0;

  /// Compatibility alias for standard control corner radius.
  static const double cornerRadius = radiusMedium;

  // ---------------------------------------------------------------------------
  // Hard-Offset Shadow System (0 px blur)
  // ---------------------------------------------------------------------------

  static const Offset shadowOffsetPressed = Offset(2, 2);
  static const Offset shadowOffsetSubtle = Offset(3, 3);
  static const Offset shadowOffsetHard = Offset(4, 4);
  static const Offset shadowOffsetHero = Offset(6, 6);

  static const List<BoxShadow> shadowPressed = [
    BoxShadow(color: ink, offset: shadowOffsetPressed, blurRadius: 0),
  ];

  static const List<BoxShadow> shadowSubtle = [
    BoxShadow(color: ink, offset: shadowOffsetSubtle, blurRadius: 0),
  ];

  static const List<BoxShadow> shadowHard = [
    BoxShadow(color: ink, offset: shadowOffsetHard, blurRadius: 0),
  ];

  static const List<BoxShadow> shadowHero = [
    BoxShadow(color: ink, offset: shadowOffsetHero, blurRadius: 0),
  ];

  static const List<BoxShadow> shadowAccentYellow = [
    BoxShadow(color: primaryYellow, offset: shadowOffsetHard, blurRadius: 0),
  ];

  // ---------------------------------------------------------------------------
  // Touch Targets, Layout & Motion
  // ---------------------------------------------------------------------------

  /// Minimum accessible interactive tap area (`44x44` dp per FigCraft `touch/minTarget`).
  static const double minTouchTarget = 44.0;

  /// Standard button and input control height (`48` dp).
  static const double controlHeight = 48.0;

  /// Maximum constrained width for centered form and page content (`560` dp).
  static const double contentWidth = 560.0;

  /// Short state transition duration (`180` ms).
  static const Duration transition = Duration(milliseconds: 180);
}

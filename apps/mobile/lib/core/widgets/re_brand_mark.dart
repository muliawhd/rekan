import 'package:material_ui/material_ui.dart';

import '../theme/re_tokens.dart';

enum ReBrandMarkVariant {
  /// Yellow fill (`#FFE500`), dark border (`#111111`), dark text, and dark hard shadow.
  badge,

  /// White surface fill (`#FFFFFF`), dark border (`#111111`), dark text, and yellow (`#FFE500`) offset shadow (FigCraft `id: 440, 481`).
  surface,

  /// Dark fill (`#111111`), yellow text (`#FFE500`), and yellow offset shadow.
  inverted,

  /// Plain bold black wordmark without an outer box.
  wordmark,
}

enum ReBrandMarkSize { sm, md, lg }

/// Official Re:kan brand identity mark (`COMPONENT_SPEC.md` §2, FigCraft `id: 224`).
///
/// Always renders the full brand name `Re:kan` (never shortened to `Re`).
class ReBrandMark extends StatelessWidget {
  const ReBrandMark({
    super.key,
    this.variant = ReBrandMarkVariant.badge,
    this.size = ReBrandMarkSize.md,
    this.showShadow = true,
    this.subtitle,
  });

  /// Canonical brand name. Never shorten to "Re".
  static const String brandName = 'Re:kan';

  final ReBrandMarkVariant variant;
  final ReBrandMarkSize size;
  final bool showShadow;
  final String? subtitle;

  double get _fontSize => switch (size) {
    ReBrandMarkSize.sm => 16,
    ReBrandMarkSize.md => 22,
    ReBrandMarkSize.lg => 28,
  };

  EdgeInsets get _padding => switch (size) {
    ReBrandMarkSize.sm => const EdgeInsets.symmetric(
      horizontal: ReTokens.spaceSm,
      vertical: ReTokens.spaceXs,
    ),
    ReBrandMarkSize.md => const EdgeInsets.symmetric(
      horizontal: ReTokens.spaceCompact,
      vertical: ReTokens.spaceSm - 2,
    ),
    ReBrandMarkSize.lg => const EdgeInsets.symmetric(
      horizontal: ReTokens.spaceMd,
      vertical: ReTokens.spaceSm,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final textColor = variant == ReBrandMarkVariant.inverted
        ? ReTokens.primaryYellow
        : ReTokens.ink;

    final wordmarkText = Text(
      brandName,
      style: TextStyle(
        fontSize: _fontSize,
        height: 1.1,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
        color: textColor,
      ),
    );

    final Widget mark;
    if (variant == ReBrandMarkVariant.wordmark) {
      mark = wordmarkText;
    } else {
      final backgroundColor = switch (variant) {
        ReBrandMarkVariant.inverted => ReTokens.ink,
        ReBrandMarkVariant.surface => ReTokens.surface,
        _ => ReTokens.primaryYellow,
      };
      final shadow = !showShadow
          ? const <BoxShadow>[]
          : (variant == ReBrandMarkVariant.inverted ||
                    variant == ReBrandMarkVariant.surface
                ? ReTokens.shadowAccentYellow
                : ReTokens.shadowHard);

      mark = Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
          border: Border.all(
            color: ReTokens.ink,
            width: size == ReBrandMarkSize.lg
                ? ReTokens.borderEmphasized
                : ReTokens.borderStandard,
          ),
          boxShadow: shadow,
        ),
        child: wordmarkText,
      );
    }

    if (subtitle == null || subtitle!.isEmpty) {
      return Semantics(
        label: brandName,
        excludeSemantics: true,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: mark,
        ),
      );
    }

    return Semantics(
      label: '$brandName — $subtitle',
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: ReTokens.spaceSm,
        runSpacing: ReTokens.spaceXs,
        children: [
          mark,
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: ReTokens.ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

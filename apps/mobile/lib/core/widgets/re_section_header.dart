import 'package:material_ui/material_ui.dart';

import '../theme/re_tokens.dart';

/// Neo-Brutalist section header (`COMPONENT_SPEC.md` §10, FigCraft `id: 410`).
///
/// Renders a bold left accent bar (`#FFE500` or `#16C7C1` with 2 px `#111111`
/// border), accessible heading text, optional count/badge pill, and optional
/// trailing action button (`>= 44x44` dp touch target). Uses a responsive layout
/// so large text scales never overflow on narrow screens.
class ReSectionHeader extends StatelessWidget {
  const ReSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.accentColor = ReTokens.primaryYellow,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String? subtitle;
  final String? badgeText;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final hasTrailing =
        (badgeText != null && badgeText!.isNotEmpty) ||
        (actionLabel != null && onActionPressed != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: ReTokens.spaceSm,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: ReTokens.ink,
                    width: ReTokens.borderStandard,
                  ),
                ),
              ),
            ),
            const SizedBox(width: ReTokens.spaceSm),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ReTokens.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasTrailing) ...[
          const SizedBox(height: ReTokens.spaceXs),
          Padding(
            padding: const EdgeInsets.only(left: ReTokens.spaceMd),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: ReTokens.spaceSm,
              runSpacing: ReTokens.spaceXs,
              children: [
                if (badgeText != null && badgeText!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ReTokens.spaceSm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ReTokens.mutedSurface,
                      borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
                      border: ReTokens.standardBorder,
                    ),
                    child: Text(
                      badgeText!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: ReTokens.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (actionLabel != null && onActionPressed != null)
                  TextButton(
                    onPressed: onActionPressed,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        ReTokens.minTouchTarget,
                        ReTokens.minTouchTarget,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: ReTokens.spaceCompact,
                        vertical: ReTokens.spaceXs,
                      ),
                      foregroundColor: ReTokens.ink,
                      backgroundColor: ReTokens.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ReTokens.radiusSmall,
                        ),
                        side: ReTokens.standardBorderSide,
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: ReTokens.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: ReTokens.spaceXs),
          Padding(
            padding: const EdgeInsets.only(left: ReTokens.spaceMd),
            child: Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}

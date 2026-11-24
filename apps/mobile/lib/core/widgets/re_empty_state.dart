import 'package:material_ui/material_ui.dart';

import '../theme/re_tokens.dart';
import 're_form_components.dart';

/// Neo-Brutalist empty state card (`COMPONENT_SPEC.md` §16, FigCraft `id: 1038, 1044`).
///
/// Displays a bordered icon badge, concise heading, single-sentence explanation,
/// and an optional primary or secondary action button (`>= 48` dp height).
class ReEmptyState extends StatelessWidget {
  const ReEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.badgeText,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onActionPressed,
    this.secondaryAction = false,
  });

  final String title;
  final String description;
  final String? badgeText;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ReTokens.spaceLg),
      decoration: BoxDecoration(
        color: ReTokens.surface,
        borderRadius: BorderRadius.circular(ReTokens.radiusLarge),
        border: ReTokens.standardBorder,
        boxShadow: ReTokens.shadowHard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: ReTokens.spaceCompact,
            runSpacing: ReTokens.spaceSm,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ReTokens.primaryYellow,
                    borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
                    border: ReTokens.standardBorder,
                  ),
                  child: Icon(icon, color: ReTokens.ink, size: 24),
                ),
              ),
              if (badgeText != null && badgeText!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ReTokens.spaceCompact,
                    vertical: ReTokens.spaceXs,
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
            ],
          ),
          const SizedBox(height: ReTokens.spaceMd),
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: ReTokens.ink, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: ReTokens.spaceSm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: ReTokens.mutedText),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: ReTokens.spaceLg),
            if (secondaryAction)
              ReSecondaryButton(label: actionLabel!, onPressed: onActionPressed)
            else
              RePrimaryButton(label: actionLabel!, onPressed: onActionPressed),
          ],
        ],
      ),
    );
  }
}

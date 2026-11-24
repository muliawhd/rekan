import 'package:material_ui/material_ui.dart';

import '../theme/re_tokens.dart';

/// Semantic variants for [ReChip] (`COMPONENT_SPEC.md` §6, FigCraft `id: 318..340`).
enum ReChipVariant {
  /// Muted surface fill (`#F2F0E8`) for general tags and metadata.
  neutral,

  /// Yellow fill (`#FFE500`), check icon, and 2x2 hard shadow for active filters/selections.
  selected,

  /// Surface fill (`#FFFFFF`) with optional proficiency level badge (`1..5`).
  skill,

  /// Paper fill (`#FFFDF5`) with optional course prefix badge (`MK`).
  course,

  /// Surface fill (`#FFFFFF`) with semantic green (`#1FA86A`) availability indicator dot.
  availability,

  /// Teal fill (`#16C7C1`) for academic degree, role, or room status tags.
  status,
}

/// Neo-Brutalist academic tag and filter chip (`COMPONENT_SPEC.md` §6).
///
/// Interactive chips (`onTap != null` or `onDeleted != null`) enforce a minimum
/// `44x44` dp accessible tap target and announce selection state without relying
/// on color alone.
class ReChip extends StatelessWidget {
  const ReChip({
    super.key,
    required this.label,
    this.variant = ReChipVariant.neutral,
    this.icon,
    this.skillLevel,
    this.coursePrefix,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.onDeleted,
    this.semanticLabel,
  }) : assert(
         skillLevel == null || (skillLevel >= 1 && skillLevel <= 5),
         'skillLevel must be between 1 and 5.',
       );

  final String label;
  final ReChipVariant variant;
  final IconData? icon;
  final int? skillLevel;
  final String? coursePrefix;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final String? semanticLabel;

  bool get _isSelected => selected || variant == ReChipVariant.selected;
  bool get _isInteractive => enabled && (onTap != null || onDeleted != null);

  Color get _backgroundColor {
    if (!enabled) return ReTokens.mutedSurface;
    if (_isSelected) return ReTokens.primaryYellow;
    return switch (variant) {
      ReChipVariant.neutral => ReTokens.mutedSurface,
      ReChipVariant.selected => ReTokens.primaryYellow,
      ReChipVariant.skill => ReTokens.surface,
      ReChipVariant.course => ReTokens.paper,
      ReChipVariant.availability => ReTokens.surface,
      ReChipVariant.status => ReTokens.accentTeal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textColor = enabled ? ReTokens.ink : ReTokens.mutedText;
    final borderColor = enabled ? ReTokens.ink : ReTokens.mutedText;
    final prefix =
        coursePrefix ?? (variant == ReChipVariant.course ? 'MK' : null);

    final chipBody = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ReTokens.spaceCompact,
        vertical: ReTokens.spaceXs + 2,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
        border: Border.all(
          color: borderColor,
          width: _isSelected
              ? ReTokens.borderEmphasized
              : ReTokens.borderStandard,
        ),
        boxShadow: _isSelected && enabled ? ReTokens.shadowPressed : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSelected) ...[
            ExcludeSemantics(
              child: Icon(Icons.check, size: 14, color: textColor),
            ),
            const SizedBox(width: ReTokens.spaceXs),
          ] else if (variant == ReChipVariant.availability) ...[
            ExcludeSemantics(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: enabled ? ReTokens.success : ReTokens.mutedText,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: ReTokens.spaceSm - 2),
          ] else if (icon != null) ...[
            ExcludeSemantics(child: Icon(icon, size: 14, color: textColor)),
            const SizedBox(width: ReTokens.spaceXs),
          ],
          if (prefix != null && prefix.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: ReTokens.primaryYellow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Text(
                prefix,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ReTokens.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: ReTokens.spaceXs + 2),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight: _isSelected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          if (skillLevel != null) ...[
            const SizedBox(width: ReTokens.spaceXs + 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _isSelected ? ReTokens.surface : ReTokens.primaryYellow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Text(
                'Lv.$skillLevel',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ReTokens.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (onDeleted != null) ...[
            const SizedBox(width: ReTokens.spaceXs),
            ExcludeSemantics(
              child: Icon(Icons.close, size: 14, color: textColor),
            ),
          ],
        ],
      ),
    );

    if (!_isInteractive && onTap == null && onDeleted == null) {
      return Semantics(
        label:
            semanticLabel ??
            (skillLevel != null ? '$label, level $skillLevel dari 5' : label),
        selected: _isSelected,
        child: chipBody,
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      selected: _isSelected,
      label:
          semanticLabel ??
          (skillLevel != null ? '$label, level $skillLevel dari 5' : label),
      child: InkWell(
        onTap: enabled ? (onTap ?? onDeleted) : null,
        borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: ReTokens.minTouchTarget,
            minHeight: ReTokens.minTouchTarget,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: chipBody,
          ),
        ),
      ),
    );
  }
}

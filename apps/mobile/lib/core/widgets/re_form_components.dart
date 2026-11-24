import 'package:material_ui/material_ui.dart';

import '../theme/re_tokens.dart';
import 're_page_scaffold.dart';

export 're_brand_mark.dart';
export 're_chip.dart';
export 're_empty_state.dart';
export 're_page_scaffold.dart';
export 're_secondary_button.dart';
export 're_section_header.dart';
export 're_text_field.dart';

/// Scrollable, keyboard-safe content shared by forms and feature screens.
///
/// Delegates directly to [RePageScaffold] so there is a single canonical
/// page-scaffold implementation across the application.
class ReFormPage extends StatelessWidget {
  const ReFormPage({
    super.key,
    required this.children,
    this.appBar,
    this.bottomBar,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.all(ReTokens.spaceLg),
  });

  final List<Widget> children;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => RePageScaffold(
    appBar: appBar,
    bottomBar: bottomBar,
    bottomNavigationBar: bottomNavigationBar,
    padding: padding,
    children: children,
  );
}

/// Primary screen/form heading with optional Neo-Brutalist eyebrow badge.
class ReFormHeading extends StatelessWidget {
  const ReFormHeading({
    super.key,
    required this.title,
    required this.description,
    this.eyebrow,
  });

  final String title;
  final String description;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (eyebrow != null && eyebrow!.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ReTokens.spaceCompact,
            vertical: ReTokens.spaceXs,
          ),
          decoration: BoxDecoration(
            color: ReTokens.primaryYellow,
            borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
            border: ReTokens.standardBorder,
          ),
          child: Text(
            eyebrow!,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: ReTokens.ink, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: ReTokens.spaceCompact),
      ],
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
      const SizedBox(height: 6),
      Text(description, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: ReTokens.spaceCompact),
    ],
  );
}

/// Canonical Neo-Brutalist primary CTA button (`COMPONENT_SPEC.md` §3, FigCraft `id: 237..243`).
///
/// Renders `#FFE500` (`ReTokens.primaryYellow`) fill, `#111111` (`ReTokens.ink`)
/// bold text and 2 px border, and a 4x4 hard-offset shadow in the default state.
/// Wraps a Material [FilledButton] inside `Semantics(liveRegion: busy)` so all
/// existing accessibility and widget tests remain compatible.
class RePrimaryButton extends StatefulWidget {
  const RePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel = 'Memproses…',
    this.icon,
    this.expanded = true,
    this.semanticLabel,
  });

  final String label;
  final String busyLabel;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final bool expanded;
  final String? semanticLabel;

  @override
  State<RePrimaryButton> createState() => _RePrimaryButtonState();
}

class _RePrimaryButtonState extends State<RePrimaryButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => !widget.busy && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = widget.busy ? widget.busyLabel : widget.label;
    final shadow = !_enabled
        ? const <BoxShadow>[]
        : (_pressed ? ReTokens.shadowPressed : ReTokens.shadowHard);
    final borderWidth = _focused
        ? ReTokens.borderEmphasized
        : ReTokens.borderStandard;

    final button = Listener(
      onPointerDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: _enabled
          ? (_) => setState(() => _pressed = false)
          : null,
      child: AnimatedContainer(
        duration: ReTokens.transition,
        transform: Matrix4.translationValues(
          _pressed && _enabled ? 2.0 : 0.0,
          _pressed && _enabled ? 2.0 : 0.0,
          0.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          boxShadow: shadow,
        ),
        child: FilledButton(
          onPressed: _enabled ? widget.onPressed : null,
          onFocusChange: (focused) => setState(() => _focused = focused),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
              side: BorderSide(
                color: _enabled ? ReTokens.ink : ReTokens.mutedText,
                width: borderWidth,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy) ...[
                const ExcludeSemantics(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: ReTokens.ink,
                    ),
                  ),
                ),
                const SizedBox(width: ReTokens.spaceSm),
              ] else if (widget.icon != null) ...[
                ExcludeSemantics(child: Icon(widget.icon, size: 18)),
                const SizedBox(width: ReTokens.spaceSm),
              ],
              Flexible(
                child: Text(effectiveLabel, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      liveRegion: widget.busy,
      label: widget.semanticLabel,
      child: widget.expanded
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

/// Compatibility alias so existing callers of [RePrimaryAction] use [RePrimaryButton] directly.
typedef RePrimaryAction = RePrimaryButton;

/// Semantic variants for [ReStatusBanner] (`COMPONENT_SPEC.md` §17, FigCraft `id: 345..358`).
enum ReStatusVariant { info, success, warning, error }

/// Canonical Neo-Brutalist status banner (`COMPONENT_SPEC.md` §17).
///
/// Combines a semantic icon, explicit status label badge (`INFO`, `BERHASIL`,
/// `PERINGATAN`, `GALAT`), high-contrast message text, and optional retry/action
/// control so state is never communicated by color alone.
class ReStatusBanner extends StatelessWidget {
  const ReStatusBanner({
    super.key,
    required this.message,
    this.variant = ReStatusVariant.info,
    this.title,
    this.showBadge = true,
    this.compact = false,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final ReStatusVariant variant;
  final String? title;
  final bool showBadge;
  final bool compact;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  IconData get _icon => switch (variant) {
    ReStatusVariant.info => Icons.info_outline,
    ReStatusVariant.success => Icons.check_circle_outline,
    ReStatusVariant.warning => Icons.warning_amber_rounded,
    ReStatusVariant.error => Icons.error_outline,
  };

  Color get _accentColor => switch (variant) {
    ReStatusVariant.info => ReTokens.accentTeal,
    ReStatusVariant.success => ReTokens.success,
    ReStatusVariant.warning => ReTokens.warning,
    ReStatusVariant.error => ReTokens.danger,
  };

  String get _defaultBadgeLabel => switch (variant) {
    ReStatusVariant.info => 'INFO',
    ReStatusVariant.success => 'BERHASIL',
    ReStatusVariant.warning => 'PERINGATAN',
    ReStatusVariant.error => 'GALAT',
  };

  @override
  Widget build(BuildContext context) {
    final isError = variant == ReStatusVariant.error;
    final badgeLabel = title ?? _defaultBadgeLabel;

    if (compact) {
      return Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                _icon,
                color: isError ? ReTokens.error : ReTokens.ink,
              ),
            ),
            const SizedBox(width: ReTokens.spaceSm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: isError ? ReTokens.error : ReTokens.ink),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ReTokens.spaceCompact),
        decoration: BoxDecoration(
          color: ReTokens.surface,
          borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          border: Border.all(
            color: isError ? ReTokens.danger : ReTokens.ink,
            width: ReTokens.borderStandard,
          ),
          boxShadow: ReTokens.shadowSubtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(ReTokens.spaceXs),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
                      border: ReTokens.standardBorder,
                    ),
                    child: Icon(_icon, size: 18, color: ReTokens.ink),
                  ),
                ),
                const SizedBox(width: ReTokens.spaceCompact),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showBadge) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ReTokens.spaceSm - 2,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: ReTokens.ink, width: 1.5),
                          ),
                          child: Text(
                            badgeLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: ReTokens.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(height: ReTokens.spaceXs + 2),
                      ],
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isError ? ReTokens.error : ReTokens.ink,
                          fontWeight: isError
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: ReTokens.spaceSm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
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
                    backgroundColor: ReTokens.primaryYellow,
                    foregroundColor: ReTokens.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Text and icon convey status together; never rely on color alone.
///
/// Delegates to [ReStatusBanner] (`compact: true` by default so existing
/// `AuthBoundary` / `AuthForm` scroll offsets remain unchanged until Iteration 2).
class ReStatusNotice extends StatelessWidget {
  const ReStatusNotice({
    super.key,
    required this.message,
    this.isError = false,
    this.variant,
    this.compact = true,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final bool isError;
  final ReStatusVariant? variant;
  final bool compact;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) => ReStatusBanner(
    message: message,
    variant:
        variant ?? (isError ? ReStatusVariant.error : ReStatusVariant.info),
    showBadge: !compact,
    compact: compact,
    actionLabel: actionLabel,
    onActionPressed: onActionPressed,
  );
}

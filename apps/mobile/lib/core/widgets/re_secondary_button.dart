import 'package:material_ui/material_ui.dart';

import '../theme/re_tokens.dart';

enum ReSecondaryButtonVariant {
  /// Surface fill (`#FFFFFF`), 2 px dark border, dark label, and 3x3 hard shadow.
  surface,

  /// Destructive fill (`#E5484D`), 2 px dark border, dark label, and 3x3 hard shadow.
  destructive,

  /// Subtle paper/muted fill without offset shadow for low-emphasis actions.
  subtle,
}

/// Neo-Brutalist secondary and destructive button (`COMPONENT_SPEC.md` §4, FigCraft `id: 247..253`).
///
/// Supports default, pressed/focused, loading (`busy`), and disabled states with
/// accessible `>= 48` dp height.
class ReSecondaryButton extends StatefulWidget {
  const ReSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.busyLabel = 'Memproses…',
    this.expanded = true,
    this.variant = ReSecondaryButtonVariant.surface,
    this.semanticLabel,
  });

  const ReSecondaryButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.busyLabel = 'Memproses…',
    this.expanded = true,
    this.semanticLabel,
  }) : variant = ReSecondaryButtonVariant.destructive;

  final String label;
  final String busyLabel;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expanded;
  final ReSecondaryButtonVariant variant;
  final String? semanticLabel;

  @override
  State<ReSecondaryButton> createState() => _ReSecondaryButtonState();
}

class _ReSecondaryButtonState extends State<ReSecondaryButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => !widget.busy && widget.onPressed != null;

  Color get _backgroundColor {
    if (!_enabled) return ReTokens.mutedSurface;
    return switch (widget.variant) {
      ReSecondaryButtonVariant.surface => ReTokens.surface,
      ReSecondaryButtonVariant.destructive => ReTokens.danger,
      ReSecondaryButtonVariant.subtle => ReTokens.paper,
    };
  }

  List<BoxShadow> get _boxShadow {
    if (!_enabled || widget.variant == ReSecondaryButtonVariant.subtle) {
      return const [];
    }
    return _pressed ? ReTokens.shadowPressed : ReTokens.shadowSubtle;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = widget.busy ? widget.busyLabel : widget.label;
    final foreground = _enabled ? ReTokens.ink : ReTokens.mutedText;
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
          _pressed && _enabled ? 1.0 : 0.0,
          _pressed && _enabled ? 1.0 : 0.0,
          0.0,
        ),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
          boxShadow: _boxShadow,
        ),
        child: OutlinedButton(
          onPressed: _enabled ? widget.onPressed : null,
          onFocusChange: (focused) => setState(() => _focused = focused),
          style: OutlinedButton.styleFrom(
            backgroundColor: _backgroundColor,
            foregroundColor: foreground,
            disabledBackgroundColor: ReTokens.mutedSurface,
            disabledForegroundColor: ReTokens.mutedText,
            minimumSize: const Size(
              ReTokens.minTouchTarget,
              ReTokens.controlHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ReTokens.spaceLg,
              vertical: ReTokens.spaceCompact,
            ),
            side: BorderSide(
              color: _enabled ? ReTokens.ink : ReTokens.mutedText,
              width: borderWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
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

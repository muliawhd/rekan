import 'package:material_ui/material_ui.dart';

import '../theme/re_tokens.dart';

/// Canonical Neo-Brutalist text input field (`COMPONENT_SPEC.md` §5, FigCraft `id: 273..300`).
///
/// Enforces a persistent visible label above the input (`DESIGN_SYSTEM.md` §11),
/// 2 px standard / 3 px focused `#111111` borders, accessible password visibility
/// toggle (`>= 48x48` dp), helper copy, and validation error messaging.
class ReTextField extends StatefulWidget {
  const ReTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixAction,
    this.obscureText = false,
    this.enablePasswordToggle = false,
    this.showPasswordTooltip = 'Tampilkan kata sandi',
    this.hidePasswordTooltip = 'Sembunyikan kata sandi',
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixAction;
  final bool obscureText;
  final bool enablePasswordToggle;
  final String showPasswordTooltip;
  final String hidePasswordTooltip;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<ReTextField> createState() => _ReTextFieldState();
}

class _ReTextFieldState extends State<ReTextField> {
  FocusNode? _internalFocusNode;
  late bool _obscured;
  bool _focused = false;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant ReTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _internalFocusNode?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
    if (oldWidget.obscureText != widget.obscureText &&
        !widget.enablePasswordToggle) {
      _obscured = widget.obscureText;
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _focused = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  Widget? _buildSuffixIcon() {
    if (widget.enablePasswordToggle) {
      return IconButton(
        tooltip: _obscured
            ? widget.showPasswordTooltip
            : widget.hidePasswordTooltip,
        constraints: const BoxConstraints(
          minWidth: ReTokens.controlHeight,
          minHeight: ReTokens.controlHeight,
        ),
        onPressed: widget.enabled && !widget.readOnly
            ? () => setState(() => _obscured = !_obscured)
            : null,
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: widget.enabled ? ReTokens.ink : ReTokens.mutedText,
        ),
      );
    }
    return widget.suffixAction;
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = widget.enabled && !widget.readOnly
        ? ReTokens.surface
        : ReTokens.mutedSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: widget.enabled ? ReTokens.ink : ReTokens.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: ReTokens.transition,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
            boxShadow: _focused && widget.enabled
                ? ReTokens.shadowSubtle
                : const [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _effectiveFocusNode,
            initialValue: widget.initialValue,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            obscureText: _obscured,
            autocorrect: widget.autocorrect,
            enableSuggestions: widget.enableSuggestions,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            maxLines: _obscured ? 1 : widget.maxLines,
            minLines: _obscured ? 1 : widget.minLines,
            maxLength: widget.maxLength,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: widget.enabled ? ReTokens.ink : ReTokens.mutedText,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              helperText: widget.helperText,
              errorText: widget.errorText,
              filled: true,
              fillColor: fillColor,
              prefixIcon: widget.prefixIcon,
              suffixIcon: _buildSuffixIcon(),
            ),
          ),
        ),
      ],
    );
  }
}

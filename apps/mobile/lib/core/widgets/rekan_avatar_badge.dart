import 'package:material_ui/material_ui.dart';

import '../theme/rekan_theme.dart';

/// Clean, academic-first monogram badge (no cartoon faces, no dating-app photo emphasis).
/// Aligns with Re:kan's academic integrity guardrails and Lemon Green + White + Blue palette.
class RekanAvatarBadge extends StatelessWidget {
  const RekanAvatarBadge({
    super.key,
    required this.name,
    this.size = 48,
    this.isOnline,
    this.useBlueTone = false,
  });

  final String name;
  final double size;
  final bool? isOnline;
  final bool useBlueTone;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'RK';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = useBlueTone ? RekanPalette.blueTint : RekanPalette.lemonTint;
    final border = useBlueTone ? RekanPalette.blueSoft : RekanPalette.lemon;
    final fg = useBlueTone ? RekanPalette.blueDark : RekanPalette.lemonInk;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(size * 0.26),
            border: Border.all(color: border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            _initials,
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: fg,
            ),
          ),
        ),
        if (isOnline != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              constraints: const BoxConstraints(minWidth: 10, maxWidth: 14, minHeight: 10, maxHeight: 14),
              decoration: BoxDecoration(
                color: isOnline! ? RekanPalette.lemonVivid : RekanPalette.borderStrong,
                shape: BoxShape.circle,
                border: Border.all(color: RekanPalette.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}


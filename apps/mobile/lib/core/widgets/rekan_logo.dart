import 'package:material_ui/material_ui.dart';

import '../theme/rekan_theme.dart';

/// Official Re:kan app logo using the bundled R:K asset image.
class RekanLogo extends StatelessWidget {
  const RekanLogo({
    super.key,
    this.size = 76,
    this.showWordmark = true,
    this.showTagline = false,
    this.horizontal = false,
  });

  const RekanLogo.header({super.key})
      : size = 34,
        showWordmark = true,
        showTagline = false,
        horizontal = true;

  static const String assetPath = 'assets/images/rekan_logo.png';

  final double size;
  final bool showWordmark;
  final bool showTagline;
  final bool horizontal;

  Widget _buildMark() {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Logo Re:kan',
    );
  }

  Widget _buildWordmark() {
    final fontSize = horizontal ? size * 0.64 : size * 0.36;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
          height: 1.05,
        ),
        children: const [
          TextSpan(
            text: 'Re',
            style: TextStyle(color: RekanPalette.ink),
          ),
          TextSpan(
            text: ':',
            style: TextStyle(color: RekanPalette.lemonVivid),
          ),
          TextSpan(
            text: 'kan',
            style: TextStyle(color: RekanPalette.blue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Semantics(
        label: 'Re:kan',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMark(),
            if (showWordmark) ...[
              const SizedBox(width: 8),
              Flexible(child: _buildWordmark()),
            ],
          ],
        ),
      );
    }

    return Semantics(
      label: 'Re:kan',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMark(),
          if (showWordmark) ...[
            SizedBox(height: size * 0.16),
            _buildWordmark(),
          ],
          if (showTagline) ...[
            const SizedBox(height: 6),
            const Text(
              'Partner Belajar & Tim Lomba Mahasiswa',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: RekanPalette.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

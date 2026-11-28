import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../core/theme/rekan_theme.dart';
import '../../../core/widgets/rekan_logo.dart';

/// Clean, minimalist Splash / Loading screen with centered Re:kan logo
/// on a crisp white canvas accented with Lemon Green & Cobalt Blue.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 1800),
  });

  final VoidCallback onFinished;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    _timer = Timer(widget.duration, () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RekanPalette.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Crisp top Hijau Lemon accent bar
            Container(
              height: 4,
              width: double.infinity,
              color: RekanPalette.lemon,
            ),
            const Spacer(flex: 3),
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: const RekanLogo(
                  size: 82,
                  showWordmark: true,
                  showTagline: true,
                ),
              ),
            ),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 72),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      minHeight: 5,
                      color: RekanPalette.lemonVivid,
                      backgroundColor: RekanPalette.lemonSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Memuat ruang kolaborasi...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: RekanPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 42),
          ],
        ),
      ),
    );
  }
}

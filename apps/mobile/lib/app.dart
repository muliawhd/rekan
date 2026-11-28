import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/initialize_auth.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/rekan_theme.dart';
import 'features/auth/auth_boundary.dart';
import 'features/auth/auth_gateway.dart';
import 'features/auth_validation/auth_validation_page.dart';
import 'features/rekan/data/supabase_rekan_repository.dart';
import 'features/splash/presentation/splash_screen.dart';

class ReApp extends StatefulWidget {
  const ReApp({
    super.key,
    this.splashDuration = const Duration(milliseconds: 1600),
    this.skipSplash = false,
    this.authGatewayOverride,
    this.repositoryOverride,
  });

  final Duration splashDuration;
  final bool skipSplash;
  final AuthGateway? authGatewayOverride;
  final RekanRepository? repositoryOverride;

  @override
  State<ReApp> createState() => _ReAppState();
}

class _ReAppState extends State<ReApp> {
  late bool _showingSplash;

  @override
  void initState() {
    super.initState();
    _showingSplash = !widget.skipSplash;
  }

  @override
  Widget build(BuildContext context) {
    final configured = AppConfig.supabase != null && isSupabaseInitialized;
    final validation =
        kDebugMode &&
        const bool.fromEnvironment('AUTH_E2E_ENABLED') &&
        configured;

    final direct = directAuthGateway;
    final gateway = widget.authGatewayOverride ?? (configured ? direct : null);
    final repo = widget.repositoryOverride ??
        (configured
            ? SupabaseRekanRepository(
                Supabase.instance.client,
                userIdProvider: () => direct?.userId,
                userEmailProvider: () => direct?.userEmail,
              )
            : null);

    return MaterialApp(
      title: 'Re:kan',
      debugShowCheckedModeBanner: false,
      theme: validation ? AppTheme.light : RekanPalette.themeData,
      home: validation
          ? const AuthValidationPage()
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showingSplash
                  ? SplashScreen(
                      key: const ValueKey('splash'),
                      duration: widget.splashDuration,
                      onFinished: () {
                        if (mounted) setState(() => _showingSplash = false);
                      },
                    )
                  : AuthBoundary(
                      key: const ValueKey('auth_boundary'),
                      gateway: gateway,
                      rekanRepository: repo,
                    ),
            ),
    );
  }
}

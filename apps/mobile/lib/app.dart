import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/api_session.dart';
import 'core/config/app_config.dart';
import 'core/network/laravel_api.dart';
import 'core/theme/app_theme.dart';
import 'features/academic_profile/data/academic_profile_repository.dart';
import 'features/auth/auth_boundary.dart';
import 'features/auth/auth_gateway.dart';
import 'features/auth_validation/auth_validation_page.dart';

class ReApp extends StatefulWidget {
  const ReApp({super.key});

  @override
  State<ReApp> createState() => _ReAppState();
}

class _ReAppState extends State<ReApp> {
  SupabaseApiSession? _apiSessions;
  AcademicProfileRepository? _profileRepository;

  @override
  void initState() {
    super.initState();
    final configured = AppConfig.supabase != null;
    if (configured && AppConfig.apiBaseUrl.isNotEmpty) {
      try {
        final sessions = SupabaseApiSession(Supabase.instance.client.auth);
        final api = LaravelApi(
          baseUrl: AppConfig.apiBaseUrl,
          sessions: sessions,
        );
        _apiSessions = sessions;
        _profileRepository = AcademicProfileRepository(api);
      } on FormatException {
        _apiSessions?.dispose();
        _apiSessions = null;
        _profileRepository = null;
      }
    }
  }

  @override
  void dispose() {
    _apiSessions?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configured = AppConfig.supabase != null;
    final validation =
        kDebugMode &&
        const bool.fromEnvironment('AUTH_E2E_ENABLED') &&
        configured;
    return MaterialApp(
      title: 'Re:kan',
      debugShowCheckedModeBanner: false,
      theme: validation ? AppTheme.light : AppTheme.onboarding,
      home: validation
          ? const AuthValidationPage()
          : AuthBoundary(
              gateway: configured
                  ? SupabaseAuthGateway(Supabase.instance.client.auth)
                  : null,
              profileRepository: _profileRepository,
            ),
    );
  }
}

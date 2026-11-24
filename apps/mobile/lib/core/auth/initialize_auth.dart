import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'secure_auth_storage.dart';

Future<void> initializeAuth() async {
  final config = AppConfig.supabase;
  if (config == null) return;
  if (kIsWeb) throw UnsupportedError('Web authentication is not configured.');
  final storage = SecureAuthStorage(projectUrl: config.url);
  await Supabase.initialize(
    url: config.url,
    publishableKey: config.publishableKey,
    debug: false,
    authOptions: FlutterAuthClientOptions(
      localStorage: storage,
      pkceAsyncStorage: storage,
      autoRefreshToken: true,
      // Enable after an owned callback URI is configured in Phase 2E.
      detectSessionInUri: false,
    ),
  );
  // SDK owns recovery/refresh. Cached sessions are not API authorization.
}

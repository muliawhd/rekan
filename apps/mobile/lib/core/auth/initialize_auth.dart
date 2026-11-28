import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/direct_supabase_auth_gateway.dart';
import '../config/app_config.dart';
import 'secure_auth_storage.dart';
 
bool _supabaseInitialized = false;
DirectSupabaseAuthGateway? _directGateway;

/// Whether [Supabase.initialize] has completed in this process.
bool get isSupabaseInitialized => _supabaseInitialized;

/// Active direct testing gateway (persists registered random-email accounts in Supabase Postgres).
DirectSupabaseAuthGateway? get directAuthGateway => _directGateway;

Future<void> initializeAuth() async {
  final config = AppConfig.supabase;
  if (config == null) return;
  if (_supabaseInitialized) return;
  if (kIsWeb) {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
      debug: false,
    );
  } else {
    final storage = SecureAuthStorage(projectUrl: config.url);
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        localStorage: storage,
        pkceAsyncStorage: storage,
        autoRefreshToken: true,
        detectSessionInUri: false,
      ),
    );
  }
  final gateway = DirectSupabaseAuthGateway(Supabase.instance.client);
  await gateway.restoreSavedSession();
  _directGateway = gateway;
  _supabaseInitialized = true;
}

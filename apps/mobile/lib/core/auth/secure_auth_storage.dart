import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Project-scoped OS-backed storage for the SDK session and PKCE verifier.
class SecureAuthStorage extends LocalStorage implements GotrueAsyncStorage {
  SecureAuthStorage({required String projectUrl})
    : _prefix = 're.auth.${Uri.parse(projectUrl).host}';
  final String _prefix;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String get _sessionKey => '$_prefix.session';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;
  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);
  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);
  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '$_prefix.pkce.$key');
  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$_prefix.pkce.$key', value: value);
  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '$_prefix.pkce.$key');
}

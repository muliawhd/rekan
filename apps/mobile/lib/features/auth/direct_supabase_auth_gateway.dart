import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateway.dart';

/// Direct Supabase Postgres account gateway for testing (no Supabase Auth email lock).
/// Any email (including random `@gmail.com`) registers immediately into `public.app_accounts`
/// and persists across app restarts via FlutterSecureStorage.
class DirectSupabaseAuthGateway implements AuthGateway {
  DirectSupabaseAuthGateway(
    this._client, {
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final SupabaseClient _client;
  final FlutterSecureStorage _storage;
  final _changes = StreamController<AuthSignal>.broadcast();

  static const _keyId = 'rekan_direct_account_id';
  static const _keyEmail = 'rekan_direct_account_email';

  String? _userId;
  String? _userEmail;

  @override
  String? get userId => _userId;

  String? get userEmail => _userEmail;

  @override
  Stream<AuthSignal> get changes => _changes.stream;

  Future<void> restoreSavedSession() async {
    try {
      _userId = await _storage.read(key: _keyId);
      _userEmail = await _storage.read(key: _keyEmail);
    } catch (_) {
      _userId = null;
      _userEmail = null;
    }
  }

  Future<void> _saveSession(String id, String email) async {
    _userId = id;
    _userEmail = email;
    try {
      await _storage.write(key: _keyId, value: id);
      await _storage.write(key: _keyEmail, value: email);
    } catch (_) {
      // Keep in-memory session even if storage unavailable in tests.
    }
    _changes.add(AuthSignal.changed);
  }

  @override
  Future<String> verifySession() async {
    final id = _userId;
    if (id == null) throw const AuthException('Session unavailable');
    final rows = await _client.rpc(
      'rekan_verify_account',
      params: {'p_account_id': id},
    );
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      await logout();
      throw const AuthException('Session unavailable');
    }
    _userEmail = list.first['email'] as String?;
    return list.first['account_id'] as String;
  }

  @override
  Future<void> register(String email, String password) async {
    final rows = await _client.rpc(
      'rekan_register_account',
      params: {
        'p_email': email.trim(),
        'p_password': password,
      },
    );
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      throw const AuthException('Registration failed');
    }
    final id = list.first['account_id'] as String;
    final savedEmail = list.first['email'] as String;
    await _saveSession(id, savedEmail);
  }

  @override
  Future<void> login(String email, String password) async {
    final rows = await _client.rpc(
      'rekan_login_account',
      params: {
        'p_email': email.trim(),
        'p_password': password,
      },
    );
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      throw const AuthException('Invalid login credentials');
    }
    final id = list.first['account_id'] as String;
    final savedEmail = list.first['email'] as String;
    await _saveSession(id, savedEmail);
  }

  @override
  Future<void> logout() async {
    _userId = null;
    _userEmail = null;
    try {
      await _storage.delete(key: _keyId);
      await _storage.delete(key: _keyEmail);
    } catch (_) {}
    _changes.add(AuthSignal.changed);
  }

  void dispose() {
    _changes.close();
  }
}


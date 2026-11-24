import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_gateway.dart';

enum AuthScreen {
  welcome,
  login,
  register,
  verification,
  recovery,
  checking,
  authenticated,
  sessionError,
}

class AuthController extends ChangeNotifier {
  AuthController(this.gateway) {
    _events = gateway.changes.listen(
      (signal) {
        _revision++;
        if (signal == AuthSignal.recovery) {
          screen = AuthScreen.recovery;
          notifyListeners();
        } else {
          unawaited(restore());
        }
      },
      onError: (Object _) {
        _revision++;
        screen = AuthScreen.sessionError;
        message = 'Sesi belum dapat dipulihkan. Coba lagi.';
        notifyListeners();
      },
    );
    unawaited(restore());
  }
  final AuthGateway gateway;
  late final StreamSubscription<AuthSignal> _events;
  AuthScreen screen = AuthScreen.checking;
  String? message;
  bool busy = false;
  int _revision = 0;
  bool _disposed = false;
  int get revision => _revision;

  Future<void> restore() async {
    final revision = ++_revision;
    final owner = gateway.userId;
    message = null;
    screen = owner == null ? AuthScreen.welcome : AuthScreen.checking;
    if (!_disposed) notifyListeners();
    if (owner == null) return;
    try {
      final verified = await gateway.verifySession().timeout(
        const Duration(seconds: 20),
      );
      if (_disposed || revision != _revision) return;
      if (verified != owner || gateway.userId != owner) {
        screen = AuthScreen.sessionError;
        message = 'Akun berubah. Periksa sesi kembali.';
      } else {
        screen = AuthScreen.authenticated;
      }
    } catch (_) {
      if (_disposed || revision != _revision) return;
      screen = AuthScreen.sessionError;
      message = 'Sesi belum dapat diverifikasi. Coba lagi atau masuk ulang.';
    }
    if (!_disposed) notifyListeners();
  }

  void go(AuthScreen next) {
    if (busy ||
        gateway.userId != null ||
        ![
          AuthScreen.welcome,
          AuthScreen.login,
          AuthScreen.register,
          AuthScreen.recovery,
        ].contains(next)) {
      return;
    }
    _revision++;
    message = null;
    screen = next;
    notifyListeners();
  }

  Future<void> submit(
    String email,
    String password, {
    required bool register,
  }) async {
    if (busy || gateway.userId != null || _disposed) return;
    busy = true;
    message = null;
    final revision = _revision;
    notifyListeners();
    try {
      if (register) {
        await gateway.register(email.trim(), password);
      } else {
        await gateway.login(email.trim(), password);
      }
      if (_disposed) return;
      if (gateway.userId != null) {
        if (revision == _revision) await restore();
      } else if (revision == _revision) {
        screen = register ? AuthScreen.verification : AuthScreen.login;
        if (!register) message = 'Sesi belum tersedia. Coba masuk kembali.';
      }
    } catch (error) {
      if (!_disposed && revision == _revision) message = safeAuthMessage(error);
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> logout() async {
    if (busy || _disposed) return;
    busy = true;
    ++_revision;
    screen = AuthScreen.checking;
    message = null;
    notifyListeners();
    try {
      await gateway.logout();
      if (_disposed) return;
      await restore();
    } catch (error) {
      if (!_disposed) {
        screen = AuthScreen.sessionError;
        message = safeAuthMessage(error);
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _events.cancel();
    super.dispose();
  }
}

abstract final class AuthValidation {
  static String? email(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Masukkan alamat email yang valid.';
  static String? password(String? value, {bool registration = false}) {
    if (value == null || value.isEmpty) return 'Masukkan kata sandi.';
    // Local UX floor, not a claim about the configured server policy.
    if (registration && value.length < 8) return 'Gunakan minimal 8 karakter.';
    return null;
  }

  static String? confirmation(String? value, String password) =>
      value == password && password.isNotEmpty
      ? null
      : 'Konfirmasi kata sandi belum sama.';
}

import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthSignal { changed, recovery }

abstract interface class AuthGateway {
  String? get userId;
  Stream<AuthSignal> get changes;
  Future<String> verifySession();
  Future<void> login(String email, String password);
  Future<void> register(String email, String password);
  Future<void> logout();
}

/// Adapter only; the existing SDK owns secure storage and refresh.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this.auth);
  final GoTrueClient auth;
  @override
  String? get userId => auth.currentSession?.user.id;
  @override
  Stream<AuthSignal> get changes => auth.onAuthStateChange
      .where((event) => event.event != AuthChangeEvent.tokenRefreshed)
      .map(
        (event) => event.event == AuthChangeEvent.passwordRecovery
            ? AuthSignal.recovery
            : AuthSignal.changed,
      );
  @override
  Future<String> verifySession() async {
    if (auth.currentSession?.isExpired ?? true) await auth.refreshSession();
    final user = (await auth.getUser()).user;
    if (user == null) throw const AuthException('Session unavailable');
    return user.id;
  }

  @override
  Future<void> login(String email, String password) async {
    await auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> register(String email, String password) async {
    // No invented callback; email confirmation uses the project's hosted flow.
    await auth.signUp(email: email, password: password);
  }

  @override
  Future<void> logout() => auth.signOut(scope: SignOutScope.local);
}

String safeAuthMessage(Object error) {
  if (error is AuthException) {
    return switch (error.code) {
      'email_not_confirmed' =>
        'Email belum dikonfirmasi. Periksa kotak masukmu.',
      'weak_password' => 'Kata sandi belum memenuhi kebijakan keamanan. Gunakan kata sandi yang lebih kuat.',
      'over_request_rate_limit' || 'over_email_send_rate_limit' =>
        'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
      _ => 'Autentikasi belum berhasil. Periksa email dan kata sandi, lalu coba lagi.',
    };
  }
  return 'Tidak dapat terhubung. Periksa koneksimu lalu coba lagi.';
}

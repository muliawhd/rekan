import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:re_mobile/core/auth/secure_auth_storage.dart';
import 'package:re_mobile/core/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('absent config is optional; partial config fails', () {
    expect(SupabaseConfiguration.parse('', ''), isNull);
    expect(
      () => SupabaseConfiguration.parse('https://dev.supabase.co', ''),
      throwsFormatException,
    );
  });
  test('only HTTPS project roots and modern public keys are accepted', () {
    for (final url in [
      'http://dev.supabase.co',
      'https://dev.supabase.co/auth',
      'https://user:password@dev.supabase.co',
      'https://dev.supabase.co?key=x',
    ]) {
      expect(
        () => SupabaseConfiguration.parse(url, 'sb_publishable_test'),
        throwsFormatException,
      );
    }
    for (final key in ['sb_secret_test', 'legacy-jwt', 'sb_publishable_']) {
      expect(
        () => SupabaseConfiguration.parse('https://dev.supabase.co', key),
        throwsFormatException,
      );
    }
    expect(
      SupabaseConfiguration.parse(
        'https://dev.supabase.co/',
        'sb_publishable_test',
      )!.url,
      'https://dev.supabase.co',
    );
  });
  test(
    'storage recreation restores session and deletion isolates projects',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final first = SecureAuthStorage(projectUrl: 'https://one.supabase.co');
      final second = SecureAuthStorage(projectUrl: 'https://two.supabase.co');
      await first.initialize();
      expect(await first.hasAccessToken(), isFalse);
      await first.persistSession('session-fixture');
      await second.persistSession('other-session');
      final restored = SecureAuthStorage(projectUrl: 'https://one.supabase.co');
      expect(await restored.accessToken(), 'session-fixture');
      await restored.setItem(key: 'verifier', value: 'pkce-fixture');
      expect(await restored.getItem(key: 'verifier'), 'pkce-fixture');
      await restored.removeItem(key: 'verifier');
      expect(await restored.getItem(key: 'verifier'), isNull);
      await restored.removePersistedSession();
      expect(await first.hasAccessToken(), isFalse);
      expect(await second.accessToken(), 'other-session');
    },
  );
}

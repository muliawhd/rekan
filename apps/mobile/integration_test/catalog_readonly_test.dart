import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:re_mobile/core/auth/api_session.dart';
import 'package:re_mobile/core/auth/initialize_auth.dart';
import 'package:re_mobile/core/auth/secure_auth_storage.dart';
import 'package:re_mobile/core/config/app_config.dart';
import 'package:re_mobile/core/network/laravel_api.dart';
import 'package:re_mobile/features/academic_profile/data/academic_catalog_repository.dart';
import 'package:re_mobile/features/academic_profile/data/academic_profile_repository.dart';

/// Explicit development-only GET validation. Never logs credentials or PUTs.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real restored session reads identity, catalogs and own profile', (
    tester,
  ) async {
    expect(AppConfig.apiBaseUrl, 'http://10.0.2.2:8000/api/v1');
    final config = AppConfig.supabase;
    expect(
      config,
      isNotNull,
      reason: 'Supabase development configuration required.',
    );
    final persisted = await SecureAuthStorage(projectUrl: config!.url)
        .hasAccessToken();
    // Only presence is logged; session contents never leave secure storage.
    // ignore: avoid_print
    print('E2E persistedSessionPresent=$persisted');
    expect(
      persisted,
      isTrue,
      reason: 'No persisted session in this app/project storage. Sign in in the normal app.',
    );
    await initializeAuth();
    final sessions = SupabaseApiSession(Supabase.instance.client.auth);
    addTearDown(sessions.dispose);
    expect(
      sessions.current,
      isNotNull,
      reason: 'No restored session: sign in manually using the normal UI before retrying.',
    );
    final api = LaravelApi(baseUrl: AppConfig.apiBaseUrl, sessions: sessions);
    final id = await api.getIdentity();
    expect(
      id,
      sessions.current!.userId,
      reason: 'Supabase/Laravel UUID mismatch.',
    );
    final profiles = AcademicProfileRepository(api);
    final before = await profiles.get();
    expect(before.userId, id);
    // UUID and emptiness are safe evidence; never print the session/token object.
    // ignore: avoid_print
    print('E2E identity=$id; profileEmpty=${before.input.isEmpty}');
    final catalog = AcademicCatalogRepository(api);
    final universities = await catalog.universities();
    final courses = await catalog.courses();
    final skills = await catalog.skills();
    expect(
      universities.map((u) => u.name).toSet(),
      containsAll([
        'Telkom University',
        'Universitas Indonesia',
        'Institut Teknologi Bandung',
        'Universitas Gadjah Mada',
      ]),
    );
    expect(
      courses.map((c) => c.name).toSet(),
      containsAll([
        'Algoritma dan Pemrograman',
        'Struktur Data',
        'Basis Data',
        'Jaringan Komputer',
        'Rekayasa Perangkat Lunak',
        'Sistem Informasi',
        'Kecerdasan Buatan',
        'Statistika',
      ]),
    );
    expect(
      skills.map((s) => s.normalizedName).toSet(),
      containsAll([
        'java',
        'python',
        'sql',
        'flutter',
        'ui/ux design',
        'data analysis',
        'machine learning',
        'public speaking',
        'project management',
        'web development',
      ]),
    );
    expect(
      (await catalog.universities(q: 'Telkom')).single.id,
      universities.firstWhere((u) => u.name == 'Telkom University').id,
    );
    expect(
      (await catalog.skills(q: 'flutter')).single.normalizedName,
      'flutter',
    );
    final scoped = await catalog.courses(
      universityId: universities.first.id,
      q: 'Basis Data',
    );
    expect(scoped, isNotEmpty);
    expect(
      scoped.every((c) => c.isCompatibleWithUniversity(universities.first.id)),
      isTrue,
    );
    expect(
      (await catalog.courses(ids: [courses.first.id])).single.id,
      courses.first.id,
    );
    expect((await profiles.get()).input.toJson(), before.input.toJson());
    // ignore: avoid_print
    print(
      'E2E GETs passed: universities=${universities.length}, courses=${courses.length}, skills=${skills.length}; own profile unchanged.',
    );
  });
}

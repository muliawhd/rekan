import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_mobile/core/network/laravel_api.dart';
import 'package:re_mobile/core/theme/app_theme.dart';
import 'package:re_mobile/features/academic_profile/data/academic_catalog_repository.dart';
import 'package:re_mobile/features/academic_profile/data/academic_profile_repository.dart';
import 'package:re_mobile/features/academic_profile/presentation/academic_catalog_selector.dart';
import 'package:re_mobile/features/academic_profile/presentation/academic_onboarding_page.dart';
import 'package:re_mobile/features/academic_profile/presentation/onboarding_draft_controller.dart';

import 'academic_onboarding_test.dart' show FakeSessionSource, FakeTransport;

const user = '11111111-1111-4111-8111-111111111111';
const university = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const otherUniversity = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const skill = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const global = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const scoped = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

ApiResponse response(Object data) =>
    ApiResponse(200, jsonEncode({'data': data, 'request_id': 'fixture'}));
final universityRows = [
  {'id': university, 'name': 'Campus A'},
  {'id': otherUniversity, 'name': 'Campus B'},
];
final courseRows = [
  {
    'id': global,
    'university_id': null,
    'code': 'GLOBAL',
    'name': 'Global Course',
  },
  {
    'id': scoped,
    'university_id': university,
    'code': 'LOCAL',
    'name': 'Scoped Course',
  },
];

void main() {
  late FakeSessionSource sessions;
  late FakeTransport transport;
  late LaravelApi api;
  late AcademicCatalogRepository repo;
  late OnboardingDraftController draft;
  setUp(() {
    sessions = FakeSessionSource();
    transport = FakeTransport();
    api = LaravelApi(
      baseUrl: 'https://fixture.invalid/api/v1',
      sessions: sessions,
      transport: transport,
    );
    repo = AcademicCatalogRepository(api);
    draft = OnboardingDraftController(
      repository: AcademicProfileRepository(api),
      ownerUserId: user,
    );
    transport.handler = (call) async {
      final rows = switch (call.uri.path.split('/').last) {
        'universities' => universityRows,
        'courses' => courseRows,
        'skills' => [
          {'id': skill, 'normalized_name': 'flutter'},
        ],
        _ => <Map<String, Object?>>[],
      };
      final ids = call.uri.queryParametersAll['ids[]'];
      final q = call.uri.queryParameters['q'];
      return response(
        rows
            .where(
              (r) =>
                  (ids == null || ids.contains(r['id'])) &&
                  (q == null ||
                      r.values
                          .join(' ')
                          .toLowerCase()
                          .contains(q.toLowerCase())),
            )
            .toList(),
      );
    };
  });
  tearDown(() => draft.dispose());

  Future<void> selector(WidgetTester tester, CatalogKind kind) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.onboarding,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: draft,
              builder: (_, _) => AcademicCatalogSelector(
                key: ValueKey(
                  '${kind.name}_${draft.ownerUserId}_${draft.universityId}',
                ),
                kind: kind,
                repository: repo,
                draft: draft,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('typed parsing, search, university scope and UUID queries use one authenticated client', () async {
    expect((await repo.universities(q: 'Campus A')).single.name, 'Campus A');
    expect((await repo.skills(ids: [skill.toUpperCase()])).single.id, skill);
    final courses = await repo.courses(universityId: university, q: 'Course');
    expect(courses.first.universityId, isNull);
    expect(courses.last.universityId, university);
    expect(
      transport.calls.last.uri.queryParameters['university_id'],
      university,
    );
    expect(
      transport.calls.every(
        (c) => c.method == 'GET' && c.body == null && c.token == 'token-$user',
      ),
      isTrue,
    );
    expect(
      transport.calls.every(
        (c) => !c.uri.queryParameters.containsKey('user_id'),
      ),
      isTrue,
    );
  });

  test(
    'lookup chunks 100 selections into two 50-item requests and deduplicates',
    () async {
      final ids = List.generate(
        100,
        (i) => '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
      );
      transport.handler = (c) async => response(
        c.uri.queryParametersAll['ids[]']!
            .map((id) => {'id': id, 'normalized_name': 'skill'})
            .toList(),
      );
      final items = await repo.skills(ids: [...ids, ids.first.toUpperCase()]);
      expect(items, hasLength(100));
      expect(transport.calls, hasLength(2));
      expect(
        transport.calls.every(
          (c) =>
              c.uri.queryParametersAll['ids[]']!.length == 50 &&
              c.uri.queryParameters['limit'] == '50',
        ),
        isTrue,
      );
      expect(await repo.skills(ids: []), isEmpty);
      expect(transport.calls, hasLength(2));
    },
  );

  test(
    'empty catalog, invalid response and network errors are distinct',
    () async {
      transport.handler = (_) async => response([]);
      expect(await repo.skills(), isEmpty);
      for (final bad in [
        <String, dynamic>{},
        [
          {'id': 'bad', 'normalized_name': 'x'},
        ],
        [
          {'id': skill, 'normalized_name': null},
        ],
      ]) {
        transport.handler = (_) async => response(bad);
        await expectLater(
          repo.skills(),
          throwsA(
            isA<ApiFailure>().having(
              (e) => e.kind,
              'kind',
              ApiFailureKind.protocol,
            ),
          ),
        );
      }
      transport.handler = (_) async => throw Exception('network');
      await expectLater(
        repo.universities(),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.network,
          ),
        ),
      );
    },
  );

  test('account changes discard in-flight responses', () async {
    final pending = Completer<ApiResponse>();
    transport.handler = (_) => pending.future;
    final result = repo.universities();
    final assertion = expectLater(
      result,
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.sessionChanged,
        ),
      ),
    );
    sessions.switchUser(otherUniversity);
    pending.complete(response(universityRows));
    await assertion;
  });

  testWidgets('search, empty and retry states preserve the draft', (
    tester,
  ) async {
    draft.setProgram('Preserved program');
    await selector(tester, CatalogKind.universities);
    expect(find.text('Campus A'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'absent');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cari universitas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tidak ada universitas'), findsOneWidget);
    transport.handler = (_) async => throw Exception('offline');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cari universitas'));
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(draft.program, 'Preserved program');
    transport.handler = (_) async => response(universityRows);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Campus A'), findsOneWidget);
  });

  testWidgets(
    'university change needs confirmation and preserves global courses',
    (tester) async {
      draft.setUniversityId(university);
      draft.toggleCourse(global);
      draft.toggleCourse(scoped);
      await selector(tester, CatalogKind.universities);
      await tester.tap(find.text('Campus B'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tinjau mata kuliah'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(draft.universityId, university);
      expect(draft.courses, [global, scoped]);
      await tester.tap(find.text('Campus B'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Ganti kampus dan hapus'));
      await tester.pumpAndSettle();
      expect(draft.universityId, otherUniversity);
      expect(draft.courses, [global]);
    },
  );

  testWidgets(
    'skills and course selectors prevent duplicates and preserve levels',
    (tester) async {
      await selector(tester, CatalogKind.skills);
      await tester.tap(find.text('flutter'));
      await tester.pumpAndSettle();
      draft.upsertSkill(skill, 5);
      draft.upsertSkill(skill.toUpperCase(), 5);
      expect(draft.skills.single.level, 5);
      await selector(tester, CatalogKind.courses);
      expect(find.textContaining('Scoped Course'), findsNothing);
      await tester.tap(find.text('GLOBAL · Global Course'));
      await tester.pumpAndSettle();
      expect(draft.courses, [global]);
      await tester.tap(find.text('GLOBAL · Global Course'));
      await tester.pumpAndSettle();
      expect(draft.courses, isEmpty);
    },
  );

  testWidgets('loading response cannot restore labels after account reset', (
    tester,
  ) async {
    final pending = Completer<ApiResponse>();
    transport.handler = (_) => pending.future;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcademicCatalogSelector(
            kind: CatalogKind.universities,
            repository: repo,
            draft: draft,
          ),
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    sessions.switchUser(otherUniversity);
    draft.resetForUser(otherUniversity);
    pending.complete(response(universityRows));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(draft.catalog, isNull);
    expect(find.text('Campus A'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('skill level controls work at narrow width and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    draft.setDisplayName('Student');
    draft.setProgram('Computing');
    draft.setSemester(2);
    draft.setUniversityId(university);
    draft.upsertSkill(skill, 3);
    draft.goToStep(3);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.onboarding,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: AcademicOnboardingPage(
          controller: draft,
          catalogRepository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final level = find.byKey(const ValueKey('skill_level_${skill}_5'));
    await tester.ensureVisible(level);
    await tester.tap(level);
    await tester.pumpAndSettle();
    expect(draft.skills.single.level, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unresolved existing courses prevent a destructive university change',
    (tester) async {
      draft.setUniversityId(university);
      draft.toggleCourse(scoped);
      await selector(tester, CatalogKind.universities);
      transport.handler = (_) async => response([]);
      await tester.tap(find.text('Campus B'));
      await tester.pumpAndSettle();
      expect(draft.universityId, university);
      expect(draft.courses, [scoped]);
      expect(
        find.textContaining('Kampus dan pilihan lama dipertahankan'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'disposing the account boundary dismisses its course confirmation',
    (tester) async {
      draft.setUniversityId(university);
      draft.toggleCourse(scoped);
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (_, show, _) => show
                  ? AcademicCatalogSelector(
                      kind: CatalogKind.universities,
                      repository: repo,
                      draft: draft,
                    )
                  : const Text('Next account'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Campus B'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tinjau mata kuliah'), findsOneWidget);
      sessions.switchUser(otherUniversity);
      visible.value = false;
      await tester.pumpAndSettle();
      expect(find.text('Tinjau mata kuliah'), findsNothing);
      expect(draft.universityId, university);
      expect(draft.courses, [scoped]);
      expect(tester.takeException(), isNull);
    },
  );

  test('catalog UUIDs submit with untouched fields, recoverable failures and duplicate lock', () async {
    draft.setDisplayName('Student');
    draft.setProgram('Computing');
    draft.setSemester(2);
    draft.setBio('Keep this');
    draft.setUniversityId((await repo.universities()).first.id);
    draft.upsertSkill((await repo.skills()).single.id, 4);
    draft.toggleCourse((await repo.courses()).first.id);
    transport.handler = (_) async => const ApiResponse(503, '{}');
    expect(await draft.save(), isNull);
    expect(draft.bio, 'Keep this');
    expect(draft.skills.single.level, 4);
    final pending = Completer<ApiResponse>();
    transport.handler = (_) => pending.future;
    final saved = draft.save();
    expect(await draft.save(), isNull);
    final call = transport.calls.last;
    expect(call.body!['university_id'], university);
    expect(call.body!['courses'], [global]);
    expect(call.body!['bio'], 'Keep this');
    expect(call.requireEmpty, isTrue);
    pending.complete(response({'user_id': user, ...call.body!}));
    expect((await saved)?.input.skills.single.level, 4);
  });
}

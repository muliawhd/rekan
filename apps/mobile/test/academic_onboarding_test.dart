import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_mobile/core/auth/api_session.dart';
import 'package:re_mobile/core/network/laravel_api.dart';
import 'package:re_mobile/core/theme/app_theme.dart';
import 'package:re_mobile/features/academic_profile/data/academic_profile.dart';
import 'package:re_mobile/features/academic_profile/data/academic_profile_repository.dart';
import 'package:re_mobile/features/academic_profile/domain/academic_onboarding_completion.dart';
import 'package:re_mobile/features/academic_profile/presentation/academic_onboarding_page.dart';
import 'package:re_mobile/features/academic_profile/presentation/onboarding_draft_controller.dart';
import 'package:re_mobile/features/auth/auth_boundary.dart';
import 'package:re_mobile/features/auth/auth_gateway.dart';

const _userA = '11111111-1111-4111-8111-111111111111';
const _userB = '22222222-2222-4222-8222-222222222222';
const _uniItb = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _uniUgm = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _skillFlutter = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _skillPython = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _courseGlobal = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _courseItbOnly = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

const _sampleCatalog = AcademicCatalogSnapshot(
  universities: [
    UniversityCatalogItem(
      id: _uniItb,
      name: 'Institut Teknologi Bandung (ITB)',
    ),
    UniversityCatalogItem(id: _uniUgm, name: 'Universitas Gadjah Mada (UGM)'),
  ],
  skills: [
    SkillCatalogItem(id: _skillFlutter, normalizedName: 'flutter'),
    SkillCatalogItem(id: _skillPython, normalizedName: 'python'),
  ],
  courses: [
    CourseCatalogItem(
      id: _courseGlobal,
      code: 'KU1102',
      name: 'Pengenalan Komputasi',
    ),
    CourseCatalogItem(
      id: _courseItbOnly,
      code: 'IF2210',
      name: 'Pemrograman Berorientasi Objek',
      universityId: _uniItb,
    ),
  ],
);

class FakeSessionSource implements ApiSessionSource {
  FakeSessionSource({String userId = _userA})
    : current = ApiSession(userId, 'token-$userId', false, 1);

  @override
  ApiSession? current;

  int generation = 1;

  void switchUser(String userId) {
    generation++;
    current = ApiSession(userId, 'token-$userId', false, generation);
  }

  @override
  Future<void> refresh() async {}
}

class FakeRecordedCall {
  const FakeRecordedCall({
    required this.method,
    required this.uri,
    required this.token,
    required this.body,
    required this.requireEmpty,
  });

  final String method;
  final Uri uri;
  final String token;
  final Map<String, dynamic>? body;
  final bool requireEmpty;
}

class FakeTransport implements ApiTransport {
  final List<FakeRecordedCall> calls = <FakeRecordedCall>[];
  late Future<ApiResponse> Function(FakeRecordedCall call) handler;

  @override
  Future<ApiResponse> send(
    String method,
    Uri uri,
    String token,
    Map<String, dynamic>? body, {
    bool requireEmpty = false,
  }) {
    final call = FakeRecordedCall(
      method: method,
      uri: uri,
      token: token,
      body: body == null
          ? null
          : jsonDecode(jsonEncode(body)) as Map<String, dynamic>,
      requireEmpty: requireEmpty,
    );
    calls.add(call);
    return handler(call);
  }
}

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.userId = _userA});

  @override
  String? userId;

  final StreamController<AuthSignal> events =
      StreamController<AuthSignal>.broadcast();

  @override
  Stream<AuthSignal> get changes => events.stream;

  @override
  Future<String> verifySession() async => userId!;

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> register(String email, String password) async {}

  @override
  Future<void> logout() async {
    userId = null;
    events.add(AuthSignal.changed);
  }
}

ApiResponse _profileEnvelope(
  String userId, {
  String? displayName,
  String? universityId,
  String? program,
  int? semester,
  String? bio,
  String? mbtiBadge,
  String visibility = 'private',
  List<String> courses = const [],
  List<Map<String, dynamic>> skills = const [],
  String? studyMode,
  String? preferredLanguage,
}) {
  return ApiResponse(
    200,
    jsonEncode({
      'data': {
        'user_id': userId,
        'display_name': displayName,
        'university_id': universityId,
        'program': program,
        'semester': semester,
        'bio': bio,
        'mbti_badge': mbtiBadge,
        'visibility': visibility,
        'courses': courses,
        'skills': skills,
        'preferences': {
          'study_mode': studyMode,
          'preferred_language': preferredLanguage,
        },
      },
      'request_id': 'req-test',
    }),
  );
}

AcademicProfileRepository _makeRepository(
  FakeSessionSource sessions,
  FakeTransport transport,
) {
  final api = LaravelApi(
    baseUrl: 'https://api.example.test/api/v1',
    sessions: sessions,
    transport: transport,
  );
  return AcademicProfileRepository(api);
}

void main() {
  test('completion predicate requires display_name, university_id, program, and semester; optional fields never block', () {
    final empty = AcademicProfileInput();
    expect(AcademicOnboardingCompletion.isComplete(empty), isFalse);
    expect(
      AcademicOnboardingCompletion.missingRequiredFields(empty),
      equals(['display_name', 'university_id', 'program', 'semester']),
    );

    final missingUniversity = AcademicProfileInput(
      displayName: 'Nabila Rahmawati',
      universityId: null,
      program: 'Teknik Informatika',
      semester: 4,
    );
    expect(AcademicOnboardingCompletion.isComplete(missingUniversity), isFalse);
    expect(
      AcademicOnboardingCompletion.missingRequiredFields(missingUniversity),
      equals(['university_id']),
    );

    final minimalComplete = AcademicProfileInput(
      displayName: 'Nabila Rahmawati',
      universityId: _uniItb,
      program: 'Teknik Informatika',
      semester: 4,
    );
    expect(AcademicOnboardingCompletion.isComplete(minimalComplete), isTrue);
    expect(
      AcademicOnboardingCompletion.missingRequiredFields(minimalComplete),
      isEmpty,
    );
  });

  test('step navigation, required/optional validation, draft preservation and existing field preservation work', () async {
    final sessions = FakeSessionSource();
    final transport = FakeTransport();
    final repo = _makeRepository(sessions, transport);

    // Existing profile with pre-existing courses, skills, and visibility (even with catalog == null)
    final existingProfile = AcademicProfile(
      userId: _userA,
      input: AcademicProfileInput(
        displayName: 'Nabila',
        universityId: _uniItb,
        program: null,
        semester: null,
        bio: 'Tertarik riset AI',
        mbtiBadge: 'INTJ',
        visibility: ProfileVisibility.university,
        courses: const [_courseGlobal],
        skills: const [SkillSelection(skillId: _skillPython, level: 4)],
        preferences: const AcademicPreferences(
          studyMode: StudyMode.hybrid,
          preferredLanguage: 'id',
        ),
      ),
    );

    final draft = OnboardingDraftController(
      repository: repo,
      ownerUserId: _userA,
      initialProfile: existingProfile,
    );

    // Step 1 validation: empty display_name blocks nextStep
    draft.setDisplayName('   ');
    expect(draft.nextStep(), isFalse);
    expect(draft.currentStep, 1);
    expect(draft.displayNameError, isNotNull);

    // Invalid MBTI blocks nextStep even though MBTI is optional
    draft.setDisplayName('Nabila Rahmawati');
    draft.setMbtiBadge('ABCD');
    expect(draft.nextStep(), isFalse);
    expect(draft.mbtiBadgeError, isNotNull);

    // Clearing optional MBTI allows advancing to Step 2
    draft.setMbtiBadge('');
    expect(draft.nextStep(), isTrue);
    expect(draft.currentStep, 2);

    // Step 2 validation: missing program or out-of-range semester blocks nextStep
    expect(draft.nextStep(), isFalse);
    expect(draft.programError, isNotNull);
    expect(draft.semesterError, isNotNull);

    draft.setProgram('Sistem Informasi');
    draft.setSemesterText('25');
    expect(draft.nextStep(), isFalse);
    expect(draft.semesterError, isNotNull);

    draft.setSemester(5);
    expect(draft.nextStep(), isTrue);
    expect(draft.currentStep, 3);

    // Step 3 (Skills) and Step 4 (Courses) are optional and preserve existing UUIDs
    expect(draft.skills.single.skillId, _skillPython);
    expect(draft.skills.single.level, 4);
    expect(draft.nextStep(), isTrue);
    expect(draft.currentStep, 4);

    expect(draft.courses, equals([_courseGlobal]));
    expect(draft.nextStep(), isTrue);
    expect(draft.currentStep, 5);

    // Back navigation preserves all draft values
    expect(draft.previousStep(), isTrue);
    expect(draft.currentStep, 4);
    expect(draft.previousStep(), isTrue);
    expect(draft.currentStep, 3);
    expect(draft.goToStep(5), isTrue);
    expect(draft.currentStep, 5);

    // Invalid language tag blocks save on Step 5
    draft.setPreferredLanguage('INVALID_LANG_TAG!!');
    expect(draft.validateStep(5), isFalse);
    expect(draft.preferredLanguageError, isNotNull);
    draft.setPreferredLanguage('id-ID');

    // Saving a profile that was NOT initially empty sends requireEmpty: false
    // and preserves untouched universityId, visibility, courses, and skills.
    transport.handler = (call) async {
      expect(call.method, 'PUT');
      expect(call.requireEmpty, isFalse);
      expect(call.body!.containsKey('user_id'), isFalse);
      expect(call.body!['display_name'], 'Nabila Rahmawati');
      expect(call.body!['university_id'], _uniItb);
      expect(call.body!['program'], 'Sistem Informasi');
      expect(call.body!['semester'], 5);
      expect(call.body!['bio'], 'Tertarik riset AI');
      expect(call.body!['mbti_badge'], isNull);
      expect(call.body!['visibility'], 'university');
      expect(call.body!['courses'], equals([_courseGlobal]));
      expect(
        call.body!['skills'],
        equals([
          {'skill_id': _skillPython, 'level': 4},
        ]),
      );
      expect(
        call.body!['preferences'],
        equals({'study_mode': 'hybrid', 'preferred_language': 'id-ID'}),
      );
      return ApiResponse(
        200,
        jsonEncode({
          'data': {'user_id': _userA, ...call.body!},
          'request_id': 'req-save-1',
        }),
      );
    };

    final saved = await draft.save();
    expect(saved, isNotNull);
    expect(AcademicOnboardingCompletion.isComplete(saved!.input), isTrue);
    expect(draft.hasUnsavedChanges, isFalse);
    draft.dispose();
  });

  test('duplicate submissions are blocked, recoverable network/validation/conflict errors preserve draft, and account switch wipes draft', () async {
    final sessions = FakeSessionSource();
    final transport = FakeTransport();
    final repo = _makeRepository(sessions, transport);

    final emptyInitial = AcademicProfile(
      userId: _userA,
      input: AcademicProfileInput(),
    );
    final draft = OnboardingDraftController(
      repository: repo,
      ownerUserId: _userA,
      initialProfile: emptyInitial,
      catalog: _sampleCatalog,
    );

    draft.setDisplayName('Raka Pratama');
    draft.setUniversityId(_uniUgm);
    draft.setProgram('Ilmu Komputer');
    draft.setSemester(3);
    draft.upsertSkill(_skillFlutter, 5);
    draft.toggleCourse(_courseGlobal);

    // 1. Duplicate submission lock
    final pending = Completer<ApiResponse>();
    transport.handler = (_) => pending.future;

    final firstSave = draft.save();
    expect(draft.saving, isTrue);
    final duplicateSave = await draft.save();
    expect(duplicateSave, isNull);
    expect(transport.calls.length, 1);
    // Initially empty profile sends X-Re-Require-Empty-Profile: true
    expect(transport.calls.single.requireEmpty, isTrue);

    // 2. Recoverable 422 validation error preserves all draft fields
    pending.complete(
      const ApiResponse(
        422,
        '{"error":{"code":"VALIDATION_ERROR","message":"Invalid.","details":{}},"request_id":"r1"}',
      ),
    );
    final firstResult = await firstSave;
    expect(firstResult, isNull);
    expect(draft.saving, isFalse);
    expect(draft.saveFailure?.kind, ApiFailureKind.validation);
    expect(draft.saveFailureMessage, contains('422'));
    expect(draft.displayName, 'Raka Pratama');
    expect(draft.universityId, _uniUgm);
    expect(draft.program, 'Ilmu Komputer');
    expect(draft.semester, 3);
    expect(draft.skills.single.skillId, _skillFlutter);
    expect(draft.courses, equals([_courseGlobal]));

    // 3. 409 PROFILE_NOT_EMPTY conflict preserves draft and surfaces safe message
    transport.handler = (_) async => const ApiResponse(
      409,
      '{"error":{"code":"PROFILE_NOT_EMPTY","message":"Not empty.","details":{}},"request_id":"r2"}',
    );
    expect(await draft.save(), isNull);
    expect(draft.saveFailure?.kind, ApiFailureKind.conflict);
    expect(draft.saveFailureMessage, contains('tidak ditimpa otomatis'));
    expect(draft.displayName, 'Raka Pratama');

    // 4. Account switch during in-flight save discards stale response and wipes draft
    final switchPending = Completer<ApiResponse>();
    transport.handler = (_) => switchPending.future;
    final inFlightForA = draft.save();
    expect(draft.saving, isTrue);

    sessions.switchUser(_userB);
    draft.resetForUser(_userB);
    expect(draft.ownerUserId, _userB);
    expect(draft.displayName, isEmpty);
    expect(draft.universityId, isNull);
    expect(draft.skills, isEmpty);
    expect(draft.courses, isEmpty);
    expect(draft.saving, isFalse);

    switchPending.complete(
      _profileEnvelope(
        _userA,
        displayName: 'Raka Pratama',
        universityId: _uniUgm,
        program: 'Ilmu Komputer',
        semester: 3,
      ),
    );
    expect(await inFlightForA, isNull);
    expect(draft.ownerUserId, _userB);
    expect(draft.displayName, isEmpty);
    expect(draft.savedProfile, isNull);
    draft.dispose();
  });

  testWidgets(
    '5-step onboarding UI navigates, validates, reviews, handles missing catalog and persists profile into completed view',
    (tester) async {
      final sessions = FakeSessionSource();
      final transport = FakeTransport();
      final repo = _makeRepository(sessions, transport);
      final auth = FakeAuthGateway(userId: _userA);

      // Scrolls in-content controls into view before tapping (800x600 viewport).
      Future<void> tapInContent(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pump();
      }

      transport.handler = (call) async {
        if (call.method == 'GET') {
          return _profileEnvelope(_userA);
        }
        return ApiResponse(
          200,
          jsonEncode({
            'data': {'user_id': _userA, ...call.body!},
            'request_id': 'req-put-ui',
          }),
        );
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          home: AuthBoundary(
            gateway: auth,
            profileRepository: repo,
            catalog: _sampleCatalog,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Incomplete profile opens Step 1 — Identitas Akademik
      expect(find.text('LANGKAH 1 DARI 5'), findsOneWidget);
      expect(find.text('Identitas Akademik'), findsOneWidget);

      // Attempting to continue without display_name shows validation error
      await tester.tap(find.text('Lanjutkan (2/5) ->'));
      await tester.pumpAndSettle();
      expect(find.text('Nama tampilan wajib diisi.'), findsOneWidget);
      expect(find.text('LANGKAH 1 DARI 5'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('onboarding_display_name')),
        'Nabila Rahmawati',
      );
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_bio')),
        'Kolaborasi lomba data science & UI/UX.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_mbti')),
        'intj',
      );
      await tester.tap(find.text('Lanjutkan (2/5) ->'));
      await tester.pumpAndSettle();

      // Step 2 — Universitas, Program Studi & Semester
      expect(find.text('LANGKAH 2 DARI 5'), findsOneWidget);
      expect(
        find.text('Universitas, Program Studi & Semester'),
        findsOneWidget,
      );

      // Select ITB, enter program & tap Semester 4 chip
      await tapInContent(
        find.byKey(const ValueKey('university_option_$_uniItb')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_program')),
        'Teknik Informatika',
      );
      await tapInContent(find.byKey(const ValueKey('semester_chip_4')));
      await tester.tap(find.text('Lanjutkan (3/5) ->'));
      await tester.pumpAndSettle();

      // Step 3 — Keahlian dan Minat
      expect(find.text('LANGKAH 3 DARI 5'), findsOneWidget);
      expect(find.text('Keahlian dan Minat'), findsOneWidget);
      await tapInContent(
        find.byKey(const ValueKey('catalog_skill_$_skillFlutter')),
      );
      await tapInContent(
        find.byKey(const ValueKey('skill_level_${_skillFlutter}_5')),
      );
      await tester.tap(find.text('Lanjutkan (4/5) ->'));
      await tester.pumpAndSettle();

      // Step 4 — Mata Kuliah Aktif
      expect(find.text('LANGKAH 4 DARI 5'), findsOneWidget);
      expect(find.text('Mata Kuliah Aktif'), findsOneWidget);
      await tapInContent(
        find.byKey(const ValueKey('catalog_course_$_courseItbOnly')),
      );
      await tester.tap(find.text('Lanjutkan (5/5) ->'));
      await tester.pumpAndSettle();

      // Step 5 — Preferensi Belajar & Review
      expect(find.text('LANGKAH 5 DARI 5'), findsOneWidget);
      expect(find.text('Preferensi Belajar & Review'), findsOneWidget);
      expect(find.text('Tinjau Profil Akademik'), findsOneWidget);
      expect(find.text('SIAP LENGKAP'), findsOneWidget);
      expect(find.text('Nabila Rahmawati'), findsOneWidget);
      expect(find.text('Institut Teknologi Bandung (ITB)'), findsOneWidget);
      expect(find.text('Teknik Informatika'), findsOneWidget);
      expect(find.text('Semester 4'), findsOneWidget);

      await tapInContent(find.byKey(const ValueKey('study_mode_hybrid')));
      await tapInContent(find.byKey(const ValueKey('lang_chip_id')));
      await tapInContent(find.byKey(const ValueKey('visibility_university')));

      // Review screen alone never sends a request; only explicit save does.
      expect(transport.calls.where((c) => c.method == 'PUT'), isEmpty);

      // Save profile from Review step
      await tester.tap(find.text('Simpan Profil'));
      await tester.pumpAndSettle();

      // Exactly one complete PUT with the reviewed draft and no user_id.
      final puts = transport.calls.where((c) => c.method == 'PUT').toList();
      expect(puts, hasLength(1));
      expect(puts.single.requireEmpty, isTrue);
      expect(puts.single.body, {
        'display_name': 'Nabila Rahmawati',
        'university_id': _uniItb,
        'program': 'Teknik Informatika',
        'semester': 4,
        'bio': 'Kolaborasi lomba data science & UI/UX.',
        'mbti_badge': 'INTJ',
        'visibility': 'university',
        'courses': [_courseItbOnly],
        'skills': [
          {'skill_id': _skillFlutter, 'level': 5},
        ],
        'preferences': {'study_mode': 'hybrid', 'preferred_language': 'id'},
      });

      // Verify transition to Completed Academic Profile view
      expect(find.text('PROFIL LENGKAP'), findsOneWidget);
      expect(find.text('Ruang akademikmu'), findsOneWidget);
      expect(find.text('Perbarui Profil Akademik'), findsOneWidget);

      // Tapping Perbarui Profil Akademik re-opens 5-step onboarding with saved data
      await tester.tap(find.text('Perbarui Profil Akademik'));
      await tester.pumpAndSettle();
      expect(find.text('LANGKAH 1 DARI 5'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('onboarding_display_name')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'Nabila Rahmawati',
      );

      await tester.pumpWidget(const SizedBox());
      await auth.events.close();
    },
  );

  testWidgets(
    'missing catalog endpoints surface clear Bahasa Indonesia notices without fabricating UUIDs and scale at 2.0x text on 320x640',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sessions = FakeSessionSource();
      final transport = FakeTransport()
        ..handler = (_) async => _profileEnvelope(_userA);
      final repo = _makeRepository(sessions, transport);
      final draft = OnboardingDraftController(
        repository: repo,
        ownerUserId: _userA,
        initialProfile: AcademicProfile(
          userId: _userA,
          input: AcademicProfileInput(
            displayName: 'Damar Prasetyo',
            program: 'Sistem Informasi',
            semester: 4,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: AcademicOnboardingPage(controller: draft),
        ),
      );
      await tester.pumpAndSettle();

      // Advance through all 5 steps with catalog == null
      await tester.tap(find.text('Lanjutkan (2/5) ->'));
      await tester.pumpAndSettle();
      expect(find.text('KATALOG KAMPUS BELUM TERSEDIA'), findsOneWidget);
      expect(draft.universityId, isNull);

      await tester.tap(find.text('Lanjutkan (3/5) ->'));
      await tester.pumpAndSettle();
      expect(find.text('KATALOG KEAHLIAN BELUM TERSEDIA'), findsOneWidget);

      await tester.tap(find.text('Lanjutkan (4/5) ->'));
      await tester.pumpAndSettle();
      expect(find.text('KATALOG MATA KULIAH BELUM TERSEDIA'), findsOneWidget);

      await tester.tap(find.text('Lanjutkan (5/5) ->'));
      await tester.pumpAndSettle();
      expect(find.text('DRAF PARSIAL'), findsOneWidget);
      expect(find.text('FIELD WAJIB BELUM LENGKAP'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );
}

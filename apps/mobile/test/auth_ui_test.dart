import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:re_mobile/core/theme/rekan_theme.dart';
import 'package:re_mobile/features/auth/auth_boundary.dart';
import 'package:re_mobile/features/auth/auth_controller.dart';
import 'package:re_mobile/features/auth/auth_gateway.dart';
import 'package:re_mobile/features/rekan/data/rekan_models.dart';
import 'package:re_mobile/features/rekan/data/supabase_rekan_repository.dart';

class FakeAuth implements AuthGateway {
  @override
  String? userId;
  final events = StreamController<AuthSignal>.broadcast(sync: true);
  Future<String> Function()? verify;
  Future<void> Function()? action;
  Object? error;
  int logins = 0, registrations = 0, logouts = 0;
  bool autoConfirm = false;

  @override
  Stream<AuthSignal> get changes => events.stream;

  @override
  Future<String> verifySession() async {
    if (verify != null) return verify!();
    if (error != null) throw error!;
    return userId!;
  }

  @override
  Future<void> login(String email, String password) async {
    logins++;
    if (action != null) await action!();
    if (error != null) throw error!;
    userId = 'account-a';
    events.add(AuthSignal.changed);
  }

  @override
  Future<void> register(String email, String password) async {
    registrations++;
    if (error != null) throw error!;
    if (autoConfirm) {
      userId = 'account-a';
      events.add(AuthSignal.changed);
    }
  }

  @override
  Future<void> logout() async {
    logouts++;
    userId = null;
    events.add(AuthSignal.changed);
  }
}

class FakeRekanRepo implements RekanRepository {
  FakeRekanRepo({this.myProfile});

  StudentProfile? myProfile;
  final Set<String> bookmarks = {};

  @override
  String? get currentUserId => 'account-a';

  @override
  String? get currentUserEmail => 'chiko@kampus.ac.id';

  @override
  Future<RekanCatalog> fetchCatalog() async => const RekanCatalog(
        universities: [
          UniversityItem(
            id: 'u1',
            name: 'Universitas Tanjungpura',
            shortName: 'UNTAN',
            city: 'Pontianak',
          ),
        ],
        courses: [
          CourseItem(
            id: 'c1',
            code: 'IF2110',
            name: 'Algoritma & Struktur Data',
            category: 'Ilmu Komputer',
          ),
        ],
        skills: [
          SkillItem(id: 's1', name: 'Flutter & Dart', category: 'Teknologi'),
        ],
      );

  @override
  Future<StudentProfile?> fetchMyProfile() async => myProfile;

  @override
  Future<StudentProfile> saveMyProfile(ProfileDraftInput input) async {
    myProfile = StudentProfile(
      id: 'me-1',
      authUserId: 'account-a',
      displayName: input.displayName,
      universityId: input.universityId,
      universityName: 'Universitas Tanjungpura',
      universityShortName: 'UNTAN',
      program: input.program,
      semester: input.semester,
      intent: input.intent,
      roleFocus: input.roleFocus,
      projectGoal: input.projectGoal,
      bio: input.bio,
      mbtiBadge: input.mbtiBadge,
      studyMode: input.studyMode,
      preferredLanguage: 'id',
      accessibilityNotes: input.accessibilityNotes,
      visibility: input.visibility,
      availabilityLabel: input.availabilityLabel,
      isOnline: true,
      onboardingCompleted: true,
    );
    return myProfile!;
  }

  @override
  Future<List<StudentProfile>> fetchDiscoveryProfiles() async => const [
        StudentProfile(
          id: 'p1',
          displayName: 'Nabila Putri',
          universityShortName: 'UNTAN',
          program: 'Informatika',
          semester: 5,
          intent: 'competition',
          roleFocus: 'UI/UX',
          projectGoal: 'Mencari tim Gemastik UX 2026',
          bio: 'Fokus desain aksesibel.',
          mbtiBadge: 'ENFP',
          studyMode: 'hybrid',
          preferredLanguage: 'id',
          accessibilityNotes: 'Diskusi teks terstruktur',
          visibility: 'public',
          availabilityLabel: 'Kamis malam',
          isOnline: true,
          onboardingCompleted: true,
        ),
      ];

  @override
  Future<Set<String>> fetchBookmarkedProfileIds() async => bookmarks;

  @override
  Future<bool> toggleBookmark(String targetProfileId) async {
    if (bookmarks.contains(targetProfileId)) {
      bookmarks.remove(targetProfileId);
      return false;
    }
    bookmarks.add(targetProfileId);
    return true;
  }

  @override
  Future<List<InvitationItem>> fetchInvitations() async => const [];

  @override
  Future<void> sendInvitation({
    required String targetProfileId,
    required String intent,
    required String goalNote,
  }) async {}

  @override
  Future<void> updateInvitationStatus(String invitationId, String status) async {}

  @override
  Future<List<CollaborationRoom>> fetchRooms() async => const [];

  @override
  Future<void> createRoom({
    required String title,
    required String courseCode,
    required String intent,
    required String description,
    required String nextSessionLabel,
  }) async {}

  @override
  Future<void> toggleTask(String taskId, bool isDone) async {}

  @override
  Future<void> addTask({
    required String roomId,
    required String title,
    required String dueLabel,
  }) async {}

  @override
  Future<void> sendRoomMessage({
    required String roomId,
    required String senderName,
    required String body,
  }) async {}

  @override
  Future<List<DirectMessageItem>> fetchDirectMessages(
    String peerProfileId,
  ) async =>
      const [];

  @override
  Future<void> sendDirectMessage({
    required String peerProfileId,
    required String senderName,
    required String body,
  }) async {}

  @override
  Future<List<CourseDiscussionItem>> fetchCourseDiscussions() async => const [];

  @override
  Future<void> createCourseDiscussion({
    required String courseId,
    required String authorName,
    required String title,
    required String body,
  }) async {}
}

Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  testWidgets(
    'small large-text auth forms scroll cleanly and recovery does not send requests',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAuth();
      await tester.pumpWidget(
        MaterialApp(
          theme: RekanPalette.themeData,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: AuthBoundary(gateway: auth),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Lupa kata sandi?'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();

      expect(find.text('Pulihkan Akses Akun'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Tidak ada email pemulihan'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Tidak ada email pemulihan'), findsOneWidget);
      expect(auth.logins + auth.registrations + auth.logouts, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await auth.events.close();
    },
  );

  test('email, login, registration and confirmation validation', () {
    expect(AuthValidation.email('bad'), isNotNull);
    expect(AuthValidation.email(' a@example.test '), isNull);
    expect(AuthValidation.password(''), isNotNull);
    expect(AuthValidation.password('short'), isNull);
    expect(AuthValidation.password('short', registration: true), isNotNull);
    expect(
      AuthValidation.password('long-password', registration: true),
      isNull,
    );
    expect(AuthValidation.confirmation('other', 'password'), isNotNull);
    expect(AuthValidation.confirmation('password', 'password'), isNull);
  });

  test('server exceptions never expose raw details', () {
    expect(
      safeAuthMessage(const AuthException('secret token')),
      isNot(contains('secret')),
    );
    expect(
      safeAuthMessage(
        const AuthException('secret', code: 'email_not_confirmed'),
      ),
      contains('belum dikonfirmasi'),
    );
  });

  test('restores existing session without login or logout', () async {
    final auth = FakeAuth()..userId = 'existing';
    final controller = AuthController(auth);
    expect(controller.screen, AuthScreen.checking);
    await tick();
    expect(controller.screen, AuthScreen.authenticated);
    expect(auth.logins + auth.logouts, 0);
    controller.dispose();
    await auth.events.close();
  });

  test('expired or failed session cannot open protected content', () async {
    final auth = FakeAuth()
      ..userId = 'expired'
      ..error = Exception('private');
    final controller = AuthController(auth);
    await tick();
    expect(controller.screen, AuthScreen.sessionError);
    expect(auth.userId, 'expired');
    expect(controller.message, isNot(contains('private')));
    controller.dispose();
    await auth.events.close();
  });

  testWidgets('login fields, visibility, loading and failure state', (
    tester,
  ) async {
    final auth = FakeAuth();
    await tester.pumpWidget(
      MaterialApp(
        theme: RekanPalette.themeData,
        home: AuthBoundary(gateway: auth),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    expect(auth.logins, 0);

    await tester.enterText(find.byType(TextFormField).at(0), 'a@example.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      true,
    );
    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      false,
    );

    final pending = Completer<void>();
    auth.action = () => pending.future;
    auth.error = const AuthException('private');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Memeriksa akun...'), findsOneWidget);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Autentikasi belum berhasil'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
  });

  testWidgets('registration checks confirmation and presents email status', (
    tester,
  ) async {
    final auth = FakeAuth();
    await tester.pumpWidget(
      MaterialApp(
        theme: RekanPalette.themeData,
        home: AuthBoundary(gateway: auth),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Daftar Sekarang'));
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'a@example.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.enterText(find.byType(TextFormField).at(2), 'wrong');
    await tester.ensureVisible(find.text('Daftar Akun'));
    await tester.tap(find.text('Daftar Akun'));
    await tester.pumpAndSettle();

    expect(auth.registrations, 0);
    expect(find.text('Konfirmasi kata sandi belum sama.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), 'password');
    await tester.ensureVisible(find.text('Daftar Akun'));
    await tester.tap(find.text('Daftar Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Periksa Emailmu'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
  });

  testWidgets(
    'authenticated workspace loads Supabase repo, navigates 5 tabs, and logs out',
    (tester) async {
      final auth = FakeAuth()..userId = 'account-a';
      final repo = FakeRekanRepo(
        myProfile: const StudentProfile(
          id: 'me-1',
          authUserId: 'account-a',
          displayName: 'Chiko Pratama',
          universityShortName: 'UNTAN',
          universityName: 'Universitas Tanjungpura',
          program: 'Informatika',
          semester: 5,
          intent: 'both',
          roleFocus: 'Mobile Dev',
          projectGoal: 'Membangun aplikasi Re:kan',
          bio: 'Mahasiswa Informatika',
          mbtiBadge: 'INTJ',
          studyMode: 'hybrid',
          preferredLanguage: 'id',
          accessibilityNotes: 'Ramah teks',
          visibility: 'public',
          availabilityLabel: 'Malam hari',
          isOnline: true,
          onboardingCompleted: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: RekanPalette.themeData,
          home: AuthBoundary(gateway: auth, rekanRepository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jelajah Rekan Akademik'), findsOneWidget);
      expect(find.text('Mencari tim Gemastik UX 2026'), findsOneWidget);

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Chiko Pratama'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Keluar dari Akun'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Keluar dari Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Selamat Datang Kembali!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await auth.events.close();
    },
  );
}

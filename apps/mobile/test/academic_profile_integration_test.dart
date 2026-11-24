import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_mobile/core/auth/api_session.dart';
import 'package:re_mobile/core/network/laravel_api.dart';
import 'package:re_mobile/features/academic_profile/data/academic_profile.dart';
import 'package:re_mobile/features/academic_profile/data/academic_profile_repository.dart';
import 'package:re_mobile/features/academic_profile/presentation/profile_controller.dart';
import 'package:re_mobile/features/academic_profile/presentation/profile_validation_panel.dart';

const owner = '11111111-1111-4111-8111-111111111111';

class FakeSessions implements ApiSessionSource {
  @override
  ApiSession? current = const ApiSession(owner, 'test-token', false, 0);
  int refreshes = 0;
  Future<void> Function()? onRefresh;
  @override
  Future<void> refresh() async {
    refreshes++;
    if (onRefresh != null) {
      await onRefresh!();
      return;
    }
    current = const ApiSession(owner, 'rotated-test-token', false, 0);
  }
}

class FakeTransport implements ApiTransport {
  FakeTransport(this.handler);
  final Future<ApiResponse> Function(String, Uri, String, Map<String, dynamic>?)
  handler;
  int calls = 0;
  @override
  Future<ApiResponse> send(
    String method,
    Uri uri,
    String token,
    Map<String, dynamic>? body, {
    bool requireEmpty = false,
  }) {
    calls++;
    return handler(method, uri, token, body);
  }
}

ApiResponse response({AcademicProfileInput? input, String user = owner}) =>
    ApiResponse(
      200,
      jsonEncode({
        'data': {
          'user_id': user,
          ...(input ?? AcademicProfileInput()).toJson(),
        },
        'request_id': 'fixture-request',
      }),
    );
LaravelApi api(FakeSessions sessions, FakeTransport transport) => LaravelApi(
  baseUrl: 'https://api.example.test/api/v1',
  sessions: sessions,
  transport: transport,
);
Matcher failure(ApiFailureKind kind) =>
    isA<ApiFailure>().having((e) => e.kind, 'kind', kind);

void main() {
  test('DTO complete round trip excludes protected fields and keeps nulls', () {
    final input = AcademicProfileInput(
      displayName: 'Student',
      semester: 3,
      visibility: ProfileVisibility.university,
      courses: const ['course-id'],
      skills: const [SkillSelection(skillId: 'skill-id', level: 5)],
      preferences: const AcademicPreferences(
        studyMode: StudyMode.inPerson,
        preferredLanguage: 'id',
      ),
    );
    final json = input.toJson();
    final decoded = AcademicProfile.fromJson({
      'user_id': owner,
      ...json,
      'status': 'verified',
    });
    expect(decoded.input.toJson(), json);
    expect(decoded.userId, owner);
    expect(json.keys, hasLength(10));
    expect(json.containsKey('user_id'), false);
    expect(json.containsKey('status'), false);
    expect(json['bio'], null);
    expect((json['preferences'] as Map)['study_mode'], 'in_person');
    expect(() => input.courses.add('mutated'), throwsUnsupportedError);
  });
  test('DTO rejects absent fields, invalid enums, types and ranges', () {
    for (final changes in [
      {'visibility': 'everyone'},
      {'semester': '2'},
      {'semester': 21},
      {
        'skills': [
          {'skill_id': 'x', 'level': 6},
        ],
      },
      {
        'preferences': {'study_mode': 'bad', 'preferred_language': null},
      },
    ]) {
      expect(
        () => AcademicProfileInput.fromJson({
          ...AcademicProfileInput().toJson(),
          ...changes,
        }),
        throwsA(anything),
      );
    }
    expect(() => AcademicProfileInput.fromJson({}), throwsFormatException);
    expect(AcademicProfileInput().isEmpty, true);
    expect(AcademicProfileInput(displayName: 'Existing').isEmpty, false);
  });
  test(
    'API root cannot redirect credentials through path/query/userinfo/http',
    () {
      for (final root in [
        'http://example.test/api/v1',
        'https://api.test/api/v1?x=y',
        'https://user:pass@api.test/api/v1',
        'https://api.test/other',
        'https://api.test/api/v1#x',
      ]) {
        expect(
          () => LaravelApi(baseUrl: root, sessions: FakeSessions()),
          throwsFormatException,
        );
      }
      expect(
        LaravelApi(
          baseUrl: 'http://10.0.2.2:8000/api/v1',
          sessions: FakeSessions(),
        ),
        isNotNull,
      );
    },
  );
  test(
    'repository attaches SDK bearer and emits exact full PUT projection',
    () async {
      final sessions = FakeSessions();
      final input = AcademicProfileInput(bio: 'Hello');
      final transport = FakeTransport((method, uri, token, body) async {
        expect(
          uri.toString(),
          'https://api.example.test/api/v1/me/academic-profile',
        );
        expect(token, 'test-token');
        if (method == 'PUT') {
          expect(body, input.toJson());
          expect(body!.containsKey('user_id'), false);
        } else {
          expect(body, null);
        }
        return response(input: input);
      });
      final repo = AcademicProfileRepository(api(sessions, transport));
      expect((await repo.get()).input.bio, 'Hello');
      expect((await repo.put(input)).input.bio, 'Hello');
      expect(transport.calls, 2);
    },
  );
  test('missing session never sends a request', () async {
    final sessions = FakeSessions()..current = null;
    final transport = FakeTransport((_, _, _, _) async => response());
    await expectLater(
      AcademicProfileRepository(api(sessions, transport)).get(),
      throwsA(failure(ApiFailureKind.authentication)),
    );
    expect(transport.calls, 0);
  });
  test('401 refreshes once and retries once', () async {
    final sessions = FakeSessions();
    final transport = FakeTransport(
      (_, _, token, _) async =>
          token == 'test-token' ? const ApiResponse(401, '') : response(),
    );
    await AcademicProfileRepository(api(sessions, transport)).get();
    expect(sessions.refreshes, 1);
    expect(transport.calls, 2);
  });
  test('persistent 401 stops after one retry', () async {
    final sessions = FakeSessions();
    final transport = FakeTransport(
      (_, _, _, _) async => const ApiResponse(401, 'do not expose'),
    );
    await expectLater(
      AcademicProfileRepository(api(sessions, transport)).get(),
      throwsA(failure(ApiFailureKind.authentication)),
    );
    expect(sessions.refreshes, 1);
    expect(transport.calls, 2);
  });
  test(
    'expired token refreshes before request; subsequent 401 cannot loop',
    () async {
      final sessions = FakeSessions()
        ..current = const ApiSession(owner, 'expired', true, 0);
      final transport = FakeTransport((_, _, token, _) async {
        expect(token, 'rotated-test-token');
        return const ApiResponse(401, '');
      });
      await expectLater(
        AcademicProfileRepository(api(sessions, transport)).get(),
        throwsA(failure(ApiFailureKind.authentication)),
      );
      expect(sessions.refreshes, 1);
      expect(transport.calls, 1);
    },
  );
  test('refresh failure is sanitized and sends no retry', () async {
    final sessions = FakeSessions()
      ..onRefresh = () async => throw Exception('private-sdk-detail');
    final transport = FakeTransport(
      (_, _, _, _) async => const ApiResponse(401, ''),
    );
    try {
      await AcademicProfileRepository(api(sessions, transport)).get();
      fail('Expected error');
    } on ApiFailure catch (e) {
      expect(e.toString(), isNot(contains('private-sdk-detail')));
    }
    expect(transport.calls, 1);
  });
  test('concurrent 401 requests share one refresh', () async {
    final sessions = FakeSessions();
    final refresh = Completer<void>();
    sessions.onRefresh = () async {
      await refresh.future;
      sessions.current = const ApiSession(owner, 'rotated', false, 0);
    };
    final transport = FakeTransport(
      (_, _, token, _) async =>
          token == 'test-token' ? const ApiResponse(401, '') : response(),
    );
    final repo = AcademicProfileRepository(api(sessions, transport));
    final first = repo.get();
    final second = repo.get();
    await Future<void>.delayed(Duration.zero);
    expect(sessions.refreshes, 1);
    refresh.complete();
    await Future.wait([first, second]);
    expect(transport.calls, 4);
  });
  test('logout or same-user re-login discards in-flight response', () async {
    for (final next in [
      null,
      const ApiSession(owner, 'new-login', false, 1),
      const ApiSession('other-user', 'other-token', false, 0),
    ]) {
      final sessions = FakeSessions();
      final transport = FakeTransport((_, _, _, _) async {
        sessions.current = next;
        return response();
      });
      await expectLater(
        AcademicProfileRepository(api(sessions, transport)).get(),
        throwsA(failure(ApiFailureKind.sessionChanged)),
      );
      expect(transport.calls, 1);
    }
  });
  test('account switch during refresh never replays PUT', () async {
    final sessions = FakeSessions()..onRefresh = () async {};
    sessions.onRefresh = () async {
      sessions.current = const ApiSession('other', 'other-token', false, 1);
    };
    final transport = FakeTransport(
      (_, _, _, _) async => const ApiResponse(401, ''),
    );
    await expectLater(
      AcademicProfileRepository(api(sessions, transport))
          .put(AcademicProfileInput()),
      throwsA(failure(ApiFailureKind.sessionChanged)),
    );
    expect(transport.calls, 1);
  });
  test(
    'redirects and non-auth failures are never refreshed or retried',
    () async {
      for (final entry in {
        302: ApiFailureKind.protocol,
        403: ApiFailureKind.forbidden,
        409: ApiFailureKind.conflict,
        422: ApiFailureKind.validation,
        429: ApiFailureKind.rateLimited,
        503: ApiFailureKind.unavailable,
      }.entries) {
        final sessions = FakeSessions();
        final transport = FakeTransport(
          (_, _, _, _) async => ApiResponse(entry.key, 'secret response'),
        );
        await expectLater(
          AcademicProfileRepository(api(sessions, transport)).get(),
          throwsA(failure(entry.value)),
        );
        expect(transport.calls, 1);
        expect(sessions.refreshes, 0);
      }
    },
  );
  test('network failures and malformed/mismatched data are safe', () async {
    final sessions = FakeSessions();
    final failing = FakeTransport(
      (_, _, _, _) async => throw Exception('sensitive URL'),
    );
    await expectLater(
      AcademicProfileRepository(api(sessions, failing)).get(),
      throwsA(failure(ApiFailureKind.network)),
    );
    for (final reply in [
      const ApiResponse(200, '<html>'),
      const ApiResponse(200, '{}'),
      response(user: 'someone-else'),
      const ApiResponse(200, '{"request_id":"x","data":{"user_id":"x"}}'),
    ]) {
      final transport = FakeTransport((_, _, _, _) async => reply);
      await expectLater(
        AcademicProfileRepository(api(sessions, transport)).get(),
        throwsA(failure(ApiFailureKind.protocol)),
      );
    }
  });
  test(
    'controller exposes loading empty success error and ignores stale results',
    () async {
      var reply = response();
      final pending = Completer<ApiResponse>();
      var hold = false;
      final transport = FakeTransport(
        (_, _, _, _) => hold ? pending.future : Future.value(reply),
      );
      final controller = ProfileController(
        AcademicProfileRepository(api(FakeSessions(), transport)),
      );
      expect(controller.status, ProfileStatus.idle);
      final loading = controller.load();
      expect(controller.status, ProfileStatus.loading);
      await loading;
      expect(controller.status, ProfileStatus.empty);
      reply = response(input: AcademicProfileInput(bio: 'Present'));
      await controller.load();
      expect(controller.status, ProfileStatus.success);
      reply = const ApiResponse(503, '');
      await controller.load();
      expect(controller.status, ProfileStatus.error);
      expect(controller.profile, null);
      hold = true;
      final stale = controller.load();
      controller.clear();
      pending.complete(response(input: AcademicProfileInput(bio: 'Discard')));
      await stale;
      expect(controller.status, ProfileStatus.idle);
      expect(controller.profile, null);
      controller.dispose();
    },
  );
  testWidgets('development panel requires explicit approval before PUT', (
    tester,
  ) async {
    var puts = 0;
    var stored = AcademicProfileInput();
    final transport = FakeTransport((method, uri, _, body) async {
      if (uri.path.endsWith('/me')) {
        return ApiResponse(
          200,
          jsonEncode({
            'data': {'id': owner},
            'request_id': 'test',
          }),
        );
      }
      if (method == 'PUT') {
        puts++;
        stored = AcademicProfileInput.fromJson(body!);
      }
      return response(input: stored);
    });
    final controller = ProfileController(
      AcademicProfileRepository(api(FakeSessions(), transport)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfileValidationPanel(controller: controller)),
      ),
    );
    await tester.tap(find.text('Load academic profile (GET)'));
    await tester.pumpAndSettle();
    expect(find.text('Profile state: empty'), findsOneWidget);
    await tester.tap(find.text('Validate PUT / GET (approval required)'));
    await tester.pumpAndSettle();
    expect(puts, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(puts, 0);
    await tester.tap(find.text('Validate PUT / GET (approval required)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve PUT'));
    await tester.pumpAndSettle();
    expect(puts, 1);
    expect(
      find.text('PASS: submitted dummy values match PUT and GET.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

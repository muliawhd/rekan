import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:re_mobile/core/auth/api_session.dart';
import 'package:re_mobile/core/network/laravel_api.dart';
import 'package:re_mobile/features/academic_profile/data/academic_profile.dart';
import 'package:re_mobile/features/academic_profile/data/academic_profile_repository.dart';
import 'package:re_mobile/features/academic_profile/presentation/development_profile_validation.dart';

import 'academic_profile_integration_test.dart'
    show FakeSessions, owner, response, failure;

class ValidationTransport implements ApiTransport {
  AcademicProfileInput stored = AcademicProfileInput();
  int puts = 0;
  int? putStatus;
  bool mismatch = false;
  bool failReadAfterPut = false;
  void Function()? afterPut;
  @override
  Future<ApiResponse> send(
    String method,
    Uri uri,
    String token,
    Map<String, dynamic>? body, {
    bool requireEmpty = false,
  }) async {
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
      expect(requireEmpty, true);
      expect(body!.containsKey('user_id'), false);
      puts++;
      if (putStatus != null) {
        return ApiResponse(putStatus!, 'secret server detail');
      }
      stored = mismatch
          ? AcademicProfileInput(bio: 'different')
          : AcademicProfileInput.fromJson(body);
      afterPut?.call();
    } else if (failReadAfterPut && puts > 0) {
      throw Exception('secret network detail');
    }
    return response(input: stored);
  }
}

void main() {
  late FakeSessions sessions;
  late ValidationTransport transport;
  late DevelopmentProfileValidation validation;
  setUp(() {
    sessions = FakeSessions();
    transport = ValidationTransport();
    validation = DevelopmentProfileValidation(
      AcademicProfileRepository(
        LaravelApi(
          baseUrl: 'https://api.example.test/api/v1',
          sessions: sessions,
          transport: transport,
        ),
      ),
    );
  });
  test(
    'empty approval uses dummy values, no references, and one-use PUT',
    () async {
      final approval = await validation.prepare();
      expect(transport.puts, 0);
      expect(approval.userId, owner);
      expect(approval.input.isEmpty, false);
      expect(approval.input.universityId, null);
      expect(approval.input.courses, isEmpty);
      expect(approval.input.skills, isEmpty);
      expect(approval.input.visibility, ProfileVisibility.private);
      expect(await validation.execute(approval), true);
      await expectLater(
        validation.execute(approval),
        throwsA(failure(ApiFailureKind.conflict)),
      );
      expect(transport.puts, 1);
    },
  );
  test(
    'non-empty profile rejected before approval and again after dialog',
    () async {
      transport.stored = AcademicProfileInput(displayName: 'Existing');
      await expectLater(
        validation.prepare(),
        throwsA(failure(ApiFailureKind.conflict)),
      );
      transport.stored = AcademicProfileInput();
      final approval = await validation.prepare();
      transport.stored = AcademicProfileInput(bio: 'Concurrent edit');
      await expectLater(
        validation.execute(approval),
        throwsA(failure(ApiFailureKind.conflict)),
      );
      expect(transport.puts, 0);
    },
  );
  test(
    'switch or logout/relogin after approval aborts without writing',
    () async {
      for (final next in [
        null,
        const ApiSession('other', 'test', false, 0),
        const ApiSession(owner, 'test', false, 1),
      ]) {
        sessions.current = const ApiSession(owner, 'test', false, 0);
        final approval = await validation.prepare();
        sessions.current = next;
        await expectLater(
          validation.execute(approval),
          throwsA(failure(ApiFailureKind.sessionChanged)),
        );
      }
      expect(transport.puts, 0);
    },
  );
  test(
    'switch during PUT never follows with another account GET or rollback',
    () async {
      final approval = await validation.prepare();
      transport.afterPut = () =>
          sessions.current = const ApiSession('other', 'test', false, 1);
      await expectLater(
        validation.execute(approval),
        throwsA(failure(ApiFailureKind.sessionChanged)),
      );
      expect(transport.puts, 1);
    },
  );
  test(
    'matching PUT and GET still fail if both differ from submitted values',
    () async {
      final approval = await validation.prepare();
      transport.mismatch = true;
      expect(await validation.execute(approval), false);
    },
  );
  test('API rejection does not retry or issue compensating writes', () async {
    for (final status in [409, 422, 503]) {
      final approval = await validation.prepare();
      transport.putStatus = status;
      await expectLater(
        validation.execute(approval),
        throwsA(isA<ApiFailure>()),
      );
    }
    expect(transport.puts, 3);
    expect(transport.stored.isEmpty, true);
  });
  test(
    'lost GET after PUT preserves data and reports unknown result safely',
    () async {
      final approval = await validation.prepare();
      transport.failReadAfterPut = true;
      await expectLater(
        validation.execute(approval),
        throwsA(failure(ApiFailureKind.network)),
      );
      expect(transport.puts, 1);
      expect(transport.stored.toJson(), approval.input.toJson());
    },
  );
}

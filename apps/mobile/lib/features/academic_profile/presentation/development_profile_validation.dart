import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/auth/api_session.dart';
import '../../../core/network/laravel_api.dart';
import '../data/academic_profile.dart';
import '../data/academic_profile_repository.dart';

/// A one-use approval bound to an authenticated session, never a client owner ID.
class DevelopmentProfileApproval {
  DevelopmentProfileApproval._(this.userId, this.generation, this.input);
  final String userId;
  final int generation;
  final AcademicProfileInput input;
  bool _used = false;
}

class DevelopmentProfileValidation {
  DevelopmentProfileValidation(this.repository);
  final AcademicProfileRepository repository;
  ApiSessionSource get _sessions => repository.api.sessions;

  static AcademicProfileInput dummyPayload() => AcademicProfileInput(
    displayName: 'Development student',
    program: 'Integration test program',
    semester: 1,
    bio: 'Dummy academic profile for development validation.',
    preferences: const AcademicPreferences(
      studyMode: StudyMode.online,
      preferredLanguage: 'en',
    ),
  );

  void _check(DevelopmentProfileApproval approval) {
    final session = _sessions.current;
    if (!kDebugMode ||
        session == null ||
        session.userId != approval.userId ||
        session.generation != approval.generation) {
      throw const ApiFailure(ApiFailureKind.sessionChanged);
    }
  }

  void ensureCurrent(DevelopmentProfileApproval approval) => _check(approval);

  Future<DevelopmentProfileApproval> prepare() async {
    if (!kDebugMode) throw const ApiFailure(ApiFailureKind.forbidden);
    final session = _sessions.current;
    if (session == null) throw const ApiFailure(ApiFailureKind.authentication);
    final approval = DevelopmentProfileApproval._(
      session.userId,
      session.generation,
      dummyPayload(),
    );
    await repository.api.getIdentity();
    _check(approval);
    final profile = await repository.get();
    _check(approval);
    if (!profile.input.isEmpty) {
      throw const ApiFailure(ApiFailureKind.conflict);
    }
    return approval;
  }

  /// Called only after the user confirms the displayed UUID and exact payload.
  Future<bool> execute(DevelopmentProfileApproval approval) async {
    _check(approval);
    if (approval._used) throw const ApiFailure(ApiFailureKind.conflict);
    approval._used = true;
    // Recheck after the dialog; never use the previously loaded profile as proof.
    final before = await repository.get();
    _check(approval);
    if (!before.input.isEmpty) {
      throw const ApiFailure(ApiFailureKind.conflict);
    }
    final saved = await repository.put(approval.input, requireEmpty: true);
    _check(approval);
    final read = await repository.get();
    _check(approval);
    final expected = jsonEncode(approval.input.toJson());
    return saved.userId == approval.userId &&
        read.userId == approval.userId &&
        jsonEncode(saved.input.toJson()) == expected &&
        jsonEncode(read.input.toJson()) == expected;
  }
}

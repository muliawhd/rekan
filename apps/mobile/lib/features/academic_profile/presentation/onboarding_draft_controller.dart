import 'package:flutter/foundation.dart';

import '../../../core/network/laravel_api.dart';
import '../data/academic_profile.dart';
import '../data/academic_profile_repository.dart';
import '../domain/academic_onboarding_completion.dart';

/// In-memory 5-step onboarding and profile-edit draft controller
/// (`phase-2e2-plan.md` §Audit line 18 & §User flows lines 44–55).
///
/// Decoupled from transient `ProfileController` read state so network reloads or
/// recoverable `PUT` failures never wipe user-entered draft fields. Bound to
/// [ownerUserId] and wiped immediately on account switch or logout.
class OnboardingDraftController extends ChangeNotifier {
  OnboardingDraftController({
    required this.repository,
    required String ownerUserId,
    AcademicProfile? initialProfile,
    this.catalog,
    this.requireUniversityWhenCatalogAbsent = false,
  }) : _ownerUserId = ownerUserId.trim() {
    if (initialProfile != null) {
      hydrateFromProfile(initialProfile, force: true);
    }
  }

  static const int totalSteps = 5;

  final AcademicProfileRepository repository;
  AcademicCatalogSnapshot? catalog;

  /// Whether Step 2 should block forward navigation if `university_id` is null
  /// even when `catalog?.universities == null`. When `catalog?.universities` is
  /// provided (non-null), `university_id` is always required on Step 2.
  final bool requireUniversityWhenCatalogAbsent;

  String _ownerUserId;
  String get ownerUserId => _ownerUserId;

  int _currentStep = 1;
  int get currentStep => _currentStep;

  AcademicProfile? _initialProfile;
  AcademicProfile? get initialProfile => _initialProfile;

  AcademicProfile? _savedProfile;
  AcademicProfile? get savedProfile => _savedProfile;

  bool _wasInitiallyEmpty = true;
  bool get wasInitiallyEmpty => _wasInitiallyEmpty;

  bool _saving = false;
  bool get saving => _saving;

  ApiFailure? _saveFailure;
  ApiFailure? get saveFailure => _saveFailure;

  int _generation = 0;
  bool _disposed = false;
  bool _dirty = false;
  bool get hasUnsavedChanges => _dirty;

  // Draft fields corresponding to the 10 writable fields in `04-api-contract.md`:
  String _displayName = '';
  String get displayName => _displayName;

  String? _universityId;
  String? get universityId => _universityId;

  String _program = '';
  String get program => _program;

  String _semesterText = '';
  String get semesterText => _semesterText;
  int? get semester => int.tryParse(_semesterText.trim());

  String _bio = '';
  String get bio => _bio;

  String _mbtiBadge = '';
  String get mbtiBadge => _mbtiBadge;

  ProfileVisibility _visibility = ProfileVisibility.private;
  ProfileVisibility get visibility => _visibility;

  final List<String> _courses = <String>[];
  List<String> get courses => List.unmodifiable(_courses);

  final List<SkillSelection> _skills = <SkillSelection>[];
  List<SkillSelection> get skills => List.unmodifiable(_skills);

  StudyMode? _studyMode;
  StudyMode? get studyMode => _studyMode;

  String _preferredLanguage = '';
  String get preferredLanguage => _preferredLanguage;

  // Field-level validation errors:
  String? displayNameError;
  String? universityIdError;
  String? programError;
  String? semesterError;
  String? bioError;
  String? mbtiBadgeError;
  String? skillsError;
  String? coursesError;
  String? preferredLanguageError;

  bool get requireUniversityOnStep2 =>
      requireUniversityWhenCatalogAbsent || (catalog?.hasUniversities ?? false);

  /// True when the user changed `university_id` away from the initially loaded
  /// `university_id` while course selections still exist (`phase-2e2-plan.md` line 50).
  bool get hasUniversityChangeCourseWarning {
    if (_courses.isEmpty) return false;
    final originalUni = _initialProfile?.input.universityId?.toLowerCase();
    final currentUni = _universityId?.toLowerCase();
    if (originalUni == null && currentUni == null) return false;
    return originalUni != currentUni;
  }

  /// Hydrates the draft from a loaded [AcademicProfile].
  ///
  /// Does not overwrite dirty user edits for the same account unless [force] is
  /// true. If [profile.userId] belongs to a different user, resets the draft for
  /// that user first.
  void hydrateFromProfile(AcademicProfile profile, {bool force = false}) {
    if (profile.userId != _ownerUserId) {
      resetForUser(profile.userId);
    } else if (_dirty && !force && _initialProfile != null) {
      return;
    }

    _initialProfile = profile;
    _wasInitiallyEmpty = profile.input.isEmpty;
    final input = profile.input;

    _displayName = input.displayName ?? '';
    _universityId = input.universityId;
    _program = input.program ?? '';
    _semesterText = input.semester?.toString() ?? '';
    _bio = input.bio ?? '';
    _mbtiBadge = input.mbtiBadge ?? '';
    _visibility = input.visibility;
    _courses
      ..clear()
      ..addAll(input.courses);
    _skills
      ..clear()
      ..addAll(input.skills);
    _studyMode = input.preferences.studyMode;
    _preferredLanguage = input.preferences.preferredLanguage ?? '';

    _dirty = false;
    _saveFailure = null;
    _clearValidationErrors();
    _notify();
  }

  /// Wipes all in-memory draft state when switching accounts or logging out.
  void resetForUser(String? newUserId) {
    _generation++;
    _ownerUserId = newUserId ?? '';
    _currentStep = 1;
    _initialProfile = null;
    _savedProfile = null;
    _wasInitiallyEmpty = true;
    _saving = false;
    _saveFailure = null;
    _dirty = false;

    _displayName = '';
    _universityId = null;
    _program = '';
    _semesterText = '';
    _bio = '';
    _mbtiBadge = '';
    _visibility = ProfileVisibility.private;
    _courses.clear();
    _skills.clear();
    catalog = null;
    _studyMode = null;
    _preferredLanguage = '';

    _clearValidationErrors();
    _notify();
  }

  void updateCatalog(AcademicCatalogSnapshot? newCatalog) {
    catalog = newCatalog;
    _notify();
  }

  // Field mutators:
  void setDisplayName(String value) {
    if (_saving) return;
    _displayName = value;
    _dirty = true;
    displayNameError = null;
    _saveFailure = null;
    _notify();
  }

  void setBio(String value) {
    if (_saving) return;
    _bio = value;
    _dirty = true;
    bioError = null;
    _saveFailure = null;
    _notify();
  }

  void setMbtiBadge(String value) {
    if (_saving) return;
    _mbtiBadge = value.toUpperCase();
    _dirty = true;
    mbtiBadgeError = null;
    _saveFailure = null;
    _notify();
  }

  void setUniversityId(String? value) {
    if (_saving) return;
    _universityId = AcademicOnboardingValidation.normalizeNullableText(value);
    _dirty = true;
    universityIdError = null;
    coursesError = null;
    _saveFailure = null;
    _notify();
  }

  void setProgram(String value) {
    if (_saving) return;
    _program = value;
    _dirty = true;
    programError = null;
    _saveFailure = null;
    _notify();
  }

  void setSemesterText(String value) {
    if (_saving) return;
    _semesterText = value;
    _dirty = true;
    semesterError = null;
    _saveFailure = null;
    _notify();
  }

  void setSemester(int? value) {
    if (_saving) return;
    _semesterText = value?.toString() ?? '';
    _dirty = true;
    semesterError = null;
    _saveFailure = null;
    _notify();
  }

  void upsertSkill(String skillId, int level) {
    if (_saving) return;
    if (!AcademicOnboardingValidation.isValidUuid(skillId)) {
      skillsError = 'ID keahlian tidak valid.';
      _notify();
      return;
    }
    if (level < 1 || level > 5) {
      skillsError = 'Tingkat keahlian harus antara 1 sampai 5.';
      _notify();
      return;
    }
    final normalizedId = skillId.trim().toLowerCase();
    final index = _skills.indexWhere(
      (s) => s.skillId.toLowerCase() == normalizedId,
    );
    final updated = SkillSelection(skillId: normalizedId, level: level);
    if (index >= 0) {
      _skills[index] = updated;
    } else {
      if (_skills.length >= 100) {
        skillsError = 'Maksimal 100 keahlian dapat dipilih.';
        _notify();
        return;
      }
      _skills.add(updated);
    }
    _dirty = true;
    skillsError = null;
    _saveFailure = null;
    _notify();
  }

  void removeSkill(String skillId) {
    if (_saving) return;
    final lower = skillId.toLowerCase();
    _skills.removeWhere((s) => s.skillId.toLowerCase() == lower);
    _dirty = true;
    skillsError = null;
    _saveFailure = null;
    _notify();
  }

  void toggleCourse(String courseId) {
    if (_saving) return;
    if (!AcademicOnboardingValidation.isValidUuid(courseId)) {
      coursesError = 'ID mata kuliah tidak valid.';
      _notify();
      return;
    }
    final normalizedId = courseId.trim().toLowerCase();
    final index = _courses.indexWhere((c) => c.toLowerCase() == normalizedId);
    if (index >= 0) {
      _courses.removeAt(index);
    } else {
      if (_courses.length >= 100) {
        coursesError = 'Maksimal 100 mata kuliah dapat dipilih.';
        _notify();
        return;
      }
      _courses.add(normalizedId);
    }
    _dirty = true;
    coursesError = null;
    _saveFailure = null;
    _notify();
  }

  void removeCourse(String courseId) {
    if (_saving) return;
    final lower = courseId.toLowerCase();
    _courses.removeWhere((c) => c.toLowerCase() == lower);
    _dirty = true;
    coursesError = null;
    _saveFailure = null;
    _notify();
  }

  void clearCourses() {
    if (_saving || _courses.isEmpty) return;
    _courses.clear();
    _dirty = true;
    coursesError = null;
    _saveFailure = null;
    _notify();
  }

  void setStudyMode(StudyMode? mode) {
    if (_saving) return;
    _studyMode = mode;
    _dirty = true;
    _saveFailure = null;
    _notify();
  }

  void setPreferredLanguage(String value) {
    if (_saving) return;
    _preferredLanguage = value;
    _dirty = true;
    preferredLanguageError = null;
    _saveFailure = null;
    _notify();
  }

  void setVisibility(ProfileVisibility value) {
    if (_saving) return;
    _visibility = value;
    _dirty = true;
    _saveFailure = null;
    _notify();
  }

  /// Validates the fields belonging to [step] (`1..5`).
  bool validateStep(int step) {
    var valid = true;
    switch (step) {
      case 1:
        displayNameError = AcademicOnboardingValidation.displayName(
          _displayName,
          required: true,
        );
        bioError = AcademicOnboardingValidation.bio(_bio);
        mbtiBadgeError = AcademicOnboardingValidation.mbtiBadge(_mbtiBadge);
        valid =
            displayNameError == null &&
            bioError == null &&
            mbtiBadgeError == null;
      case 2:
        universityIdError = AcademicOnboardingValidation.universityId(
          _universityId,
          required: requireUniversityOnStep2,
        );
        programError = AcademicOnboardingValidation.program(
          _program,
          required: true,
        );
        semesterError = AcademicOnboardingValidation.semesterText(
          _semesterText,
          required: true,
        );
        valid =
            universityIdError == null &&
            programError == null &&
            semesterError == null;
      case 3:
        skillsError = AcademicOnboardingValidation.skills(_skills);
        valid = skillsError == null;
      case 4:
        coursesError = AcademicOnboardingValidation.courses(
          _courses,
          selectedUniversityId: _universityId,
          catalog: catalog,
        );
        valid = coursesError == null;
      case 5:
        preferredLanguageError = AcademicOnboardingValidation.preferredLanguage(
          _preferredLanguage,
        );
        valid = preferredLanguageError == null;
    }
    _notify();
    return valid;
  }

  /// Validates all 5 steps before sending `PUT /api/v1/me/academic-profile`.
  ///
  /// When [ validateStep ] fails on an earlier step, moves [currentStep] to the
  /// first invalid step so the user can fix it immediately.
  bool validateAllSteps() {
    int? firstInvalidStep;
    for (var step = 1; step <= totalSteps; step++) {
      final stepValid = validateStep(step);
      if (!stepValid && firstInvalidStep == null) {
        firstInvalidStep = step;
      }
    }
    if (firstInvalidStep != null) {
      _currentStep = firstInvalidStep;
      _notify();
      return false;
    }
    return true;
  }

  /// Advances to the next step (`1 -> 2 -> 3 -> 4 -> 5`) if the current step is valid.
  bool nextStep() {
    if (_saving) return false;
    if (!validateStep(_currentStep)) return false;
    if (_currentStep < totalSteps) {
      _currentStep++;
      _saveFailure = null;
      _notify();
      return true;
    }
    return false;
  }

  /// Moves back one step (`5 -> 4 -> 3 -> 2 -> 1`) while preserving all draft values.
  bool previousStep() {
    if (_saving) return false;
    if (_currentStep > 1) {
      _currentStep--;
      _saveFailure = null;
      _notify();
      return true;
    }
    return false;
  }

  /// Jumps directly to [targetStep] (`1..5`).
  ///
  /// Moving backward is always permitted without validation; moving forward
  /// validates intermediate steps first.
  bool goToStep(int targetStep) {
    if (_saving || targetStep < 1 || targetStep > totalSteps) return false;
    if (targetStep == _currentStep) return true;
    if (targetStep < _currentStep) {
      _currentStep = targetStep;
      _saveFailure = null;
      _notify();
      return true;
    }
    for (var s = _currentStep; s < targetStep; s++) {
      if (!validateStep(s)) {
        _currentStep = s;
        _notify();
        return false;
      }
    }
    _currentStep = targetStep;
    _saveFailure = null;
    _notify();
    return true;
  }

  /// Builds the complete 10-field [AcademicProfileInput] projection for `PUT`.
  ///
  /// Preserves untouched fields (including loaded `university_id`, `courses`,
  /// `skills`, and `visibility`) and normalizes empty optional strings to `null`.
  AcademicProfileInput toProfileInput() {
    final normalizedDisplayName =
        AcademicOnboardingValidation.normalizeNullableText(_displayName);
    final normalizedUniversityId =
        AcademicOnboardingValidation.normalizeNullableText(_universityId)
            ?.toLowerCase();
    final normalizedProgram =
        AcademicOnboardingValidation.normalizeNullableText(_program);
    final parsedSemester = int.tryParse(_semesterText.trim());
    final normalizedBio = AcademicOnboardingValidation.normalizeNullableText(
      _bio,
    );
    final normalizedMbti = AcademicOnboardingValidation.normalizeNullableText(
      _mbtiBadge,
    )?.toUpperCase();
    final normalizedLang = AcademicOnboardingValidation.normalizeNullableText(
      _preferredLanguage,
    );

    return AcademicProfileInput(
      displayName: normalizedDisplayName,
      universityId: normalizedUniversityId,
      program: normalizedProgram,
      semester: parsedSemester,
      bio: normalizedBio,
      mbtiBadge: normalizedMbti,
      visibility: _visibility,
      courses: _courses.map((c) => c.toLowerCase()).toList(),
      skills: _skills
          .map(
            (s) => SkillSelection(
              skillId: s.skillId.toLowerCase(),
              level: s.level,
            ),
          )
          .toList(),
      preferences: AcademicPreferences(
        studyMode: _studyMode,
        preferredLanguage: normalizedLang,
      ),
    );
  }

  /// Persists the reviewed profile via `PUT /api/v1/me/academic-profile`.
  ///
  /// - Blocks duplicate concurrent submissions (`_saving`).
  /// - Sends `requireEmpty: true` (`X-Re-Require-Empty-Profile: true`) when the
  ///   profile was initially empty so a non-empty server profile is never
  ///   overwritten automatically (`409 PROFILE_NOT_EMPTY`).
  /// - Preserves all draft fields on recoverable errors.
  /// - Discards results if the account switched during the request.
  Future<AcademicProfile?> save() async {
    if (_saving || _ownerUserId.isEmpty) return null;
    if (!validateAllSteps()) return null;

    final startGeneration = ++_generation;
    final expectedUser = _ownerUserId;
    final payload = toProfileInput();
    final requireEmpty = _wasInitiallyEmpty;

    _saving = true;
    _saveFailure = null;
    _notify();

    try {
      final persisted = await repository.put(
        payload,
        requireEmpty: requireEmpty,
      );
      if (_disposed ||
          startGeneration != _generation ||
          _ownerUserId != expectedUser ||
          persisted.userId != expectedUser) {
        return null;
      }
      _saving = false;
      _initialProfile = persisted;
      _savedProfile = persisted;
      _wasInitiallyEmpty = persisted.input.isEmpty;
      _dirty = false;
      _saveFailure = null;
      _notify();
      return persisted;
    } catch (error) {
      if (_disposed ||
          startGeneration != _generation ||
          _ownerUserId != expectedUser) {
        return null;
      }
      _saving = false;
      _saveFailure = error is ApiFailure
          ? error
          : const ApiFailure(ApiFailureKind.protocol);
      _notify();
      return null;
    }
  }

  /// Localized Bahasa Indonesia error message for [saveFailure].
  String? get saveFailureMessage {
    final failure = _saveFailure;
    if (failure == null) return null;
    return switch (failure.kind) {
      ApiFailureKind.authentication =>
        'Sesi akun berakhir. Masuk kembali untuk melanjutkan penyimpanan.',
      ApiFailureKind.sessionChanged =>
        'Sesi akun berubah. Muat ulang profil sebelum menyimpan.',
      ApiFailureKind.forbidden => 'Akses ditolak. Kamu hanya dapat mengubah profil akademik milikmu sendiri.',
      ApiFailureKind.validation => 'Data profil ditolak oleh server (422). Periksa kembali isian wajib, format MBTI/bahasa, atau pilihan katalog.',
      ApiFailureKind.conflict =>
        _wasInitiallyEmpty
            ? 'Profil di server sudah berisi data dan tidak ditimpa otomatis (409). Muat ulang profil terlebih dahulu.'
            : 'Referensi katalog berubah di server (409). Muat ulang pilihan lalu coba simpan kembali.',
      ApiFailureKind.rateLimited => 'Terlalu banyak permintaan ke server. Tunggu sebentar lalu coba simpan lagi.',
      ApiFailureKind.unavailable => 'Layanan profil akademik sedang tidak tersedia. Draf tetap tersimpan di layar ini.',
      ApiFailureKind.network => 'Tidak dapat terhubung ke server Re:kan. Periksa koneksi internetmu; draf formulir tetap aman.',
      ApiFailureKind.protocol => 'Respons server tidak dikenali. Draf formulir tetap aman; silakan coba lagi.',
    };
  }

  void _clearValidationErrors() {
    displayNameError = null;
    universityIdError = null;
    programError = null;
    semesterError = null;
    bioError = null;
    mbtiBadgeError = null;
    skillsError = null;
    coursesError = null;
    preferredLanguageError = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

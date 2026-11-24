import '../data/academic_profile.dart';

/// Read-only university item from `GET /api/v1/universities` (when available).
class UniversityCatalogItem {
  const UniversityCatalogItem({required this.id, required this.name});

  final String id;
  final String name;
}

/// Read-only course item from `GET /api/v1/courses` (when available).
class CourseCatalogItem {
  const CourseCatalogItem({
    required this.id,
    required this.code,
    required this.name,
    this.universityId,
  });

  final String id;
  final String code;
  final String name;

  /// Null indicates a shared global course (`04-api-contract.md`).
  final String? universityId;

  bool isCompatibleWithUniversity(String? selectedUniversityId) {
    if (universityId == null) return true;
    if (selectedUniversityId == null) return false;
    return universityId!.toLowerCase() == selectedUniversityId.toLowerCase();
  }
}

/// Read-only skill item from `GET /api/v1/skills` (when available).
class SkillCatalogItem {
  const SkillCatalogItem({required this.id, required this.normalizedName});

  final String id;
  final String normalizedName;
}

/// Optional read-only catalog snapshot.
///
/// Retains resolved labels independently of filtered search results. Also used
/// for offline test/preview injection; production loads the authenticated APIs.
class AcademicCatalogSnapshot {
  const AcademicCatalogSnapshot({this.universities, this.courses, this.skills});

  final List<UniversityCatalogItem>? universities;
  final List<CourseCatalogItem>? courses;
  final List<SkillCatalogItem>? skills;

  bool get hasUniversities => universities != null;
  bool get hasCourses => courses != null;
  bool get hasSkills => skills != null;

  UniversityCatalogItem? findUniversity(String? id) {
    if (id == null || universities == null) return null;
    final target = id.toLowerCase();
    for (final item in universities!) {
      if (item.id.toLowerCase() == target) return item;
    }
    return null;
  }

  CourseCatalogItem? findCourse(String id) {
    if (courses == null) return null;
    final target = id.toLowerCase();
    for (final item in courses!) {
      if (item.id.toLowerCase() == target) return item;
    }
    return null;
  }

  SkillCatalogItem? findSkill(String id) {
    if (skills == null) return null;
    final target = id.toLowerCase();
    for (final item in skills!) {
      if (item.id.toLowerCase() == target) return item;
    }
    return null;
  }
}

/// Evaluates whether a persisted [AcademicProfileInput] satisfies the
/// onboarding completion criteria (`phase-2e2-plan.md` §Missing capabilities).
///
/// Required fields for completion:
/// - `display_name` (non-blank, max 100 chars)
/// - `university_id` (non-null valid UUID)
/// - `program` (non-blank, max 150 chars)
/// - `semester` (integer 1–20)
///
/// Optional fields (`bio`, `mbti_badge`, `courses`, `skills`,
/// `preferences.study_mode`, `preferences.preferred_language`) never block
/// onboarding completion.
abstract final class AcademicOnboardingCompletion {
  static bool isComplete(AcademicProfileInput input) =>
      missingRequiredFields(input).isEmpty;

  static List<String> missingRequiredFields(AcademicProfileInput input) {
    final missing = <String>[];
    if (AcademicOnboardingValidation.displayName(
          input.displayName,
          required: true,
        ) !=
        null) {
      missing.add('display_name');
    }
    if (AcademicOnboardingValidation.universityId(
          input.universityId,
          required: true,
        ) !=
        null) {
      missing.add('university_id');
    }
    if (AcademicOnboardingValidation.program(input.program, required: true) !=
        null) {
      missing.add('program');
    }
    if (AcademicOnboardingValidation.semesterValue(
          input.semester,
          required: true,
        ) !=
        null) {
      missing.add('semester');
    }
    return missing;
  }

  static String fieldLabel(String fieldKey) => switch (fieldKey) {
    'display_name' => 'Nama tampilan',
    'university_id' => 'Universitas',
    'program' => 'Program studi',
    'semester' => 'Semester aktif',
    _ => fieldKey,
  };
}

/// Client-side validation rules matching `AcademicProfileController.php` and
/// `docs/architecture/04-api-contract.md`.
abstract final class AcademicOnboardingValidation {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final RegExp _mbtiPattern = RegExp(r'^[EI][NS][FT][JP]$');
  static final RegExp _languagePattern = RegExp(
    r'^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$',
  );

  static bool isValidUuid(String value) => _uuidPattern.hasMatch(value.trim());

  static String? normalizeNullableText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? displayName(String? value, {bool required = true}) {
    final normalized = normalizeNullableText(value);
    if (normalized == null) {
      return required ? 'Nama tampilan wajib diisi.' : null;
    }
    if (normalized.length > 100) {
      return 'Nama tampilan maksimal 100 karakter.';
    }
    return null;
  }

  static String? universityId(String? value, {bool required = false}) {
    final normalized = normalizeNullableText(value);
    if (normalized == null) {
      return required ? 'Pilih universitas asalmu.' : null;
    }
    if (!isValidUuid(normalized)) {
      return 'ID universitas harus berupa UUID yang valid.';
    }
    return null;
  }

  static String? program(String? value, {bool required = true}) {
    final normalized = normalizeNullableText(value);
    if (normalized == null) {
      return required ? 'Program studi wajib diisi.' : null;
    }
    if (normalized.length > 150) {
      return 'Program studi maksimal 150 karakter.';
    }
    return null;
  }

  static String? semesterText(String? rawValue, {bool required = true}) {
    final normalized = normalizeNullableText(rawValue);
    if (normalized == null) {
      return required ? 'Semester aktif wajib diisi (1–20).' : null;
    }
    final parsed = int.tryParse(normalized);
    if (parsed == null) {
      return 'Semester harus berupa angka bulat antara 1 sampai 20.';
    }
    return semesterValue(parsed, required: required);
  }

  static String? semesterValue(int? value, {bool required = true}) {
    if (value == null) {
      return required ? 'Semester aktif wajib diisi (1–20).' : null;
    }
    if (value < 1 || value > 20) {
      return 'Semester harus berada di rentang 1 sampai 20.';
    }
    return null;
  }

  static String? bio(String? value) {
    final normalized = normalizeNullableText(value);
    if (normalized == null) return null;
    if (normalized.length > 2000) {
      return 'Ringkasan akademik maksimal 2000 karakter.';
    }
    return null;
  }

  static String? mbtiBadge(String? value) {
    final normalized = normalizeNullableText(value)?.toUpperCase();
    if (normalized == null) return null;
    if (!_mbtiPattern.hasMatch(normalized)) {
      return 'MBTI harus terdiri dari 4 huruf valid (contoh: INTJ, ENFP).';
    }
    return null;
  }

  static String? preferredLanguage(String? value) {
    final normalized = normalizeNullableText(value);
    if (normalized == null) return null;
    if (normalized.length > 35 || !_languagePattern.hasMatch(normalized)) {
      return 'Gunakan kode bahasa yang valid (contoh: id, en, id-ID).';
    }
    return null;
  }

  static String? skills(List<SkillSelection> items) {
    if (items.length > 100) {
      return 'Maksimal 100 keahlian dapat dipilih.';
    }
    final seen = <String>{};
    for (final item in items) {
      if (!isValidUuid(item.skillId)) {
        return 'ID keahlian tidak valid.';
      }
      if (item.level < 1 || item.level > 5) {
        return 'Tingkat keahlian harus antara 1 sampai 5.';
      }
      final lower = item.skillId.toLowerCase();
      if (!seen.add(lower)) {
        return 'Keahlian tidak boleh duplikat.';
      }
    }
    return null;
  }

  static String? courses(
    List<String> courseIds, {
    String? selectedUniversityId,
    AcademicCatalogSnapshot? catalog,
  }) {
    if (courseIds.length > 100) {
      return 'Maksimal 100 mata kuliah dapat dipilih.';
    }
    final seen = <String>{};
    for (final id in courseIds) {
      if (!isValidUuid(id)) {
        return 'ID mata kuliah tidak valid.';
      }
      final lower = id.toLowerCase();
      if (!seen.add(lower)) {
        return 'Mata kuliah tidak boleh duplikat.';
      }
      final meta = catalog?.findCourse(id);
      if (meta != null &&
          !meta.isCompatibleWithUniversity(selectedUniversityId)) {
        return 'Mata kuliah ${meta.code} tidak sesuai dengan universitas yang dipilih.';
      }
    }
    return null;
  }
}

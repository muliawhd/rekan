enum ProfileVisibility { private, university, public }

enum StudyMode {
  online('online'),
  inPerson('in_person'),
  hybrid('hybrid');

  const StudyMode(this.value);
  final String value;
}

class SkillSelection {
  const SkillSelection({required this.skillId, required this.level});
  final String skillId;
  final int level;
  factory SkillSelection.fromJson(Map<String, dynamic> json) {
    final level = json['level'] as int;
    if (level < 1 || level > 5) throw const FormatException();
    return SkillSelection(skillId: json['skill_id'] as String, level: level);
  }
  Map<String, dynamic> toJson() => {'skill_id': skillId, 'level': level};
}

class AcademicPreferences {
  const AcademicPreferences({this.studyMode, this.preferredLanguage});
  final StudyMode? studyMode;
  final String? preferredLanguage;
  factory AcademicPreferences.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('study_mode') ||
        !json.containsKey('preferred_language')) {
      throw const FormatException();
    }
    return AcademicPreferences(
      studyMode: json['study_mode'] == null
          ? null
          : StudyMode.values.firstWhere((v) => v.value == json['study_mode']),
      preferredLanguage: json['preferred_language'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
    'study_mode': studyMode?.value,
    'preferred_language': preferredLanguage,
  };
}

/// Full PUT projection, with no identity/status/timestamp properties.
class AcademicProfileInput {
  AcademicProfileInput({
    this.displayName,
    this.universityId,
    this.program,
    this.semester,
    this.bio,
    this.mbtiBadge,
    this.visibility = ProfileVisibility.private,
    List<String> courses = const [],
    List<SkillSelection> skills = const [],
    this.preferences = const AcademicPreferences(),
  }) : courses = List.unmodifiable(courses),
       skills = List.unmodifiable(skills);
  final String? displayName, universityId, program, bio, mbtiBadge;
  final int? semester;
  final ProfileVisibility visibility;
  final List<String> courses;
  final List<SkillSelection> skills;
  final AcademicPreferences preferences;
  factory AcademicProfileInput.fromJson(Map<String, dynamic> json) {
    const fields = [
      'display_name',
      'university_id',
      'program',
      'semester',
      'bio',
      'mbti_badge',
      'visibility',
      'courses',
      'skills',
      'preferences',
    ];
    if (!fields.every(json.containsKey)) throw const FormatException();
    final semester = json['semester'] as int?;
    if (semester != null && (semester < 1 || semester > 20)) {
      throw const FormatException();
    }
    return AcademicProfileInput(
      displayName: json['display_name'] as String?,
      universityId: json['university_id'] as String?,
      program: json['program'] as String?,
      semester: semester,
      bio: json['bio'] as String?,
      mbtiBadge: json['mbti_badge'] as String?,
      visibility: ProfileVisibility.values.byName(json['visibility'] as String),
      courses: (json['courses'] as List).cast<String>(),
      skills: (json['skills'] as List)
          .map((s) => SkillSelection.fromJson(s as Map<String, dynamic>))
          .toList(),
      preferences: AcademicPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      ),
    );
  }
  Map<String, dynamic> toJson() => {
    'display_name': displayName,
    'university_id': universityId,
    'program': program,
    'semester': semester,
    'bio': bio,
    'mbti_badge': mbtiBadge,
    'visibility': visibility.name,
    'courses': courses,
    'skills': skills.map((s) => s.toJson()).toList(),
    'preferences': preferences.toJson(),
  };

  /// Content-empty only: Laravel does not expose whether a profile row exists.
  bool get isEmpty =>
      displayName == null &&
      universityId == null &&
      program == null &&
      semester == null &&
      bio == null &&
      mbtiBadge == null &&
      visibility == ProfileVisibility.private &&
      courses.isEmpty &&
      skills.isEmpty &&
      preferences.studyMode == null &&
      preferences.preferredLanguage == null;
}

class AcademicProfile {
  const AcademicProfile({required this.userId, required this.input});
  final String userId;
  final AcademicProfileInput input;
  factory AcademicProfile.fromJson(Map<String, dynamic> json) =>
      AcademicProfile(
        userId: json['user_id'] as String,
        input: AcademicProfileInput.fromJson(json),
      );
}

// Immutable domain models mapped directly to Supabase Postgres tables.

class UniversityItem {
  const UniversityItem({
    required this.id,
    required this.name,
    required this.shortName,
    required this.city,
  });

  final String id;
  final String name;
  final String shortName;
  final String city;

  factory UniversityItem.fromMap(Map<String, dynamic> map) => UniversityItem(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? '',
        shortName: (map['short_name'] as String?) ?? '',
        city: (map['city'] as String?) ?? '',
      );
}

class CourseItem {
  const CourseItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
  });

  final String id;
  final String code;
  final String name;
  final String category;

  factory CourseItem.fromMap(Map<String, dynamic> map) => CourseItem(
        id: map['id'] as String,
        code: (map['code'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        category: (map['category'] as String?) ?? 'Umum',
      );
}

class SkillItem {
  const SkillItem({
    required this.id,
    required this.name,
    required this.category,
  });

  final String id;
  final String name;
  final String category;

  factory SkillItem.fromMap(Map<String, dynamic> map) => SkillItem(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? '',
        category: (map['category'] as String?) ?? 'Umum',
      );
}

class ProfileSkillEntry {
  const ProfileSkillEntry({
    required this.skill,
    required this.level,
  });

  final SkillItem skill;
  final int level;
}

class RekanCatalog {
  const RekanCatalog({
    required this.universities,
    required this.courses,
    required this.skills,
  });

  const RekanCatalog.empty()
      : universities = const [],
        courses = const [],
        skills = const [];

  final List<UniversityItem> universities;
  final List<CourseItem> courses;
  final List<SkillItem> skills;
}

class StudentProfile {
  const StudentProfile({
    required this.id,
    this.authUserId,
    required this.displayName,
    this.universityId,
    this.universityName = '',
    this.universityShortName = '',
    required this.program,
    this.semester,
    required this.intent,
    required this.roleFocus,
    required this.projectGoal,
    required this.bio,
    this.mbtiBadge,
    required this.studyMode,
    required this.preferredLanguage,
    required this.accessibilityNotes,
    required this.visibility,
    required this.availabilityLabel,
    required this.isOnline,
    required this.onboardingCompleted,
    this.courses = const [],
    this.skills = const [],
  });

  final String id;
  final String? authUserId;
  final String displayName;
  final String? universityId;
  final String universityName;
  final String universityShortName;
  final String program;
  final int? semester;
  final String intent; // study_group, competition, research, both
  final String roleFocus;
  final String projectGoal;
  final String bio;
  final String? mbtiBadge;
  final String studyMode; // online, in_person, hybrid
  final String preferredLanguage;
  final String accessibilityNotes;
  final String visibility; // private, university, public
  final String availabilityLabel;
  final bool isOnline;
  final bool onboardingCompleted;
  final List<CourseItem> courses;
  final List<ProfileSkillEntry> skills;

  String get intentLabel => switch (intent) {
        'study_group' => 'Study Group',
        'competition' => 'Tim Lomba',
        'research' => 'Riset & TA',
        'both' => 'Belajar & Lomba',
        _ => 'Kolaborasi',
      };

  String get studyModeLabel => switch (studyMode) {
        'online' => 'Online',
        'in_person' => 'Tatap Muka',
        _ => 'Hybrid',
      };

  String get semesterLabel => semester != null ? 'Smt $semester' : 'Mahasiswa';

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    final uni = map['universities'] as Map<String, dynamic>?;
    final rawCourses = (map['profile_courses'] as List?) ?? const [];
    final courses = <CourseItem>[];
    for (final entry in rawCourses) {
      if (entry is Map<String, dynamic>) {
        final courseMap = entry['courses'];
        if (courseMap is Map<String, dynamic>) {
          courses.add(CourseItem.fromMap(courseMap));
        }
      }
    }

    final rawSkills = (map['profile_skills'] as List?) ?? const [];
    final skills = <ProfileSkillEntry>[];
    for (final entry in rawSkills) {
      if (entry is Map<String, dynamic>) {
        final skillMap = entry['skills'];
        if (skillMap is Map<String, dynamic>) {
          skills.add(
            ProfileSkillEntry(
              skill: SkillItem.fromMap(skillMap),
              level: (entry['level'] as num?)?.toInt() ?? 3,
            ),
          );
        }
      }
    }

    return StudentProfile(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String?,
      displayName: (map['display_name'] as String?) ?? 'Mahasiswa Re:kan',
      universityId: map['university_id'] as String?,
      universityName: (uni?['name'] as String?) ?? '',
      universityShortName: (uni?['short_name'] as String?) ?? '',
      program: (map['program'] as String?) ?? '',
      semester: (map['semester'] as num?)?.toInt(),
      intent: (map['intent'] as String?) ?? 'study_group',
      roleFocus: (map['role_focus'] as String?) ?? 'Anggota Tim',
      projectGoal: (map['project_goal'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
      mbtiBadge: map['mbti_badge'] as String?,
      studyMode: (map['study_mode'] as String?) ?? 'hybrid',
      preferredLanguage: (map['preferred_language'] as String?) ?? 'id',
      accessibilityNotes: (map['accessibility_notes'] as String?) ?? '',
      visibility: (map['visibility'] as String?) ?? 'public',
      availabilityLabel: (map['availability_label'] as String?) ?? 'Tersedia',
      isOnline: (map['is_online'] as bool?) ?? true,
      onboardingCompleted: (map['onboarding_completed'] as bool?) ?? false,
      courses: courses,
      skills: skills,
    );
  }
}

class ProfileDraftInput {
  const ProfileDraftInput({
    required this.displayName,
    this.universityId,
    required this.program,
    this.semester,
    required this.intent,
    required this.roleFocus,
    required this.projectGoal,
    required this.bio,
    this.mbtiBadge,
    required this.studyMode,
    required this.accessibilityNotes,
    required this.visibility,
    required this.availabilityLabel,
    required this.courseIds,
    required this.skillLevels,
  });

  final String displayName;
  final String? universityId;
  final String program;
  final int? semester;
  final String intent;
  final String roleFocus;
  final String projectGoal;
  final String bio;
  final String? mbtiBadge;
  final String studyMode;
  final String accessibilityNotes;
  final String visibility;
  final String availabilityLabel;
  final List<String> courseIds;
  final Map<String, int> skillLevels;
}

class InvitationItem {
  const InvitationItem({
    required this.id,
    required this.senderUserId,
    required this.targetProfileId,
    required this.targetName,
    required this.targetProgram,
    required this.intent,
    required this.goalNote,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String senderUserId;
  final String targetProfileId;
  final String targetName;
  final String targetProgram;
  final String intent;
  final String goalNote;
  final String status; // pending, accepted, declined
  final DateTime createdAt;

  String get statusLabel => switch (status) {
        'accepted' => 'Diterima',
        'declined' => 'Ditolak',
        _ => 'Menunggu',
      };

  factory InvitationItem.fromMap(Map<String, dynamic> map) {
    final target = map['profiles'] as Map<String, dynamic>?;
    return InvitationItem(
      id: map['id'] as String,
      senderUserId: (map['sender_user_id'] as String?) ?? '',
      targetProfileId: (map['target_profile_id'] as String?) ?? '',
      targetName: (target?['display_name'] as String?) ?? 'Rekan',
      targetProgram: (target?['program'] as String?) ?? '',
      intent: (map['intent'] as String?) ?? 'study_group',
      goalNote: (map['goal_note'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class RoomTaskItem {
  const RoomTaskItem({
    required this.id,
    required this.roomId,
    required this.title,
    required this.dueLabel,
    required this.isDone,
  });

  final String id;
  final String roomId;
  final String title;
  final String dueLabel;
  final bool isDone;

  factory RoomTaskItem.fromMap(Map<String, dynamic> map) => RoomTaskItem(
        id: map['id'] as String,
        roomId: (map['room_id'] as String?) ?? '',
        title: (map['title'] as String?) ?? '',
        dueLabel: (map['due_label'] as String?) ?? 'Minggu ini',
        isDone: (map['is_done'] as bool?) ?? false,
      );
}

class RoomMaterialItem {
  const RoomMaterialItem({
    required this.id,
    required this.roomId,
    required this.title,
    required this.fileType,
    required this.fileSizeKb,
    required this.fileUrl,
  });

  final String id;
  final String roomId;
  final String title;
  final String fileType;
  final int fileSizeKb;
  final String fileUrl;

  String get sizeLabel => fileSizeKb >= 1024
      ? '${(fileSizeKb / 1024).toStringAsFixed(1)} MB'
      : '$fileSizeKb KB';

  factory RoomMaterialItem.fromMap(Map<String, dynamic> map) => RoomMaterialItem(
        id: map['id'] as String,
        roomId: (map['room_id'] as String?) ?? '',
        title: (map['title'] as String?) ?? '',
        fileType: (map['file_type'] as String?) ?? 'PDF',
        fileSizeKb: (map['file_size_kb'] as num?)?.toInt() ?? 0,
        fileUrl: (map['file_url'] as String?) ?? '',
      );
}

class RoomMessageItem {
  const RoomMessageItem({
    required this.id,
    required this.roomId,
    this.senderUserId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String? senderUserId;
  final String senderName;
  final String body;
  final DateTime createdAt;

  factory RoomMessageItem.fromMap(Map<String, dynamic> map) => RoomMessageItem(
        id: map['id'] as String,
        roomId: (map['room_id'] as String?) ?? '',
        senderUserId: map['sender_user_id'] as String?,
        senderName: (map['sender_name'] as String?) ?? 'Mahasiswa',
        body: (map['body'] as String?) ?? '',
        createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
            DateTime.now(),
      );
}

class CollaborationRoom {
  const CollaborationRoom({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.intent,
    required this.description,
    required this.nextSessionLabel,
    this.tasks = const [],
    this.materials = const [],
    this.messages = const [],
  });

  final String id;
  final String title;
  final String courseCode;
  final String intent;
  final String description;
  final String nextSessionLabel;
  final List<RoomTaskItem> tasks;
  final List<RoomMaterialItem> materials;
  final List<RoomMessageItem> messages;

  factory CollaborationRoom.fromMap(Map<String, dynamic> map) {
    final tasks = ((map['room_tasks'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RoomTaskItem.fromMap)
        .toList();
    final materials = ((map['room_materials'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RoomMaterialItem.fromMap)
        .toList();
    final messages = ((map['room_messages'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RoomMessageItem.fromMap)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return CollaborationRoom(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      courseCode: (map['course_code'] as String?) ?? 'UMUM',
      intent: (map['intent'] as String?) ?? 'study_group',
      description: (map['description'] as String?) ?? '',
      nextSessionLabel: (map['next_session_label'] as String?) ?? 'Fleksibel',
      tasks: tasks,
      materials: materials,
      messages: messages,
    );
  }
}

class DirectMessageItem {
  const DirectMessageItem({
    required this.id,
    required this.senderUserId,
    required this.peerProfileId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String senderUserId;
  final String peerProfileId;
  final String senderName;
  final String body;
  final DateTime createdAt;

  factory DirectMessageItem.fromMap(Map<String, dynamic> map) =>
      DirectMessageItem(
        id: map['id'] as String,
        senderUserId: (map['sender_user_id'] as String?) ?? '',
        peerProfileId: (map['peer_profile_id'] as String?) ?? '',
        senderName: (map['sender_name'] as String?) ?? 'Mahasiswa',
        body: (map['body'] as String?) ?? '',
        createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
            DateTime.now(),
      );
}

class CourseDiscussionItem {
  const CourseDiscussionItem({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.authorName,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String courseCode;
  final String courseName;
  final String authorName;
  final String title;
  final String body;
  final DateTime createdAt;

  factory CourseDiscussionItem.fromMap(Map<String, dynamic> map) {
    final course = map['courses'] as Map<String, dynamic>?;
    return CourseDiscussionItem(
      id: map['id'] as String,
      courseId: (map['course_id'] as String?) ?? '',
      courseCode: (course?['code'] as String?) ?? 'MK',
      courseName: (course?['name'] as String?) ?? '',
      authorName: (map['author_name'] as String?) ?? 'Mahasiswa',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

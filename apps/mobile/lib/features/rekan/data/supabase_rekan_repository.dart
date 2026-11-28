import 'package:supabase_flutter/supabase_flutter.dart';

import 'rekan_models.dart';

/// Contract for all Re:kan academic data backed by Supabase Postgres.
abstract interface class RekanRepository {
  String? get currentUserId;
  String? get currentUserEmail;

  Future<RekanCatalog> fetchCatalog();
  Future<StudentProfile?> fetchMyProfile();
  Future<StudentProfile> saveMyProfile(ProfileDraftInput input);
  Future<List<StudentProfile>> fetchDiscoveryProfiles();
  Future<Set<String>> fetchBookmarkedProfileIds();
  Future<bool> toggleBookmark(String targetProfileId);
  Future<List<InvitationItem>> fetchInvitations();
  Future<void> sendInvitation({
    required String targetProfileId,
    required String intent,
    required String goalNote,
  });
  Future<void> updateInvitationStatus(String invitationId, String status);
  Future<List<CollaborationRoom>> fetchRooms();
  Future<void> createRoom({
    required String title,
    required String courseCode,
    required String intent,
    required String description,
    required String nextSessionLabel,
  });
  Future<void> toggleTask(String taskId, bool isDone);
  Future<void> addTask({
    required String roomId,
    required String title,
    required String dueLabel,
  });
  Future<void> sendRoomMessage({
    required String roomId,
    required String senderName,
    required String body,
  });
  Future<List<DirectMessageItem>> fetchDirectMessages(String peerProfileId);
  Future<void> sendDirectMessage({
    required String peerProfileId,
    required String senderName,
    required String body,
  });
  Future<List<CourseDiscussionItem>> fetchCourseDiscussions();
  Future<void> createCourseDiscussion({
    required String courseId,
    required String authorName,
    required String title,
    required String body,
  });
}

/// Live Supabase Postgres implementation — zero hardcoded dummy data.
class SupabaseRekanRepository implements RekanRepository {
  SupabaseRekanRepository(
    this._client, {
    this.userIdProvider,
    this.userEmailProvider,
  });

  final SupabaseClient _client;
  final String? Function()? userIdProvider;
  final String? Function()? userEmailProvider;

  static const _profileSelect = '''
    id, auth_user_id, display_name, university_id, program, semester,
    intent, role_focus, project_goal, bio, mbti_badge, study_mode,
    preferred_language, accessibility_notes, visibility,
    availability_label, is_online, onboarding_completed,
    universities(id, name, short_name, city),
    profile_courses(courses(id, code, name, category)),
    profile_skills(level, skills(id, name, category))
  ''';

  @override
  String? get currentUserId =>
      userIdProvider?.call() ?? _client.auth.currentUser?.id;

  @override
  String? get currentUserEmail =>
      userEmailProvider?.call() ?? _client.auth.currentUser?.email;

  @override
  Future<RekanCatalog> fetchCatalog() async {
    final results = await Future.wait([
      _client.from('universities').select().order('name'),
      _client.from('courses').select().order('code'),
      _client.from('skills').select().order('name'),
    ]);

    return RekanCatalog(
      universities: (results[0] as List)
          .cast<Map<String, dynamic>>()
          .map(UniversityItem.fromMap)
          .toList(),
      courses: (results[1] as List)
          .cast<Map<String, dynamic>>()
          .map(CourseItem.fromMap)
          .toList(),
      skills: (results[2] as List)
          .cast<Map<String, dynamic>>()
          .map(SkillItem.fromMap)
          .toList(),
    );
  }

  @override
  Future<StudentProfile?> fetchMyProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final row = await _client
        .from('profiles')
        .select(_profileSelect)
        .eq('auth_user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return StudentProfile.fromMap(row);
  }

  @override
  Future<StudentProfile> saveMyProfile(ProfileDraftInput input) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Pengguna belum masuk.');

    final payload = <String, dynamic>{
      'auth_user_id': uid,
      'display_name': input.displayName.trim(),
      'university_id': input.universityId,
      'program': input.program.trim(),
      'semester': input.semester,
      'intent': input.intent,
      'role_focus': input.roleFocus.trim().isEmpty
          ? 'Anggota Tim'
          : input.roleFocus.trim(),
      'project_goal': input.projectGoal.trim(),
      'bio': input.bio.trim(),
      'mbti_badge': (input.mbtiBadge == null || input.mbtiBadge!.trim().isEmpty)
          ? null
          : input.mbtiBadge!.trim().toUpperCase(),
      'study_mode': input.studyMode,
      'accessibility_notes': input.accessibilityNotes.trim(),
      'visibility': input.visibility,
      'availability_label': input.availabilityLabel.trim().isEmpty
          ? 'Fleksibel'
          : input.availabilityLabel.trim(),
      'onboarding_completed': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final upserted = await _client
        .from('profiles')
        .upsert(payload, onConflict: 'auth_user_id')
        .select('id')
        .single();
    final profileId = upserted['id'] as String;

    // Replace selected courses
    await _client.from('profile_courses').delete().eq('profile_id', profileId);
    if (input.courseIds.isNotEmpty) {
      await _client.from('profile_courses').insert(
            input.courseIds
                .map((cid) => {'profile_id': profileId, 'course_id': cid})
                .toList(),
          );
    }

    // Replace selected skills & levels
    await _client.from('profile_skills').delete().eq('profile_id', profileId);
    if (input.skillLevels.isNotEmpty) {
      await _client.from('profile_skills').insert(
            input.skillLevels.entries
                .map(
                  (e) => {
                    'profile_id': profileId,
                    'skill_id': e.key,
                    'level': e.value.clamp(1, 5),
                  },
                )
                .toList(),
          );
    }

    final refreshed = await fetchMyProfile();
    if (refreshed == null) {
      throw StateError('Gagal memuat ulang profil tersimpan.');
    }
    return refreshed;
  }

  @override
  Future<List<StudentProfile>> fetchDiscoveryProfiles() async {
    final uid = currentUserId;
    final rows = await _client
        .from('profiles')
        .select(_profileSelect)
        .order('is_online', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(StudentProfile.fromMap)
        .where((p) => p.authUserId == null || p.authUserId != uid)
        .toList();
  }

  @override
  Future<Set<String>> fetchBookmarkedProfileIds() async {
    final uid = currentUserId;
    if (uid == null) return {};
    final rows = await _client
        .from('bookmarks')
        .select('target_profile_id')
        .eq('owner_user_id', uid);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => r['target_profile_id'] as String)
        .toSet();
  }

  @override
  Future<bool> toggleBookmark(String targetProfileId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    final existing = await _client
        .from('bookmarks')
        .select('id')
        .eq('owner_user_id', uid)
        .eq('target_profile_id', targetProfileId)
        .maybeSingle();

    if (existing != null) {
      await _client.from('bookmarks').delete().eq('id', existing['id']);
      return false;
    } else {
      await _client.from('bookmarks').insert({
        'owner_user_id': uid,
        'target_profile_id': targetProfileId,
      });
      return true;
    }
  }

  @override
  Future<List<InvitationItem>> fetchInvitations() async {
    final rows = await _client
        .from('invitations')
        .select(
          'id, sender_user_id, target_profile_id, intent, goal_note, status, created_at, profiles(display_name, program)',
        )
        .order('created_at', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(InvitationItem.fromMap)
        .toList();
  }

  @override
  Future<void> sendInvitation({
    required String targetProfileId,
    required String intent,
    required String goalNote,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Pengguna belum masuk.');
    await _client.from('invitations').upsert(
      {
        'sender_user_id': uid,
        'target_profile_id': targetProfileId,
        'intent': intent,
        'goal_note': goalNote.trim(),
        'status': 'pending',
      },
      onConflict: 'sender_user_id,target_profile_id',
    );
  }

  @override
  Future<void> updateInvitationStatus(String invitationId, String status) async {
    await _client
        .from('invitations')
        .update({'status': status})
        .eq('id', invitationId);
  }

  @override
  Future<List<CollaborationRoom>> fetchRooms() async {
    final rows = await _client
        .from('collaboration_rooms')
        .select('''
          id, title, course_code, intent, description, next_session_label,
          room_tasks(id, room_id, title, due_label, is_done),
          room_materials(id, room_id, title, file_type, file_size_kb, file_url),
          room_messages(id, room_id, sender_user_id, sender_name, body, created_at)
        ''')
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(CollaborationRoom.fromMap)
        .toList();
  }

  @override
  Future<void> createRoom({
    required String title,
    required String courseCode,
    required String intent,
    required String description,
    required String nextSessionLabel,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Pengguna belum masuk.');
    final room = await _client
        .from('collaboration_rooms')
        .insert({
          'title': title.trim(),
          'course_code': courseCode.trim().toUpperCase(),
          'intent': intent,
          'description': description.trim(),
          'next_session_label': nextSessionLabel.trim().isEmpty
              ? 'Jadwal fleksibel'
              : nextSessionLabel.trim(),
          'created_by': uid,
        })
        .select('id')
        .single();

    await _client.from('room_members').upsert({
      'room_id': room['id'],
      'user_id': uid,
      'role': 'owner',
    });
  }

  @override
  Future<void> toggleTask(String taskId, bool isDone) async {
    await _client
        .from('room_tasks')
        .update({'is_done': isDone})
        .eq('id', taskId);
  }

  @override
  Future<void> addTask({
    required String roomId,
    required String title,
    required String dueLabel,
  }) async {
    final uid = currentUserId;
    await _client.from('room_tasks').insert({
      'room_id': roomId,
      'title': title.trim(),
      'due_label': dueLabel.trim().isEmpty ? 'Minggu ini' : dueLabel.trim(),
      'is_done': false,
      'created_by': uid,
    });
  }

  @override
  Future<void> sendRoomMessage({
    required String roomId,
    required String senderName,
    required String body,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Pengguna belum masuk.');
    await _client.from('room_messages').insert({
      'room_id': roomId,
      'sender_user_id': uid,
      'sender_name': senderName,
      'body': body.trim(),
    });
  }

  @override
  Future<List<DirectMessageItem>> fetchDirectMessages(
    String peerProfileId,
  ) async {
    final rows = await _client
        .from('direct_messages')
        .select()
        .eq('peer_profile_id', peerProfileId)
        .order('created_at', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(DirectMessageItem.fromMap)
        .toList();
  }

  @override
  Future<void> sendDirectMessage({
    required String peerProfileId,
    required String senderName,
    required String body,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Pengguna belum masuk.');
    await _client.from('direct_messages').insert({
      'sender_user_id': uid,
      'peer_profile_id': peerProfileId,
      'sender_name': senderName,
      'body': body.trim(),
    });
  }

  @override
  Future<List<CourseDiscussionItem>> fetchCourseDiscussions() async {
    final rows = await _client
        .from('course_discussions')
        .select(
          'id, course_id, author_name, title, body, created_at, courses(code, name)',
        )
        .order('created_at', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(CourseDiscussionItem.fromMap)
        .toList();
  }

  @override
  Future<void> createCourseDiscussion({
    required String courseId,
    required String authorName,
    required String title,
    required String body,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Pengguna belum masuk.');
    await _client.from('course_discussions').insert({
      'course_id': courseId,
      'author_user_id': uid,
      'author_name': authorName,
      'title': title.trim(),
      'body': body.trim(),
    });
  }
}


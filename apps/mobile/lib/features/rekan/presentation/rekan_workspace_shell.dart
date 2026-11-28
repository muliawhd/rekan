import 'package:material_ui/material_ui.dart';

import '../../../core/theme/rekan_theme.dart';
import '../../../core/widgets/rekan_logo.dart';
import '../../auth/auth_controller.dart';
import '../data/rekan_models.dart';
import '../data/supabase_rekan_repository.dart';
import 'collab_tab.dart';
import 'discover_tab.dart';
import 'messages_tab.dart';
import 'profile_tab.dart';
import 'rekan_onboarding_page.dart';
import 'search_tab.dart';

/// Main authenticated coordinator implementing the exact Re:kan User Flow:
/// 02 ONBOARD (5-step if incomplete) -> 03 DISCOVER (Jelajah + Cari) ->
/// 04 COLLAB (Kolaborasi + Pesan) -> 05 PROFILE (Profil Akademik Saya).
/// 100% backed by live Supabase Postgres data (zero hardcoded dummy arrays).
class RekanWorkspaceShell extends StatefulWidget {
  const RekanWorkspaceShell({
    super.key,
    required this.authController,
    required this.repository,
  });

  final AuthController authController;
  final RekanRepository repository;

  @override
  State<RekanWorkspaceShell> createState() => _RekanWorkspaceShellState();
}

class _RekanWorkspaceShellState extends State<RekanWorkspaceShell> {
  int _tabIndex = 0;
  bool _loading = true;
  bool _editingProfile = false;
  String? _loadError;

  RekanCatalog _catalog = const RekanCatalog.empty();
  StudentProfile? _myProfile;
  List<StudentProfile> _discoveryProfiles = const [];
  Set<String> _bookmarkedIds = {};
  List<InvitationItem> _invitations = const [];
  List<CollaborationRoom> _rooms = const [];
  List<CourseDiscussionItem> _discussions = const [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final results = await Future.wait([
        widget.repository.fetchCatalog(),
        widget.repository.fetchMyProfile(),
        widget.repository.fetchDiscoveryProfiles(),
        widget.repository.fetchBookmarkedProfileIds(),
        widget.repository.fetchInvitations(),
        widget.repository.fetchRooms(),
        widget.repository.fetchCourseDiscussions(),
      ]);
      if (!mounted) return;
      setState(() {
        _catalog = results[0] as RekanCatalog;
        _myProfile = results[1] as StudentProfile?;
        _discoveryProfiles = results[2] as List<StudentProfile>;
        _bookmarkedIds = results[3] as Set<String>;
        _invitations = results[4] as List<InvitationItem>;
        _rooms = results[5] as List<CollaborationRoom>;
        _discussions = results[6] as List<CourseDiscussionItem>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError =
            'Belum dapat memuat data dari Supabase. Periksa koneksi internet lalu coba lagi.';
        _loading = false;
      });
    }
  }

  void _showNotice(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: RekanPalette.ink,
        content: Text(msg),
      ),
    );
  }

  String get _currentUserName =>
      _myProfile?.displayName ??
      (widget.repository.currentUserEmail?.split('@').first ?? 'Mahasiswa');

  Future<void> _handleSaveProfile(ProfileDraftInput input) async {
    final saved = await widget.repository.saveMyProfile(input);
    if (!mounted) return;
    setState(() {
      _myProfile = saved;
      _editingProfile = false;
    });
    _showNotice('Profil akademik tersimpan ke Supabase.');
    await _loadAll(silent: true);
  }

  Future<void> _handleToggleBookmark(String profileId) async {
    final added = await widget.repository.toggleBookmark(profileId);
    if (!mounted) return;
    setState(() {
      if (added) {
        _bookmarkedIds = {..._bookmarkedIds, profileId};
      } else {
        _bookmarkedIds = {..._bookmarkedIds}..remove(profileId);
      }
    });
    _showNotice(added ? 'Disimpan ke Bookmark.' : 'Dihapus dari Bookmark.');
  }

  Future<void> _handleSendInvitation(
    StudentProfile target,
    String intent,
    String goalNote,
  ) async {
    await widget.repository.sendInvitation(
      targetProfileId: target.id,
      intent: intent,
      goalNote: goalNote,
    );
    await _loadAll(silent: true);
    _showNotice('Undangan kolaborasi terkirim ke ${target.displayName}.');
  }

  Future<void> _handleCreateDiscussion(
    String courseId,
    String title,
    String body,
  ) async {
    await widget.repository.createCourseDiscussion(
      courseId: courseId,
      authorName: _currentUserName,
      title: title,
      body: body,
    );
    await _loadAll(silent: true);
    _showNotice('Topik forum berhasil diterbitkan.');
  }

  Future<void> _handleCreateRoom({
    required String title,
    required String courseCode,
    required String intent,
    required String description,
    required String nextSessionLabel,
  }) async {
    await widget.repository.createRoom(
      title: title,
      courseCode: courseCode,
      intent: intent,
      description: description,
      nextSessionLabel: nextSessionLabel,
    );
    await _loadAll(silent: true);
    _showNotice('Ruang kolaborasi "$title" berhasil dibuat.');
  }

  void _openDirectChatWith(StudentProfile peer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DirectChatScreen(
          peer: peer,
          repository: widget.repository,
          currentUserName: _currentUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: RekanPalette.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RekanLogo(size: 64, showWordmark: true),
                SizedBox(height: 20),
                SizedBox(
                  width: 170,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      color: RekanPalette.lemonVivid,
                      backgroundColor: RekanPalette.lemonSoft,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Mengambil data dari Supabase...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RekanPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: RekanPalette.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: RekanLogo.header()),
                  const SizedBox(height: 20),
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: RekanPalette.inkSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadAll,
                    child: const Text('Coba Muat Ulang'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: widget.authController.logout,
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 02 ONBOARD — Show 5-step onboarding if profile not yet completed or user tapped Edit
    final needsOnboarding =
        _myProfile == null || !_myProfile!.onboardingCompleted;
    if (needsOnboarding || _editingProfile) {
      return RekanOnboardingPage(
        catalog: _catalog,
        initialProfile: _myProfile,
        initialEmail: widget.repository.currentUserEmail,
        onSave: _handleSaveProfile,
        onCancel: needsOnboarding
            ? null
            : () => setState(() => _editingProfile = false),
        onLogout: widget.authController.logout,
      );
    }

    final pendingInvites =
        _invitations.where((i) => i.status == 'pending').length;

    return Scaffold(
      backgroundColor: RekanPalette.background,
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            // Tab 1: Jelajah (03 DISCOVER)
            RekanDiscoverTab(
              profiles: _discoveryProfiles,
              courses: _catalog.courses,
              discussions: _discussions,
              bookmarkedIds: _bookmarkedIds,
              onToggleBookmark: _handleToggleBookmark,
              onSendInvitation: _handleSendInvitation,
              onCreateDiscussion: _handleCreateDiscussion,
              onOpenSearch: () => setState(() => _tabIndex = 1),
              onOpenCollab: () => setState(() => _tabIndex = 2),
              onOpenChatWith: _openDirectChatWith,
              onRefresh: () => _loadAll(silent: true),
            ),
            // Tab 2: Cari (03 DISCOVER)
            RekanSearchTab(
              profiles: _discoveryProfiles,
              catalog: _catalog,
              bookmarkedIds: _bookmarkedIds,
              onToggleBookmark: _handleToggleBookmark,
              onSendInvitation: _handleSendInvitation,
              onOpenChatWith: _openDirectChatWith,
            ),
            // Tab 3: Kolaborasi (04 COLLAB)
            RekanCollabTab(
              rooms: _rooms,
              invitations: _invitations,
              currentUserName: _currentUserName,
              onCreateRoom: _handleCreateRoom,
              onToggleTask: (taskId, isDone) async {
                await widget.repository.toggleTask(taskId, isDone);
                await _loadAll(silent: true);
              },
              onAddTask: (roomId, title, dueLabel) async {
                await widget.repository.addTask(
                  roomId: roomId,
                  title: title,
                  dueLabel: dueLabel,
                );
                await _loadAll(silent: true);
              },
              onSendRoomMessage: (roomId, body) async {
                await widget.repository.sendRoomMessage(
                  roomId: roomId,
                  senderName: _currentUserName,
                  body: body,
                );
                await _loadAll(silent: true);
              },
              onUpdateInvitation: (id, status) async {
                await widget.repository.updateInvitationStatus(id, status);
                await _loadAll(silent: true);
              },
              onRefresh: () => _loadAll(silent: true),
            ),
            // Tab 4: Pesan (04 COLLAB)
            RekanMessagesTab(
              peers: _discoveryProfiles,
              repository: widget.repository,
              currentUserName: _currentUserName,
            ),
            // Tab 5: Profil (05 PROFILE)
            RekanProfileTab(
              profile: _myProfile,
              userEmail: widget.repository.currentUserEmail,
              onEditProfile: () => setState(() => _editingProfile = true),
              onLogout: widget.authController.logout,
              logoutBusy: widget.authController.busy,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: RekanPalette.surface,
          border: Border(top: BorderSide(color: RekanPalette.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: 'Jelajah',
                  active: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  label: 'Cari',
                  active: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
                _NavItem(
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder_rounded,
                  label: 'Kolaborasi',
                  badgeCount: pendingInvites,
                  active: _tabIndex == 2,
                  onTap: () => setState(() => _tabIndex = 2),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Pesan',
                  active: _tabIndex == 3,
                  onTap: () => setState(() => _tabIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                  active: _tabIndex == 4,
                  onTap: () => setState(() => _tabIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = active ? RekanPalette.blue : RekanPalette.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? activeIcon : icon, color: color, size: 23),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: RekanPalette.lemon,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: RekanPalette.lemonVivid,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: RekanPalette.lemonInk,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


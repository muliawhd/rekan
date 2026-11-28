import 'package:material_ui/material_ui.dart';

import '../../../core/theme/rekan_theme.dart';
import '../../../core/widgets/rekan_avatar_badge.dart';
import '../../../core/widgets/rekan_illustrations.dart';
import '../../../core/widgets/rekan_logo.dart';
import '../data/rekan_models.dart';

/// 03 DISCOVER (Tab 1: Jelajah) — Intent-based Academic Discovery Deck +
/// Open Course Discussion Hub, backed 100% by live Supabase Postgres data.
class RekanDiscoverTab extends StatefulWidget {
  const RekanDiscoverTab({
    super.key,
    required this.profiles,
    required this.courses,
    required this.discussions,
    required this.bookmarkedIds,
    required this.onToggleBookmark,
    required this.onSendInvitation,
    required this.onCreateDiscussion,
    required this.onOpenSearch,
    required this.onOpenCollab,
    required this.onOpenChatWith,
    required this.onRefresh,
  });

  final List<StudentProfile> profiles;
  final List<CourseItem> courses;
  final List<CourseDiscussionItem> discussions;
  final Set<String> bookmarkedIds;
  final Future<void> Function(String profileId) onToggleBookmark;
  final Future<void> Function(
    StudentProfile target,
    String intent,
    String goalNote,
  ) onSendInvitation;
  final Future<void> Function(String courseId, String title, String body)
      onCreateDiscussion;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenCollab;
  final ValueChanged<StudentProfile> onOpenChatWith;
  final Future<void> Function() onRefresh;

  @override
  State<RekanDiscoverTab> createState() => _RekanDiscoverTabState();
}

class _RekanDiscoverTabState extends State<RekanDiscoverTab> {
  String _intentFilter = 'all';
  int _deckIndex = 0;

  List<StudentProfile> get _filteredProfiles {
    return widget.profiles.where((p) {
      if (_intentFilter == 'all') return true;
      return p.intent == _intentFilter || p.intent == 'both';
    }).toList();
  }

  void _openInviteDialog(StudentProfile target) {
    final noteCtrl = TextEditingController();
    String selectedIntent =
        target.intent == 'both' ? 'study_group' : target.intent;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: RekanPalette.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: RekanPalette.borderStrong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ajak Kolaborasi: ${target.displayName}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: RekanPalette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ('study_group', 'Study Group'),
                    ('competition', 'Tim Lomba'),
                    ('research', 'Riset & TA'),
                  ].map((opt) {
                    final active = selectedIntent == opt.$1;
                    return ChoiceChip(
                      label: Text(opt.$2),
                      selected: active,
                      selectedColor: RekanPalette.lemon,
                      onSelected: (_) =>
                          setSheetState(() => selectedIntent = opt.$1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Tulis tujuan belajar/lomba & jadwal yang kamu usulkan...',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await widget.onSendInvitation(
                      target,
                      selectedIntent,
                      noteCtrl.text.trim().isEmpty
                          ? 'Yuk kolaborasi akademik sesuai mata kuliah & keahlian kita!'
                          : noteCtrl.text.trim(),
                    );
                  },
                  child: const Text('Kirim Undangan Kolaborasi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCandidateDetail(StudentProfile profile) {
    final isSaved = widget.bookmarkedIds.contains(profile.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: RekanPalette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RekanPalette.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  RekanAvatarBadge(
                    name: profile.displayName,
                    size: 54,
                    isOnline: profile.isOnline,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: RekanPalette.ink,
                          ),
                        ),
                        Text(
                          '${profile.universityShortName.isNotEmpty ? "${profile.universityShortName} · " : ""}${profile.program} · ${profile.semesterLabel}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: RekanPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.mbtiBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: RekanPalette.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: RekanPalette.border),
                      ),
                      child: Text(
                        profile.mbtiBadge!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: RekanPalette.inkSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              if (profile.projectGoal.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RekanPalette.lemonTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RekanPalette.lemonSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TARGET KOLABORASI',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: RekanPalette.lemonDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.projectGoal,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: RekanPalette.lemonInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (profile.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  profile.bio,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: RekanPalette.inkSecondary,
                  ),
                ),
              ],
              if (profile.skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Keahlian',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: profile.skills
                      .map(
                        (s) => _TagChip(
                          label: s.skill.name,
                          bg: RekanPalette.blueTint,
                          fg: RekanPalette.blueDark,
                          border: RekanPalette.blueSoft,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (profile.accessibilityNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RekanPalette.blueTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.accessibility_new_rounded,
                        size: 18,
                        color: RekanPalette.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profile.accessibilityNotes,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: RekanPalette.blueDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await widget.onToggleBookmark(profile.id);
                    },
                    child: Text(isSaved ? 'Tersimpan' : 'Simpan'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      widget.onOpenChatWith(profile);
                    },
                    child: const Text('Chat'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openInviteDialog(profile);
                      },
                      child: const Text('Ajak'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNewDiscussionDialog() {
    if (widget.courses.isEmpty) return;
    String selectedCourseId = widget.courses.first.id;
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: RekanPalette.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Buat Topik Forum Mata Kuliah',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedCourseId,
                  items: widget.courses
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.code} · ${c.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => selectedCourseId = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Judul pertanyaan / topik diskusi',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Tulis detail pembahasan mata kuliah...',
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        bodyCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(ctx).pop();
                    await widget.onCreateDiscussion(
                      selectedCourseId,
                      titleCtrl.text.trim(),
                      bodyCtrl.text.trim(),
                    );
                  },
                  child: const Text('Terbitkan ke Forum'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredProfiles;
    final activeIndex = list.isEmpty ? 0 : _deckIndex % list.length;
    final activeCandidate = list.isEmpty ? null : list[activeIndex];

    return RefreshIndicator(
      color: RekanPalette.blue,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          // Top Header Bar
          SliverToBoxAdapter(
            child: Container(
              color: RekanPalette.surface,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Row(
                children: [
                  const RekanLogo.header(),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: widget.onOpenSearch,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: RekanPalette.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: RekanPalette.border),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: RekanPalette.ink,
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Intent Categories (2x2 clean flat cards using custom vector art)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Row(
                children: [
                  _IntentChipTile(
                    categoryId: 'all',
                    label: 'Semua',
                    selected: _intentFilter == 'all',
                    onTap: () => setState(() {
                      _intentFilter = 'all';
                      _deckIndex = 0;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _IntentChipTile(
                    categoryId: 'study',
                    label: 'Study Group',
                    selected: _intentFilter == 'study_group',
                    onTap: () => setState(() {
                      _intentFilter = 'study_group';
                      _deckIndex = 0;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _IntentChipTile(
                    categoryId: 'lomba',
                    label: 'Tim Lomba',
                    selected: _intentFilter == 'competition',
                    onTap: () => setState(() {
                      _intentFilter = 'competition';
                      _deckIndex = 0;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _IntentChipTile(
                    categoryId: 'riset',
                    label: 'Riset',
                    selected: _intentFilter == 'research',
                    onTap: () => setState(() {
                      _intentFilter = 'research';
                      _deckIndex = 0;
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Discovery Deck Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Jelajah Rekan Akademik',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: RekanPalette.ink,
                      ),
                    ),
                  ),
                  if (list.isNotEmpty)
                    Text(
                      '${activeIndex + 1} / ${list.length}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: RekanPalette.blue,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Swipe / Card Discovery Deck (Academic-first: Goal & Role first, NO photo gallery!)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: activeCandidate == null
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: RekanPalette.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: RekanPalette.border),
                      ),
                      child: const Text(
                        'Belum ada kandidat rekan pada kategori ini di Supabase.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: RekanPalette.muted),
                      ),
                    )
                  : _AcademicDeckCard(
                      profile: activeCandidate,
                      isSaved: widget.bookmarkedIds.contains(activeCandidate.id),
                      onOpenDetail: () => _openCandidateDetail(activeCandidate),
                      onSkip: () => setState(() => _deckIndex++),
                      onBookmark: () =>
                          widget.onToggleBookmark(activeCandidate.id),
                      onInvite: () => _openInviteDialog(activeCandidate),
                    ),
            ),
          ),

          // Quick Bento Shortcuts (matching Re:kan's core modules)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: widget.onOpenSearch,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: RekanPalette.blue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filter Keahlian',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Cari rekan cocok',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: RekanPalette.blueSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            BentoVectorEmblem(kind: 'bolt', size: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: widget.onOpenCollab,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: RekanPalette.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: RekanPalette.lemonVivid,
                            width: 1.4,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ruang & Materi',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: RekanPalette.ink,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tugas & unduh file',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: RekanPalette.lemonDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            BentoVectorEmblem(kind: 'rooms', size: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Open Discussion Forum Hub per Course (Abstract §4 & §5)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Forum Diskusi Mata Kuliah',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: RekanPalette.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _openNewDiscussionDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: RekanPalette.blue,
                    ),
                    child: const Text(
                      '+ Topik',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            sliver: SliverList.separated(
              itemCount: widget.discussions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final d = widget.discussions[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: RekanPalette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: RekanPalette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TagChip(
                            label: d.courseCode,
                            bg: RekanPalette.lemonTint,
                            fg: RekanPalette.lemonDark,
                            border: RekanPalette.lemonSoft,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.authorName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: RekanPalette.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        d.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: RekanPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.body,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: RekanPalette.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentChipTile extends StatelessWidget {
  const _IntentChipTile({
    required this.categoryId,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String categoryId;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? RekanPalette.lemonTint : RekanPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? RekanPalette.blue : RekanPalette.border,
              width: selected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              CategoryVectorArt(categoryId: categoryId, size: 28),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? RekanPalette.blue : RekanPalette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademicDeckCard extends StatelessWidget {
  const _AcademicDeckCard({
    required this.profile,
    required this.isSaved,
    required this.onOpenDetail,
    required this.onSkip,
    required this.onBookmark,
    required this.onInvite,
  });

  final StudentProfile profile;
  final bool isSaved;
  final VoidCallback onOpenDetail;
  final VoidCallback onSkip;
  final VoidCallback onBookmark;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RekanPalette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: RekanPalette.border, width: 1.2),
            boxShadow: RekanPalette.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Goal Header (Academic-first: Goal & Role BEFORE personal details!)
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: RekanPalette.lemon,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: RekanPalette.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            profile.intentLabel.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: RekanPalette.blue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          profile.studyModeLabel,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: RekanPalette.lemonInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.projectGoal.isNotEmpty
                          ? profile.projectGoal
                          : 'Mencari rekan ${profile.intentLabel.toLowerCase()} di bidang ${profile.program}',
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.28,
                        fontWeight: FontWeight.w900,
                        color: RekanPalette.lemonInk,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Identity row with clean Monogram Badge (NO cartoon face!)
              Row(
                children: [
                  RekanAvatarBadge(
                    name: profile.displayName,
                    size: 46,
                    isOnline: profile.isOnline,
                    useBlueTone: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: RekanPalette.ink,
                          ),
                        ),
                        Text(
                          '${profile.universityShortName.isNotEmpty ? "${profile.universityShortName} · " : ""}${profile.program} · ${profile.semesterLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: RekanPalette.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.mbtiBadge != null)
                    _TagChip(
                      label: profile.mbtiBadge!,
                      bg: RekanPalette.surfaceSubtle,
                      fg: RekanPalette.inkSecondary,
                      border: RekanPalette.border,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Skills tags from Supabase (tanpa level)
              if (profile.skills.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: profile.skills
                      .take(4)
                      .map(
                        (s) => _TagChip(
                          label: s.skill.name,
                          bg: RekanPalette.blueTint,
                          fg: RekanPalette.blueDark,
                          border: RekanPalette.blueSoft,
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 10),
              Text(
                'Jadwal: ${profile.availabilityLabel} · Fokus: ${profile.roleFocus}',
                style: const TextStyle(
                  fontSize: 12,
                  color: RekanPalette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 14),
              const Divider(color: RekanPalette.border, height: 1),
              const SizedBox(height: 12),

              // 3 Explicit Deck Actions: Lewati / Simpan / Ajak Kolaborasi
              Row(
                children: [
                  OutlinedButton(
                    onPressed: onSkip,
                    child: const Text('Lewati'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onBookmark,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isSaved ? RekanPalette.blue : RekanPalette.ink,
                      side: BorderSide(
                        color: isSaved
                            ? RekanPalette.blue
                            : RekanPalette.borderStrong,
                      ),
                    ),
                    child: Text(isSaved ? 'Disimpan' : 'Simpan'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onInvite,
                      child: const Text('Ajak'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}


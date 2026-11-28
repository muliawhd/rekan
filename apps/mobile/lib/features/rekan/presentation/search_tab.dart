import 'package:material_ui/material_ui.dart';

import '../../../core/theme/rekan_theme.dart';
import '../../../core/widgets/rekan_avatar_badge.dart';
import '../data/rekan_models.dart';

/// 03 DISCOVER (Tab 2: Cari) — Direct Academic Search & Skill Filters backed by Supabase.
class RekanSearchTab extends StatefulWidget {
  const RekanSearchTab({
    super.key,
    required this.profiles,
    required this.catalog,
    required this.bookmarkedIds,
    required this.onToggleBookmark,
    required this.onSendInvitation,
    required this.onOpenChatWith,
  });

  final List<StudentProfile> profiles;
  final RekanCatalog catalog;
  final Set<String> bookmarkedIds;
  final Future<void> Function(String profileId) onToggleBookmark;
  final Future<void> Function(
    StudentProfile target,
    String intent,
    String goalNote,
  ) onSendInvitation;
  final ValueChanged<StudentProfile> onOpenChatWith;

  @override
  State<RekanSearchTab> createState() => _RekanSearchTabState();
}

class _RekanSearchTabState extends State<RekanSearchTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _selectedSkillId;
  bool _onlyBookmarked = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StudentProfile> get _results {
    return widget.profiles.where((p) {
      if (_onlyBookmarked && !widget.bookmarkedIds.contains(p.id)) return false;
      if (_selectedSkillId != null &&
          !p.skills.any((s) => s.skill.id == _selectedSkillId)) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.displayName.toLowerCase().contains(q) ||
          p.program.toLowerCase().contains(q) ||
          p.universityName.toLowerCase().contains(q) ||
          p.projectGoal.toLowerCase().contains(q) ||
          p.roleFocus.toLowerCase().contains(q) ||
          p.skills.any((s) => s.skill.name.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        const Text(
          'Cari Rekan & Filter Akademik',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: RekanPalette.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Saring kandidat berdasarkan keahlian, prodi, kampus, atau bookmark.',
          style: TextStyle(fontSize: 13, color: RekanPalette.muted),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Cari nama, keahlian, prodi, atau kampus...',
            prefixIcon:
                const Icon(Icons.search_rounded, color: RekanPalette.muted),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // Bookmark toggle + Skill filters from Supabase
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text('Tersimpan (${widget.bookmarkedIds.length})'),
                selected: _onlyBookmarked,
                selectedColor: RekanPalette.lemon,
                onSelected: (v) => setState(() => _onlyBookmarked = v),
              ),
              const SizedBox(width: 8),
              ...widget.catalog.skills.map((s) {
                final active = _selectedSkillId == s.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.name),
                    selected: active,
                    selectedColor: RekanPalette.lemon,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? RekanPalette.lemonInk
                          : RekanPalette.inkSecondary,
                    ),
                    onSelected: (_) => setState(
                      () => _selectedSkillId = active ? null : s.id,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),
        if (results.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RekanPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RekanPalette.border),
            ),
            child: const Text(
              'Tidak ada rekan yang sesuai dengan filter saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: RekanPalette.muted),
            ),
          )
        else
          ...results.map((peer) {
            final saved = widget.bookmarkedIds.contains(peer.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: RekanPalette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: RekanPalette.border),
                boxShadow: RekanPalette.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RekanAvatarBadge(
                        name: peer.displayName,
                        size: 44,
                        isOnline: peer.isOnline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              peer.displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: RekanPalette.ink,
                              ),
                            ),
                            Text(
                              '${peer.universityShortName.isNotEmpty ? "${peer.universityShortName} · " : ""}${peer.program} · ${peer.semesterLabel}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: RekanPalette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: saved ? 'Hapus bookmark' : 'Simpan bookmark',
                        onPressed: () => widget.onToggleBookmark(peer.id),
                        icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: saved ? RekanPalette.blue : RekanPalette.muted,
                        ),
                      ),
                    ],
                  ),
                  if (peer.projectGoal.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      peer.projectGoal,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: RekanPalette.ink,
                      ),
                    ),
                  ],
                  if (peer.skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: peer.skills.take(3).map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: RekanPalette.blueTint,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: RekanPalette.blueSoft),
                          ),
                          child: Text(
                            s.skill.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: RekanPalette.blueDark,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => widget.onOpenChatWith(peer),
                          child: const Text('Chat 1-1'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => widget.onSendInvitation(
                            peer,
                            peer.intent == 'both' ? 'study_group' : peer.intent,
                            'Halo ${peer.displayName}, yuk kolaborasi bareng!',
                          ),
                          child: const Text('Ajak Kolaborasi'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

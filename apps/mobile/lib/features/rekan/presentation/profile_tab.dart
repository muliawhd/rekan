import 'package:material_ui/material_ui.dart';

import '../../../core/theme/rekan_theme.dart';
import '../../../core/widgets/rekan_avatar_badge.dart';
import '../data/rekan_models.dart';

/// 05 PROFILE (Tab 5: Profil Akademik Saya) — Live summary from Supabase,
/// clean academic monogram badge (NO cartoon icon), Edit 5-Step button, and Logout.
class RekanProfileTab extends StatelessWidget {
  const RekanProfileTab({
    super.key,
    required this.profile,
    required this.userEmail,
    required this.onEditProfile,
    required this.onLogout,
    required this.logoutBusy,
  });

  final StudentProfile? profile;
  final String? userEmail;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final bool logoutBusy;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final displayName = p?.displayName ?? 'Mahasiswa Re:kan';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        // Crisp Hijau Lemon Profile Header (Clean Academic Monogram — NO cartoon face!)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: RekanPalette.lemon,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RekanPalette.lemonVivid, width: 1.2),
          ),
          child: Row(
            children: [
              RekanAvatarBadge(
                name: displayName,
                size: 58,
                isOnline: true,
                useBlueTone: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: RekanPalette.lemonInk,
                      ),
                    ),
                    if (userEmail != null && userEmail!.isNotEmpty)
                      Text(
                        userEmail!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: RekanPalette.lemonDark,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (p != null)
                          _Badge(p.intentLabel, RekanPalette.blue),
                        if (p?.mbtiBadge != null)
                          _Badge(p!.mbtiBadge!, RekanPalette.ink),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Academic Summary Card (from Supabase `profiles`)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RekanPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RekanPalette.border),
          ),
          child: p == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Profil Akademik Belum Dilengkapi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Lengkapi 5 langkah onboarding agar rekan dengan mata kuliah & keahlian cocok dapat menemukanmu.',
                      style: TextStyle(fontSize: 13, color: RekanPalette.muted),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onEditProfile,
                      child: const Text('Lengkapi Profil Akademik'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Profil Akademik',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: RekanPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      'Kampus',
                      p.universityName.isNotEmpty ? p.universityName : '-',
                    ),
                    _InfoRow(
                      'Prodi & Semester',
                      '${p.program.isNotEmpty ? p.program : "-"} · ${p.semesterLabel}',
                    ),
                    _InfoRow('Fokus Peran', p.roleFocus),
                    _InfoRow('Mode Belajar', p.studyModeLabel),
                    _InfoRow('Jadwal', p.availabilityLabel),
                    if (p.projectGoal.isNotEmpty)
                      _InfoRow('Target Proyek', p.projectGoal),
                    if (p.accessibilityNotes.isNotEmpty)
                      _InfoRow('Aksesibilitas', p.accessibilityNotes),
                    if (p.skills.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Keahlian',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: RekanPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: p.skills
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: RekanPalette.blueTint,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: RekanPalette.blueSoft,
                                  ),
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
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onEditProfile,
                        child: const Text('Edit Profil Akademik'),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 14),

        OutlinedButton(
          onPressed: logoutBusy ? null : onLogout,
          style: OutlinedButton.styleFrom(
            foregroundColor: RekanPalette.danger,
            side: const BorderSide(color: Color(0xFFFECACA), width: 1.4),
            backgroundColor: RekanPalette.dangerSoft,
          ),
          child: const Text('Keluar dari Akun'),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.fg);
  final String text;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: RekanPalette.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: RekanPalette.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: RekanPalette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


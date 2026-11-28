import 'package:material_ui/material_ui.dart';

import '../../../core/theme/rekan_theme.dart';
import '../../../core/widgets/rekan_logo.dart';
import '../data/rekan_models.dart';

/// 02 ONBOARD — 4-Step Academic Onboarding & Profile Editor backed by Supabase:
/// 1. Identitas & Tujuan  2. Kampus & Prodi  3. Keahlian Akademik (tanpa level)  4. Preferensi & Review
class RekanOnboardingPage extends StatefulWidget {
  const RekanOnboardingPage({
    super.key,
    required this.catalog,
    this.initialProfile,
    this.initialEmail,
    required this.onSave,
    this.onCancel,
    this.onLogout,
  });

  final RekanCatalog catalog;
  final StudentProfile? initialProfile;
  final String? initialEmail;
  final Future<void> Function(ProfileDraftInput input) onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onLogout;

  @override
  State<RekanOnboardingPage> createState() => _RekanOnboardingPageState();
}

class _RekanOnboardingPageState extends State<RekanOnboardingPage> {
  int _step = 0; // 0..3 (4 langkah)
  bool _saving = false;
  String? _error;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _goalCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _programCtrl;
  late final TextEditingController _availabilityCtrl;
  late final TextEditingController _accessibilityCtrl;

  String _intent = 'study_group';
  String? _mbti;
  String? _universityId;
  int _semester = 5;
  String _studyMode = 'hybrid';
  String _visibility = 'public';
  final Set<String> _selectedSkillIds = {};

  static const _mbtiOptions = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    final fallbackName = (widget.initialEmail ?? '').split('@').first;
    _nameCtrl = TextEditingController(
      text: p?.displayName ?? (fallbackName.isNotEmpty ? fallbackName : ''),
    );
    _roleCtrl = TextEditingController(text: p?.roleFocus ?? 'Anggota Tim');
    _goalCtrl = TextEditingController(text: p?.projectGoal ?? '');
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _programCtrl = TextEditingController(text: p?.program ?? '');
    _availabilityCtrl = TextEditingController(
      text: p?.availabilityLabel ?? 'Malam hari & akhir pekan',
    );
    _accessibilityCtrl = TextEditingController(
      text: p?.accessibilityNotes ?? '',
    );

    if (p != null) {
      _intent = p.intent;
      _mbti = p.mbtiBadge;
      _universityId = p.universityId;
      _semester = p.semester ?? 5;
      _studyMode = p.studyMode;
      _visibility = p.visibility;
      for (final s in p.skills) {
        _selectedSkillIds.add(s.skill.id);
      }
    } else if (widget.catalog.universities.isNotEmpty) {
      _universityId = widget.catalog.universities.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _goalCtrl.dispose();
    _bioCtrl.dispose();
    _programCtrl.dispose();
    _availabilityCtrl.dispose();
    _accessibilityCtrl.dispose();
    super.dispose();
  }

  String? _validateStep(int step) {
    if (step == 0 && _nameCtrl.text.trim().isEmpty) {
      return 'Masukkan nama lengkap terlebih dahulu.';
    }
    if (step == 1 && _programCtrl.text.trim().isEmpty) {
      return 'Masukkan program studi kamu.';
    }
    return null;
  }

  void _next() {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      if (_step < 3) _step++;
    });
  }

  Future<void> _submit() async {
    for (var i = 0; i <= 1; i++) {
      final err = _validateStep(i);
      if (err != null) {
        setState(() {
          _step = i;
          _error = err;
        });
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        ProfileDraftInput(
          displayName: _nameCtrl.text.trim(),
          universityId: _universityId,
          program: _programCtrl.text.trim(),
          semester: _semester,
          intent: _intent,
          roleFocus: _roleCtrl.text.trim(),
          projectGoal: _goalCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          mbtiBadge: _mbti,
          studyMode: _studyMode,
          accessibilityNotes: _accessibilityCtrl.text.trim(),
          visibility: _visibility,
          availabilityLabel: _availabilityCtrl.text.trim(),
          courseIds: const [],
          skillLevels: {for (final id in _selectedSkillIds) id: 3},
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Gagal menyimpan profil ke Supabase. Periksa koneksi lalu coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static const _stepTitles = [
    '1. Identitas & Tujuan',
    '2. Kampus & Prodi',
    '3. Keahlian Akademik',
    '4. Preferensi & Review',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RekanPalette.surface,
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / 4,
              minHeight: 4,
              color: RekanPalette.lemonVivid,
              backgroundColor: RekanPalette.lemonSoft,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  if (widget.onCancel != null)
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: _saving ? null : widget.onCancel,
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    const RekanLogo.header(),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: RekanPalette.lemonTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RekanPalette.lemonSoft),
                    ),
                    child: Text(
                      'Langkah ${_step + 1} / 4',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: RekanPalette.lemonDark,
                      ),
                    ),
                  ),
                  if (widget.onLogout != null && widget.onCancel == null) ...[
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: _saving ? null : widget.onLogout,
                      style: TextButton.styleFrom(
                        foregroundColor: RekanPalette.muted,
                      ),
                      child: const Text('Keluar'),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _stepTitles[_step],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: RekanPalette.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_error != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RekanPalette.dangerSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: RekanPalette.danger,
                          ),
                        ),
                      ),
                    ],
                    if (_step == 0) _buildStepIdentity(),
                    if (_step == 1) _buildStepCampus(),
                    if (_step == 2) _buildStepSkills(),
                    if (_step == 3) _buildStepPreferencesReview(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: RekanPalette.surface,
                border: Border(top: BorderSide(color: RekanPalette.border)),
              ),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                  _error = null;
                                  _step--;
                                }),
                        child: const Text('Sebelumnya'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : (_step < 3 ? _next : _submit),
                      child: Text(
                        _saving
                            ? 'Menyimpan ke Supabase...'
                            : (_step < 3 ? 'Lanjut' : 'Simpan Profil'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIdentity() {
    const intents = [
      ('study_group', 'Study Group'),
      ('competition', 'Tim Lomba'),
      ('research', 'Riset & TA'),
      ('both', 'Belajar & Lomba'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Data ini membantu mahasiswa lain memahami tujuan akademikmu — bukan galeri foto.',
          style: TextStyle(fontSize: 13.5, color: RekanPalette.muted),
        ),
        const SizedBox(height: 18),
        const _Label('Nama Lengkap'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Contoh: Chiko Pratama'),
        ),
        const SizedBox(height: 14),
        const _Label('Tujuan Kolaborasi Utama'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: intents.map((item) {
            final selected = _intent == item.$1;
            return ChoiceChip(
              label: Text(item.$2),
              selected: selected,
              selectedColor: RekanPalette.lemon,
              backgroundColor: RekanPalette.surface,
              side: BorderSide(
                color: selected
                    ? RekanPalette.lemonVivid
                    : RekanPalette.borderStrong,
              ),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? RekanPalette.lemonInk : RekanPalette.ink,
              ),
              onSelected: (_) => setState(() => _intent = item.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        const _Label('Peran / Fokus Tim'),
        const SizedBox(height: 6),
        TextField(
          controller: _roleCtrl,
          decoration: const InputDecoration(
            hintText: 'Contoh: Mobile Dev, UI/UX, Penulis Riset, Tutor Sebaya',
          ),
        ),
        const SizedBox(height: 14),
        const _Label('Target Proyek / Belajar Saat Ini'),
        const SizedBox(height: 6),
        TextField(
          controller: _goalCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText:
                'Contoh: Cari tim Gemastik 2026 atau kelompok belajar UTS',
          ),
        ),
        const SizedBox(height: 14),
        const _Label('Bio Akademik Singkat'),
        const SizedBox(height: 6),
        TextField(
          controller: _bioCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Ceritakan gaya belajar atau minat risetmu',
          ),
        ),
        const SizedBox(height: 14),
        const _Label(
          'Badge MBTI (Opsional — hanya tampilan, tidak memengaruhi matching)',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Tanpa MBTI'),
              selected: _mbti == null,
              selectedColor: RekanPalette.blueTint,
              onSelected: (_) => setState(() => _mbti = null),
            ),
            ..._mbtiOptions.map(
              (m) => ChoiceChip(
                label: Text(m),
                selected: _mbti == m,
                selectedColor: RekanPalette.blueTint,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _mbti == m
                      ? RekanPalette.blueDark
                      : RekanPalette.inkSecondary,
                ),
                onSelected: (_) => setState(() => _mbti = m),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCampus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pilih kampus dari katalog Supabase dan isi program studimu.',
          style: TextStyle(fontSize: 13.5, color: RekanPalette.muted),
        ),
        const SizedBox(height: 18),
        const _Label('Perguruan Tinggi / Kampus'),
        const SizedBox(height: 8),
        if (widget.catalog.universities.isEmpty)
          const Text(
            'Katalog kampus kosong di Supabase.',
            style: TextStyle(color: RekanPalette.muted),
          )
        else
          ...widget.catalog.universities.map((uni) {
            final selected = _universityId == uni.id;
            return InkWell(
              onTap: () => setState(() => _universityId = uni.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      selected ? RekanPalette.lemonTint : RekanPalette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? RekanPalette.blue : RekanPalette.border,
                    width: selected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uni.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: RekanPalette.ink,
                            ),
                          ),
                          Text(
                            '${uni.shortName} · ${uni.city}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: RekanPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: RekanPalette.blue,
                      ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
        const _Label('Program Studi / Jurusan'),
        const SizedBox(height: 6),
        TextField(
          controller: _programCtrl,
          decoration: const InputDecoration(hintText: 'Contoh: Informatika'),
        ),
        const SizedBox(height: 16),
        _Label('Semester Saat Ini: Semester $_semester'),
        Slider(
          value: _semester.toDouble(),
          min: 1,
          max: 14,
          divisions: 13,
          activeColor: RekanPalette.blue,
          label: 'Semester $_semester',
          onChanged: (v) => setState(() => _semester = v.round()),
        ),
      ],
    );
  }

  Widget _buildStepSkills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pilih keahlian akademik yang kamu kuasai atau ingin kolaborasikan.',
          style: TextStyle(fontSize: 13.5, color: RekanPalette.muted),
        ),
        const SizedBox(height: 16),
        ...widget.catalog.skills.map((skill) {
          final selected = _selectedSkillIds.contains(skill.id);
          return InkWell(
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedSkillIds.remove(skill.id);
                } else {
                  _selectedSkillIds.add(skill.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? RekanPalette.lemonTint : RekanPalette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? RekanPalette.lemonVivid
                      : RekanPalette.border,
                  width: selected ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: RekanPalette.ink,
                          ),
                        ),
                        Text(
                          skill.category,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: RekanPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: selected
                        ? RekanPalette.blue
                        : RekanPalette.borderStrong,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepPreferencesReview() {
    final uniName = widget.catalog.universities
            .where((u) => u.id == _universityId)
            .map((u) => u.name)
            .firstOrNull ??
        '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('Mode Belajar'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ('online', 'Online'),
            ('in_person', 'Tatap Muka'),
            ('hybrid', 'Hybrid'),
          ].map((m) {
            final selected = _studyMode == m.$1;
            return ChoiceChip(
              label: Text(m.$2),
              selected: selected,
              selectedColor: RekanPalette.lemon,
              onSelected: (_) => setState(() => _studyMode = m.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        const _Label('Jadwal Ketersediaan'),
        const SizedBox(height: 6),
        TextField(
          controller: _availabilityCtrl,
          decoration: const InputDecoration(
            hintText: 'Contoh: Senin & Kamis 19:30 WIB',
          ),
        ),
        const SizedBox(height: 14),
        const _Label(
          'Preferensi Komunikasi & Aksesibilitas (Inklusif Disabilitas)',
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _accessibilityCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText:
                'Contoh: Lebih nyaman diskusi teks, transkrip, atau jadwal terstruktur',
          ),
        ),
        const SizedBox(height: 14),
        const _Label('Visibilitas Profil'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ('public', 'Publik Mahasiswa'),
            ('university', 'Satu Kampus'),
            ('private', 'Privat'),
          ].map((v) {
            final selected = _visibility == v.$1;
            return ChoiceChip(
              label: Text(v.$2),
              selected: selected,
              selectedColor: RekanPalette.blueTint,
              onSelected: (_) => setState(() => _visibility = v.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: RekanPalette.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RekanPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Profil Akademik',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: RekanPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text('Nama: ${_nameCtrl.text.trim()}'),
              Text('Kampus: $uniName'),
              Text('Prodi: ${_programCtrl.text.trim()} (Semester $_semester)'),
              Text('Keahlian dipilih: ${_selectedSkillIds.length}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: RekanPalette.ink,
      ),
    );
  }
}

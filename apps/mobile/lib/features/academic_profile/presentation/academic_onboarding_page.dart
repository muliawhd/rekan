import 'package:material_ui/material_ui.dart';

import '../../../core/network/laravel_api.dart';
import '../../../core/theme/re_tokens.dart';
import '../../../core/widgets/re_form_components.dart';
import '../../auth/auth_controller.dart';
import '../data/academic_profile.dart';
import '../data/academic_catalog_repository.dart';
import '../data/academic_profile_repository.dart';
import '../domain/academic_onboarding_completion.dart';
import 'onboarding_draft_controller.dart';
import 'profile_controller.dart';
import 'academic_catalog_selector.dart';

/// Session-aware coordinator that loads the authenticated user's
/// [AcademicProfile] via [ProfileController] and routes between:
/// - Loading / Recoverable Error states
/// - 5-step [AcademicOnboardingPage] when the persisted profile is incomplete
///   (or when the user explicitly chooses to edit their profile)
/// - Completed Academic Profile overview when [AcademicOnboardingCompletion.isComplete]
///   is satisfied by the persisted server response.
class AcademicOnboardingBoundary extends StatefulWidget {
  const AcademicOnboardingBoundary({
    super.key,
    required this.userId,
    required this.repository,
    this.authController,
    this.catalog,
    this.requireUniversityWhenCatalogAbsent = false,
  });

  final String userId;
  final AcademicProfileRepository repository;
  final AuthController? authController;
  final AcademicCatalogSnapshot? catalog;
  final bool requireUniversityWhenCatalogAbsent;

  @override
  State<AcademicOnboardingBoundary> createState() =>
      _AcademicOnboardingBoundaryState();
}

class _AcademicOnboardingBoundaryState
    extends State<AcademicOnboardingBoundary> {
  late ProfileController _profileController;
  late OnboardingDraftController _draftController;
  late AcademicCatalogRepository _catalogRepository;
  bool _editingCompletedProfile = false;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController(widget.repository);
    _catalogRepository = AcademicCatalogRepository(widget.repository.api);
    _draftController = OnboardingDraftController(
      repository: widget.repository,
      ownerUserId: widget.userId,
      catalog: widget.catalog,
      requireUniversityWhenCatalogAbsent:
          widget.requireUniversityWhenCatalogAbsent,
    );
    _profileController.addListener(_onProfileStateChanged);
    _profileController.load();
  }

  @override
  void didUpdateWidget(covariant AcademicOnboardingBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _editingCompletedProfile = false;
      _draftController.resetForUser(widget.userId);
      _profileController.clear();
      _profileController.load();
    } else if (oldWidget.catalog != widget.catalog) {
      _draftController.updateCatalog(widget.catalog);
    }
  }

  void _onProfileStateChanged() {
    final loaded = _profileController.profile;
    if (loaded != null && loaded.userId == widget.userId) {
      _draftController.hydrateFromProfile(loaded);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSaved(AcademicProfile saved) {
    _profileController.profile = saved;
    _profileController.status = saved.input.isEmpty
        ? ProfileStatus.empty
        : ProfileStatus.success;
    _profileController.failure = null;
    if (AcademicOnboardingCompletion.isComplete(saved.input)) {
      _editingCompletedProfile = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _profileController.removeListener(_onProfileStateChanged);
    _profileController.dispose();
    _draftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _profileController.status;
    final persistedProfile =
        _draftController.savedProfile ?? _profileController.profile;

    if (status == ProfileStatus.idle || status == ProfileStatus.loading) {
      return RePageScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: ReTokens.spaceSm,
              runSpacing: ReTokens.spaceXs,
              children: [
                ReBrandMark(
                  variant: ReBrandMarkVariant.surface,
                  size: ReBrandMarkSize.sm,
                ),
                ReChip(label: 'MEMUAT PROFIL', variant: ReChipVariant.status),
              ],
            ),
            const SizedBox(height: ReTokens.spaceMd),
            const ReFormHeading(
              title: 'Memuat profil akademikmu',
              description: 'Mengambil data profil akademik dari server Re:kan dengan aman.',
            ),
            const LinearProgressIndicator(
              semanticsLabel: 'Memuat profil akademik',
              color: ReTokens.ink,
              backgroundColor: ReTokens.primaryYellow,
              minHeight: 8,
            ),
            if (widget.authController != null) ...[
              const SizedBox(height: ReTokens.spaceLg),
              ReSecondaryButton.destructive(
                label: 'Keluar',
                icon: Icons.logout,
                onPressed: widget.authController!.busy
                    ? null
                    : widget.authController!.logout,
              ),
            ],
          ],
        ),
      );
    }

    if (status == ProfileStatus.error && persistedProfile == null) {
      final failure = _profileController.failure;
      return RePageScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ReBrandMark(
              variant: ReBrandMarkVariant.surface,
              size: ReBrandMarkSize.sm,
            ),
            const SizedBox(height: ReTokens.spaceMd),
            const ReFormHeading(
              title: 'Profil akademik belum dapat dimuat',
              description:
                  'Periksa koneksi jaringanmu atau coba muat ulang profil.',
            ),
            ReStatusBanner(
              variant: ReStatusVariant.error,
              title: 'GALAT PROFIL',
              message: _localizedLoadError(failure),
            ),
            const SizedBox(height: ReTokens.spaceMd),
            RePrimaryButton(
              label: 'Muat ulang profil',
              onPressed: _profileController.load,
            ),
            if (widget.authController != null) ...[
              const SizedBox(height: ReTokens.spaceSm),
              ReSecondaryButton.destructive(
                label: 'Keluar',
                icon: Icons.logout,
                onPressed: widget.authController!.busy
                    ? null
                    : widget.authController!.logout,
              ),
            ],
          ],
        ),
      );
    }

    final isComplete =
        persistedProfile != null &&
        AcademicOnboardingCompletion.isComplete(persistedProfile.input);

    if (isComplete && !_editingCompletedProfile) {
      return _CompletedAcademicProfileView(
        profile: persistedProfile,
        catalog: _draftController.catalog,
        onEdit: () {
          _draftController.hydrateFromProfile(persistedProfile, force: true);
          _draftController.goToStep(1);
          setState(() => _editingCompletedProfile = true);
        },
        onLogout: widget.authController?.logout,
      );
    }

    return AcademicOnboardingPage(
      controller: _draftController,
      catalogRepository: widget.catalog == null ? _catalogRepository : null,
      onSaved: _handleSaved,
      onCancelEdit: isComplete
          ? () {
              _draftController.hydrateFromProfile(
                persistedProfile,
                force: true,
              );
              setState(() => _editingCompletedProfile = false);
            }
          : null,
      onLogout: widget.authController?.logout,
    );
  }

  String _localizedLoadError(ApiFailure? failure) {
    if (failure == null) {
      return 'Terjadi kendala saat mengambil profil akademik.';
    }
    return switch (failure.kind) {
      ApiFailureKind.authentication =>
        'Sesi berakhir. Silakan keluar dan masuk kembali.',
      ApiFailureKind.sessionChanged =>
        'Sesi akun berubah. Muat ulang profil akademikmu.',
      ApiFailureKind.forbidden => 'Akses ke profil akademik ditolak.',
      ApiFailureKind.network =>
        'Tidak dapat terhubung ke server. Periksa koneksi internetmu.',
      ApiFailureKind.unavailable =>
        'Layanan profil akademik sedang tidak tersedia. Coba lagi sebentar.',
      ApiFailureKind.rateLimited =>
        'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
      _ => 'Respons layanan profil tidak dikenali. Silakan coba lagi.',
    };
  }
}

class _CompletedAcademicProfileView extends StatelessWidget {
  const _CompletedAcademicProfileView({
    required this.profile,
    this.catalog,
    required this.onEdit,
    this.onLogout,
  });

  final AcademicProfile profile;
  final AcademicCatalogSnapshot? catalog;
  final VoidCallback onEdit;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final input = profile.input;
    final universityLabel =
        catalog?.findUniversity(input.universityId)?.name ??
        input.universityId ??
        '-';

    return RePageScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: ReTokens.spaceSm,
            runSpacing: ReTokens.spaceXs,
            children: [
              ReBrandMark(
                variant: ReBrandMarkVariant.surface,
                size: ReBrandMarkSize.sm,
              ),
              ReChip(
                label: 'PROFIL LENGKAP',
                variant: ReChipVariant.availability,
              ),
            ],
          ),
          const SizedBox(height: ReTokens.spaceSm),
          const ReFormHeading(
            title: 'Ruang akademikmu',
            description: 'Profil akademik dasar telah tersimpan dan siap digunakan di Re:kan.',
          ),
          Container(
            padding: const EdgeInsets.all(ReTokens.spaceMd),
            decoration: BoxDecoration(
              color: ReTokens.surface,
              borderRadius: BorderRadius.circular(ReTokens.radiusLarge),
              border: ReTokens.emphasizedBorder,
              boxShadow: ReTokens.shadowHard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  input.displayName ?? '-',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ReTokens.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$universityLabel · ${input.program ?? '-'} · Semester ${input.semester ?? '-'}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: ReTokens.mutedText),
                ),
                if (input.bio != null && input.bio!.isNotEmpty) ...[
                  const SizedBox(height: ReTokens.spaceSm),
                  Text(
                    input.bio!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: ReTokens.spaceCompact),
                Wrap(
                  spacing: ReTokens.spaceSm,
                  runSpacing: ReTokens.spaceXs,
                  children: [
                    ReChip(
                      label:
                          'Visibilitas: ${_visibilityLabel(input.visibility)}',
                      variant: ReChipVariant.neutral,
                    ),
                    if (input.mbtiBadge != null)
                      ReChip(
                        label: 'MBTI: ${input.mbtiBadge}',
                        variant: ReChipVariant.neutral,
                      ),
                    ReChip(
                      label: '${input.skills.length} Keahlian',
                      variant: ReChipVariant.skill,
                    ),
                    ReChip(
                      label: '${input.courses.length} Mata Kuliah',
                      variant: ReChipVariant.course,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ReTokens.spaceMd),
          RePrimaryButton(label: 'Perbarui Profil Akademik', onPressed: onEdit),
          if (onLogout != null) ...[
            const SizedBox(height: ReTokens.spaceSm),
            ReSecondaryButton.destructive(
              label: 'Keluar',
              icon: Icons.logout,
              onPressed: onLogout,
            ),
          ],
        ],
      ),
    );
  }
}

/// Screen 9 — 5-Step Academic Onboarding & Profile Editor (`FigCraft id: 760`).
///
/// Steps:
/// 1. Identitas Akademik (`display_name`, `bio`, `mbti_badge`)
/// 2. Universitas, Program Studi & Semester (`university_id`, `program`, `semester`)
/// 3. Keahlian dan Minat (`skills[{skill_id, level}]`)
/// 4. Mata Kuliah Aktif (`courses`)
/// 5. Preferensi Belajar & Review (`preferences`, `visibility`, full summary & save)
class AcademicOnboardingPage extends StatefulWidget {
  const AcademicOnboardingPage({
    super.key,
    required this.controller,
    this.catalogRepository,
    this.onSaved,
    this.onCancelEdit,
    this.onLogout,
  });

  final OnboardingDraftController controller;
  final AcademicCatalogRepository? catalogRepository;
  final ValueChanged<AcademicProfile>? onSaved;
  final VoidCallback? onCancelEdit;
  final VoidCallback? onLogout;

  @override
  State<AcademicOnboardingPage> createState() => _AcademicOnboardingPageState();
}

class _AcademicOnboardingPageState extends State<AcademicOnboardingPage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _mbtiController;
  late final TextEditingController _programController;
  late final TextEditingController _semesterController;
  late final TextEditingController _languageController;

  OnboardingDraftController get _draft => widget.controller;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: _draft.displayName);
    _bioController = TextEditingController(text: _draft.bio);
    _mbtiController = TextEditingController(text: _draft.mbtiBadge);
    _programController = TextEditingController(text: _draft.program);
    _semesterController = TextEditingController(text: _draft.semesterText);
    _languageController = TextEditingController(text: _draft.preferredLanguage);
    _draft.addListener(_syncControllersFromDraft);
  }

  @override
  void didUpdateWidget(covariant AcademicOnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncControllersFromDraft);
      widget.controller.addListener(_syncControllersFromDraft);
      _syncControllersFromDraft();
    }
  }

  void _syncControllersFromDraft() {
    if (_displayNameController.text != _draft.displayName) {
      _displayNameController.text = _draft.displayName;
    }
    if (_bioController.text != _draft.bio) {
      _bioController.text = _draft.bio;
    }
    if (_mbtiController.text != _draft.mbtiBadge) {
      _mbtiController.text = _draft.mbtiBadge;
    }
    if (_programController.text != _draft.program) {
      _programController.text = _draft.program;
    }
    if (_semesterController.text != _draft.semesterText) {
      _semesterController.text = _draft.semesterText;
    }
    if (_languageController.text != _draft.preferredLanguage) {
      _languageController.text = _draft.preferredLanguage;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _draft.removeListener(_syncControllersFromDraft);
    _displayNameController.dispose();
    _bioController.dispose();
    _mbtiController.dispose();
    _programController.dispose();
    _semesterController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final saved = await _draft.save();
    if (saved != null && mounted) {
      widget.onSaved?.call(saved);
    }
  }

  Future<void> _reloadRemoteProfile() async {
    if (_draft.saving) return;
    try {
      final fresh = await _draft.repository.get();
      if (!mounted) return;
      _draft.hydrateFromProfile(fresh, force: true);
    } catch (_) {
      // Keep user's current draft safe if reload fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _draft.currentStep;

    return PopScope(
      canPop: step == 1 && widget.onCancelEdit == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _draft.saving) return;
        if (step > 1) {
          _draft.previousStep();
        } else if (widget.onCancelEdit != null) {
          widget.onCancelEdit!();
        }
      },
      child: RePageScaffold(
        padding: const EdgeInsets.symmetric(
          horizontal: ReTokens.spaceLg,
          vertical: ReTokens.spaceCompact,
        ),
        bottomBar: _OnboardingBottomBar(
          currentStep: step,
          saving: _draft.saving,
          onPrevious: step > 1 ? _draft.previousStep : widget.onCancelEdit,
          previousLabel: step > 1 ? '<- Kembali' : 'Batal',
          onNext: step < OnboardingDraftController.totalSteps
              ? () {
                  FocusScope.of(context).unfocus();
                  _draft.nextStep();
                }
              : _handleSave,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OnboardingProgressHeader(
              currentStep: step,
              totalSteps: OnboardingDraftController.totalSteps,
              saving: _draft.saving,
              onBack: step > 1 ? _draft.previousStep : widget.onCancelEdit,
              onLogout: widget.onLogout,
            ),
            const SizedBox(height: ReTokens.spaceCompact),
            switch (step) {
              1 => _buildStep1Identity(context),
              2 => _buildStep2University(context),
              3 => _buildStep3Skills(context),
              4 => _buildStep4Courses(context),
              _ => _buildStep5PreferencesAndReview(context),
            },
            const SizedBox(height: ReTokens.spaceCompact),
            ReStatusBanner(
              variant: ReStatusVariant.info,
              title: 'DRAF FORMULIR TERSIMPAN OTOMATIS',
              message: step < 5
                  ? 'Data tetap aman saat berpindah langkah atau terjadi gangguan jaringan. Berikutnya: ${_stepTitle(step + 1)}.'
                  : 'Tinjau seluruh isianmu di atas. Profil hanya dikirim ke server saat kamu menekan Simpan Profil.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Identity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReFormHeading(
          title: 'Identitas Akademik',
          description: 'Perkenalkan nama tampilan dan fokus kolaborasi akademikmu di Re:kan.',
        ),
        _NeoStepCard(
          children: [
            ReTextField(
              key: const ValueKey('onboarding_display_name'),
              label: 'NAMA TAMPILAN AKADEMIK *',
              hintText: 'Contoh: Nabila Rahmawati',
              controller: _displayNameController,
              enabled: !_draft.saving,
              textInputAction: TextInputAction.next,
              errorText: _draft.displayNameError,
              onChanged: _draft.setDisplayName,
            ),
            const SizedBox(height: ReTokens.spaceCompact),
            ReTextField(
              key: const ValueKey('onboarding_bio'),
              label: 'RINGKASAN AKADEMIK & TUJUAN KOLABORASI (OPSIONAL)',
              hintText: 'Minat belajar, topik riset, atau target kompetisi yang ingin diikuti',
              controller: _bioController,
              enabled: !_draft.saving,
              maxLines: 3,
              minLines: 2,
              errorText: _draft.bioError,
              helperText: 'Maksimal 2000 karakter. Tidak wajib diisi.',
              onChanged: _draft.setBio,
            ),
            const SizedBox(height: ReTokens.spaceCompact),
            ReTextField(
              key: const ValueKey('onboarding_mbti'),
              label: 'BADGE MBTI (OPSIONAL — HANYA TAMPILAN)',
              hintText: 'Contoh: INTJ atau ENFP',
              controller: _mbtiController,
              enabled: !_draft.saving,
              autocorrect: false,
              enableSuggestions: false,
              errorText: _draft.mbtiBadgeError,
              helperText: 'Hanya ditampilkan sebagai badge profil; tidak memengaruhi rekomendasi kolaborasi.',
              onChanged: _draft.setMbtiBadge,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2University(BuildContext context) {
    final catalogUniversities = _draft.catalog?.universities;
    final selectedUniversity = _draft.catalog?.findUniversity(
      _draft.universityId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReFormHeading(
          title: 'Universitas, Program Studi & Semester',
          description: 'Pilih kampus, program studi, dan semester aktif agar rekomendasi rekan kolaborasi sesuai kurikulum akademikmu.',
        ),
        _NeoStepCard(
          children: [
            Text(
              'UNIVERSITAS / INSTITUSI KAMPUS *',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: ReTokens.ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (widget.catalogRepository != null)
              AcademicCatalogSelector(
                key: ValueKey('universities_${_draft.ownerUserId}'),
                kind: CatalogKind.universities,
                repository: widget.catalogRepository!,
                draft: _draft,
              )
            else if (catalogUniversities != null &&
                catalogUniversities.isNotEmpty) ...[
              Wrap(
                spacing: ReTokens.spaceSm,
                runSpacing: ReTokens.spaceXs,
                children: [
                  for (final uni in catalogUniversities)
                    ReChip(
                      key: ValueKey('university_option_${uni.id}'),
                      label: uni.name,
                      variant:
                          _draft.universityId?.toLowerCase() ==
                              uni.id.toLowerCase()
                          ? ReChipVariant.selected
                          : ReChipVariant.neutral,
                      selected:
                          _draft.universityId?.toLowerCase() ==
                          uni.id.toLowerCase(),
                      enabled: !_draft.saving,
                      onTap: () => _draft.setUniversityId(uni.id),
                    ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(ReTokens.spaceCompact),
                decoration: BoxDecoration(
                  color: ReTokens.mutedSurface,
                  borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
                  border: ReTokens.standardBorder,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, color: ReTokens.ink),
                    const SizedBox(width: ReTokens.spaceSm),
                    Expanded(
                      child: Text(
                        _draft.universityId != null
                            ? 'Universitas tersimpan (${selectedUniversity?.name ?? _draft.universityId})'
                            : 'Pilihan universitas belum tersedia (menunggu endpoint GET /api/v1/universities)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ReTokens.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ReTokens.spaceSm),
              const ReStatusBanner(
                variant: ReStatusVariant.warning,
                title: 'KATALOG KAMPUS BELUM TERSEDIA',
                message: 'Endpoint GET /api/v1/universities belum diaktifkan di server. Aplikasi tidak memalsukan ID universitas; isian program studi dan semester tetap dapat disimpan.',
              ),
            ],
            if (_draft.universityIdError != null) ...[
              const SizedBox(height: 6),
              Text(
                _draft.universityIdError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ReTokens.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (_draft.hasUniversityChangeCourseWarning) ...[
              const SizedBox(height: ReTokens.spaceSm),
              const ReStatusBanner(
                variant: ReStatusVariant.warning,
                title: 'PERUBAHAN UNIVERSITAS',
                message: 'Universitas diubah dari profil awal. Tinjau kembali mata kuliah aktif pada Langkah 4 agar sesuai dengan kampus baru.',
              ),
            ],
            const SizedBox(height: ReTokens.spaceCompact),
            ReTextField(
              key: const ValueKey('onboarding_program'),
              label: 'PROGRAM STUDI / JURUSAN *',
              hintText: 'Contoh: Ilmu Komputer / Sistem Informasi',
              controller: _programController,
              enabled: !_draft.saving,
              textInputAction: TextInputAction.next,
              errorText: _draft.programError,
              onChanged: _draft.setProgram,
            ),
            const SizedBox(height: ReTokens.spaceCompact),
            ReTextField(
              key: const ValueKey('onboarding_semester'),
              label: 'JENJANG & SEMESTER AKTIF (1–20) *',
              hintText: 'Contoh: 4',
              controller: _semesterController,
              enabled: !_draft.saving,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              errorText: _draft.semesterError,
              onChanged: _draft.setSemesterText,
            ),
            const SizedBox(height: ReTokens.spaceSm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final sem in const [1, 2, 3, 4, 5, 6, 7, 8])
                  ReChip(
                    key: ValueKey('semester_chip_$sem'),
                    label: 'Semester $sem',
                    variant: _draft.semester == sem
                        ? ReChipVariant.selected
                        : ReChipVariant.neutral,
                    selected: _draft.semester == sem,
                    enabled: !_draft.saving,
                    onTap: () => _draft.setSemester(sem),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Skills(BuildContext context) {
    final catalogSkills = _draft.catalog?.skills;
    final selectedSkills = _draft.skills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReFormHeading(
          title: 'Keahlian dan Minat',
          description: 'Pilih keahlian akademik beserta tingkat penguasaan (1–5). Langkah ini opsional dan tidak menghambat penyelesaian onboarding.',
        ),
        _NeoStepCard(
          children: [
            const ReSectionHeader(
              title: 'Keahlian Terpilih',
              subtitle: 'Atur level penguasaan 1 (Dasar) hingga 5 (Mahir) atau hapus keahlian.',
            ),
            const SizedBox(height: ReTokens.spaceSm),
            if (selectedSkills.isEmpty)
              Text(
                'Belum ada keahlian dipilih. Kamu dapat melanjutkan ke langkah berikutnya kapan saja.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: ReTokens.mutedText),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final selection in selectedSkills)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ReTokens.spaceSm),
                      child: Container(
                        padding: const EdgeInsets.all(ReTokens.spaceSm),
                        decoration: BoxDecoration(
                          color: ReTokens.paper,
                          borderRadius: BorderRadius.circular(
                            ReTokens.radiusSmall,
                          ),
                          border: ReTokens.standardBorder,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: ReTokens.spaceSm,
                              children: [
                                ReChip(
                                  label:
                                      _draft.catalog
                                          ?.findSkill(selection.skillId)
                                          ?.normalizedName ??
                                      'Keahlian (${selection.skillId})',
                                  variant: ReChipVariant.skill,
                                  skillLevel: selection.level,
                                ),
                                TextButton(
                                  onPressed: _draft.saving
                                      ? null
                                      : () => _draft.removeSkill(
                                          selection.skillId,
                                        ),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (var lvl = 1; lvl <= 5; lvl++)
                                  ReChip(
                                    key: ValueKey(
                                      'skill_level_${selection.skillId}_$lvl',
                                    ),
                                    label: 'Lv.$lvl',
                                    variant: selection.level == lvl
                                        ? ReChipVariant.selected
                                        : ReChipVariant.neutral,
                                    selected: selection.level == lvl,
                                    enabled: !_draft.saving,
                                    onTap: () => _draft.upsertSkill(
                                      selection.skillId,
                                      lvl,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: ReTokens.spaceCompact),
            if (widget.catalogRepository != null)
              AcademicCatalogSelector(
                key: ValueKey('skills_${_draft.ownerUserId}'),
                kind: CatalogKind.skills,
                repository: widget.catalogRepository!,
                draft: _draft,
              )
            else if (catalogSkills != null && catalogSkills.isNotEmpty) ...[
              const ReSectionHeader(
                title: 'Katalog Keahlian Akademik',
                subtitle: 'Ketuk keahlian untuk menambahkan ke profilmu.',
              ),
              const SizedBox(height: ReTokens.spaceSm),
              Wrap(
                spacing: ReTokens.spaceSm,
                runSpacing: ReTokens.spaceXs,
                children: [
                  for (final skill in catalogSkills)
                    ReChip(
                      key: ValueKey('catalog_skill_${skill.id}'),
                      label: skill.normalizedName,
                      variant:
                          selectedSkills.any(
                            (s) =>
                                s.skillId.toLowerCase() ==
                                skill.id.toLowerCase(),
                          )
                          ? ReChipVariant.selected
                          : ReChipVariant.skill,
                      selected: selectedSkills.any(
                        (s) =>
                            s.skillId.toLowerCase() == skill.id.toLowerCase(),
                      ),
                      enabled: !_draft.saving,
                      onTap: () {
                        final exists = selectedSkills.any(
                          (s) =>
                              s.skillId.toLowerCase() == skill.id.toLowerCase(),
                        );
                        if (exists) {
                          _draft.removeSkill(skill.id);
                        } else {
                          _draft.upsertSkill(skill.id, 3);
                        }
                      },
                    ),
                ],
              ),
            ] else ...[
              const ReStatusBanner(
                variant: ReStatusVariant.info,
                title: 'KATALOG KEAHLIAN BELUM TERSEDIA',
                message: 'Endpoint GET /api/v1/skills belum diaktifkan. Aplikasi tidak memalsukan UUID keahlian; keahlian yang sudah tersimpan tetap dipertahankan.',
              ),
            ],
            if (_draft.skillsError != null) ...[
              const SizedBox(height: 6),
              Text(
                _draft.skillsError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ReTokens.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStep4Courses(BuildContext context) {
    final catalogCourses = _draft.catalog?.courses;
    final compatibleCatalogCourses = catalogCourses
        ?.where((c) => c.isCompatibleWithUniversity(_draft.universityId))
        .toList();
    final selectedCourses = _draft.courses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReFormHeading(
          title: 'Mata Kuliah Aktif',
          description: 'Tambahkan mata kuliah yang sedang kamu ambil untuk menemukan partner belajar yang sekelas atau satu topik. Langkah ini opsional.',
        ),
        _NeoStepCard(
          children: [
            if (_draft.hasUniversityChangeCourseWarning) ...[
              const ReStatusBanner(
                variant: ReStatusVariant.warning,
                title: 'TINJAU MATA KULIAH KAMPUS',
                message: 'Kamu mengubah pilihan universitas. Hapus mata kuliah khusus kampus lama jika tidak lagi sesuai.',
              ),
              const SizedBox(height: ReTokens.spaceSm),
              const SizedBox(height: ReTokens.spaceCompact),
            ],
            const ReSectionHeader(
              title: 'Mata Kuliah Terpilih',
              subtitle: 'Daftar mata kuliah yang akan disimpan pada profilmu.',
            ),
            const SizedBox(height: ReTokens.spaceSm),
            if (selectedCourses.isEmpty)
              Text(
                'Belum ada mata kuliah dipilih. Kamu dapat melewati langkah ini.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: ReTokens.mutedText),
              )
            else
              Wrap(
                spacing: ReTokens.spaceSm,
                runSpacing: ReTokens.spaceXs,
                children: [
                  for (final courseId in selectedCourses)
                    ReChip(
                      key: ValueKey('selected_course_$courseId'),
                      label: _courseLabel(courseId),
                      variant: ReChipVariant.course,
                      enabled: !_draft.saving,
                      onDeleted: () => _draft.removeCourse(courseId),
                    ),
                ],
              ),
            const SizedBox(height: ReTokens.spaceCompact),
            if (widget.catalogRepository != null)
              AcademicCatalogSelector(
                key: ValueKey(
                  'courses_${_draft.ownerUserId}_${_draft.universityId}',
                ),
                kind: CatalogKind.courses,
                repository: widget.catalogRepository!,
                draft: _draft,
              )
            else if (compatibleCatalogCourses != null) ...[
              const ReSectionHeader(
                title: 'Katalog Mata Kuliah',
                subtitle: 'Menampilkan mata kuliah umum (global) dan mata kuliah kampus terpilih.',
              ),
              const SizedBox(height: ReTokens.spaceSm),
              if (compatibleCatalogCourses.isEmpty)
                Text(
                  'Belum ada mata kuliah katalog untuk universitas ini.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: ReTokens.mutedText),
                )
              else
                Wrap(
                  spacing: ReTokens.spaceSm,
                  runSpacing: ReTokens.spaceXs,
                  children: [
                    for (final course in compatibleCatalogCourses)
                      ReChip(
                        key: ValueKey('catalog_course_${course.id}'),
                        label: '${course.code} · ${course.name}',
                        coursePrefix: course.code,
                        variant:
                            selectedCourses.any(
                              (id) =>
                                  id.toLowerCase() == course.id.toLowerCase(),
                            )
                            ? ReChipVariant.selected
                            : ReChipVariant.course,
                        selected: selectedCourses.any(
                          (id) => id.toLowerCase() == course.id.toLowerCase(),
                        ),
                        enabled: !_draft.saving,
                        onTap: () => _draft.toggleCourse(course.id),
                      ),
                  ],
                ),
            ] else ...[
              const ReStatusBanner(
                variant: ReStatusVariant.info,
                title: 'KATALOG MATA KULIAH BELUM TERSEDIA',
                message: 'Endpoint GET /api/v1/courses belum diaktifkan. Aplikasi tidak memalsukan UUID mata kuliah; mata kuliah yang sudah tersimpan tetap dipertahankan.',
              ),
            ],
            if (_draft.coursesError != null) ...[
              const SizedBox(height: 6),
              Text(
                _draft.coursesError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ReTokens.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStep5PreferencesAndReview(BuildContext context) {
    final previewInput = _draft.toProfileInput();
    final missingFields = AcademicOnboardingCompletion.missingRequiredFields(
      previewInput,
    );
    final universityLabel =
        _draft.catalog?.findUniversity(previewInput.universityId)?.name ??
        previewInput.universityId ??
        'Belum dipilih (menunggu katalog)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReFormHeading(
          title: 'Preferensi Belajar & Review',
          description: 'Tentukan preferensi kolaborasi dan tinjau kembali seluruh data profil sebelum menyimpan.',
        ),
        _NeoStepCard(
          children: [
            const ReSectionHeader(
              title: 'Preferensi Belajar (Opsional)',
              subtitle: 'Pilih cara belajar dan bahasa pengantar diskusi.',
            ),
            const SizedBox(height: ReTokens.spaceSm),
            Wrap(
              spacing: ReTokens.spaceSm,
              runSpacing: ReTokens.spaceXs,
              children: [
                ReChip(
                  key: const ValueKey('study_mode_online'),
                  label: 'Daring (Online)',
                  variant: _draft.studyMode == StudyMode.online
                      ? ReChipVariant.selected
                      : ReChipVariant.neutral,
                  selected: _draft.studyMode == StudyMode.online,
                  enabled: !_draft.saving,
                  onTap: () => _draft.setStudyMode(
                    _draft.studyMode == StudyMode.online
                        ? null
                        : StudyMode.online,
                  ),
                ),
                ReChip(
                  key: const ValueKey('study_mode_in_person'),
                  label: 'Tatap Muka (Luring)',
                  variant: _draft.studyMode == StudyMode.inPerson
                      ? ReChipVariant.selected
                      : ReChipVariant.neutral,
                  selected: _draft.studyMode == StudyMode.inPerson,
                  enabled: !_draft.saving,
                  onTap: () => _draft.setStudyMode(
                    _draft.studyMode == StudyMode.inPerson
                        ? null
                        : StudyMode.inPerson,
                  ),
                ),
                ReChip(
                  key: const ValueKey('study_mode_hybrid'),
                  label: 'Campuran (Hybrid)',
                  variant: _draft.studyMode == StudyMode.hybrid
                      ? ReChipVariant.selected
                      : ReChipVariant.neutral,
                  selected: _draft.studyMode == StudyMode.hybrid,
                  enabled: !_draft.saving,
                  onTap: () => _draft.setStudyMode(
                    _draft.studyMode == StudyMode.hybrid
                        ? null
                        : StudyMode.hybrid,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ReTokens.spaceCompact),
            ReTextField(
              key: const ValueKey('onboarding_preferred_language'),
              label: 'BAHASA PENGANTAR BELAJAR (OPSIONAL)',
              hintText: 'Contoh: id atau en',
              controller: _languageController,
              enabled: !_draft.saving,
              autocorrect: false,
              errorText: _draft.preferredLanguageError,
              onChanged: _draft.setPreferredLanguage,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final lang in const [
                  ('id', 'Bahasa Indonesia (id)'),
                  ('en', 'Bahasa Inggris (en)'),
                  ('id-ID', 'Indonesia (id-ID)'),
                ])
                  ReChip(
                    key: ValueKey('lang_chip_${lang.$1}'),
                    label: lang.$2,
                    variant: _draft.preferredLanguage.trim() == lang.$1
                        ? ReChipVariant.selected
                        : ReChipVariant.neutral,
                    selected: _draft.preferredLanguage.trim() == lang.$1,
                    enabled: !_draft.saving,
                    onTap: () => _draft.setPreferredLanguage(lang.$1),
                  ),
              ],
            ),
            const SizedBox(height: ReTokens.spaceCompact),
            Text(
              'VISIBILITAS PROFIL AKADEMIK',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: ReTokens.ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: ReTokens.spaceSm,
              runSpacing: ReTokens.spaceXs,
              children: [
                for (final vis in ProfileVisibility.values)
                  ReChip(
                    key: ValueKey('visibility_${vis.name}'),
                    label: _visibilityLabel(vis),
                    variant: _draft.visibility == vis
                        ? ReChipVariant.selected
                        : ReChipVariant.neutral,
                    selected: _draft.visibility == vis,
                    enabled: !_draft.saving,
                    onTap: () => _draft.setVisibility(vis),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: ReTokens.spaceCompact),
        _NeoStepCard(
          children: [
            ReSectionHeader(
              title: 'Tinjau Profil Akademik',
              subtitle:
                  'Periksa kembali ringkasan data yang akan dikirim ke server.',
              badgeText: missingFields.isEmpty
                  ? 'SIAP LENGKAP'
                  : 'DRAF PARSIAL',
            ),
            const SizedBox(height: ReTokens.spaceSm),
            _ReviewRow(
              label: 'Nama Tampilan',
              value: previewInput.displayName ?? '-',
              onEdit: _draft.saving ? null : () => _draft.goToStep(1),
            ),
            _ReviewRow(
              label: 'Ringkasan / Bio',
              value: previewInput.bio ?? 'Tidak diisi (opsional)',
              onEdit: _draft.saving ? null : () => _draft.goToStep(1),
            ),
            _ReviewRow(
              label: 'Badge MBTI',
              value: previewInput.mbtiBadge ?? 'Tidak diisi (opsional)',
              onEdit: _draft.saving ? null : () => _draft.goToStep(1),
            ),
            _ReviewRow(
              label: 'Universitas',
              value: universityLabel,
              onEdit: _draft.saving ? null : () => _draft.goToStep(2),
            ),
            _ReviewRow(
              label: 'Program Studi',
              value: previewInput.program ?? '-',
              onEdit: _draft.saving ? null : () => _draft.goToStep(2),
            ),
            _ReviewRow(
              label: 'Semester Aktif',
              value: previewInput.semester != null
                  ? 'Semester ${previewInput.semester}'
                  : '-',
              onEdit: _draft.saving ? null : () => _draft.goToStep(2),
            ),
            _ReviewRow(
              label: 'Keahlian',
              value: '${previewInput.skills.length} keahlian dipilih',
              onEdit: _draft.saving ? null : () => _draft.goToStep(3),
            ),
            _ReviewRow(
              label: 'Mata Kuliah Aktif',
              value: '${previewInput.courses.length} mata kuliah dipilih',
              onEdit: _draft.saving ? null : () => _draft.goToStep(4),
            ),
            _ReviewRow(
              label: 'Mode & Bahasa Belajar',
              value:
                  '${_studyModeLabel(previewInput.preferences.studyMode)} · ${previewInput.preferences.preferredLanguage ?? ' Bahasa belum ditentukan'}',
            ),
            _ReviewRow(
              label: 'Visibilitas',
              value: _visibilityLabel(previewInput.visibility),
            ),
            if (missingFields.isNotEmpty) ...[
              const SizedBox(height: ReTokens.spaceSm),
              ReStatusBanner(
                variant: ReStatusVariant.warning,
                title: 'FIELD WAJIB BELUM LENGKAP',
                message:
                    'Untuk menyelesaikan onboarding sepenuhnya, lengkapi: ${missingFields.map(AcademicOnboardingCompletion.fieldLabel).join(', ')}.',
              ),
            ],
            if (_draft.saveFailureMessage != null) ...[
              const SizedBox(height: ReTokens.spaceSm),
              ReStatusBanner(
                variant: ReStatusVariant.error,
                title: 'GAGAL MENYIMPAN PROFIL',
                message: _draft.saveFailureMessage!,
              ),
              if (_draft.saveFailure?.kind == ApiFailureKind.conflict) ...[
                const SizedBox(height: ReTokens.spaceSm),
                ReSecondaryButton(
                  label: 'Muat Ulang Profil dari Server',
                  onPressed: _draft.saving ? null : _reloadRemoteProfile,
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }

  String _courseLabel(String courseId) {
    final found = _draft.catalog?.findCourse(courseId);
    if (found != null) {
      return '${found.code} · ${found.name}';
    }
    return 'Mata Kuliah ($courseId)';
  }

  static String _stepTitle(int step) => switch (step) {
    1 => 'Langkah 1 - Identitas Akademik',
    2 => 'Langkah 2 - Universitas & Program Studi',
    3 => 'Langkah 3 - Keahlian dan Minat',
    4 => 'Langkah 4 - Mata Kuliah Aktif',
    _ => 'Langkah 5 - Preferensi Belajar & Review',
  };
}

class _OnboardingProgressHeader extends StatelessWidget {
  const _OnboardingProgressHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.saving,
    this.onBack,
    this.onLogout,
  });

  final int currentStep;
  final int totalSteps;
  final bool saving;
  final VoidCallback? onBack;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wrap (not Row) so 200% text on 320 dp never overflows horizontally.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: ReTokens.spaceSm,
          runSpacing: ReTokens.spaceXs,
          children: [
            if (onBack != null)
              Container(
                decoration: BoxDecoration(
                  color: ReTokens.surface,
                  borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
                  border: ReTokens.standardBorder,
                  boxShadow: ReTokens.shadowSubtle,
                ),
                child: IconButton(
                  tooltip: 'Langkah sebelumnya',
                  constraints: const BoxConstraints(
                    minWidth: ReTokens.controlHeight,
                    minHeight: ReTokens.controlHeight,
                  ),
                  onPressed: saving ? null : onBack,
                  icon: const Icon(Icons.arrow_back, color: ReTokens.ink),
                ),
              )
            else
              const ReBrandMark(
                variant: ReBrandMarkVariant.surface,
                size: ReBrandMarkSize.sm,
              ),
            Semantics(
              label: 'Langkah $currentStep dari $totalSteps',
              excludeSemantics: true,
              child: Text(
                'LANGKAH $currentStep DARI $totalSteps',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ReTokens.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const ReChip(label: 'DRAF AMAN', variant: ReChipVariant.status),
            if (onLogout != null)
              IconButton(
                tooltip: 'Keluar',
                constraints: const BoxConstraints(
                  minWidth: ReTokens.controlHeight,
                  minHeight: ReTokens.controlHeight,
                ),
                onPressed: saving ? null : onLogout,
                icon: const Icon(Icons.logout, color: ReTokens.ink),
              ),
          ],
        ),
        const SizedBox(height: ReTokens.spaceSm),
        Row(
          children: [
            for (var i = 1; i <= totalSteps; i++) ...[
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: i < currentStep
                        ? ReTokens.accentTeal
                        : i == currentStep
                        ? ReTokens.primaryYellow
                        : ReTokens.surface,
                    borderRadius: BorderRadius.circular(ReTokens.radiusFull),
                    border: ReTokens.standardBorder,
                  ),
                ),
              ),
              if (i < totalSteps) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _OnboardingBottomBar extends StatelessWidget {
  const _OnboardingBottomBar({
    required this.currentStep,
    required this.saving,
    this.onPrevious,
    required this.previousLabel,
    required this.onNext,
  });

  final int currentStep;
  final bool saving;
  final VoidCallback? onPrevious;
  final String previousLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isFinalStep = currentStep == OnboardingDraftController.totalSteps;
    final nextLabel = isFinalStep
        ? 'Simpan Profil'
        : 'Lanjutkan (${currentStep + 1}/${OnboardingDraftController.totalSteps}) ->';

    return Row(
      children: [
        if (onPrevious != null) ...[
          Expanded(
            flex: 2,
            child: ReSecondaryButton(
              label: previousLabel,
              onPressed: saving ? null : onPrevious,
            ),
          ),
          const SizedBox(width: ReTokens.spaceSm),
        ],
        Expanded(
          flex: 3,
          child: RePrimaryButton(
            label: nextLabel,
            busy: isFinalStep && saving,
            busyLabel: 'Menyimpan profil…',
            onPressed: saving ? null : onNext,
          ),
        ),
      ],
    );
  }
}

class _NeoStepCard extends StatelessWidget {
  const _NeoStepCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ReTokens.spaceCompact),
      decoration: BoxDecoration(
        color: ReTokens.surface,
        borderRadius: BorderRadius.circular(ReTokens.radiusLarge),
        border: ReTokens.emphasizedBorder,
        boxShadow: ReTokens.shadowHard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value, this.onEdit});

  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ReTokens.spaceSm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: ReTokens.paper,
          borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
          border: ReTokens.standardBorder,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: ReTokens.spaceSm,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ReTokens.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ReTokens.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (onEdit != null)
              TextButton(
                onPressed: onEdit,
                child: const Text(
                  'Ubah',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _visibilityLabel(ProfileVisibility visibility) => switch (visibility) {
  ProfileVisibility.private => 'Privat',
  ProfileVisibility.university => 'Kampus',
  ProfileVisibility.public => 'Publik',
};

String _studyModeLabel(StudyMode? mode) => switch (mode) {
  StudyMode.online => 'Daring (Online)',
  StudyMode.inPerson => 'Tatap Muka (Luring)',
  StudyMode.hybrid => 'Campuran (Hybrid)',
  null => 'Mode belum ditentukan',
};

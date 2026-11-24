import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/re_form_components.dart';
import '../data/academic_catalog_repository.dart';
import '../domain/academic_onboarding_completion.dart';
import 'onboarding_draft_controller.dart';

enum CatalogKind { universities, skills, courses }

/// Search results are separate from the label cache, so filtering never removes
/// selected IDs or their known labels from the draft.
class AcademicCatalogSelector extends StatefulWidget {
  const AcademicCatalogSelector({
    super.key,
    required this.kind,
    required this.repository,
    required this.draft,
  });
  final CatalogKind kind;
  final AcademicCatalogRepository repository;
  final OnboardingDraftController draft;

  @override
  State<AcademicCatalogSelector> createState() =>
      _AcademicCatalogSelectorState();
}

class _AcademicCatalogSelectorState extends State<AcademicCatalogSelector> {
  final _search = TextEditingController();
  int _generation = 0;
  bool _loading = true;
  bool _changingUniversity = false;
  DialogRoute<bool>? _confirmationRoute;
  NavigatorState? _confirmationNavigator;
  String? _error;
  List<UniversityCatalogItem> _universities = [];
  List<SkillCatalogItem> _skills = [];
  List<CourseCatalogItem> _courses = [];

  String get _label => switch (widget.kind) {
    CatalogKind.universities => 'universitas',
    CatalogKind.skills => 'keahlian',
    CatalogKind.courses => 'mata kuliah',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generation++;
    final route = _confirmationRoute;
    final navigator = _confirmationNavigator;
    if (route != null && navigator != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted && route.isActive) navigator.removeRoute(route);
      });
    }
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final draft = widget.draft;
    final owner = draft.ownerUserId;
    final session = widget.repository.api.sessions.current;
    bool current() =>
        mounted &&
        generation == _generation &&
        draft.ownerUserId == owner &&
        widget.repository.api.sessions.current?.userId == session?.userId &&
        widget.repository.api.sessions.current?.generation ==
            session?.generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = widget.repository;
      final q = _search.text;
      var universities = <UniversityCatalogItem>[];
      var skills = <SkillCatalogItem>[];
      var courses = <CourseCatalogItem>[];
      var selectedUniversities = <UniversityCatalogItem>[];
      var selectedSkills = <SkillCatalogItem>[];
      var selectedCourses = <CourseCatalogItem>[];
      switch (widget.kind) {
        case CatalogKind.universities:
          universities = await repo.universities(q: q);
          selectedUniversities = await repo.universities(
            ids: [if (draft.universityId != null) draft.universityId!],
          );
        case CatalogKind.skills:
          skills = await repo.skills(q: q);
          selectedSkills = await repo.skills(
            ids: draft.skills.map((s) => s.skillId).toList(),
          );
        case CatalogKind.courses:
          courses = await repo.courses(q: q, universityId: draft.universityId);
          // Unscoped lookup is intentional: retain labels and review old selections.
          selectedCourses = await repo.courses(ids: draft.courses);
      }
      if (!current()) return;
      final old = draft.catalog;
      draft.updateCatalog(
        AcademicCatalogSnapshot(
          universities: {
            for (final item in [
              ...?old?.universities,
              ...universities,
              ...selectedUniversities,
            ])
              item.id: item,
          }.values.toList(),
          skills: {
            for (final item in [...?old?.skills, ...skills, ...selectedSkills])
              item.id: item,
          }.values.toList(),
          courses: {
            for (final item in [
              ...?old?.courses,
              ...courses,
              ...selectedCourses,
            ])
              item.id: item,
          }.values.toList(),
        ),
      );
      setState(() {
        _universities = universities;
        _skills = skills;
        _courses = courses
            .where((c) => c.isCompatibleWithUniversity(draft.universityId))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!current()) return;
      setState(() {
        _loading = false;
        _error = 'Katalog belum dapat dimuat. Periksa koneksi atau sesi akun, lalu coba lagi. Pilihan dan draf tetap disimpan.';
      });
    }
  }

  Future<void> _selectUniversity(UniversityCatalogItem university) async {
    final draft = widget.draft;
    if (draft.saving ||
        _changingUniversity ||
        draft.universityId == university.id) {
      return;
    }
    final owner = draft.ownerUserId;
    final session = widget.repository.api.sessions.current;
    bool current() =>
        mounted &&
        draft.ownerUserId == owner &&
        !draft.saving &&
        widget.repository.api.sessions.current?.userId == session?.userId &&
        widget.repository.api.sessions.current?.generation ==
            session?.generation;
    setState(() {
      _changingUniversity = true;
      _error = null;
    });
    try {
      final courses = await widget.repository.courses(ids: draft.courses);
      if (!current()) return;
      if (draft.courses.any(
        (id) => !courses.any((c) => c.id == id.toLowerCase()),
      )) {
        throw const FormatException('Unresolved selection');
      }
      final incompatible = courses
          .where((c) => !c.isCompatibleWithUniversity(university.id))
          .toList();
      if (incompatible.isNotEmpty) {
        if (!mounted) return;
        final route = DialogRoute<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tinjau mata kuliah'),
            content: SingleChildScrollView(
              child: Text(
                'Hapus mata kuliah yang tidak sesuai kampus baru? Mata kuliah global tetap dipertahankan.\n\n${incompatible.map((c) => c.name).join('\n')}',
              ),
            ),
            actions: [
              ReSecondaryButton(
                label: 'Batal',
                onPressed: () => Navigator.pop(context, false),
              ),
              RePrimaryButton(
                label: 'Ganti kampus dan hapus',
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
        _confirmationRoute = route;
        _confirmationNavigator = Navigator.of(context);
        final confirmed = await _confirmationNavigator!.push(route);
        _confirmationRoute = null;
        _confirmationNavigator = null;
        if (!current() || confirmed != true) return;
      }
      draft.setUniversityId(university.id);
      for (final course in incompatible) {
        draft.removeCourse(course.id);
      }
    } catch (_) {
      if (current()) {
        setState(
          () => _error = 'Mata kuliah tersimpan belum dapat diperiksa. Kampus dan pilihan lama dipertahankan. Coba pilih kampus lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _changingUniversity = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final busy = draft.saving || _changingUniversity;
    final empty = switch (widget.kind) {
      CatalogKind.universities => _universities.isEmpty,
      CatalogKind.skills => _skills.isEmpty,
      CatalogKind.courses => _courses.isEmpty,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReTextField(
          key: ValueKey('search_${widget.kind.name}'),
          label: 'Cari $_label',
          controller: _search,
          maxLength: 100,
          enabled: !busy,
          onFieldSubmitted: (_) {
            if (!busy && !_loading) _load();
          },
        ),
        const SizedBox(height: 8),
        ReSecondaryButton(
          label: 'Cari $_label',
          onPressed: busy || _loading ? null : _load,
        ),
        if (widget.kind == CatalogKind.universities &&
            draft.universityId != null)
          Text(
            'Terpilih: ${draft.catalog?.findUniversity(draft.universityId)?.name ?? draft.universityId}',
          ),
        if (_loading || _changingUniversity)
          const LinearProgressIndicator(semanticsLabel: 'Memuat katalog'),
        if (_error != null) ...[
          ReStatusBanner(
            variant: ReStatusVariant.error,
            title: 'KATALOG BELUM TERSEDIA',
            message: _error!,
          ),
          ReSecondaryButton(
            label: 'Coba lagi',
            onPressed: busy || _loading ? null : _load,
          ),
        ],
        if (!_loading && _error == null) ...[
          if (empty)
            Text(
              'Tidak ada $_label yang cocok. Ubah pencarian atau coba lagi.',
            ),
          const Text(
            'Maksimal 50 hasil. Gunakan pencarian untuk mempersempit pilihan.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final university in _universities)
                ReChip(
                  key: ValueKey('university_option_${university.id}'),
                  label: university.name,
                  selected: draft.universityId == university.id,
                  enabled: !busy,
                  onTap: () => _selectUniversity(university),
                ),
              for (final skill in _skills)
                ReChip(
                  key: ValueKey('catalog_skill_${skill.id}'),
                  label: skill.normalizedName,
                  selected: draft.skills.any((s) => s.skillId == skill.id),
                  enabled: !busy,
                  onTap: () {
                    if (draft.skills.any((s) => s.skillId == skill.id)) {
                      draft.removeSkill(skill.id);
                    } else {
                      draft.upsertSkill(skill.id, 3);
                    }
                  },
                ),
              for (final course in _courses)
                ReChip(
                  key: ValueKey('catalog_course_${course.id}'),
                  label: '${course.code} · ${course.name}',
                  selected: draft.courses.contains(course.id),
                  enabled: !busy,
                  onTap: () => draft.toggleCourse(course.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

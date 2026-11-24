import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_mobile/core/theme/app_theme.dart';
import 'package:re_mobile/core/theme/re_tokens.dart';
import 'package:re_mobile/core/widgets/re_form_components.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return first > second
      ? (first + .05) / (second + .05)
      : (second + .05) / (first + .05);
}

void main() {
  test('text palette meets AA normal-text contrast', () {
    for (final background in [ReTokens.paper, ReTokens.surface]) {
      for (final foreground in [ReTokens.ink, ReTokens.muted, ReTokens.error]) {
        expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(ReTokens.outline, background), greaterThanOrEqualTo(3));
    }
    expect(
      contrast(ReTokens.surface, ReTokens.forest),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets(
    'busy action disables submission and announces Indonesian state',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var taps = 0;
        Future<void> show(bool busy) => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.onboarding,
            home: ReFormPage(
              children: [
                RePrimaryAction(
                  label: 'Lanjutkan',
                  busy: busy,
                  onPressed: () => taps++,
                ),
              ],
            ),
          ),
        );
        await show(false);
        expect(
          tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(48),
        );
        await tester.tap(find.text('Lanjutkan'));
        expect(taps, 1);
        await show(true);
        await tester.tap(find.text('Memproses…'));
        expect(taps, 1);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        expect(find.bySemanticsLabel('Memproses…'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'narrow screen supports large text, keyboard inset and scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 200),
            ),
            child: child!,
          ),
          home: ReFormPage(
            children: [
              const ReFormHeading(
                title: 'Bangun koneksi akademik',
                description: 'Lengkapi informasi belajarmu secara bertahap.',
              ),
              const ReStatusNotice(
                message: 'Koneksi terputus. Isianmu tetap tersedia. Coba lagi.',
                isError: true,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nama panggilan'),
              ),
              const SizedBox(height: 24),
              RePrimaryAction(label: 'Simpan dan lanjutkan', onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Simpan dan lanjutkan'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Simpan dan lanjutkan'), findsOneWidget);
    },
  );

  testWidgets('wide screens constrain form content', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.onboarding,
        home: const ReFormPage(children: [Text('Profil akademik')]),
      ),
    );
    expect(tester.getSize(find.byType(ListView)).width, ReTokens.contentWidth);
    expect(tester.takeException(), isNull);
  });

  test('canonical FigCraft tokens and Neo-Brutalist contrast rules hold', () {
    expect(ReTokens.ink, const Color(0xFF111111));
    expect(ReTokens.paper, const Color(0xFFFFFDF5));
    expect(ReTokens.surface, const Color(0xFFFFFFFF));
    expect(ReTokens.mutedSurface, const Color(0xFFF2F0E8));
    expect(ReTokens.mutedText, const Color(0xFF626262));
    expect(ReTokens.primaryYellow, const Color(0xFFFFE500));
    expect(ReTokens.accentPrimary, ReTokens.primaryYellow);
    expect(ReTokens.accentTeal, const Color(0xFF16C7C1));
    expect(ReTokens.accentMagenta, const Color(0xFFF22DBB));
    expect(ReTokens.success, const Color(0xFF1FA86A));
    expect(ReTokens.warning, const Color(0xFFF2A900));
    expect(ReTokens.danger, const Color(0xFFE5484D));
    expect(ReTokens.error, isNot(equals(ReTokens.danger)));

    // Ink text on all accent and neutral fills meets WCAG AA (>= 4.5:1).
    for (final fill in [
      ReTokens.paper,
      ReTokens.surface,
      ReTokens.mutedSurface,
      ReTokens.primaryYellow,
      ReTokens.accentTeal,
      ReTokens.accentMagenta,
      ReTokens.warning,
    ]) {
      expect(contrast(ReTokens.ink, fill), greaterThanOrEqualTo(4.5));
    }

    // Spacing, border, radius, and hard-shadow tokens match FigCraft exports.
    expect(
      [
        ReTokens.space4,
        ReTokens.space8,
        ReTokens.space12,
        ReTokens.space16,
        ReTokens.space24,
        ReTokens.space32,
        ReTokens.space48,
      ],
      [4.0, 8.0, 12.0, 16.0, 24.0, 32.0, 48.0],
    );
    expect(ReTokens.borderStandard, 2.0);
    expect(ReTokens.borderEmphasized, 3.0);
    expect(ReTokens.radiusSmall, 6.0);
    expect(ReTokens.radiusMedium, 10.0);
    expect(ReTokens.radiusLarge, 16.0);
    expect(ReTokens.radiusFull, 999.0);
    expect(ReTokens.minTouchTarget, 44.0);
    expect(ReTokens.controlHeight, 48.0);
    for (final shadow in [
      ...ReTokens.shadowSubtle,
      ...ReTokens.shadowHard,
      ...ReTokens.shadowHero,
    ]) {
      expect(shadow.blurRadius, 0.0);
    }
  });

  testWidgets('ReBrandMark always renders full Re:kan identity', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          home: const RePageScaffold(
            children: [
              ReBrandMark(),
              ReBrandMark(
                variant: ReBrandMarkVariant.inverted,
                size: ReBrandMarkSize.lg,
                subtitle: 'Kolaborasi Akademik',
              ),
              ReBrandMark(variant: ReBrandMarkVariant.wordmark),
            ],
          ),
        ),
      );
      expect(find.text('Re:kan'), findsNWidgets(3));
      expect(find.text('Re'), findsNothing);
      expect(
        find.bySemanticsLabel('Re:kan — Kolaborasi Akademik'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'ReSecondaryButton supports surface, destructive, busy and disabled states',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          home: RePageScaffold(
            children: [
              ReSecondaryButton(
                label: 'Simpan Dulu',
                icon: Icons.bookmark_border,
                onPressed: () => taps++,
              ),
              const ReSecondaryButton.destructive(
                label: 'Batalkan Ajakan',
                onPressed: null,
              ),
              ReSecondaryButton(
                label: 'Sinkronisasi',
                busy: true,
                busyLabel: 'Menyimpan…',
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(OutlinedButton).first).height,
        greaterThanOrEqualTo(ReTokens.controlHeight),
      );
      await tester.tap(find.text('Simpan Dulu'));
      expect(taps, 1);

      await tester.tap(find.text('Batalkan Ajakan'));
      await tester.tap(find.text('Menyimpan…'));
      expect(taps, 1);
    },
  );

  testWidgets(
    'ReTextField renders visible label, validation errors and password toggle',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          home: RePageScaffold(
            children: [
              Form(
                key: formKey,
                child: Column(
                  children: [
                    ReTextField(
                      label: 'Email Kampus',
                      hintText: 'nama@kampus.ac.id',
                      helperText: 'Gunakan email aktif.',
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Masukkan email kampus yang valid.'
                          : null,
                    ),
                    const SizedBox(height: ReTokens.spaceMd),
                    const ReTextField(
                      label: 'Kata Sandi',
                      obscureText: true,
                      enablePasswordToggle: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Email Kampus'), findsWidgets);
      expect(find.text('Gunakan email aktif.'), findsOneWidget);

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Masukkan email kampus yang valid.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'mahasiswa@itb.ac.id',
      );
      expect(formKey.currentState!.validate(), isTrue);

      // Password visibility toggle has >= 48x48 touch target and flips obscureText.
      final toggleFinder = find.byTooltip('Tampilkan kata sandi');
      expect(
        tester.getSize(toggleFinder).width,
        greaterThanOrEqualTo(ReTokens.controlHeight),
      );
      expect(
        tester.getSize(toggleFinder).height,
        greaterThanOrEqualTo(ReTokens.controlHeight),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue,
      );
      await tester.tap(toggleFinder);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse,
      );
      expect(find.byTooltip('Sembunyikan kata sandi'), findsOneWidget);
    },
  );

  testWidgets(
    'ReChip, ReSectionHeader, ReStatusBanner and ReEmptyState meet touch target and semantic rules',
    (tester) async {
      var chipTaps = 0;
      var retryTaps = 0;
      var emptyTaps = 0;
      var headerActionTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          home: RePageScaffold(
            children: [
              ReSectionHeader(
                title: 'Keahlian & Mata Kuliah',
                badgeText: '3 dipilih',
                actionLabel: 'Ubah',
                onActionPressed: () => headerActionTaps++,
              ),
              const SizedBox(height: ReTokens.spaceSm),
              Wrap(
                spacing: ReTokens.spaceSm,
                runSpacing: ReTokens.spaceSm,
                children: [
                  ReChip(
                    label: 'Python',
                    variant: ReChipVariant.skill,
                    skillLevel: 4,
                    onTap: () => chipTaps++,
                  ),
                  const ReChip(
                    label: 'IF2211 Strategi Algoritma',
                    variant: ReChipVariant.course,
                  ),
                  const ReChip(
                    label: 'Siap Diskusi',
                    variant: ReChipVariant.availability,
                  ),
                  const ReChip(
                    label: 'Hackathon',
                    variant: ReChipVariant.selected,
                  ),
                ],
              ),
              const SizedBox(height: ReTokens.spaceMd),
              ReStatusBanner(
                message: 'Gagal memuat rekomendasi kolaborasi.',
                variant: ReStatusVariant.error,
                actionLabel: 'Coba lagi',
                onActionPressed: () => retryTaps++,
              ),
              const SizedBox(height: ReTokens.spaceMd),
              ReEmptyState(
                badgeText: 'KOSONG',
                title: 'Belum ada kandidat yang cocok',
                description: 'Longgarkan filter mata kuliah untuk melihat rekan lainnya.',
                actionLabel: 'Atur Ulang Filter',
                onActionPressed: () => emptyTaps++,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Lv.4'), findsOneWidget);
      expect(find.text('MK'), findsOneWidget);
      expect(find.text('GALAT'), findsOneWidget);
      expect(find.text('KOSONG'), findsOneWidget);

      // Interactive chip and section action meet minimum 44x44 touch target.
      final pythonChip = find.ancestor(
        of: find.text('Python'),
        matching: find.byType(InkWell),
      );
      expect(
        tester.getSize(pythonChip).height,
        greaterThanOrEqualTo(ReTokens.minTouchTarget),
      );
      await tester.tap(pythonChip);
      expect(chipTaps, 1);

      await tester.tap(find.text('Ubah'));
      expect(headerActionTaps, 1);

      await tester.tap(find.text('Coba lagi'));
      expect(retryTaps, 1);

      await tester.ensureVisible(find.text('Atur Ulang Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atur Ulang Filter'));
      expect(emptyTaps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all shared Neo-Brutalist components scale to 2.0x text on 320px screen without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: RePageScaffold(
            bottomBar: RePrimaryButton(
              label: 'Ajukan Kolaborasi',
              onPressed: () {},
            ),
            children: [
              const ReBrandMark(subtitle: 'Kolaborasi Akademik Mahasiswa'),
              const SizedBox(height: ReTokens.spaceMd),
              const ReFormHeading(
                eyebrow: 'ITERASI 1',
                title: 'Komponen Neo-Brutalist Re:kan',
                description: 'Seluruh komponen diuji dengan ukuran teks dua kali lipat pada layar sempit.',
              ),
              ReSectionHeader(
                title: 'Preferensi Belajar & Keahlian',
                subtitle: 'Pilih topik riset atau mata kuliah aktif',
                badgeText: 'Aktif',
                actionLabel: 'Filter',
                onActionPressed: () {},
              ),
              const SizedBox(height: ReTokens.spaceSm),
              const Wrap(
                spacing: ReTokens.spaceSm,
                runSpacing: ReTokens.spaceSm,
                children: [
                  ReChip(
                    label: 'Pembelajaran Mesin',
                    variant: ReChipVariant.skill,
                    skillLevel: 5,
                  ),
                  ReChip(
                    label: 'Sistem Terdistribusi',
                    variant: ReChipVariant.course,
                  ),
                ],
              ),
              const SizedBox(height: ReTokens.spaceMd),
              const ReTextField(
                label: 'Tujuan Kolaborasi',
                hintText: 'Contoh: Mencari rekan tugas akhir',
                helperText: 'Tuliskan tujuan akademik secara singkat.',
              ),
              const SizedBox(height: ReTokens.spaceMd),
              const ReStatusBanner(
                message: 'Perubahan tersimpan secara lokal.',
                variant: ReStatusVariant.success,
              ),
              const SizedBox(height: ReTokens.spaceMd),
              ReEmptyState(
                badgeText: 'INFO',
                title: 'Belum ada riwayat kolaborasi',
                description: 'Mulai jelajahi profil mahasiswa dari berbagai program studi.',
                actionLabel: 'Muat Ulang',
                secondaryAction: true,
                onActionPressed: () {},
              ),
            ],
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Muat Ulang'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

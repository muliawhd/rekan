import 'package:material_ui/material_ui.dart';

import '../../core/theme/re_tokens.dart';
import '../../core/widgets/re_form_components.dart';
import '../academic_profile/data/academic_profile_repository.dart';
import '../academic_profile/domain/academic_onboarding_completion.dart';
import '../academic_profile/presentation/academic_onboarding_page.dart';
import 'auth_controller.dart';
import 'auth_form.dart';
import 'auth_gateway.dart';

class AuthBoundary extends StatefulWidget {
  const AuthBoundary({
    super.key,
    this.gateway,
    this.profileRepository,
    this.catalog,
  });
  final AuthGateway? gateway;
  final AcademicProfileRepository? profileRepository;
  final AcademicCatalogSnapshot? catalog;
  @override
  State<AuthBoundary> createState() => _AuthBoundaryState();
}

class _AuthBoundaryState extends State<AuthBoundary>
    with WidgetsBindingObserver {
  AuthController? _controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.gateway != null) _controller = AuthController(widget.gateway!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.resumed &&
        controller != null &&
        !controller.busy &&
        controller.gateway.userId != null &&
        controller.screen != AuthScreen.recovery) {
      controller.restore();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const WelcomePage();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final screen = controller.screen;
        // A single replaced page prevents back navigation into prior accounts.
        return PopScope(
          canPop:
              screen == AuthScreen.welcome ||
              screen == AuthScreen.authenticated,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !controller.busy) controller.go(AuthScreen.welcome);
          },
          child: switch (screen) {
            AuthScreen.welcome => WelcomePage(controller: controller),
            AuthScreen.login || AuthScreen.register => AuthForm(
              key: ValueKey('${screen.name}:${controller.revision}'),
              controller: controller,
              registration: screen == AuthScreen.register,
            ),
            AuthScreen.checking => const RePageScaffold(
              children: [
                ReBrandMark(variant: ReBrandMarkVariant.surface),
                SizedBox(height: ReTokens.spaceLg),
                ReFormHeading(
                  eyebrow: 'MEMERIKSA SESI',
                  title: 'Menyiapkan ruangmu',
                  description: 'Memeriksa sesi dengan aman.',
                ),
                LinearProgressIndicator(
                  semanticsLabel: 'Memeriksa sesi',
                  color: ReTokens.ink,
                  backgroundColor: ReTokens.primaryYellow,
                  minHeight: 8,
                ),
              ],
            ),
            AuthScreen.authenticated =>
              widget.profileRepository != null &&
                      controller.gateway.userId != null
                  ? AcademicOnboardingBoundary(
                      key: ValueKey(controller.gateway.userId),
                      userId: controller.gateway.userId!,
                      repository: widget.profileRepository!,
                      authController: controller,
                      catalog: widget.catalog,
                    )
                  : RePageScaffold(
                      key: ValueKey(controller.gateway.userId),
                      children: [
                        const Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: ReTokens.spaceSm,
                          runSpacing: ReTokens.spaceSm,
                          children: [
                            ReBrandMark(variant: ReBrandMarkVariant.surface),
                            ReChip(
                              label: 'SESI AKTIF',
                              variant: ReChipVariant.availability,
                            ),
                          ],
                        ),
                        const SizedBox(height: ReTokens.spaceLg),
                        const ReFormHeading(
                          eyebrow: 'TERVERIFIKASI',
                          title: 'Ruang akademikmu',
                          description: 'Kamu sudah masuk ke Re:kan. Fitur profil akademik sedang disiapkan.',
                        ),
                        const ReStatusBanner(
                          variant: ReStatusVariant.success,
                          title: 'SIAP',
                          message: 'Belum ada tindakan yang perlu kamu lakukan di sini.',
                        ),
                        const SizedBox(height: ReTokens.spaceLg),
                        ReSecondaryButton.destructive(
                          label: 'Keluar',
                          icon: Icons.logout,
                          onPressed: controller.busy ? null : controller.logout,
                        ),
                      ],
                    ),
            AuthScreen.verification => RePageScaffold(
              padding: const EdgeInsets.symmetric(
                horizontal: ReTokens.spaceLg,
                vertical: ReTokens.spaceSm,
              ),
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
                      label: 'VERIFIKASI EMAIL',
                      variant: ReChipVariant.status,
                    ),
                  ],
                ),
                const SizedBox(height: ReTokens.spaceSm),
                const ReFormHeading(
                  title: 'Periksa emailmu',
                  description: 'Jika pendaftaran diterima, ikuti petunjuk konfirmasi di email. Periksa juga folder spam.',
                ),
                Container(
                  padding: const EdgeInsets.all(ReTokens.spaceCompact),
                  decoration: BoxDecoration(
                    color: ReTokens.surface,
                    borderRadius: BorderRadius.circular(ReTokens.radiusLarge),
                    border: ReTokens.emphasizedBorder,
                    boxShadow: ReTokens.shadowHard,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReSectionHeader(
                        title: 'Langkah Konfirmasi Akun',
                        subtitle: '1. Buka kotak masuk atau folder spam emailmu.\n2. Klik tautan konfirmasi pendaftaran.\n3. Kembali ke Re:kan lalu masuk.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ReTokens.spaceSm),
                const ReStatusBanner(
                  variant: ReStatusVariant.info,
                  title: 'INFO',
                  message: 'Setelah konfirmasi, kembali ke Re:kan dan masuk. Tautan kembali otomatis ke aplikasi belum tersedia.',
                ),
                const SizedBox(height: ReTokens.spaceCompact),
                RePrimaryButton(
                  label: 'Kembali ke masuk',
                  onPressed: () => controller.go(AuthScreen.login),
                ),
              ],
            ),
            AuthScreen.recovery => RePageScaffold(
              children: [
                const Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: ReTokens.spaceSm,
                  runSpacing: ReTokens.spaceSm,
                  children: [
                    ReBrandMark(variant: ReBrandMarkVariant.surface),
                    ReChip(
                      label: 'PEMULIHAN AKUN',
                      variant: ReChipVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: ReTokens.spaceMd),
                const ReFormHeading(
                  title: 'Pulihkan akses akun',
                  description:
                      'Pemulihan kata sandi belum tersedia di versi ini.',
                ),
                const ReStatusBanner(
                  variant: ReStatusVariant.warning,
                  title: 'BELUM TERSEDIA',
                  message: 'Tautan pemulihan belum dikonfigurasi. Tidak ada email pemulihan yang dikirim. Hubungi pengelola Re:kan untuk bantuan.',
                ),
                const SizedBox(height: ReTokens.spaceLg),
                RePrimaryButton(
                  label: controller.gateway.userId == null
                      ? 'Kembali ke masuk'
                      : 'Keluar dari sesi pemulihan',
                  onPressed: controller.busy
                      ? null
                      : () {
                          if (controller.gateway.userId == null) {
                            controller.go(AuthScreen.login);
                          } else {
                            controller.logout();
                          }
                        },
                ),
              ],
            ),
            AuthScreen.sessionError => RePageScaffold(
              children: [
                const ReBrandMark(variant: ReBrandMarkVariant.surface),
                const SizedBox(height: ReTokens.spaceLg),
                const ReFormHeading(
                  eyebrow: 'SESI TERKUNCI',
                  title: 'Periksa koneksi dan sesi',
                  description: 'Ruang akun Re:kan belum dapat dibuka.',
                ),
                ReStatusBanner(
                  variant: ReStatusVariant.error,
                  title: 'GALAT SESI',
                  message: controller.message ?? 'Coba lagi sebentar.',
                ),
                const SizedBox(height: ReTokens.spaceLg),
                RePrimaryButton(
                  label: 'Coba lagi',
                  busy: controller.busy,
                  onPressed: controller.restore,
                ),
                const SizedBox(height: ReTokens.spaceSm),
                ReSecondaryButton(
                  label: 'Keluar dan masuk ulang',
                  onPressed: controller.busy ? null : controller.logout,
                ),
              ],
            ),
          },
        );
      },
    );
  }
}

/// Screen 1 — Welcome / Landing (`FigCraft id: 434`).
///
/// Implements the approved Neo-Brutalist academic landing screen with
/// `ReBrandMark` (`Re:kan`), `MAHASISWA` badge, academic collaboration preview
/// card (`Study Group & UTS`, `Tim Lomba & Riset`, student cards `NR` & `DP`),
/// and primary/secondary CTAs.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, this.controller});
  final AuthController? controller;

  @override
  Widget build(BuildContext context) => RePageScaffold(
    padding: const EdgeInsets.symmetric(
      horizontal: ReTokens.spaceLg,
      vertical: ReTokens.spaceSm,
    ),
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
          ReChip(label: 'MAHASISWA', variant: ReChipVariant.status),
        ],
      ),
      const SizedBox(height: 6),
      const ReFormHeading(
        title: 'Temukan partner belajar dan rekan kompetisi',
        description: 'Kolaborasi belajar, riset, dan kompetisi lintas jurusan.',
      ),
      const _AcademicCollaborationHeroCard(),
      const SizedBox(height: 8),
      if (controller == null) ...[
        const ReStatusBanner(
          variant: ReStatusVariant.error,
          title: 'KONFIGURASI',
          message:
              'Layanan akun belum dikonfigurasi. Hubungi pengelola Re:kan.',
        ),
        const SizedBox(height: 6),
      ],
      RePrimaryButton(
        label: 'Daftar',
        onPressed: controller == null
            ? null
            : () => controller!.go(AuthScreen.register),
      ),
      const SizedBox(height: 6),
      ReSecondaryButton(
        label: 'Sudah punya akun? Masuk',
        onPressed: controller == null
            ? null
            : () => controller!.go(AuthScreen.login),
      ),
    ],
  );
}

class _AcademicCollaborationHeroCard extends StatelessWidget {
  const _AcademicCollaborationHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ReTokens.spaceSm),
      decoration: BoxDecoration(
        color: ReTokens.surface,
        borderRadius: BorderRadius.circular(ReTokens.radiusLarge),
        border: ReTokens.emphasizedBorder,
        boxShadow: ReTokens.shadowHero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            spacing: ReTokens.spaceSm,
            runSpacing: ReTokens.spaceXs,
            children: [
              ReChip(
                label: 'STUDY GROUP & UTS',
                variant: ReChipVariant.selected,
              ),
              ReChip(label: 'TIM LOMBA & RISET', variant: ReChipVariant.status),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ReTokens.primaryYellow,
              borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
              border: ReTokens.standardBorder,
            ),
            child: const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _StudentPreviewMiniCard(
                  initials: 'NR',
                  avatarColor: ReTokens.mutedSurface,
                  focus: 'Data Science',
                  program: 'Ilmu Komputer',
                ),
                _StudentPreviewMiniCard(
                  initials: 'DP',
                  avatarColor: ReTokens.accentTeal,
                  focus: 'UI/UX & Riset',
                  program: 'Sistem Informasi',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ReTokens.spaceSm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: ReTokens.mutedSurface,
              borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
              border: ReTokens.standardBorder,
            ),
            child: Text(
              'KOLABORASI LINTAS JURUSAN & KAMPUS',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: ReTokens.ink, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentPreviewMiniCard extends StatelessWidget {
  const _StudentPreviewMiniCard({
    required this.initials,
    required this.avatarColor,
    required this.focus,
    required this.program,
  });

  final String initials;
  final Color avatarColor;
  final String focus;
  final String program;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: ReTokens.surface,
          borderRadius: BorderRadius.circular(ReTokens.radiusSmall),
          border: ReTokens.standardBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                  border: ReTokens.standardBorder,
                ),
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ReTokens.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$focus · $program',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ReTokens.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

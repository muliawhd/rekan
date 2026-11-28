import 'package:material_ui/material_ui.dart';

import '../../core/theme/rekan_theme.dart';
import '../../core/widgets/rekan_logo.dart';
import '../academic_profile/data/academic_profile_repository.dart';
import '../academic_profile/domain/academic_onboarding_completion.dart';
import '../academic_profile/presentation/academic_onboarding_page.dart';
import '../rekan/data/supabase_rekan_repository.dart';
import '../rekan/presentation/rekan_workspace_shell.dart';
import 'auth_controller.dart';
import 'auth_form.dart';
import 'auth_gateway.dart';

class AuthBoundary extends StatefulWidget {
  const AuthBoundary({
    super.key,
    this.gateway,
    this.rekanRepository,
    this.profileRepository,
    this.catalog,
  });

  final AuthGateway? gateway;
  final RekanRepository? rekanRepository;
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
    if (widget.gateway != null) {
      _controller = AuthController(
        widget.gateway!,
        unauthenticatedLanding: AuthScreen.login,
      );
    }
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
    if (controller == null) {
      return const _UnconfiguredNoticeScreen();
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final screen = controller.screen;
        return PopScope(
          canPop: screen == AuthScreen.login ||
              screen == AuthScreen.welcome ||
              screen == AuthScreen.authenticated,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !controller.busy) {
              controller.go(AuthScreen.login);
            }
          },
          child: switch (screen) {
            AuthScreen.welcome || AuthScreen.login => AuthForm(
              key: ValueKey('login:${controller.revision}'),
              controller: controller,
              registration: false,
            ),
            AuthScreen.register => AuthForm(
              key: ValueKey('register:${controller.revision}'),
              controller: controller,
              registration: true,
            ),
            AuthScreen.checking => const _SessionCheckingScreen(),
            AuthScreen.authenticated => widget.rekanRepository != null
                ? RekanWorkspaceShell(
                    key: ValueKey(controller.gateway.userId),
                    authController: controller,
                    repository: widget.rekanRepository!,
                  )
                : (widget.profileRepository != null &&
                        controller.gateway.userId != null)
                    ? AcademicOnboardingBoundary(
                        key: ValueKey(controller.gateway.userId),
                        userId: controller.gateway.userId!,
                        repository: widget.profileRepository!,
                        authController: controller,
                        catalog: widget.catalog,
                      )
                    : _InfoStateScreen(
                        badge: 'SESI AKTIF',
                        title: 'Terhubung ke Re:kan',
                        description:
                            'Akun terverifikasi. Repository Supabase belum terhubung pada konteks pengujian ini.',
                        primaryLabel: 'Keluar dari Akun',
                        onPrimary: controller.busy ? null : controller.logout,
                      ),
            AuthScreen.verification => _InfoStateScreen(
              badge: 'VERIFIKASI EMAIL',
              title: 'Periksa Emailmu',
              description:
                  'Kami telah mengirim tautan konfirmasi pendaftaran ke emailmu. Cek kotak masuk atau folder spam, lalu kembali masuk ke Re:kan.',
              primaryLabel: 'Kembali ke Masuk',
              onPrimary: () => controller.go(AuthScreen.login),
            ),
            AuthScreen.recovery => _InfoStateScreen(
              badge: 'PEMULIHAN AKUN',
              title: 'Pulihkan Akses Akun',
              description:
                  'Pemulihan kata sandi otomatis belum dikonfigurasi pada versi ini. Tidak ada email pemulihan yang dikirim. Hubungi pengelola Re:kan untuk bantuan.',
              primaryLabel: controller.gateway.userId == null
                  ? 'Kembali ke Masuk'
                  : 'Keluar dari Sesi Pemulihan',
              onPrimary: controller.busy
                  ? null
                  : () {
                      if (controller.gateway.userId == null) {
                        controller.go(AuthScreen.login);
                      } else {
                        controller.logout();
                      }
                    },
            ),
            AuthScreen.sessionError => _InfoStateScreen(
              badge: 'GALAT SESI',
              title: 'Periksa Koneksi & Sesi',
              description:
                  controller.message ?? 'Ruang akun Re:kan belum dapat dibuka.',
              primaryLabel: 'Coba Lagi',
              onPrimary: controller.busy ? null : controller.restore,
              secondaryLabel: 'Keluar dan Masuk Ulang',
              onSecondary: controller.busy ? null : controller.logout,
              isError: true,
            ),
          },
        );
      },
    );
  }
}

class _SessionCheckingScreen extends StatelessWidget {
  const _SessionCheckingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RekanPalette.surface,
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RekanLogo(size: 68, showWordmark: true),
              SizedBox(height: 22),
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
                'Memeriksa sesi akun...',
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
}

class _UnconfiguredNoticeScreen extends StatelessWidget {
  const _UnconfiguredNoticeScreen();

  @override
  Widget build(BuildContext context) {
    return const _InfoStateScreen(
      badge: 'KONFIGURASI',
      title: 'Layanan Akun Belum Siap',
      description:
          'Layanan akun belum dikonfigurasi. Tutup dan buka kembali Re:kan.',
      isError: true,
    );
  }
}

class _InfoStateScreen extends StatelessWidget {
  const _InfoStateScreen({
    required this.badge,
    required this.title,
    required this.description,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isError = false,
  });

  final String badge;
  final String title;
  final String description;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RekanPalette.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: RekanLogo.header(),
                  ),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isError
                            ? RekanPalette.dangerSoft
                            : RekanPalette.lemonTint,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isError
                              ? const Color(0xFFFECACA)
                              : RekanPalette.lemonSoft,
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isError
                              ? RekanPalette.danger
                              : RekanPalette.lemonDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: RekanPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: RekanPalette.inkSecondary,
                    ),
                  ),
                  if (primaryLabel != null) ...[
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onPrimary,
                      child: Text(primaryLabel!),
                    ),
                  ],
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

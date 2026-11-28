import 'package:material_ui/material_ui.dart';

import '../../core/theme/rekan_theme.dart';
import '../../core/widgets/rekan_logo.dart';
import 'auth_controller.dart';

/// 01 AUTH — Clean editorial Login & Register screens in Lemon Green, White, and Blue.
/// Connected directly to Supabase Auth (no local demo/dummy auth).
class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.controller,
    required this.registration,
  });

  final AuthController controller;
  final bool registration;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  Future<void> _submit() async {
    if (widget.controller.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.controller.submit(
      _email.text,
      _password.text,
      register: widget.registration,
    );
    if (mounted) {
      _password.clear();
      _confirmation.clear();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final registration = widget.registration;

    return Scaffold(
      backgroundColor: RekanPalette.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              color: RekanPalette.lemon,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                    child: AutofillGroup(
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                if (registration)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: controller.busy
                                        ? null
                                        : () => controller.go(AuthScreen.login),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: RekanPalette.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: RekanPalette.border,
                                        ),
                                      ),
                                      child: const Tooltip(
                                        message: 'Kembali ke Masuk',
                                        child: Icon(
                                          Icons.arrow_back_rounded,
                                          size: 20,
                                          color: RekanPalette.ink,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  const RekanLogo.header(),
                                if (registration) const RekanLogo.header(),
                              ],
                            ),

                            const SizedBox(height: 28),

                            Text(
                              registration
                                  ? 'Buat Akun Baru'
                                  : 'Selamat Datang Kembali!',
                              style: const TextStyle(
                                fontSize: 25,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                                color: RekanPalette.ink,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              registration
                                  ? 'Daftar dengan email mahasiswa untuk mulai mencari partner belajar & tim lomba.'
                                  : 'Masuk dengan akun Re:kan untuk melanjutkan kolaborasi akademikmu.',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: RekanPalette.muted,
                              ),
                            ),

                            const SizedBox(height: 26),

                            const _FieldLabel('Email'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _email,
                              enabled: !controller.busy,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'nama@kampus.ac.id',
                              ),
                              validator: AuthValidation.email,
                            ),
                            const SizedBox(height: 16),

                            const _FieldLabel('Kata Sandi'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _password,
                              enabled: !controller.busy,
                              obscureText: _obscurePassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: [
                                registration
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              textInputAction: registration
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onFieldSubmitted:
                                  registration ? null : (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: registration
                                    ? 'Minimal 8 karakter'
                                    : 'Masukkan kata sandi',
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Tampilkan kata sandi'
                                      : 'Sembunyikan kata sandi',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: RekanPalette.muted,
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: (value) => AuthValidation.password(
                                value,
                                registration: registration,
                              ),
                            ),

                            if (registration) ...[
                              const SizedBox(height: 16),
                              const _FieldLabel('Konfirmasi Kata Sandi'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _confirmation,
                                enabled: !controller.busy,
                                obscureText: _obscureConfirmation,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: 'Ulangi kata sandi',
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirmation
                                        ? 'Tampilkan konfirmasi'
                                        : 'Sembunyikan konfirmasi',
                                    onPressed: () => setState(
                                      () => _obscureConfirmation =
                                          !_obscureConfirmation,
                                    ),
                                    icon: Icon(
                                      _obscureConfirmation
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: RekanPalette.muted,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    AuthValidation.confirmation(
                                  value,
                                  _password.text,
                                ),
                              ),
                            ],

                            if (!registration) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: controller.busy
                                      ? null
                                      : () =>
                                          controller.go(AuthScreen.recovery),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    foregroundColor: RekanPalette.blue,
                                  ),
                                  child: const Text(
                                    'Lupa kata sandi?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            if (controller.message != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: RekanPalette.dangerSoft,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Text(
                                  controller.message!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: RekanPalette.danger,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: controller.busy ? null : _submit,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (controller.busy) ...[
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: RekanPalette.lemonInk,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Text(
                                      controller.busy
                                          ? (registration
                                              ? 'Mendaftarkan akun...'
                                              : 'Memeriksa akun...')
                                          : (registration
                                              ? 'Daftar Akun'
                                              : 'Masuk'),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            const Divider(
                              color: RekanPalette.border,
                              height: 1,
                            ),
                            const SizedBox(height: 18),

                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              runSpacing: 2,
                              children: [
                                Text(
                                  registration
                                      ? 'Sudah punya akun?'
                                      : 'Belum punya akun?',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: RekanPalette.inkSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: controller.busy
                                      ? null
                                      : () => controller.go(
                                            registration
                                                ? AuthScreen.login
                                                : AuthScreen.register,
                                          ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    foregroundColor: RekanPalette.blue,
                                  ),
                                  child: Text(
                                    registration
                                        ? 'Masuk Sekarang'
                                        : 'Daftar Sekarang',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

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

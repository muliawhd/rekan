import 'package:material_ui/material_ui.dart';

import '../../core/theme/re_tokens.dart';
import '../../core/widgets/re_form_components.dart';
import 'auth_controller.dart';

/// Screen 2 — Login & Register (`FigCraft id: 473`).
///
/// Implements the Neo-Brutalist authentication form card with top navigation
/// (`48x48` back button + `ReBrandMark`), `ReTextField` inputs, password
/// visibility toggle, recovery entry point, `RePrimaryButton` CTA, info banner,
/// and mode-switching footer card.
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

    return AutofillGroup(
      child: Form(
        key: _form,
        child: RePageScaffold(
          padding: const EdgeInsets.symmetric(
            horizontal: ReTokens.spaceLg,
            vertical: ReTokens.spaceCompact,
          ),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: ReTokens.spaceSm,
              runSpacing: ReTokens.spaceSm,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ReTokens.surface,
                    borderRadius: BorderRadius.circular(ReTokens.radiusMedium),
                    border: ReTokens.standardBorder,
                    boxShadow: ReTokens.shadowSubtle,
                  ),
                  child: IconButton(
                    tooltip: 'Kembali',
                    constraints: const BoxConstraints(
                      minWidth: ReTokens.controlHeight,
                      minHeight: ReTokens.controlHeight,
                    ),
                    onPressed: controller.busy
                        ? null
                        : () => controller.go(AuthScreen.welcome),
                    icon: const Icon(Icons.arrow_back, color: ReTokens.ink),
                  ),
                ),
                const ReBrandMark(
                  variant: ReBrandMarkVariant.surface,
                  size: ReBrandMarkSize.sm,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ReFormHeading(
              title: registration ? 'Daftar di Re:kan' : 'Masuk ke Re:kan',
              description: registration
                  ? 'Buat akun untuk memulai perjalanan akademikmu.'
                  : 'Lanjutkan kolaborasi akademikmu.',
            ),
            ReTextField(
              label: 'EMAIL',
              hintText: 'nama@email.com',
              controller: _email,
              enabled: !controller.busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: AuthValidation.email,
            ),
            const SizedBox(height: ReTokens.spaceSm),
            ReTextField(
              label: 'KATA SANDI',
              hintText: 'Masukkan kata sandi',
              controller: _password,
              enabled: !controller.busy,
              obscureText: true,
              enablePasswordToggle: true,
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
              onFieldSubmitted: registration ? null : (_) => _submit(),
              helperText: registration
                  ? 'Minimal 8 karakter. Kebijakan akun dapat meminta lebih.'
                  : null,
              validator: (value) =>
                  AuthValidation.password(value, registration: registration),
            ),
            if (registration) ...[
              const SizedBox(height: ReTokens.spaceSm),
              ReTextField(
                label: 'KONFIRMASI KATA SANDI',
                hintText: 'Ulangi kata sandi',
                controller: _confirmation,
                enabled: !controller.busy,
                obscureText: true,
                enablePasswordToggle: true,
                showPasswordTooltip: 'Tampilkan konfirmasi',
                hidePasswordTooltip: 'Sembunyikan konfirmasi',
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) =>
                    AuthValidation.confirmation(value, _password.text),
              ),
            ],
            if (!registration) ...[
              const SizedBox(height: ReTokens.spaceXs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: controller.busy
                      ? null
                      : () => controller.go(AuthScreen.recovery),
                  child: const Text(
                    'Lupa kata sandi?',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: ReTokens.spaceCompact),
            if (controller.message != null) ...[
              ReStatusBanner(
                variant: ReStatusVariant.error,
                title: 'GALAT',
                message: controller.message!,
              ),
              const SizedBox(height: ReTokens.spaceCompact),
            ],
            RePrimaryButton(
              label: registration ? 'Buat akun' : 'Masuk',
              busy: controller.busy,
              busyLabel: registration
                  ? 'Mendaftarkan akun…'
                  : 'Memeriksa akun…',
              onPressed: _submit,
            ),
            const SizedBox(height: ReTokens.spaceCompact),
            ReStatusBanner(
              variant: ReStatusVariant.info,
              title: 'AKUN',
              message: registration
                  ? 'Gunakan email aktif yang dapat menerima konfirmasi akun Re:kan.'
                  : 'Masuk menggunakan email & kata sandi akun Re:kan yang telah terdaftar.',
            ),
            const SizedBox(height: ReTokens.spaceCompact),
            ReSecondaryButton(
              label: registration
                  ? 'Sudah punya akun? Masuk'
                  : 'Belum punya akun? Daftar',
              onPressed: controller.busy
                  ? null
                  : () => controller.go(
                      registration ? AuthScreen.login : AuthScreen.register,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

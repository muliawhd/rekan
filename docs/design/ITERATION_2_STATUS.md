# Re:kan — Iteration 2 Status: FigCraft Authentication UI Redesign (`ITERATION_2_STATUS.md`)

**Date:** 2026-11-16
**Scope:** Iteration 2 — FigCraft Authentication UI Redesign (`apps/mobile/lib/features/auth/`, `lib/app.dart`, `lib/main.dart`)
**Status:** Complete (Stop before Iteration 3 Academic Onboarding pending owner approval)

---

## 1. Screens Implemented & FigCraft Frame Mapping

All 5 required authentication screens (plus the 3 session-boundary states in `AuthBoundary`) have been redesigned in `apps/mobile/lib/features/auth/` to match the approved FigCraft Neo-Brutalist designs on Page `03 — Authentication`:

| # | Screen / State | FigCraft Frame & Key Nodes | Flutter Implementation | Visual & Functional Summary |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Welcome / Landing** | Page `03`, Frame `id: 434` (`Brand Header Row` `439`, `Hero Headline` `444`, `Academic Collaboration Illustration Card` `447`, `Welcome CTA Stack` `466`) | `WelcomePage` (`lib/features/auth/auth_boundary.dart`) | Top header with `ReBrandMark` (`Re:kan`, `surface` variant with `#FFE500` offset shadow) + `MAHASISWA` teal `ReChip`, headline `'Temukan partner belajar dan rekan kompetisi'`, Neo-Brutalist collaboration preview card (`STUDY GROUP & UTS`, `TIM LOMBA & RISET`, student cards `NR` & `DP`, cross-campus banner), unconfigured error banner when `controller == null`, primary yellow `Daftar` CTA, and secondary surface `Sudah punya akun? Masuk` CTA. |
| **2** | **Login** | Page `03`, Frame `id: 473` (`Top Navigation Row` `478`, `Login Title & Subtitle` `483`, `Login Form Container Card` `486`, `ReStatusBanner / AKUN` `503`, `Registration Footer` `507`) | `AuthForm(registration: false)` (`lib/features/auth/auth_form.dart`) | Top bar with bordered `48×48 dp` back button (`id: 479`) + `ReBrandMark` (`id: 481`), heading `'Masuk ke Re:kan'`, Neo-Brutalist `3px`-bordered form card (`6×6 dp` hard shadow) containing `ReTextField` (`EMAIL` & `KATA SANDI` with `>= 48×48 dp` visibility toggle), underlined `'Lupa kata sandi?'` link, `RePrimaryButton` (`'Masuk'` / `'Memeriksa akun…'`), `AKUN` info `ReStatusBanner`, and `ReSecondaryButton` (`'Belum punya akun? Daftar'`). |
| **3** | **Register** | Page `03`, Frame `id: 473` (Registration mode variant) | `AuthForm(registration: true)` (`lib/features/auth/auth_form.dart`) | Uses the same Neo-Brutalist `AuthForm` card with heading `'Daftar di Re:kan'`, `EMAIL`, `KATA SANDI` (with 8-character helper copy), `KONFIRMASI KATA SANDI` (with independent visibility toggle), `RePrimaryButton` (`'Buat akun'` / `'Mendaftarkan akun…'`), `AKUN` info `ReStatusBanner`, and `ReSecondaryButton` (`'Sudah punya akun? Masuk'`). |
| **4** | **Email Verification** | `AuthScreen.verification` state | `AuthBoundary` (`lib/features/auth/auth_boundary.dart`) | Header with `ReBrandMark` + `VERIFIKASI EMAIL` status chip, `'Periksa emailmu'` heading, Neo-Brutalist instruction card (`ReSectionHeader` with 3 activation steps), `INFO` `ReStatusBanner` explaining manual return to `Re:kan`, and `RePrimaryButton` (`'Kembali ke masuk'`). |
| **5** | **Password Recovery Explanation** | `AuthScreen.recovery` state | `AuthBoundary` (`lib/features/auth/auth_boundary.dart`) | Header with `ReBrandMark` + `PEMULIHAN AKUN` neutral chip, `'Pulihkan akses akun'` heading, `#F2A900` (`ReTokens.warning`) `BELUM TERSEDIA` `ReStatusBanner` explaining that recovery links/emails are not yet configured (no fake recovery request sent), and `RePrimaryButton` (`'Kembali ke masuk'` / `'Keluar dari sesi pemulihan'`). |
| **6** | **Checking / Session Error / Authenticated Placeholder** | `AuthScreen.checking`, `sessionError`, `authenticated` | `AuthBoundary` (`lib/features/auth/auth_boundary.dart`) | Neo-Brutalist session verification progress bar (`checking`), error banner + retry/logout controls (`sessionError`), and verified session placeholder (`'Ruang akademikmu'` + destructive `'Keluar'` button). |

---

## 2. Design Token & Shared Component Reuse Verification

- **Verified `ReTokens.warning`:** Confirmed `ReTokens.warning = Color(0xFFF2A900)` (`#F2A900`) in `lib/core/theme/re_tokens.dart` and tested in `test/design_foundation_test.dart`.
- **Shared Components Reused (Zero Duplicate Widgets Created):**
  - `RePageScaffold` (`lib/core/widgets/re_page_scaffold.dart`)
  - `ReBrandMark` (`lib/core/widgets/re_brand_mark.dart` — added `ReBrandMarkVariant.surface` to match the `#FFFFFF` fill + `#111111` border + `#FFE500` offset shadow of FigCraft nodes `440` and `481`)
  - `ReFormHeading` (`lib/core/widgets/re_form_components.dart`)
  - `RePrimaryButton` / `RePrimaryAction` (`lib/core/widgets/re_form_components.dart`)
  - `ReSecondaryButton` (`lib/core/widgets/re_secondary_button.dart`)
  - `ReTextField` (`lib/core/widgets/re_text_field.dart`)
  - `ReChip` (`lib/core/widgets/re_chip.dart`)
  - `ReSectionHeader` (`lib/core/widgets/re_section_header.dart`)
  - `ReStatusBanner` (`lib/core/widgets/re_form_components.dart`)
- **Brand Consistency (`Re:kan` Everywhere):**
  - Replaced all 6 user-facing occurrences of `'Re'` across `lib/app.dart`, `lib/main.dart`, `lib/features/auth/auth_boundary.dart`, and `lib/features/auth/auth_form.dart` with `'Re:kan'` and `ReBrandMark`.
  - Preserved the debug-only `AuthValidationPage` untouched per scope boundaries.

---

## 3. Preserved Authentication & Security Logic

- `SupabaseAuthGateway`, `AuthController`, `AuthValidation`, `SecureAuthStorage`, `initializeAuth`, `SupabaseApiSession`, and `LaravelApi` were **not modified**.
- Single-page `PopScope` replacement, revision-guarded account switching, password controller clearing after submission/disposal, and safe Indonesian error mapping remain 100% intact.

---

## 4. Changed Files

- `apps/mobile/lib/core/widgets/re_brand_mark.dart` (added `ReBrandMarkVariant.surface` for FigCraft `id: 440, 481` fidelity)
- `apps/mobile/lib/app.dart` (`title: 'Re:kan'`)
- `apps/mobile/lib/main.dart` (`'Re'` → `'Re:kan'` in fallback error text)
- `apps/mobile/lib/features/auth/auth_boundary.dart` (Neo-Brutalist redesign of `WelcomePage`, `verification`, `recovery`, `checking`, `sessionError`, and `authenticated` placeholder)
- `apps/mobile/lib/features/auth/auth_form.dart` (Neo-Brutalist redesign of `Login` and `Register` screens using `ReTextField`, `RePrimaryButton`, `ReSecondaryButton`, `ReStatusBanner`, and `ReBrandMark`)
- `apps/mobile/test/widget_test.dart` (updated unconfigured welcome test from `'Re'` to `'Re:kan'` and new welcome headline/status banner)
- `apps/mobile/test/auth_ui_test.dart` (preserved all 12 existing auth tests + added comprehensive Iteration 2 widget test for `Re:kan` branding, hero card, login/register switch, verification, recovery, and `sessionError` states)
- `docs/design/ITERATION_2_STATUS.md` (New)
- `implementation-plan.md` & `task-checklist.md`

---

## 5. Test & Validation Results

- **`dart format lib test`**: Clean (`0` unformatted files)
- **`flutter analyze`**: `No issues found!`
- **`flutter test`**: **`52 passed, 0 failed`** (`51` prior tests + `1` new end-to-end Neo-Brutalist auth UI test in `test/auth_ui_test.dart`; `test/widget_test.dart` updated for `'Re:kan'` branding)
- **`git diff --check`**: `Exit code 0`

---

## 6. Visual Differences & Remaining Limitations

- **Intentional Button Copy Retention for Test & UX Continuity:**
  - On `WelcomePage`, the secondary CTA uses `ReSecondaryButton(label: 'Sudah punya akun? Masuk')` (matching the existing `auth_ui_test.dart` finder while rendering the exact FigCraft Neo-Brutalist `#FFFFFF` surface button with `2px` `#111111` border and `3×3 dp` hard shadow from `id: 469`).
  - On `AuthForm(registration: true)`, the submit CTA uses `'Buat akun'` (matching `auth_ui_test.dart` lines `289–296`).
- **Password Recovery Limitation:** Remains an explanatory state (`AuthScreen.recovery`) without sending emails until an owned callback URI and deep-link flow are configured (`docs/architecture/phase-2e2-iteration-b-status.md`).
- **Next Actionable Step (Iteration 3):** Upon owner approval, implement Academic Onboarding (`Screen 9`, `Steps 1–5`) and confirm read-only catalog endpoint availability.

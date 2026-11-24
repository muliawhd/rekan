# Re:kan — Iteration 0: Repository Integration & Readiness Audit (`REPOSITORY_INTEGRATION_AUDIT.md`)

**Date:** 2026-11-16
**Scope:** Iteration 0 — FigCraft-to-Flutter Repository Integration & Verification
**Status:** Complete (No Flutter UI or Laravel API code modified; ready for Iteration 1 approval)

---

## 1. Verified Repository Paths

Both workspaces were verified on disk and inspected in full without deleting or altering existing source code:

| Workspace | Absolute Path | Verified Contents |
| :--- | :--- | :--- |
| **Application Repository** | `D:\Mulia\hackgdgocitb\rekan` | Monorepo containing Flutter 3.50 mobile app (`apps/mobile`, `package:re_mobile`), Laravel 12.72 API (`services/api`), architecture/testing documentation (`docs/architecture/`, `docs/testing/`), and Docker infrastructure (`infrastructure/`). |
| **Design Workspace** | `D:\Mulia\rekan ui ux` | Standalone FigCraft design system (`Re_kan_Mobile_UI_Design_System_v0.1.figcraft`, `187,372` bytes, 10 pages, 16 `readyForDev` frames, 56 `COMPONENT` nodes, 26 variables, 25 styles), 14 Markdown design & handoff specifications (`docs/design/`), exported design tokens (`exports/rekan_design_tokens.json`, `exports/rekan_design_tokens.dart`), Code Connect metadata (`exports/figcraft.connect.json`), and 18 `2x` PNG previews (`exports/preview_*.png`). |

---

## 2. Design Files Imported into `D:\Mulia\hackgdgocitb\rekan\docs\design\`

All approved design specifications, Post-FigCraft audit deliverables, exported tokens, and Code Connect mappings were integrated into `D:\Mulia\hackgdgocitb\rekan\docs\design\` while preserving the existing `docs/design/README.md` (`407` bytes):

### 2.1 Preserved Existing File
- `docs/design/README.md` (`407` bytes — Historical Phase 1 foundation design note; preserved untouched)

### 2.2 Imported Design Specifications (`docs/design/*.md`)
1. `docs/design/README_DESIGN_HANDOFF.md` (`2,684` bytes)
2. `docs/design/TASTE.md` (`4,150` bytes)
3. `docs/design/DESIGN_SYSTEM.md` (`4,454` bytes)
4. `docs/design/UI_HIERARCHY.md` (`2,245` bytes)
5. `docs/design/INTERACTION_MODEL.md` (`2,781` bytes)
6. `docs/design/NAVIGATION_ARCHITECTURE.md` (`1,628` bytes)
7. `docs/design/COMPONENT_SPEC.md` (`2,353` bytes)
8. `docs/design/SCREEN_SPEC.md` (`2,051` bytes)
9. `docs/design/IMPLEMENTATION_CONSTRAINTS.md` (`1,959` bytes)
10. `docs/design/ANTIGRAVITY_ITERATION_PROMPTS.md` (`9,455` bytes)

### 2.3 Imported FigCraft Audit & Handoff Deliverables (`docs/design/*.md`)
11. `docs/design/FIGCRAFT_AUDIT.md` (`20,351` bytes — 14-point visual & technical audit + codebase integration findings)
12. `docs/design/FLUTTER_COMPONENT_MAPPING.md` (`17,998` bytes — 56 FigCraft components mapped to `package:re_mobile/...`)
13. `docs/design/SCREEN_IMPLEMENTATION_MATRIX.md` (`25,717` bytes — Screen-by-screen readiness matrix against `services/api/routes/api.php`)
14. `docs/design/DESIGN_TO_CODE_PLAN.md` (`16,284` bytes — Phased implementation plan across Iterations 1–11)
15. `docs/design/REPOSITORY_INTEGRATION_AUDIT.md` (This document)

### 2.4 Imported Design Tokens & Code Connect Metadata
- `docs/design/tokens/rekan_design_tokens.json` (`16,299` bytes — W3C/FigCraft variable collections `VariableID:1..26`)
- `docs/design/tokens/rekan_design_tokens.dart` (`1,408` bytes — Reference Dart constants exported from FigCraft)
- `docs/design/code-connect/figcraft.connect.json` (`5,127` bytes — 21 component family bindings targeting `package:re_mobile/...`)

---

## 3. Existing Flutter Architecture (`apps/mobile`)

### 3.1 Package & Dependency Profile (`apps/mobile/pubspec.yaml`)
- **Package Name:** `re_mobile` (SDK `^3.11.0`, Flutter `3.50.0` / Dart `3.14.0`)
- **Runtime Dependencies:**
  - `flutter` (SDK)
  - `material_ui: 0.1.0` (local alias to Flutter Material in `pubspec.yaml`)
  - `cupertino_icons: ^1.0.8`
  - `supabase_flutter: ^2.18.3`
  - `flutter_secure_storage: ^11.2.0`
- **State Management & Networking:** Native `ChangeNotifier` + `ListenableBuilder` and `dart:io` `HttpClient` via injectable `ApiTransport` (`IoApiTransport`). No Riverpod, Provider, Bloc, GoRouter, or Dio dependencies are installed or required.

### 3.2 Complete Source Inventory (`apps/mobile/lib/`)

| File Path | Symbols Defined | Current Role & State |
| :--- | :--- | :--- |
| `lib/main.dart` | `main()` | Calls `initializeAuth()` and `runApp(const ReApp())`; renders fallback error scaffold if SDK init fails. |
| `lib/app.dart` | `ReApp` | Routes to `AuthValidationPage` with `AppTheme.light()` when `kDebugMode && AUTH_E2E_ENABLED && AppConfig.supabase != null`; otherwise routes to `AuthBoundary` with `AppTheme.onboarding`. Currently sets `title: 'Re'`. |
| `lib/core/config/app_config.dart` | `AppConfig`, `SupabaseConfiguration` | Validates compile-time `--dart-define` values (`API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`). |
| `lib/core/auth/initialize_auth.dart` | `initializeAuth()` | Initializes `Supabase` with `SecureAuthStorage`, `autoRefreshToken: true`, and `detectSessionInUri: false`. |
| `lib/core/auth/secure_auth_storage.dart` | `SecureAuthStorage` | Project-scoped `FlutterSecureStorage` wrapper for session and PKCE verifier keys. |
| `lib/core/auth/api_session.dart` | `ApiSession`, `ApiSessionSource`, `SupabaseApiSession` | Runtime-only view of Supabase access token, user UUID, expiration state, and auth-event generation counter. |
| `lib/core/network/laravel_api.dart` | `ApiFailureKind`, `ApiFailure`, `ApiEndpoint`, `ApiResponse`, `ApiTransport`, `IoApiTransport`, `LaravelApi` | Enforces HTTPS (or debug `http://10.0.2.2:8000/api/v1`), 15s timeout, 1 MiB body cap, single shared 401 token refresh, generation checks, and `X-Re-Require-Empty-Profile` header support. Exposes `ApiEndpoint.me` and `ApiEndpoint.academicProfile`. |
| `lib/core/theme/re_tokens.dart` | `ReTokens` | Phase 2E.2 Iteration A forest-green token class (`paper`, `surface`, `ink`, `muted`, `forest`, `forestTint`, `amber`, `amberTint`, `error`, `errorTint`, `outline`, `spaceXs..spaceXl`, `radiusMd`, `minTouchTarget`, `contentWidth`). |
| `lib/core/theme/app_theme.dart` | `AppTheme` (`light()`, `onboarding`) | `AppTheme.light()` for debug harness; `AppTheme.onboarding` for normal UI. |
| `lib/core/widgets/re_form_components.dart` | `ReFormPage`, `ReFormHeading`, `RePrimaryAction`, `ReNoticeTone`, `ReStatusNotice` | Reusable accessible form layout primitives introduced in Phase 2E.2 Iteration A. |
| `lib/features/auth/auth_gateway.dart` | `AuthSignal`, `AuthGateway`, `SupabaseAuthGateway`, `safeAuthMessage` | Adapts `GoTrueClient` (`verifySession`, `login`, `register`, `logout`) and maps `AuthException` codes to safe Bahasa Indonesia messages. |
| `lib/features/auth/auth_controller.dart` | `AuthScreen`, `AuthController`, `AuthValidation` | State machine (`welcome`, `login`, `register`, `verification`, `recovery`, `checking`, `authenticated`, `sessionError`), revision-guarded session restoration, and email/password/confirmation validators. |
| `lib/features/auth/auth_boundary.dart` | `AuthBoundary` | Renders `Welcome`, `AuthForm`, `checking`, `verification`, `recovery`, `sessionError`, and the `authenticated` placeholder (`'Ruang akademikmu'` + `'Keluar'`). Currently renders `'Re'` instead of `'Re:kan'` in 5 locations. |
| `lib/features/auth/auth_form.dart` | `AuthForm` | Shared login/registration form with email, password, visibility toggle, confirmation field, recovery link, and status notice. Currently renders `title: 'Re'`. |
| `lib/features/academic_profile/data/academic_profile.dart` | `ProfileVisibility`, `StudyMode`, `SkillSelection`, `AcademicPreferences`, `AcademicProfileInput`, `AcademicProfile` | Immutable DTOs matching the 10-field `GET/PUT /api/v1/me/academic-profile` contract. |
| `lib/features/academic_profile/data/academic_profile_repository.dart` | `AcademicProfileRepository` | Typed `get()` and `put(AcademicProfileInput, {bool requireEmpty})` repository. |
| `lib/features/academic_profile/presentation/profile_controller.dart` | `ProfileStatus`, `ProfileController` | `ChangeNotifier` managing `idle`, `loading`, `empty`, `success`, and `error` states with request versioning. |
| `lib/features/academic_profile/presentation/development_profile_validation.dart` & `profile_validation_panel.dart` | `DevelopmentProfileApproval`, `DevelopmentProfileValidation`, `ProfileValidationPanel` | Debug-only one-use PUT/GET verification harness embedded in `AuthValidationPage`. |
| `lib/features/auth_validation/auth_validation_page.dart` & `development_api.dart` | `AuthValidationPage`, `DevelopmentApi` | Debug-only connectivity, token-rejection, `/me`, and profile PUT/GET harness. |
| `lib/features/foundation/presentation/foundation_page.dart` | `FoundationPage` | Legacy Phase 1 placeholder screen (preserved). |

### 3.3 Existing Flutter Test Suite (`45` Passing Tests across 7 Files)
1. `test/design_foundation_test.dart` (`4` tests — WCAG AA contrast ratios on `ReTokens`, busy button semantics `'Memproses…'`, `320×640` `2.0x` text scaling + keyboard inset scrolling, `1200×900` wide screen `ReTokens.contentWidth` constraint)
2. `test/auth_ui_test.dart` (`12` tests — `320×640` `2.0x` large-text auth scrolling & safe recovery, validators, sanitized errors, session restore, expired session lock, account switch & logout, registration verification vs immediate session, duplicate submit lock, recovery isolation, login visibility/loading/error, registration confirmation, protected back-navigation block)
3. `test/academic_profile_integration_test.dart` (`15` tests — DTO 10-field projection, enum/range validation, HTTPS root enforcement, Bearer token + PUT projection, missing session guard, single 401 refresh + retry, persistent 401 stop, proactive refresh, sanitized refresh error, shared concurrent 401 refresh, logout/re-login discard, account-switch PUT abort, non-auth error non-retry, malformed/mismatched UUID rejection, `ProfileController` state transitions, `ProfileValidationPanel` approval dialog)
4. `test/development_profile_validation_test.dart` (`7` tests — one-use empty approval, non-empty conflict rejection, session switch abort, post-PUT session switch, value mismatch detection, non-retry on 409/422/503, lost GET after PUT handling)
5. `test/auth_configuration_test.dart` (`3` tests — optional empty config, HTTPS + `sb_publishable_` enforcement, `SecureAuthStorage` project isolation)
6. `test/development_api_test.dart` (`2` tests — emulator host restriction, `/me` UUID matching)
7. `test/widget_test.dart` (`1` test — unconfigured `ReApp` renders safe welcome with `'Re'` and `'Belajar bersama.\nTumbuh bersama.'`)

---

## 4. Component Reuse Matrix

Comparison of the existing Flutter codebase against the 21 FigCraft component families (`COMPONENT_SPEC.md` and `docs/design/FLUTTER_COMPONENT_MAPPING.md`):

### 4.1 Reusable As-Is (Logic, Data & Infrastructure Layers — `10` Modules)
| Existing Class / File | Layer | Reuse Status |
| :--- | :--- | :--- |
| `SupabaseAuthGateway` & `safeAuthMessage` (`lib/features/auth/auth_gateway.dart`) | Auth Infrastructure | **Reusable as-is** (100% preserved) |
| `AuthController` & `AuthValidation` (`lib/features/auth/auth_controller.dart`) | Auth State & Validation | **Reusable as-is** (100% preserved) |
| `SecureAuthStorage` & `initializeAuth` (`lib/core/auth/`) | Session Storage | **Reusable as-is** (100% preserved) |
| `SupabaseApiSession` & `ApiSessionSource` (`lib/core/auth/api_session.dart`) | API Session Adapter | **Reusable as-is** (100% preserved) |
| `LaravelApi` & `IoApiTransport` (`lib/core/network/laravel_api.dart`) | Network Transport | **Reusable as-is** (extend `ApiEndpoint` only when catalog/future routes are approved) |
| `AcademicProfile`, `AcademicProfileInput`, `SkillSelection`, `AcademicPreferences`, `ProfileVisibility`, `StudyMode` (`lib/features/academic_profile/data/academic_profile.dart`) | Domain DTOs | **Reusable as-is** (matches `AcademicProfileController` 10-field contract) |
| `AcademicProfileRepository` (`lib/features/academic_profile/data/academic_profile_repository.dart`) | Data Repository | **Reusable as-is** (`GET/PUT /api/v1/me/academic-profile`) |
| `ProfileController` (`lib/features/academic_profile/presentation/profile_controller.dart`) | Read/Save State | **Reusable as-is** (pair with a separate in-memory draft controller for multi-step onboarding) |
| `AuthValidationPage`, `DevelopmentApi`, `DevelopmentProfileValidation`, `ProfileValidationPanel` | Debug E2E Harness | **Reusable as-is** (preserved behind `AUTH_E2E_ENABLED`) |

### 4.2 Requires Visual Refactor (`7` Existing UI Classes)
| Existing Widget / File | Mapped FigCraft Component (`figcraft.connect.json`) | Required Visual Refactor |
| :--- | :--- | :--- |
| `ReTokens` (`lib/core/theme/re_tokens.dart`) | `VariableID:1..26` & `S:1..25` | Upgrade palette from Iteration A forest-green to Academic Neo-Brutalist tokens (`#111111` ink, `#FFFDF5` paper, `#FFE500` primary yellow, `#16C7C1` teal, `#F22DBB` magenta, `2px`/`3px` borders, hard offset shadows) while keeping backwards-compatible aliases (`forest`, `error`, `contentWidth = 520`). |
| `AppTheme.onboarding` (`lib/core/theme/app_theme.dart`) | Page `01` Foundations | Restyle `Scaffold`, `AppBarTheme`, `InputDecorationTheme`, `FilledButtonTheme`, `OutlinedButtonTheme`, and `TextTheme` to Neo-Brutalism; keep `AppTheme.light()` untouched for debug harness. |
| `ReFormPage` (`lib/core/widgets/re_form_components.dart`) | `RePageScaffold` (`Screens 434..945`) | Keep constructor signature (`children`, `appBar`); delegate to or style as Neo-Brutalist paper scaffold with `SafeArea`, `520dp` max width constraint, and keyboard inset padding. |
| `ReFormHeading` (`lib/core/widgets/re_form_components.dart`) | `ReSectionHeader` / Screen Heading | Keep constructor signature (`eyebrow`, `title`, `description`); style eyebrow as a Neo-Brutalist bordered pill/badge (`ReBrandMark` when eyebrow is `'Re:kan'`) and title with `w800` `#111111` typography. |
| `RePrimaryAction` (`lib/core/widgets/re_form_components.dart`) | `RePrimaryButton` (`id: 237, 239, 241, 243`) | Keep constructor signature (`label`, `onPressed`, `busy`, `busyLabel = 'Memproses…'`) and `FilledButton` child so `test/design_foundation_test.dart` & `test/auth_ui_test.dart` pass; wrap/style with `#FFE500` fill, `#111111` foreground, `2px` `#111111` border, and `4×4px` hard shadow when enabled. |
| `ReStatusNotice` (`lib/core/widgets/re_form_components.dart`) | `ReStatusBanner` (`id: 345, 349, 354, 358`) | Keep constructor signature (`message`, `tone`, `isError`); upgrade to `2px` `#111111` border, `3×3px` hard shadow, semantic status icon + badge, and optional retry action. |
| `AuthBoundary` & `AuthForm` (`lib/features/auth/`) | `Screen 1 — Welcome` (`id: 434`), `Screen 2 — Login` (`id: 473`) | Replace all 6 occurrences of `'Re'` (`app.dart:29`, `auth_boundary.dart:79,109,126,182,199`, `auth_form.dart:64`) with `'Re:kan'` / `ReBrandMark`, add hero academic collaboration card on Welcome, and apply Neo-Brutalist `ReSecondaryButton` and `ReTextField` styling while preserving all existing button labels/tooltips asserted in `test/auth_ui_test.dart`. |

### 4.3 Missing UI Components (`14` New Flutter Widgets to Implement)
| Target Widget & File Path | FigCraft Node IDs | Target Iteration | Backend Dependency |
| :--- | :--- | :---: | :--- |
| `ReBrandMark` (`lib/core/widgets/re_brand_mark.dart`) | `id: 224, 1057` | Iteration 1 | None (UI primitive) |
| `ReSecondaryButton` (`lib/core/widgets/re_secondary_button.dart`) | `id: 247, 249, 251, 253, 1061` | Iteration 1 | None (UI primitive) |
| `ReTextField` (`lib/core/widgets/re_text_field.dart`) | `id: 273, 279, 285, 294, 300` | Iteration 1 | None (UI primitive) |
| `ReChip` (`lib/core/widgets/re_chip.dart`) | `id: 318..340, 1063, 1065` | Iteration 1 | None (UI primitive) |
| `ReSectionHeader` (`lib/core/widgets/re_section_header.dart`) | `id: 410` | Iteration 1 | None (UI primitive) |
| `ReEmptyState` (`lib/core/widgets/re_empty_state.dart`) | `id: 1038, 1044` | Iteration 1 | None (UI primitive) |
| `ReTopAppBar` (`lib/core/widgets/re_top_app_bar.dart`) | `id: 393` | Iteration 4 | None (UI primitive) |
| `ReBottomNavigation` (`lib/core/widgets/re_bottom_navigation.dart`) | `id: 378, 584, 749, 934` | Iteration 4 | None (UI primitive) |
| `ReUnreadBadge` (`lib/core/widgets/re_unread_badge.dart`) | `id: 364, 366, 368, 1067` | Iteration 4 | None (UI primitive) |
| `ReSearchAndFilterBar` (`lib/core/widgets/re_search_and_filter_bar.dart`) | `id: 305, 883` | Iteration 4/8 | None (UI primitive) |
| `ReSegmentedTabs` (`lib/core/widgets/re_segmented_tabs.dart`) | `id: 401, 885, 976` | Iteration 8/9 | None (UI primitive) |
| `ReInfoRow` (`lib/features/academic_profile/presentation/re_info_row.dart`) | `id: 668, 702, 745` | Iteration 6 | Uses `AcademicProfile` DTO |
| `ReProfileCard`, `ReSwipeDeck`, `ReSwipeStamp`, `ReDiscoverActionBar` (`lib/features/discover/widgets/`) | `id: 531, 528, 370, 372, 571` | Iteration 5 | UI-only until Phase 3 matching/invitations API |
| `ReConversationTile`, `ReRoomHeader`, `RePinnedPurpose`, `ReMessageBubble` (`lib/features/chat/` & `rooms/`) | `id: 894, 915, 949, 971, 990..1051` | Iteration 8/9 | UI-only until Phase 5 chat/rooms API |

### 4.4 Components & Flows Requiring Backend Capabilities (`5` Feature Areas)
1. **Onboarding University / Course / Skill Selectors (`Screen 9`, `id: 760`):**
   - `PUT /api/v1/me/academic-profile` validates `university_id`, `courses[]`, and `skills[].skill_id` against PostgreSQL `universities`, `courses`, and `skills` tables, but `services/api/routes/api.php` has **no** `GET /api/v1/universities`, `GET /api/v1/courses`, or `GET /api/v1/skills` endpoints yet.
2. **Discover / Swipe Deck Live Feed & Filtering (`Screen 3`, `id: 518`):**
   - Requires `GET /api/v1/matches/recommendations` (Phase 3 — not yet implemented).
3. **Peer Profile Detail Live Lookup (`Screen 4`, `id: 611`):**
   - Requires peer profile read endpoint or recommendation payload projection (current `AcademicProfilePolicy` restricts `/api/v1/me/academic-profile` to owner-only).
4. **Collaboration Invitations & Mutual Connection (`Screen 5B`, `id: 841` & `Screen 5A`, `id: 805`):**
   - Requires `POST /api/v1/invitations`, `GET /api/v1/invitations`, `POST /api/v1/invitations/{id}/accept`, `POST /api/v1/invitations/{id}/decline`, and `GET /api/v1/connections` (Phase 4 — not yet implemented).
5. **Chat Inbox & Room Chat Messaging (`Screen 6`, `id: 871` & `Screen 7`, `id: 945`):**
   - Requires `GET/POST /api/v1/conversations` and `GET/POST /api/v1/conversations/{id}/messages` plus room metadata/tabs (Phase 5 — not yet implemented).

---

## 5. Resolution of Design Token Conflicts & Canonical Token Architecture

### 5.1 Token Conflict Analysis Across the 3 Sources

| Token Category | Existing `ReTokens` (`lib/core/theme/re_tokens.dart`) | `DESIGN_SYSTEM.md` Spec | Exported FigCraft (`rekan_design_tokens.dart`) | Canonical Resolution in `ReTokens` (`lib/core/theme/re_tokens.dart`) |
| :--- | :--- | :--- | :--- | :--- |
| **Primary Background (`paper`)** | `#F7F8F4` (Cool greenish paper) | `#F7F4EC` (`paperBackground`) | `#FFFDF5` (`colorPaper`) | Use `#FFFDF5` (`0xFFFFFDF5`) as `ReTokens.paper` and expose `ReTokens.paperWarm = Color(0xFFF7F4EC)` for secondary warm sections. Both exceed `18:1` contrast with `#111111`. |
| **Card Surface (`surface`)** | `#FFFFFF` | `#FFFFFF` (`cardSurface`) | `#FFFFFF` (`colorSurface`) | `ReTokens.surface = Color(0xFFFFFFFF)` (No conflict). |
| **Secondary / Muted Surface** | `#E6EFEA` (`forestTint`) | `#EFECE3` (`secondarySurface`) | `#F2F0E8` (`colorMutedSurface`) | `ReTokens.mutedSurface = Color(0xFFF2F0E8)` (and alias `forestTint = Color(0xFFF2F0E8)` for backwards compatibility). |
| **Primary Ink / Outline** | `ink: #182B24`, `outline: #718078` | `inkBlack: #111111` | `colorInk: #111111` | `ReTokens.ink = Color(0xFF111111)` and `ReTokens.outline = Color(0xFF111111)` (`19.3:1` contrast on paper; satisfies `design_foundation_test.dart` `>= 3.0` outline check). |
| **Secondary / Muted Text** | `muted: #475750` | `secondaryText: #3D3D3D`, `mutedText: #6B6B6B` | `colorMutedText: #626262` | `ReTokens.secondaryText = Color(0xFF3D3D3D)` (`10.8:1`) and `ReTokens.muted = Color(0xFF626262)` (`5.97:1` on `#FFFDF5`, `6.07:1` on `#FFFFFF` — passes `design_foundation_test.dart` `>= 4.5:1`). |
| **Primary Brand Accent** | `forest: #245C45` (white text) | `primaryYellow: #FFD400` (`#111111` text) | `colorAccentPrimary: #FFE500` (`#111111` text) | `ReTokens.accentPrimary = Color(0xFFFFE500)` (`ReTokens.primaryYellow = Color(0xFFFFD400)` optional warm alias). Keep `@Deprecated` `ReTokens.forest = Color(0xFF245C45)` so `design_foundation_test.dart` line 24 (`contrast(ReTokens.surface, ReTokens.forest) >= 4.5`) remains green. |
| **Secondary Accents** | *None* | `secondaryTeal: #00C2B8`, `secondaryMagenta: #FF2E93` | `colorAccentTeal: #16C7C1`, `colorAccentMagenta: #F22DBB` | `ReTokens.accentTeal = Color(0xFF16C7C1)` and `ReTokens.accentMagenta = Color(0xFFF22DBB)` (always paired with `#111111` ink text/borders for `> 5.2:1` contrast). |
| **Semantic Status Colors** | `error: #B42318`, `amber: #7B4E00` | `success: #19B36B`, `warning: #FFB800`, `danger: #E53935` | `colorSuccess: #1FA86A`, `colorWarning: #F2A900`, `colorDanger: #E5484D` | **Critical Test Constraint:** `test/design_foundation_test.dart` line 18 asserts `contrast(ReTokens.error, ReTokens.paper/surface) >= 4.5`. `#E5484D` (`4.00:1`) and `#E53935` (`4.18:1`) fail `>= 4.5` when used as normal text on white/paper. Therefore: keep `ReTokens.error = Color(0xFFB42318)` (`7.09:1`) for error text, and add `ReTokens.danger = Color(0xFFE5484D)` (`ReTokens.success = Color(0xFF1FA86A)`, `ReTokens.warning = Color(0xFFF2A900)`) for Neo-Brutalist surface fills/borders paired with `#111111` ink text. |
| **Spacing Scale** | `spaceXs: 8`, `spaceSm: 12`, `spaceMd: 16`, `spaceLg: 24`, `spaceXl: 32` | `4, 8, 12, 16, 20, 24, 32, 48` | `space4, space8, space12, space16, space24, space32, space48` | Preserve existing `spaceXs..spaceXl` names (`8, 12, 16, 24, 32`) AND expose explicit numeric constants `space4 = 4`, `space8 = 8`, `space12 = 12`, `space16 = 16`, `space20 = 20`, `space24 = 24`, `space32 = 32`, `space48 = 48` inside `ReTokens`. |
| **Corner Radii** | `radiusMd = 10` | `0, 8, 12, 16, 999` | `0, 6, 10, 16, 999` | Single scale in `ReTokens`: `radiusNone = 0`, `radiusSm = 6`, `radiusMd = 10`, `radiusLg = 16`, `radiusFull = 999`. |
| **Borders & Shadows** | `1px` / `2px` outline, no shadows | `2px` / `3px` `#111111` border; `4×4px` & `6×6px` `0px`-blur shadow | `borderStandard = 2`, `borderEmphasized = 3`; `3×3px`, `4×4px`, `6×6px` hard shadows | Add `borderStandard = 2.0`, `borderEmphasized = 3.0`, and `List<BoxShadow>` helpers `shadowSubtle` (`3×3dp`), `shadowHard` (`4×4dp`), and `shadowHero` (`6×6dp`) with `blurRadius: 0` and `color: ReTokens.ink` to `ReTokens`. |
| **Touch Target & Width** | `minTouchTarget = 48`, `contentWidth = 520` | `48×48dp` (`min 44×44dp`) | `touchMinTarget = 44` | Keep `minTouchTarget = 48.0` (exceeds `44.0` minimum), add `minCompactTarget = 44.0`, and keep `contentWidth = 520.0` (asserted by `test/design_foundation_test.dart` line 127). |

### 5.2 Font Availability & Licensing Verification
- **Evaluated Typefaces:**
  1. **Plus Jakarta Sans** (specified in `DESIGN_SYSTEM.md` §3): Licensed under **SIL Open Font License 1.1 (OFL-1.1)**.
  2. **Montserrat** (used in FigCraft headings `S:1..8`, `S:15..20`): Licensed under **SIL Open Font License 1.1 (OFL-1.1)**.
  3. **Inter** (specified as fallback in `DESIGN_SYSTEM.md` §3 and used in FigCraft body styles): Licensed under **SIL Open Font License 1.1 (OFL-1.1)**.
- **Repository Availability:**
  - `apps/mobile/pubspec.yaml` currently bundles **no custom `.ttf`/`.otf` font files** and does **not** depend on `google_fonts`.
  - Per Iteration 0 rules (*"Do not introduce fonts or dependencies automatically"*), no font binaries or packages were added.
  - **Recommendation for Iteration 1:** Either keep the platform default sans-serif (`Roboto` on Android) with the exact Neo-Brutalist `TextTheme` size/weight/line-height scale in `AppTheme.onboarding` (zero binary footprint, deterministic widget tests), or—if the owner approves—bundle static OFL-1.1 `.ttf` files under `apps/mobile/assets/fonts/` (never runtime network fetching via `google_fonts`).

### 5.3 Iconography Architecture
- `apps/mobile/pubspec.yaml` already enables `uses-material-design: true` and `cupertino_icons: ^1.0.8`.
- All required icons (visibility eye, search, filter, close/pass, bookmark/save, info/detail, add/collaborate, chat, group/room, check, warning, error, arrow back/forward) map directly to built-in `Icons.*` from Flutter's Material icon font (`20dp`/`24dp`, `color: ReTokens.ink`), requiring **zero** external icon packages.

---

## 6. API Readiness by Screen (`services/api` Verification)

### 6.1 Verified Laravel Routes & Schema (`services/api`)
- **Implemented Routes (`services/api/routes/api.php`):**
  1. `GET /api/v1/health` & `GET /api/health` (`HealthController`)
  2. `GET /api/v1/me` (`MeController`, `supabase.jwt` + `throttle:api-authenticated`) → returns `data: {id, status, created_at}`
  3. `GET /api/v1/me/academic-profile` (`AcademicProfileController@show`, owner-only via `AcademicProfilePolicy`) → returns `data: {user_id, display_name, university_id, program, semester, bio, mbti_badge, visibility, courses, skills, preferences}`
  4. `PUT /api/v1/me/academic-profile` (`AcademicProfileController@upsert`, owner-only, optional `X-Re-Require-Empty-Profile: true` header)
- **Strict 10-Field Whitelist (`AcademicProfileController.php` lines 27–44):**
  - `ALLOWED_FIELDS = ['display_name', 'university_id', 'program', 'semester', 'bio', 'mbti_badge', 'visibility', 'courses', 'skills', 'preferences']`.
  - Any unknown key (`user_id`, `status`, `interests`, `portfolio`, `schedule`, `degree`, `collaboration_goal`) triggers `422 VALIDATION_ERROR`.
  - All 10 keys must be present in every `PUT` request (`required` validation rules).
  - `courses` must be existing UUIDs in `courses` (and if `university_id` is null, university-scoped courses are rejected; if `university_id` is set, courses from another university are rejected).
  - `skills` must be `[{skill_id: UUID, level: 1..5}]` referencing existing rows in `skills`.

### 6.2 Screen-by-Screen API Readiness Matrix

| # | Screen Name | FigCraft Frame ID | API Classification | Backing Endpoints (`routes/api.php`) | Missing API / Schema Capabilities |
| :---: | :--- | :---: | :--- | :--- | :--- |
| **1** | **Screen 1 — Welcome** | `id: 434` | **Ready for real backend integration** | Supabase Auth session check (`AuthController.restore`) | None |
| **2** | **Screen 2 — Login & Register** | `id: 473` | **Ready for real backend integration** | Supabase `signInWithPassword` / `signUp` + `GET /api/v1/me` | Password recovery requires owned callback URI + deep-link config (`phase-2e2-iteration-b-status.md`). |
| **3** | **Screen 9 — Academic Onboarding (`Steps 1–5`)** | `id: 760` | **Partially Ready (`GET/PUT` ready; Catalog Selectors Blocked)** | `GET /api/v1/me/academic-profile`, `PUT /api/v1/me/academic-profile` | Missing read-only catalog endpoints (`GET /api/v1/universities`, `/courses`, `/skills`) to populate picker UUIDs; `interests` and `schedule` are UI-only extensions not stored in PostgreSQL. |
| **4** | **Screen 8 — My Academic Profile** | `id: 679` | **Ready for real backend integration (Core 10 fields)** | `GET /api/v1/me`, `GET / PUT /api/v1/me/academic-profile` | `university_id`, `courses[]`, and `skills[]` return UUIDs without display labels until catalog endpoints or joined projections exist; `interests`/`portfolio`/`schedule` are local view-only extensions. |
| **5** | **Screen 3 — Discover / Swipe Cards** | `id: 518` | **UI-only implementation possible (Blocked for live data)** | *None implemented* | Missing `GET /api/v1/matches/recommendations` (Phase 3) and `POST /api/v1/invitations` (Phase 4). |
| **6** | **Screen 4 — Peer Profile Detail** | `id: 611` | **UI-only implementation possible (Blocked for live data)** | *None implemented for non-owners* | `AcademicProfilePolicy` restricts `/me/academic-profile` to owner; requires Phase 3 recommendation projection or peer profile endpoint. |
| **7** | **Screen 5B — Invitation Sent (Pending)** | `id: 841` | **UI-only implementation possible (Blocked for live data)** | *None implemented* | Missing `POST /api/v1/invitations` and `GET /api/v1/invitations` (Phase 4). |
| **8** | **Screen 5A — Collaboration Connected** | `id: 805` | **UI-only implementation possible (Blocked for live data)** | *None implemented* | Missing `POST /api/v1/invitations/{id}/accept` and `GET /api/v1/connections` (Phase 4). |
| **9** | **Screen 6 — Chat Inbox (`Pesan`)** | `id: 871` | **UI-only implementation possible (Blocked for live data)** | *None implemented* | Missing `GET /api/v1/conversations` (Phase 5). |
| **10** | **Screen 7 — Room Chat (`Diskusi Kelompok`)** | `id: 945` | **UI-only implementation possible (Blocked for live data)** | *None implemented* | Missing `GET / POST /api/v1/conversations/{id}/messages` and room task/file/note endpoints (Phase 5+). |

---

## 7. Missing Dependencies Assessment

1. **Pub / Composer Packages:** **None missing.** All UI components, custom Neo-Brutalist borders/shadows, swipe gestures (`GestureDetector` + `AnimationController`), state controllers (`ChangeNotifier`), and HTTP calls (`IoApiTransport`) can and should be built without adding third-party packages.
2. **Font Assets:** No local `.ttf` files are bundled in `apps/mobile/assets/fonts/`. System sans-serif with explicit weights works out-of-the-box; bundling OFL-1.1 `Plus Jakarta Sans` or `Montserrat` + `Inter` is optional and requires owner approval.
3. **Backend Catalog Endpoints (Phase 2E.2 Iteration C dependency):** Read-only `GET /api/v1/universities`, `GET /api/v1/courses`, and `GET /api/v1/skills` are needed before users can select human-readable universities, courses, and skills by UUID in Onboarding (`Screen 9`) and My Academic Profile (`Screen 8`).

---

## 8. Recommended Implementation Sequence

Aligned with `docs/design/ANTIGRAVITY_ITERATION_PROMPTS.md` and `docs/design/DESIGN_TO_CODE_PLAN.md`, stopping after each iteration for review:

1. **Iteration 0 — Repository Integration & Audit (Current — Complete)**
2. **Iteration 1 — Design Tokens & Shared Neo-Brutalist Components:**
   - Evolve `lib/core/theme/re_tokens.dart` and `lib/core/theme/app_theme.dart` (`AppTheme.onboarding`).
   - Refactor `ReFormPage`, `ReFormHeading`, `RePrimaryAction`, `ReStatusNotice` in-place in `lib/core/widgets/re_form_components.dart`.
   - Create `RePageScaffold`, `ReBrandMark`, `ReSecondaryButton`, `ReTextField`, `ReChip`, `ReSectionHeader`, `ReEmptyState`.
   - Verify all 45 existing Flutter tests + new component tests pass.
3. **Iteration 2 — Authentication UI Redesign (`Welcome`, `Login`, `Register`, `Verification`, `Recovery`):**
   - Refactor `lib/app.dart`, `lib/features/auth/auth_boundary.dart`, and `lib/features/auth/auth_form.dart` to Neo-Brutalism and replace `'Re'` with `'Re:kan'` (`ReBrandMark`), updating `test/widget_test.dart` (`find.text('Re:kan')`) while keeping all 12 `test/auth_ui_test.dart` tests passing.
4. **Iteration 3 — Academic Onboarding (`Screen 9`, `Steps 1–5`):**
   - Implement `OnboardingDraftController` + `AcademicOnboardingPage` wired to `ProfileController` (`GET/PUT /api/v1/me/academic-profile`). Coordinate with owner on whether read-only catalog endpoints are approved or if catalog pickers remain gated.
5. **Iteration 4 — Authenticated App Shell & Navigation (`ReBottomNavigation`, `ReTopAppBar`, `ReUnreadBadge`):**
   - Route authenticated users from `AuthBoundary` into the 5-tab `MainShellPage` (`Jelajah`, `Cari`, `Kolaborasi`, `Pesan`, `Profil`) with onboarding completion guard.
6. **Iteration 5 — Discover & Swipe Cards (`Screen 3` — UI-Only with Isolated Preview Fixtures):**
   - Implement `ReProfileCard`, `ReSwipeDeck`, `ReSwipeStamp`, `ReDiscoverActionBar`, and `DiscoverPage`.
7. **Iteration 6 — Academic Profile Screens (`Screen 8` Live & `Screen 4` UI-Only):**
   - Implement `MyAcademicProfilePage` (`GET/PUT /api/v1/me/academic-profile`) and `ProfileDetailPage`.
8. **Iteration 7 — Collaboration States (`Screen 5B` Pending & `Screen 5A` Connected — UI-Only):**
   - Implement `CollaborationOutcomePage` with explicit `[PRATINJAU UI]` badge where backend endpoints are unimplemented.
9. **Iteration 8 — Chat Inbox (`Screen 6` — UI-Only):**
   - Implement `ReConversationTile`, `ReSegmentedTabs`, `ReSearchAndFilterBar`, and `ChatInboxPage`.
10. **Iteration 9 — Room Chat (`Screen 7` — UI-Only):**
    - Implement `ReRoomHeader`, `RePinnedPurpose`, `ReMessageBubble`, and `RoomChatPage` (with `Tugas`, `File`, `Catatan` marked `[SEGERA]`).
11. **Iteration 10 — Accessibility, Responsiveness & Polish Audit**
12. **Iteration 11 — Final Verification & Handoff**

---

## 9. Risk Assessment & Mitigations

| Risk ID | Severity | Description | Mitigation Strategy |
| :---: | :---: | :--- | :--- |
| **R-01** | **High** | **Breaking Existing Widget Tests During Token/Widget Upgrade:** `test/design_foundation_test.dart` checks `contrast(ReTokens.error, ReTokens.paper/surface) >= 4.5`, `contrast(ReTokens.surface, ReTokens.forest) >= 4.5`, `FilledButton` height `>= 48`, `'Memproses…'` semantics, and `ListView` width `== ReTokens.contentWidth` (`520`). | Keep `ReTokens.error = Color(0xFFB42318)` (`7.09:1`) for error text, add `ReTokens.danger = Color(0xFFE5484D)` for Neo-Brutalist fills/borders, retain `ReTokens.forest` and `ReTokens.contentWidth = 520`, and keep `FilledButton` inside `RePrimaryAction`. |
| **R-02** | **High** | **Strict 10-Field Whitelist on `PUT /api/v1/me/academic-profile`:** `AcademicProfileController.php` rejects any extra JSON key (`interests`, `portfolio`, `schedule`, `degree`) with `422 VALIDATION_ERROR`, and rejects missing keys among the 10 required fields. | Always construct `PUT` payloads exclusively through `AcademicProfileInput.toJson()`. Store UI-only extensions (`interests`, `portfolio`, `schedule`) in a separate view-only model that is never serialized into `AcademicProfileRepository.put()`. |
| **R-03** | **High** | **Missing Catalog Endpoints for UUID Foreign Keys:** `university_id`, `courses[]`, and `skills[].skill_id` require valid UUIDs existing in PostgreSQL (`universities`, `courses`, `skills`), but no catalog `GET` routes exist in `routes/api.php`. | Never fabricate random UUIDs on the client. Preserve existing loaded `universityId`, `courses`, and `skills` during `PUT` updates until read-only catalog endpoints are approved and implemented. |
| **R-04** | **Medium** | **Brand Name Test Assertion in `test/widget_test.dart`:** `test/widget_test.dart` line 10 asserts `expect(find.text('Re'), findsOneWidget)`. | Keep `'Re'` untouched in Iteration 0 & Iteration 1; update `auth_boundary.dart`, `auth_form.dart`, `app.dart`, and `test/widget_test.dart` together in Iteration 2 when refactoring Authentication UI to `'Re:kan'`. |
| **R-05** | **Medium** | **Debug Validation Harness Regression (`AUTH_E2E_ENABLED`):** Modifying `AuthValidationPage` or `ProfileValidationPanel` could break Phase 2B.1 / 2E.1 verification flows. | Do not modify `lib/features/auth_validation/*`, `lib/features/academic_profile/presentation/development_profile_validation.dart`, or `AppTheme.light()`. |

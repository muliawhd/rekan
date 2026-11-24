# Implementation checklist

## Integration 3.2 - Real onboarding E2E validation

- [x] PASS: verify public development configuration alignment, PostgreSQL/Redis health, Laravel liveness and emulator boot; preserve existing data/storage.
- [x] PASS: record read-only full-row fingerprints; independently reconfirm all eight domain tables unchanged.
- [x] PASS: 68 automated Flutter tests, Dart formatting and whitespace checks; these are not real UI evidence.
- [x] Add GET-only Android integration test; record its observed execution outcome in [E2E report](docs/testing/INTEGRATION_3_2_E2E.md).
- [ ] Real-session identity/catalog/profile GET acceptance.
- [ ] Resolve FAIL prerequisite: Android GET-only test found no restored SDK session; user must sign in manually, then rerun (no passwords/tokens in chat).
- [ ] Real five-step onboarding, navigation/search/selection/error/session observations (capture blocked).
- [ ] Explicit approval of an exact account/profile payload before PUT; verify persistence and unrelated users afterward.
- [ ] Complete real E2E acceptance before further iteration; no Iteration 4 work.

## Integration 3.2 - Real onboarding E2E validation

- [x] PASS: verify public development configuration alignment, PostgreSQL/Redis health, Laravel liveness and emulator boot; preserve existing data/storage.
- [x] PASS: record read-only full-row fingerprints; independently reconfirm all eight domain tables unchanged.
- [x] PASS: 68 automated Flutter tests, Dart formatting and whitespace checks; these are not real UI evidence.
- [x] Add GET-only Android integration test; record its observed execution outcome in [E2E report](docs/testing/INTEGRATION_3_2_E2E.md).
- [ ] Real-session identity/catalog/profile GET acceptance.
- [ ] Real five-step onboarding, navigation/search/selection/error/session observations (capture blocked).
- [ ] Explicit approval of an exact account/profile payload before PUT; verify persistence and unrelated users afterward.
- [ ] Complete real E2E acceptance before further iteration; no Iteration 4 work.

## Integration 3.1 - Flutter academic catalog selectors

- [x] Audit the actual catalog query/response contract and existing session/profile/draft implementation.
- [x] Reuse LaravelApi for typed read-only university/course/skill search and UUID lookup in batches of 50.
- [x] Add searchable selectors with loading, results, empty, error/retry, selection preservation and skill levels.
- [x] Confirm incompatible course removal on university changes; preserve global courses and unresolved selections.
- [x] Discard stale account responses, clear label cache, dismiss stale confirmation dialogs, and retain existing explicit-save protections.
- [x] Apply Dart formatting; pass analyzer, 68 Flutter tests and git diff --check.
- [x] Document [Integration 3.1 status](docs/design/INTEGRATION_3_1_STATUS.md), changed files, provenance and E2E limitations.
- [ ] Real Supabase-session emulator acceptance (no connected device/emulator or local API listener during verification).
- [ ] Owner approval before Iteration 4.

## Backend Sprint A.1 - Development academic catalog seed

- [x] Verify local PostgreSQL environment, live constraints, empty catalog counts and existing users/profiles before insertion.
- [x] Add explicit development-only insert-only seeder with stable IDs, natural-key preservation and transactional concurrency protection.
- [x] Insert 4 universities, 8 global courses and 10 skills; rerun with zero inserts and identical catalog rows.
- [x] Verify all expected names, no duplicates, and full-row preservation of existing users/profiles/preferences/selections.
- [x] Verify authenticated catalog responses against committed PostgreSQL using process-local signed JWT/JWKS fixtures.
- [x] Pass 92 Laravel tests / 1413 assertions and Pint; document provenance and limitations in [Sprint A.1 status](docs/architecture/BACKEND_SPRINT_A1_STATUS.md).
- [x] Stop after seed and verification; no Flutter or additional backend features.

## Backend Sprint A - Academic Catalog REST API

- [x] Audit architecture, models, migrations, JWT middleware, API conventions and live PostgreSQL catalog columns/indexes/constraints.
- [x] Implement authenticated read-only university/course/skill routes with validated query parameters, deterministic limits, private no-store responses, request IDs and explicit field allowlists.
- [x] Preserve global/university-scoped course semantics; intersect search and UUID filters without scope bypass.
- [x] Add isolated PostgreSQL feature tests for JWT failures, search, scope, IDs, validation, ordering, limits, empty catalogs, privacy and no domain mutations.
- [x] Pass full PostgreSQL-backed Laravel suite (87 tests / 1321 assertions), Pint, infrastructure health checks and git diff --check.
- [x] Inspect development catalogs read-only: universities 0, courses 0, skills 0; no seed inserted.
- [x] Update API contract, implementation plan and [Sprint A status](docs/architecture/BACKEND_SPRINT_A_STATUS.md), including a dummy-only seed proposal.
- [ ] Owner approval before development catalog seeding or any further backend/Flutter work.

## FigCraft Design Handoff - Iteration 3 (Academic Onboarding UI & Laravel Integration)

- [x] Audit existing Flutter `AcademicProfile` DTOs, `AcademicProfileRepository`, `ProfileController`, `LaravelApi`, `SupabaseApiSession`, and Laravel `AcademicProfileController.php` 10-field contract.
- [x] Implement 5-step Neo-Brutalist Academic Onboarding UI (`Identitas Akademik`, `Universitas, Program Studi & Semester`, `Keahlian dan Minat`, `Mata Kuliah Aktif`, `Preferensi Belajar & Review`) matching FigCraft `Screen 9` (`id: 760`) in Bahasa Indonesia.
- [x] Implement `AcademicOnboardingCompletion` (`display_name`, `university_id`, `program`, `semester` required from persisted data; optional fields never block) and `OnboardingDraftController`.
- [x] Preserve drafts across steps and recoverable errors, prevent duplicate submissions, protect non-empty profiles (`X-Re-Require-Empty-Profile: true` on initially empty profiles), preserve untouched fields, and invalidate drafts on account switch/logout.
- [x] Document missing read-only catalog endpoints (`GET /api/v1/universities`, `/courses`, `/skills`), propose the smallest secure Laravel contract, and avoid fabricating catalog UUIDs.
- [x] Add comprehensive unit and widget tests (`test/academic_onboarding_test.dart`) and run `dart format`, `flutter analyze`, `flutter test` (57 passed), and `git diff --check`. See [Iteration 3 Status](docs/design/ITERATION_3_STATUS.md).
- [ ] Owner approval before Iteration 4.

## FigCraft Design Handoff - Iteration 2 (Authentication UI redesign)

- [x] Verify `ReTokens.warning` (`#F2A900`) and add `ReBrandMarkVariant.surface` matching FigCraft nodes `440` and `481`.
- [x] Redesign `WelcomePage` (`id: 434`), `Login` & `Register` (`id: 473`), `Email Verification`, `Password Recovery Explanation`, `checking`, `sessionError`, and `authenticated` placeholder using shared Neo-Brutalist components.
- [x] Replace all user-facing `'Re'` brand strings with `'Re:kan'` (`lib/app.dart`, `lib/main.dart`, `lib/features/auth/auth_boundary.dart`, `lib/features/auth/auth_form.dart`).
- [x] Preserve `SupabaseAuthGateway`, `AuthController`, `SecureAuthStorage`, single-page `PopScope` replacement, and debug `AuthValidationPage`.
- [x] Update `test/widget_test.dart` for `'Re:kan'` branding and add Neo-Brutalist auth state coverage in `test/auth_ui_test.dart`.
- [x] Run `dart format`, `flutter analyze`, `flutter test` (52 passed), and `git diff --check`. See [Iteration 2 Status](docs/design/ITERATION_2_STATUS.md).
- [x] Owner approval before Iteration 3 (Academic Onboarding).

## FigCraft Design Handoff - Iteration 1 (canonical design tokens & shared Neo-Brutalist components)

- [x] Refactor `ReTokens` (`apps/mobile/lib/core/theme/re_tokens.dart`) as the single canonical design token source with the approved FigCraft palette, spacing, border, radius, and hard-shadow tokens while preserving compatibility tokens (`error`, `forest`, `contentWidth`, `controlHeight`).
- [x] Implement consistent Neo-Brutalist typography scale and theme rules in `AppTheme.onboarding` (`apps/mobile/lib/core/theme/app_theme.dart`) while preserving `AppTheme.light` for debug validation.
- [x] Implement and refactor shared Neo-Brutalist components (`RePageScaffold`, `ReBrandMark`, `RePrimaryButton` / `RePrimaryAction`, `ReSecondaryButton`, `ReTextField`, `ReChip`, `ReSectionHeader`, `ReFormHeading`, `ReStatusBanner` / `ReStatusNotice`, `ReEmptyState`).
- [x] Add widget and unit tests for token contrast/compatibility, `ReBrandMark`, button states, input validation & password visibility, chips/headers/banners/empty states, touch targets, and `2.0x` large-text scaling on `320×640` screens.
- [x] Run `dart format`, `flutter analyze`, `flutter test` (51 passed), and `git diff --check`. See [Iteration 1 Status](docs/design/ITERATION_1_STATUS.md).
- [ ] Owner approval before Iteration 2 (Authentication UI Redesign).

## FigCraft Design Handoff - Iteration 0 (repository integration & audit)

- [x] Verify application repository (`D:\Mulia\hackgdgocitb\rekan`) and design workspace (`D:\Mulia\rekan ui ux`).
- [x] Integrate approved design specifications, FigCraft audit deliverables, exported tokens (`docs/design/tokens/`), and Code Connect metadata (`docs/design/code-connect/`) into `docs/design/` without overwriting `docs/design/README.md`.
- [x] Audit existing Flutter architecture, widgets, controllers, DTOs, and 45 tests against the 21 FigCraft component families.
- [x] Resolve design token conflicts into a single canonical `ReTokens` architecture and verify font licensing (`Plus Jakarta Sans`, `Montserrat`, `Inter` under OFL-1.1) without adding dependencies.
- [x] Verify Laravel API contracts (`GET /api/v1/me`, `GET/PUT /api/v1/me/academic-profile` 10-field whitelist) and classify screen readiness in [Repository Integration Audit](docs/design/REPOSITORY_INTEGRATION_AUDIT.md).
- [x] Run `flutter analyze`, `flutter test` (45 passed), and `git diff --check` with existing functionality unchanged.
- [ ] Owner approval before Iteration 1 (Design Tokens & Shared Neo-Brutalist Components).

## Phase 2E.2 - Iteration B

- [x] Welcome, login, registration, email-verification status and safe recovery entry point in Bahasa Indonesia.
- [x] Reuse SDK/secure storage; verify restored sessions, lock protected content on failure, discard stale account results, explicit local logout.
- [x] Preserve debug validation flag and completed profile/API functionality; no onboarding or catalog routing.
- [x] Inspect public development Auth settings: email enabled, signup enabled, confirmation required; document missing recovery callback and hosted configuration limits.
- [x] Build/install/launch normal UI on existing Android emulator without clearing data.
- [x] Dart formatting, analysis and editor diagnostics clean; all 45 Flutter tests pass. See [Iteration B report](docs/architecture/phase-2e2-iteration-b-status.md).
- [ ] Manual B authentication/email/logout/recovery acceptance (UI capture helper unavailable); do not treat launch as E2E success.
- [ ] Owner approval before Iteration C.

## Phase 2E.2 - Iteration A only

- [x] Audit existing implementation/contracts and present design proposal before edits.
- [x] Document flows, screen/component inventory, navigation, completion proposal, missing catalog/recovery contracts and risk boundaries in [Phase 2E.2 plan](docs/architecture/phase-2e2-plan.md).
- [x] Add reusable design tokens, opt-in theme and form page/heading/action/status components; preserve existing debug flag and active app shell.
- [x] Dart formatting applied; Flutter analysis clean; 33 tests pass including contrast, busy action/semantics, narrow large-text/keyboard layout and wide content width. No live E2E claim for A.
- [x] Owner authorized Iteration B; completion rules deferred because B has no onboarding routing. Public Auth settings inspected; recovery configuration limitation documented in B report.
- [ ] Later C/D: approved catalog contract, onboarding, integration/device QA; no implementation in A.

## Phase 2E.2 — Iteration A only

- [x] Audit existing implementation/contracts and present design proposal before edits.
- [x] Document flows, screen/component inventory, navigation, completion proposal, missing catalog/recovery contracts and risk boundaries in [Phase 2E.2 plan](docs/architecture/phase-2e2-plan.md).
- [x] Add reusable design tokens, opt-in theme and form page/heading/action/status components; preserve existing debug flag and active app shell.
- [x] Dart formatting applied; Flutter analysis clean; 33 tests pass including contrast, busy action/semantics, narrow large-text/keyboard layout and wide content width. No live E2E claim for A.
- [ ] Owner checkpoint: approve Iteration B and completion rule; confirm Auth email/password/callback configuration. Do not begin B yet.
- [ ] Later C/D: approved catalog contract, onboarding, integration/device QA; no implementation in A.

## Phase 2E.1 Flutter API integration — complete

- [x] Reuse Supabase secure sessions; typed Laravel client, bounded refresh and session-change protection.
- [x] Schema-matching profile DTOs/repository and loading/empty/success/error states.
- [x] Debug-only dummy validation, exact payload/UUID confirmation and fresh empty-profile checks.
- [x] Atomic server empty-profile precondition; compare PUT and GET against submitted data.
- [x] Real Android PUT/GET manually confirmed by owner: success, UUID correspondence, matching values.
- [x] Independently verify dummy PostgreSQL persistence and single identity/profile/preference records read-only.
- [x] Inspect available historical evidence: first identity remains present; lack of pre-PUT snapshots explicitly limits claims that other users were unchanged.
- [x] Final regressions: Flutter analyze clean, 29 Flutter tests, 73 Laravel tests / 507 assertions, Pint and PostgreSQL/Redis checks pass.
- [x] Update implementation plan, [status](docs/architecture/phase-2e1-status.md) and [final E2E evidence/limitations](docs/testing/phase-2e1-real-integration.md).
- [ ] Optional remaining real-device coverage: profile-specific logout clearing/live refresh (not newly verified during finalization).
- [ ] Review/authorize Phase 2E.2; final onboarding UI has not started.

## Phase 2D academic profile API

- [x] Audit Phase 2C schema and missing models; retain and document scoped/global course uniqueness.
- [x] Add Eloquent models and relationships for all Phase 2C tables, including composite-key pivot models.
- [x] Preserve GET /me and implement GET/PUT /me/academic-profile with verified JWT identity and owner policy.
- [x] Validate complete payloads, catalog references, course/university consistency, duplicate relationships and protected fields.
- [x] Use transactions and user-row locks; prove rollback of late database failures and preservation of other users/identity data.
- [x] Run full PostgreSQL-backed suite: 71 tests / 537 assertions; Pint and PostgreSQL/Redis checks pass.
- [x] Update [API contract](docs/architecture/04-api-contract.md), implementation plan and [Phase 2D report](docs/architecture/phase-2d-status.md).
- [ ] Review before Phase 2E; Flutter onboarding/profile integration has not started.

## Phase 2C academic database

- [x] User authorizes Phase 2C; preserve Supabase UUID identity and local domain database.
- [x] Extend existing users and add universities, academic_profiles, courses, skills, user_skills, user_courses and academic_preferences.
- [x] Add foreign keys, composite/partial unique indexes, range/enumeration checks and private visibility default.
- [x] Document minimal nullable preference fields and historical scope contradictions.
- [x] Pass full PostgreSQL-backed suite: 50 tests / 306 assertions, including 23 academic schema tests; Pint passes.
- [x] Test rollback/reapply in disposable schemas; apply additive migration locally and retain one existing identity record.
- [x] PostgreSQL/Redis checks pass; existing API routes unchanged.
- [x] User authorized Phase 2D against the Phase 2C schema; see [Phase 2C status](docs/architecture/phase-2c-status.md) for historical assumptions.

## Phase 2B.1 E2E validation

- [x] Inspect Flutter SDK and Laravel authentication middleware.
- [x] Match public mobile/backend Supabase configuration without copying secrets.
- [x] Add debug-only login, `/me` UUID comparison, restoration check and logout harness.
- [x] Add read-only local UUID record count command.
- [x] Pass Flutter analyze/6 tests and Laravel 27 tests/128 assertions plus Pint.
- [x] Android emulator integration test passes: host API reachable, missing/invalid tokens rejected with 401.
- [x] User confirms real development-account login, repeated login and matching `/me` UUID.
- [x] Independent read-only inspection confirms exactly one local PostgreSQL record for `e41527c8-7e48-46f6-8057-62420c6a4c80` after the reported repeated requests.
- [x] User confirms restored-session verification twice, logout and missing-token rejection.
- [x] User confirms session recovery after new login and force-stop/relaunch; no agent UI replay claimed.
- [x] Rerun Flutter/Laravel regressions, Pint, local PostgreSQL/Redis checks and route listing successfully.
- [x] Review E2E evidence and distinguish manual results, independent checks and untested cases in the [validation report](docs/testing/phase-2b1-auth-e2e.md). Final live HTTP recheck could not connect to port 8000.
- [x] User authorized Phase 2C after Phase 2B.1 review; see current checkpoint above.

## Current Phase 2A checkpoint

Phase 2B is implemented after explicit development-only owner confirmation. See [Phase 2B report](docs/architecture/phase-2b-status.md). This checkpoint is historical; current Phase 2C status is above.

- [x] Verify signatures, issuer/audience/expiry/UUID and allowed algorithms using configured JWKS.
- [x] Bound JWKS cache/rotation, fail closed and rate-limit requests.
- [x] Implement authenticated `/api/v1/me`, idempotent UUID provisioning and standardized errors.
- [x] Apply identity-only users migration to guarded local PostgreSQL without overwriting data.
- [x] Test security, ownership denial and reversible migrations on isolated PostgreSQL schemas.
- [x] User confirms real Supabase login/access-token round trip in Phase 2B.1; see the E2E report for provenance.
- [x] User authorized Phase 2C following Phase 2B.1 validation.

- [x] Inspect required documents and configuration presence without exposing secrets.
- [x] Add Supabase Flutter SDK and project-scoped secure session/PKCE storage.
- [x] Validate public compile-time configuration; preserve unconfigured shell.
- [x] Document database strategy and contradictions in [Phase 2A status](docs/architecture/phase-2a-status.md).
- [x] Confirm Supabase Cloud Auth, local Docker domain PostgreSQL, local Redis and canonical Supabase UUID architecture.
- [x] Consolidate duplicate Supabase settings, preserve credentials, validate issuer/JWKS/audience through Laravel configuration.
- [x] Run Flutter analysis/tests, Laravel routes/Pint/tests, Compose/connection checks and HTTP health smoke tests.
- [x] Owner confirms configured project is exclusively development/testing, with no production use/data.
- [x] Remove Laravel's dormant merged password/session defaults in Phase 2B.
- [x] User confirms real Supabase session recovery on Android after force-stop/relaunch (separate from mocked storage tests).

The user reports emulator startup has passed. Historical Phase 1 checklist follows.

- [x] Read all requested architecture kit files and inspect the existing project.
- [x] Record differences before implementation; preserve original kit and Android sources.
- [x] Initialize Git and monorepo destination directories.
- [x] Configure PostgreSQL/Redis Compose with local-only ports, persistent volumes and health checks.
- [x] Add environment templates; generate ignored local database credentials.
- [x] Add setup/development/check scripts and documentation.
- [x] Prepare minimal health controller, versioned route and alias, and HTTP feature tests as overlays.
- [x] Prepare Flutter shell, theme, public config and widget test as overlays.
- [x] Validate PowerShell syntax and Compose configuration.
- [x] Generate Flutter under apps/mobile (Flutter 3.50.0 / Dart 3.14.0).
- [x] Generate Laravel under services/api (Laravel 12.72.0 / PHP 8.5.12).
- [x] Install and lock dependencies; apply overlays and run formatters.
- [x] Run Flutter doctor, analyze and widget tests; see validation report for Android warnings.
- [x] Build Android debug APK successfully with the installed Flutter SDK.
- [ ] Verify emulator startup (AVD remains offline); resolve Android command-line tools/license-status warnings.
- [x] Run Laravel route list, feature tests and Pint (5 tests, 16 assertions).
- [x] Start Docker PostgreSQL/Redis and verify healthy state.
- [x] Verify actual Laravel PostgreSQL SELECT 1 and both Redis PING connections.
- [x] Start Laravel and verify both HTTP liveness routes (200, exact JSON).
- [x] Fix PHP 8.5 deprecations, DB_SSLMODE, Redis driver, unused storage routes and theme cast.
- [x] Pin Flutter SDK and configure CI using actual generated projects and lockfiles.
- [ ] Observe hosted CI run; workflow is configured locally only.
- [ ] Review and commit the validated foundation checkpoint.
- [ ] Mark Phase 1 validated before proceeding to identity.

Historical Phase 1 review: 2026-11-13. Current status: Phase 2D implemented and validated; Phase 2E not started. See [validation](docs/testing/phase-1-validation.md) and the [Phase 2 proposal](docs/architecture/phase-2-plan.md).

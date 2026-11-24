# Implementation plan

## Integration 3.2 - Real onboarding validation (blocked on manual sign-in)

Restored existing local services and emulator without resets; health/dependency checks and 68 Flutter regressions pass. Added an explicit GET-only Android test using the existing SDK session. Its actual device run failed at the prerequisite: no SDK session restored, so authenticated GETs were not reached. Manual development-account sign-in is needed. Real visual validation is also blocked by computer-use capture showing the editor behind the emulator; profile PUT remains gated on verified identity/current data and explicit approval. Full-row database fingerprints remain identical to the pre-validation baseline. See [Integration 3.2 evidence](docs/testing/INTEGRATION_3_2_E2E.md); do not treat automated tests as full E2E acceptance or begin Iteration 4.

## Integration 3.2 - Real onboarding validation (in progress)

Restored existing local services and emulator without resets; health/dependency checks and 68 Flutter regressions pass. Added an explicit GET-only Android test using the existing SDK session. Real visual validation is blocked by computer-use capture showing the editor behind the emulator; profile PUT remains gated on verified identity/current data and explicit approval. Full-row database fingerprints remain identical to the pre-validation baseline. See [Integration 3.2 evidence](docs/testing/INTEGRATION_3_2_E2E.md); do not treat automated tests as full E2E acceptance or begin Iteration 4.

## Integration 3.1 - Flutter academic catalogs (2026-11-16)

Connected onboarding Steps 2–4 to authenticated Laravel catalog reads using the existing LaravelApi instance. Added typed search and batched UUID lookup, searchable selectors with loading/empty/retry states, preserved selection labels/skill levels, and explicit confirmation before removing incompatible courses on university changes. Global courses and drafts survive recoverable errors; account changes invalidate results and close pending confirmation dialogs. Formatter applied, analyze clean, 68 Flutter tests passed, whitespace check clean. Real E2E remains unverified: no connected emulator/device and no Laravel listener on port 8000. See [Integration 3.1 status](docs/design/INTEGRATION_3_1_STATUS.md). Stop before Iteration 4 pending approval.

## Backend Sprint A.1 - Development academic catalog seed (2026-11-16)

Completed the authorized insert-only local seeder: 4 universities, 8 global courses, 10 normalized skills. Actual environment/schema/constraints verified before application; second run inserted zero and full-row comparisons preserved all users/profiles/preferences/selections. Development fixtures are not verified official offerings. Authenticated catalog checks against committed PostgreSQL returned 200 with 4/8/10 items using process-local JWT fixtures. Laravel: 92 tests / 1413 assertions; Pint passed. See [Sprint A.1 report](docs/architecture/BACKEND_SPRINT_A1_STATUS.md). Stop after seeding and verification; no Flutter or future backend modules.

## Backend Sprint A - Academic Catalog REST API (2026-11-16)

Implemented authenticated GET `/api/v1/universities`, `/courses`, and `/skills` using existing Supabase middleware, parameterized Eloquent queries, strict query validation, bounded deterministic results, and response allowlists. Course filtering includes selected-university and global records. Live PostgreSQL columns/indexes/constraints match migrations; all three catalogs contain zero records. No development seed or migration was run. PostgreSQL feature tests use disposable transactional schemas. See [Sprint A status](docs/architecture/BACKEND_SPRINT_A_STATUS.md) for final validation and the fictional development seed proposal. Stop after Sprint A; seeding and further backend/Flutter integration require approval.

## FigCraft Design Handoff - Iteration 3 (Academic Onboarding UI & Laravel Integration)

Implemented the 5-step Neo-Brutalist Academic Onboarding flow (`Identitas Akademik`, `Universitas, Program Studi & Semester`, `Keahlian dan Minat`, `Mata Kuliah Aktif`, `Preferensi Belajar & Review` matching FigCraft `Screen 9` `id: 760`), `AcademicOnboardingCompletion` (`display_name`, `university_id`, `program`, `semester` required; optional fields never block), `OnboardingDraftController`, and `AcademicOnboardingBoundary` wired to `AcademicProfileRepository`, `AcademicProfileInput`, `ProfileController`, `LaravelApi`, and `SupabaseApiSession`. Preserves drafts across step navigation and recoverable errors, blocks duplicate submissions, protects non-empty profiles (`X-Re-Require-Empty-Profile: true` on initially empty profiles), preserves untouched `university_id`/`courses`/`skills`/`visibility` fields, and wipes drafts on account switches. Documented missing read-only catalog endpoints (`GET /api/v1/universities`, `/courses`, `/skills`) and proposed the smallest secure Laravel contract without fabricating catalog UUIDs. `dart format`, `flutter analyze`, 57 Flutter tests, and `git diff --check` pass. See [Iteration 3 Status](docs/design/ITERATION_3_STATUS.md). Stop before Iteration 4 pending owner approval.

## FigCraft Design Handoff - Iteration 2 (Authentication UI redesign)

Redesigned all user-facing authentication screens (`WelcomePage` `id: 434`, `AuthForm` Login/Register `id: 473`, `Email Verification`, `Password Recovery Explanation`, `checking`, `sessionError`, and `authenticated` placeholder) in `apps/mobile/lib/features/auth/` using the canonical Neo-Brutalist design system (`RePageScaffold`, `ReBrandMark`, `RePrimaryButton`, `ReSecondaryButton`, `ReTextField`, `ReChip`, `ReSectionHeader`, `ReStatusBanner`). Replaced all user-facing `'Re'` brand references with `'Re:kan'` while preserving `SupabaseAuthGateway`, `AuthController`, `SecureAuthStorage`, and `AuthValidationPage` untouched. `dart format`, `flutter analyze`, 52 Flutter tests, and `git diff --check` pass. See [Iteration 2 Status](docs/design/ITERATION_2_STATUS.md). Stop before Iteration 3 pending owner approval.

## FigCraft Design Handoff - Iteration 1 (canonical design tokens & shared Neo-Brutalist components)

Refactored `ReTokens` (`apps/mobile/lib/core/theme/re_tokens.dart`) into the single canonical token source integrating the approved FigCraft palette (`#111111` ink, `#FFFDF5` paper, `#FFFFFF` surface, `#F2F0E8` mutedSurface, `#626262` mutedText, `#FFE500` primaryYellow, `#16C7C1` accentTeal, `#F22DBB` accentMagenta, `#1FA86A` success, `#F2A900` warning, `#E5484D` danger, `#B3261E` standalone error text), spacing/border/radius/hard-shadow scales, and `AppTheme.onboarding` typography (`DESIGN_SYSTEM.md` §4). Implemented shared Neo-Brutalist components (`RePageScaffold`, `ReBrandMark`, `RePrimaryButton` / `RePrimaryAction`, `ReSecondaryButton`, `ReTextField`, `ReChip`, `ReSectionHeader`, `ReStatusBanner` / `ReStatusNotice`, `ReEmptyState`) reusing `ReFormPage` and `ReFormHeading` without duplication. `dart format`, `flutter analyze`, 51 Flutter tests (45 existing + 6 new Iteration 1 tests), and `git diff --check` pass. See [Iteration 1 Status](docs/design/ITERATION_1_STATUS.md). Stop before Iteration 2 pending owner approval.

## FigCraft Design Handoff - Iteration 0 (repository integration & audit)

Approved FigCraft design documentation, audit deliverables, exported design tokens (`docs/design/tokens/`), and Code Connect metadata (`docs/design/code-connect/`) integrated into `docs/design/` while preserving `docs/design/README.md` and all existing Flutter/Laravel code. Full component reuse matrix, canonical `ReTokens` conflict resolution, font licensing check, and screen-by-screen API readiness verified in [Repository Integration Audit](docs/design/REPOSITORY_INTEGRATION_AUDIT.md) and [Design-to-Code Plan](docs/design/DESIGN_TO_CODE_PLAN.md). `flutter analyze`, all 45 Flutter tests, and `git diff --check` pass. Stop before Iteration 1 pending owner approval.

## Phase 2E.2 - Iteration B

Authentication screens and session-aware boundary implemented using the existing Supabase SDK and design foundation. Debug override preserved; authenticated users reach a safe placeholder, not onboarding. Actual public Auth settings confirm confirmation-required email signup. Recovery remains explanatory until owned callbacks/reset UI are configured. See [B report](docs/architecture/phase-2e2-iteration-b-status.md). Dart formatting and analysis pass; all 45 Flutter tests pass. Debug APK built, installed and launched preserving data; real new-UI auth E2E remains unverified because computer-use capture was unavailable. Stop before Iteration C pending owner approval.

## Phase 2E.2 - Iteration A (audit and design foundation)

Approved scope is A only; B requires a new owner approval. See [the implementation proposal](docs/architecture/phase-2e2-plan.md) for flows, components, navigation, catalog/recovery dependencies and risks.

1. Audit implemented Flutter, Supabase/session and Laravel contracts: complete.
2. Present proposal before editing: complete. Reuse current stack/state management with no new dependencies.
3. Add isolated tokens, opt-in onboarding theme and shared form primitives: complete; active navigation/theme unchanged.
4. Verification complete: Dart editor formatter applied; flutter analyze clean; all 33 Flutter tests pass (29 existing plus four foundation cases). No emulator visual QA or live auth/profile requests performed in A.
5. Stop before B. Confirm proposed completion requirements and nonsecret Auth email/password/callback settings before auth implementation; catalog extension approval/data availability blocks C selectors.

## Phase 2E.2 — Iteration A (audit and design foundation)

Approved scope is A only; B requires a new owner approval. See [the implementation proposal](docs/architecture/phase-2e2-plan.md) for flows, components, navigation, catalog/recovery dependencies and risks.

1. Audit implemented Flutter, Supabase/session and Laravel contracts: complete.
2. Present proposal before editing: complete. Reuse current stack/state management with no new dependencies.
3. Add isolated tokens, opt-in onboarding theme and shared form primitives: complete; active navigation/theme unchanged.
4. Verification complete: Dart editor formatter applied; flutter analyze clean; all 33 Flutter tests pass (29 existing plus four foundation cases). No emulator visual QA or live auth/profile requests performed in A.
5. Stop before B. Confirm proposed completion requirements and nonsecret Auth email/password/callback settings before auth implementation; catalog extension approval/data availability blocks C selectors.

## Phase 2E.1 — complete (2026-11-15)

1. Flutter session/API integration, typed DTOs/repository and profile states: complete.
2. Debug dummy validation with explicit UUID/payload approval and atomic empty-profile protection: complete.
3. Real Android PUT/GET: PASS by owner manual observation; dummy data independently verified persisted in local PostgreSQL with one identity/profile/preference row.
4. Final regressions: Flutter analyze clean, 29 Flutter tests, 73 Laravel tests / 507 assertions, Pint and local PostgreSQL/Redis checks pass.
5. Historical non-interference limitation recorded: no pre-PUT snapshot proves other users' prior fields unchanged. Current first-account identity count is one; no other profile rows currently exist. Automated preservation tests pass separately.
6. Stop before Phase 2E.2; no onboarding UI implementation authorized here.

See [final validation evidence](docs/testing/phase-2e1-real-integration.md) and [status](docs/architecture/phase-2e1-status.md). Earlier checkpoints below are historical.

Current milestone: user-authorized Phase 2D completed. See [audit, implementation and validation](docs/architecture/phase-2d-status.md).

1. Audit Phase 2C schema, missing Eloquent models and JWT boundaries: done. Retain global course-code uniqueness for a curated shared catalog; university-scoped codes remain independent.
2. Add all academic models and inverse relationships, plus explicit owner policy: done.
3. Preserve identity GET /me; add authenticated GET/PUT /me/academic-profile with complete input validation and transactional multi-table replacement: done.
4. Run isolated PostgreSQL integration/security/rollback tests, full Laravel regressions, Pint and infrastructure checks: done (71 tests, 537 assertions).
5. Update API contract/checklist/status and stop before Phase 2E: done. Flutter onboarding requires separate authorization.

The historical Phase 1 plan below is retained; its statements about unimplemented identity/domain work describe that earlier checkpoint.

1. Inspect the existing project and the complete architecture kit. **Done.**
2. Preserve the native Android project and kit; initialize a Git monorepo and required directories. **Done.**
3. Configure loopback-only local Postgres/Redis, health checks, safe environment templates and setup scripts. **Done; Compose configuration validated.**
4. Generate real Laravel 12 and Flutter stable projects using installed supported toolchains. **Done: Laravel 12.72.0 and Flutter 3.50.0 exist with lockfiles.**
5. Apply the minimal public health controller/tests and feature-based Flutter shell/test. **Done: HTTP liveness, Laravel tests and Flutter widget test verified.**
6. Validate formatter, routes, Laravel tests, Flutter doctor/analyze/tests, Android debug build, running containers and HTTP smoke. **Partially checked; see validation report.**
7. Pin the actual Flutter SDK and add CI using generated lockfiles. **Configured; hosted CI run and validation checkpoint pending.**

No matching, authentication, chat, notifications, domain schema or full screens are implemented. No architectural stack changes are proposed. Infrastructure rollback is `scripts/dev.ps1 -Target infra-down`, preserving volumes. Generated source stays in its own directories and the existing Android project remains intact.

After all Phase 1 gates pass, the next phase is Supabase identity: JWT signature/issuer/audience/expiry verification, UUID provisioning, student gating, secure Flutter sessions and negative authorization tests. Product questions in the preserved architecture kit remain open.

The [Phase 2 proposal](docs/architecture/phase-2-plan.md) requires explicit user approval after Phase 1 closes. No Phase 2 work has started.

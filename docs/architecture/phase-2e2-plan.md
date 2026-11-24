# Phase 2E.2 — authentication and academic onboarding

## Scope and checkpoint

Iteration B validation: Dart formatting applied, analysis clean, 45 Flutter tests passed. Android debug build/install/launch succeeded with preserved app data. Real new-UI auth/email/recovery validation is not claimed; manual checks and configuration blockers are recorded in the B report. Await owner approval before C.

Iteration B update (2026-11-15): owner authorized authentication UI only. Welcome/login/registration/email status/recovery explanation and SDK-session-aware placeholder routing are implemented. No onboarding routing or completion predicate is applied. Public project settings confirm email confirmation is required; mobile recovery configuration is missing. See [Iteration B report](phase-2e2-iteration-b-status.md) for exact configuration steps, tests and limits. Stop before C. The A checkpoint and proposed C/D work below are historical/planned context.

2026-11-15: Iteration A only. Audit and design foundation implemented; Iteration B requires owner approval. No user-facing auth/onboarding routes, SDK calls, domain writes, catalog endpoints or new dependencies introduced here. Existing app theme/navigation and the debug validation flag remain active as before. This document distinguishes implemented foundation from proposed later behavior.

## Audit: implemented authority

- Flutter uses `material_ui`, `supabase_flutter`, `flutter_secure_storage`, native HTTP and ChangeNotifier. No Riverpod, router package or Dio is required. The installed SDK/test dependencies suffice for A; revisit platform link support only in B.
- `main.dart` initializes the SDK and secure project-scoped storage. Auto-refresh is on; callback session detection is explicitly off. No Android auth deep-link intent filter is configured. Do not read/export stored sessions to develop the UI.
- `app.dart` selects the debug harness only for debug + AUTH_E2E_ENABLED + valid config; otherwise the foundation shell. Preserve this override before future production routing.
- The current session adapter tracks UUID and login generation. The API client checks both around requests/refreshes. Reuse this behavior and its one-refresh limit. SDK session presence alone does not prove API authorization.
- Only health, GET /me and GET/PUT /me/academic-profile are implemented. Profile DTOs cover ten writable fields. PUT replaces all fields/relationships, so a form must preserve untouched loaded values, including selections whose labels are temporarily unavailable.
- ProfileController clears its read model on load/errors. A future form needs a separate in-memory draft; never bind editable fields directly to that transient read state.
- [Phase 2D](phase-2d-status.md) and [Phase 2E.1 acceptance](../testing/phase-2e1-real-integration.md) establish owner policies, transactions and real manual dummy persistence. Historical reports mentioning unimplemented later phases are not current contracts. `isEmpty` is not onboarding completeness.

## Missing capabilities and proposed decisions

| Gap | Smallest compatible proposal | Gate |
| --- | --- | --- |
| University/course/skill directory routes do not exist | Add authenticated read-only GET /universities, /courses, /skills under /api/v1, matching the existing proposed inventory; no schema/catalog writes | Approve concrete contract before C; no calls to these routes in A |
| No catalog pagination/search/label contract | Proposed bounded `q` (max 100), `limit` (1–50, default 20), opaque cursor; `{data: [...], next_cursor, request_id}`; stable name/id order. University `{id,name}`; course `{id,university_id,code,name}`; skill `{id,normalized_name}`. Course filter includes selected university and global courses; null filter returns globals. Add bounded ID lookup to resolve existing selected labels, with independent validation/tests | Proposal only; confirm catalog ownership/curated data availability, never fabricate choices |
| No completion rule | Proposed UI readiness: persisted nonblank display_name, nonnull university_id, nonblank program and semester 1–20. Other fields optional. This is navigation only, not student verification or matching eligibility | Confirm with B approval before routing implementation; backend currently allows nulls |
| Email confirmation policy, password requirements and recovery destination not recorded | Inspect development Supabase Auth settings with owner-provided nonsecret values; handle sign-up responses both with and without a session. Use configured password policy, never invent server enforcement | Before B registration acceptance |
| Recovery/mobile callback missing | Agree owned app-link/custom URI, platform registration, Supabase allowlist and email-template behavior. Recovery event must route to password reset rather than onboarding; await actual SDK session verification | Before claiming functional recovery. No cloud settings changed in A |
| No optimistic concurrency for normal edits | Keep loaded snapshot and draft; re-fetch before explicit save, offer reload/review on differences. Document residual concurrent-edit race; propose ETag/version precondition separately if strict conflict prevention is required | No silently invented version fields |
| No interests/availability/learning-goal schema | Omit separate controls. Bio is optional academic context, not a structured interests store | No extra persisted properties |

Catalog failure must retain selections and show “Pilihan belum tersedia. Coba lagi.” Do not silently replace missing selections with empty arrays or offer invented “Universitas lain” UUIDs. If university remains required, completion waits for real catalog availability; changing that rule requires an explicit product decision. Existing null-university dummy profiles will remain incomplete under the proposed rule.

## User flows and screen inventory (planned B–D)

1. Startup: initializing → signed out / verifying authenticated profile / recoverable error. Network errors offer retry without destroying session or draft. Missing config shows a safe unavailable state, not fake auth.
2. Signed out: Welcome (“Temukan rekan untuk belajar dan berkarya.”; Daftar / Masuk) → login or registration. Native form/autofill, password visibility with Indonesian accessibility labels, inline validation and disabled duplicate submit.
3. Registration: email/password/confirmation → verification-pending if SDK returns no session (“Periksa emailmu”) or verified-session loading if session returned. Generic resend/recovery messages avoid account enumeration. Confirmation-required users are not routed to protected screens merely because a user object exists.
4. Recovery: email entry → generic sent state → configured recovery callback → new password/confirmation → explicit return to normal routing. No fake success when configuration is absent.
5. Authenticated: GET /me and profile → incomplete profile opens onboarding; complete profile opens existing shell with a clear “Profil akademik” entry point added later. Never imply matching/recruitment exists. 401 terminal failure locks protected content and offers sign-in; 403 shows access denied; no refresh loop.
6. Logout/account switch: invalidate requests/draft, reset navigation stack, return to welcome; do not leave protected pages reachable through back. Drafts are memory-only, discarded on account boundaries, not persisted in plaintext.

Onboarding uses five steps, with a visible text counter “Langkah 2 dari 5”:

| Step | Fields / behavior |
| --- | --- |
| Identitas akademik | display_name, university_id, program, semester; explicit labels/required markers; reuse validation lengths from contract |
| Keahlian | optional skills and level 1–5; no inferred ratings or fake skills |
| Mata kuliah | optional scoped/global courses; university changes require explicit review/removal of incompatible selections |
| Cara belajar | optional study mode/language, bio, MBTI; visibility private by default, retain explicit existing choice; MBTI has no completion or matching influence |
| Tinjau profil | human-readable summary, edit/back, single “Simpan profil” operation; only successful persisted response changes completion routing |

Back preserves values/errors. Cancel with unsaved changes asks before discarding. An existing non-empty profile opens a populated edit draft and is saved only by explicit action. Empty first-time initialization may use the existing atomic empty precondition. On failed/uncertain PUT, retain draft and retrieve current data before another explicit save; no compensating writes or blind retry. Never send `user_id`.

## Design foundation (implemented A, opt-in)

The visual identity retains existing forest green; warm paper backgrounds, strong dark text and restrained outlined controls support an academic reading/form experience. No decorative gradients, blobs, oversized cards or external font/network dependency.

| Token | Value / use |
| --- | --- |
| Forest / ink | #245C45 action; #182B24 body |
| Paper / surface | #F7F8F4 page; #FFFFFF input/surface |
| Muted / outline / error | #52645B secondary text; #718078 control border; #B3261E error |
| Spacing | 4, 8, 16, 24, 32 logical pixels |
| Type | Native system font; headings 28/22, body 16/14, line heights 1.2–1.5; never disable scaling |
| Controls | Minimum 48-pixel target, 12-pixel corners, no fixed text heights |
| Layout | SafeArea, keyboard-resizing Scaffold, scrollable form, max width 560, 24-pixel gutter |
| Motion | 180ms token for future focus/step feedback; respect reduced motion; no required animation in A |

`AppTheme.onboarding` is opt-in; existing `AppTheme.light` remains unchanged. Components are presentational only: `ReFormPage` → `ReFormHeading`, standard TextFormField/selection controls (later), `ReStatusNotice`, `RePrimaryAction`. Status uses text and icon, live announcements, busy action blocks taps and retains a readable Indonesian label. Inputs retain native focus/error semantics. A does not implement a new field framework or route.

## UI architecture and navigation plan

- `core/theme`: tokens and opt-in theme; `core/widgets`: shared form primitives.
- B: `features/auth` presentation/controller plus a small injectable adapter over the existing Supabase client, not another session manager. Root coordinator observes existing session source/events and builds a session-keyed Navigator/pages stack using SDK Flutter navigation. No router dependency needed for this bounded flow; revisit only for approved deep-link requirements.
- C: `features/onboarding` owns draft, step index, field validation, dirty/saving state; existing academic repository owns network persistence. Profile view/edit reuses draft/form sections.
- Root and feature controllers use ChangeNotifier/ListenableBuilder. Dispose listeners/controllers; drop stale async results by generation. Auth errors translate typed categories to safe Bahasa Indonesia rather than raw SDK/server strings.
- Keep debug validation override unchanged. Do not switch production home during A. No Laravel changes in A.

## Controlled delivery and verification

A: audit + proposal + tokens/components + this plan; format through Dart tooling; analyze and Flutter regression/widget tests. Tests cover text contrast, tap height/busy action, accessible label, narrow viewport with 200% text/keyboard inset, and wide width constraint. Widget layout tests are not device screenshots or full accessibility certification.

B (approval required): auth screens/session navigation and mocks for validation, loading, duplicate submit, verification variants, safe errors, expired sessions, recovery event and account switching. Confirm nonsecret Supabase settings/callback first. No actual logout/session clearing without owner authorization.

C (after B acceptance): agree and independently test catalog extension, draft navigation/back preservation, full payload preservation, nulls and review/save. Completion predicate unit tests include partial/non-empty profiles. Catalog failure cannot erase selections.

D: mock integration failures, race/session changes, save response reconciliation; real emulator review at small/large text, keyboard/TalkBack/reduced motion; restore/logout and approved profile writes with before/after snapshots. Never delete database data to test. Report manual evidence separately from mocks. No E2E claim for A; no account or cloud configuration mutations.

## Iteration A results

Iteration A complete: Dart editor formatter applied to all four changed/new Dart files; flutter analyze reports no issues; all 33 Flutter tests pass (29 existing plus four design foundation cases). Initial test-only semantics cleanup and ambiguous scroll targeting failures were corrected before the successful rerun. Editor diagnostics are clean. No emulator screenshots, TalkBack/device testing, new real authentication, profile mutation, Laravel tests or cloud changes performed for this presentational-only iteration. Existing runtime theme/navigation and secure storage remain unchanged.

Changed files: `apps/mobile/lib/core/theme/re_tokens.dart`, `apps/mobile/lib/core/theme/app_theme.dart`, `apps/mobile/lib/core/widgets/re_form_components.dart`, `apps/mobile/test/design_foundation_test.dart`, this plan, `flutter-client.md`, root implementation plan and checklist.

Stop before B. Approval for B should confirm the proposed completion fields and provide/confirm email verification/password policy and recovery callback configuration. Catalog contract approval/data availability blocks C selectors, not the presentational foundation. Manual visual QA is deferred to actual screens in B/C: test small Android viewport, keyboard, 200% text, TalkBack focus order and reduced motion without clearing app data or logging out existing sessions.

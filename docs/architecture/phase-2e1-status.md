# Phase 2E.1: Flutter architecture and API integration

## Final status: complete — 2026-11-15

Owner-reported real Android PUT/GET passes: success state, matching authenticated/profile UUIDs and submitted dummy values matching both responses. Independent read-only PostgreSQL verification found one exact dummy profile, one identity and one preference row, with no course/skill links; the same result remained after regression tests. Final checks: Flutter analyze clean, 29 Flutter tests, 73 Laravel tests / 507 assertions, Pint and PostgreSQL/Redis checks pass.

Limitation: no pre-PUT snapshot exists to prove other users' fields/profiles were unchanged historically. The first account still exists once, and no other academic profile rows currently exist; fixture preservation/ownership tests pass. Real profile-specific logout clearing/live refresh were not newly tested. See the [final evidence matrix](../testing/phase-2e1-real-integration.md). No application data was changed during finalization. Stop before Phase 2E.2.

## Historical implementation and validation notes

Runtime follow-up (2026-11-15): services and emulator are now running; current APK build/launch, live host-side missing/invalid-token 401s, Flutter analysis and all 22 tests pass. Emulator UI geometry prevents authenticated screen validation; no PUT was sent. See the [PASS/FAIL/NOT TESTED report and manual handoff](../testing/phase-2e1-real-integration.md). Earlier runtime-unavailable observations below are historical.

Implemented 2026-11-15. Stop before Phase 2E.2 UI.

Latest harness fix: replaced loaded-value resubmission with an explicit private dummy payload, session-derived UUID confirmation, `/me` verification and empty GET checks before/after approval. Added optional server-enforced empty-profile precondition under the existing transaction lock, preventing concurrent profile edits from being overwritten. Both PUT and GET are compared to submitted values. Account changes invalidate approval; failures trigger no compensating writes. Flutter analyze passes; all 29 Flutter tests and 23 PostgreSQL profile tests (245 assertions) pass; targeted Pint passes. Real second-account E2E remains NOT TESTED. Earlier harness descriptions below are historical; see the latest section of the runtime report.

Second-account PUT/GET approval received: execution is pending verification of the intended UUID through `/me` and an empty authenticated profile GET. Current panel resubmits loaded values rather than dummy data; no PUT has been sent. Latest emulator capture still shows VS Code instead of Android. See the approved-test section in the runtime report; no E2E pass is claimed.

Continuation: local services/emulator restarted preserving data; infrastructure, health and single-user checks reconfirmed. Flutter analysis and all 22 tests passed again. UI recovery now returns mismatched VS Code captures for the emulator; authenticated validation remains at the manual boundary documented in the runtime report.

## Changes

- Audited existing Flutter sources, installed dependencies, secure Supabase storage and actual Laravel contract.
- Reused Supabase's session manager through a runtime adapter; no new dependency or plaintext token persistence.
- Added typed Laravel client with fixed endpoint paths, HTTPS/debug-host validation, no redirects, timeouts, safe failures, account-generation checks and bounded single-flight refresh.
- Added academic profile DTOs and GET/PUT repository. Writable DTOs exclude user IDs and protected fields.
- Added loading/empty/success/error states (plus idle), stale-result suppression and session-boundary clearing.
- Added minimal profile validation controls to the existing debug authentication screen. /me now uses the new typed client. Guest rejection checks retain the existing harness.
- PUT validation requires explicit in-app approval and sends only the loaded writable fields. No existing real profile was overwritten.
- Preserved the app shell, theme, backend, credentials and existing secure storage.

See [Flutter architecture](flutter-client.md) for retry/security/state details. This is a hand-written client, not generated from an OpenAPI schema.

## Automated verification

- flutter analyze: **no issues**.
- flutter test: **22 tests passed**, including **16 new mocked unit/widget cases**.
- New coverage: full DTO serialization/null handling/protected-field omission, malformed DTOs, destination restrictions, bearer attachment, GET/PUT projection, missing session, one-shot 401 refresh/retry, persistent 401, expired session, refresh failure, concurrent refresh sharing, logout/relogin/account switching, no non-auth retry, network/protocol failures, UUID mismatch, controller states/stale-result rejection and explicit PUT approval/cancellation.
- Existing secure-storage/configuration, guest-client and foundation-shell tests continue to pass.
- Dart files formatted through the editor tool. Initial formatter-exposed brace lints were corrected; final analysis is clean.
- No Laravel source changes; the prior 71-test backend result was not rerun or relabeled as new evidence.

All new API tests use mocked transport/session responses. Despite its filename, test/academic_profile_integration_test.dart runs mocked component integration, not a live backend test. No real SDK refresh, emulator profile GET/PUT/GET, Android APK build or new backend persistence claim is made.

## Runtime availability and manual boundary

Read-only workstation checks found **no attached Android devices/emulators** and **no responding Laravel health endpoint on 127.0.0.1:8000**. Real profile validation could not run. No credentials or tokens were requested/extracted and no development profile was written.

For a real round trip:

1. Start Docker Desktop and the existing Android AVD. From the repository root, start preserved local containers and Laravel in separate terminals:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev.ps1 -Target infra-up
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev.ps1 -Target api
```

2. From apps/mobile, use the existing ignored public development configuration:

```powershell
flutter run -d emulator-5554 --dart-define-from-file=.env.e2e.json --dart-define=AUTH_E2E_ENABLED=true
```

Use the actual device ID reported by flutter devices if different. Do not copy the Laravel environment into Flutter.

3. Privately log in with the existing development test account (or verify the restored session). Tap **Load academic profile (GET)**. Check its UUID matches the authenticated identity.
4. Only if you explicitly approve replacing that test account's current profile with the loaded values, tap **Validate PUT / GET (approval required)**, read the stale-data warning and select **Approve PUT**. Otherwise select **Cancel**; no PUT is sent.
5. Expect **PASS: PUT response matches subsequent GET.** Reopen/reload to check persistence. Share only PASS/FAIL and non-secret error information, never passwords or tokens.

The API uses complete replacement and has no optimistic version field; do not approve against concurrently edited data. This development harness is not a profile editor.

## Deliverables and next step

New files: session adapter, typed API client, profile DTO/repository/controller/debug panel and mocked test suite. Updated auth validation screen, implementation plan, checklist, system-architecture link and these architecture/status reports.

Phase 2E.1 code and automated checks are ready for review; real backend validation remains unverified at the manual boundary above. Phase 2E.2 onboarding/profile UI, registration UX, matching, chat, workspace and FCM were not implemented.

# Phase 2A: Supabase configuration

Current update: owner-confirmed development-only use cleared the project blocker and Phase 2B is implemented. See [Phase 2B report](phase-2b-status.md). Confirmation/authorization limits below describe the historical Phase 2A checkpoint.

## Scope and execution plan

The user's 2026-11-13 instruction authorizes Phase 2A only and reports successful emulator startup. Older approval gates and emulator status in Phase 1 documents are historical; hosted CI has not been observed. Existing uncommitted Phase 1 changes are preserved.

1. Inspect the architecture and existing environment without exposing secrets.
2. Add and lock Supabase Flutter and secure storage dependencies.
3. Validate compile-time public configuration and initialize SDK session recovery/refresh using OS-backed storage.
4. Test configuration and persistence boundaries; stop before Laravel authentication.

## Configuration and session behavior

- Flutter uses `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` compile-time values. Neither is bundled by default. Both absent retains the foundation shell; partial/invalid configuration stops startup with a generic error.
- Only HTTPS project roots and modern `sb_publishable_` keys are accepted. Secret/service-role keys and legacy JWT keys are rejected. SDK debug logging is disabled.
- `SecureAuthStorage` supplies both SDK session storage and PKCE storage through `flutter_secure_storage`, scoped by project hostname. The SDK owns restoration, refresh, persistence and logout cleanup. No separate identity/session implementation is introduced.
- SDK initialization can return before expired-session refresh completes. Future authenticated UI must observe SDK auth events and session expiration; a cached session is not proof of API authorization. Laravel will independently verify every bearer token in Phase 2B.
- Android Internet permission is explicit; application backup is disabled to avoid restoring encrypted credentials without their device keys. Native storage behavior still requires device validation. Configured web authentication is intentionally unsupported at this milestone.
- Callback detection is disabled until an owned mobile redirect URI is agreed and registered. No registration/login/profile screens are added in 2A.

## Development database strategy and dependency boundary

Preserve existing local Docker PostgreSQL for Laravel domain data and Redis for cache/queues. No connection settings, migrations, database rows or cloud resources were changed. Supabase Auth remains the sole identity authority; future application user UUIDs equal the verified Supabase subject, linked in service logic rather than a cross-database foreign key.

Approved integration: Supabase Cloud Auth plus existing local Docker PostgreSQL for all application domain data and local Redis for cache/queues. Do not migrate domain data to Supabase Cloud. The configured cloud project's development-only status still requires user confirmation. See [approved decisions](phase-2a-decisions.md). Never point migrations at production or Supabase-managed schemas.

The ignored backend environment contains a hosted URL, modern public key, JWKS URL and server secret. Their presence does not prove validity or development ownership. Configuration resolution removed the empty duplicate URL/JWKS entries while preserving populated credentials, set the issuer to the project URL plus `/auth/v1`, and set audience to `authenticated`. Laravel runtime checks confirm the issuer and JWKS relationships. All non-Supabase environment lines, including PostgreSQL/Redis settings, were preserved. Do not pass the backend environment to Flutter or copy it wholesale. No privileged credential is needed for Flutter initialization.

Before enabling the current hosted configuration, confirm it is a dedicated development project. Then supply only the URL/public key in an ignored mobile environment file. A public configuration example and run command are in the mobile README. No hosted requests or test accounts were created in this milestone.

## Reconciliation for later milestones

- The current request's `GET`/`PUT /api/v1/me/academic-profile` supersedes the older `PATCH /me/profile` proposal.
- `academic_preferences` is requested but absent from the old data model; define its fields before 2C. Broader intent/availability/competition tables in the old proposal are outside the current bounded implementation.
- JWT verification remains signature verification via Supabase JWKS, with strict issuer/audience/expiry/algorithm checks; no second password store.
- Login method, confirmed-email policy, redirect identifiers, university catalogs and profile defaults remain decisions for their respective milestones, not prerequisites for offline SDK setup.

## Verification

Validation on 2026-11-13: `flutter analyze` passed with no issues after correcting one constructor style lint; `flutter test` passed all 4 tests, including the existing shell widget test. Editor diagnostics reported no errors. Configuration tests cover absent/partial configuration, invalid URLs, rejection of privileged keys, project-isolated storage, persistence across adapter recreation, deletion and PKCE storage. Storage tests use the plugin mock; they do not prove Android Keystore behavior or real login/session refresh. No new Android APK build was run for 2A.

## Files changed in this milestone

- Mobile: `pubspec.yaml`, `pubspec.lock`, `.env.example`, `README.md`, `lib/main.dart`, `lib/core/config/app_config.dart`, new `lib/core/auth/initialize_auth.dart`, new `lib/core/auth/secure_auth_storage.dart`, new `test/auth_configuration_test.dart`, `android/app/src/main/AndroidManifest.xml`.
- Documentation: root `README.md`, `implementation-plan.md`, `task-checklist.md`, `infrastructure/supabase/README.md`, `docs/architecture/phase-2-plan.md`, and this report.
- Other working-tree changes predated this milestone and were preserved.

Real Supabase login, session recovery and profile persistence have NOT been tested. Laravel auth/security/API/migration tests belong to subsequent milestones and were not run for this Flutter-only configuration change.

## Configuration resolution verification

- `flutter analyze`: passed; `flutter test`: 4 passed.
- `flutter doctor`: Android toolchain passes; Chrome executable and Windows C++ desktop components are missing. These do not block the Android target.
- Laravel route list: only two public health routes; Pint passed; `php artisan test`: 5 passed, 16 assertions. Initial sandbox cache-write warning was resolved by rerunning with elevated tool permission.
- Compose configuration passed; PostgreSQL and Redis containers are healthy. Initial Docker config access warnings were resolved by rerunning with elevated tool permission.
- Live PostgreSQL `SELECT 1`, Redis default/cache `PING`, and both HTTP health routes passed (200 with exact liveness JSON).
- Loaded Laravel configuration validates issuer, JWKS, audience, local database and local cache/queue settings. A stricter assertion that all auth configuration arrays were empty failed because Laravel merges dormant defaults; see the decisions document. No second login implementation exists.
- Flutter source/config scan found no privileged Supabase credential; the only secret-key marker was a deliberately invalid test fixture. There is no mobile `.env` containing real credentials.
- No real authentication, session recovery, JWKS signature verification, new APK build or domain migration tests were executed. No domain migrations exist yet. No production resources or application data were modified.

Resolution files changed: ignored `services/api/.env`, `services/api/.env.example`, new `services/api/config/supabase.php`, this report, new `phase-2a-decisions.md`, architecture topology/deployment notes, Supabase infrastructure notes, root README and task checklist. Existing unrelated changes were preserved.

Next: obtain confirmation that the configured cloud project is development-only. Local configuration is ready for Phase 2B planning; Phase 2B implementation requires separate authorization and remains unimplemented.

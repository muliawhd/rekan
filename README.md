# Re:kan — fullstack foundation

Latest checkpoint (2026-11-15): [Phase 2D academic profile API](docs/architecture/phase-2d-status.md) is implemented with owner-only GET/PUT, complete payload validation and transactional relationship updates. All 71 PostgreSQL-backed tests pass (537 assertions). Stopped before Phase 2E; earlier checkpoint statements below are historical.

Current checkpoint (2026-11-15): [Phase 2C academic database](docs/architecture/phase-2c-status.md) is implemented and migrated on local PostgreSQL after user authorization. All 50 PostgreSQL-backed backend tests pass. [Phase 2B.1](docs/testing/phase-2b1-auth-e2e.md) records manual authentication evidence. Stopped before Phase 2D; older checkpoint statements below are historical.

Current work: [Phase 2A Supabase configuration](docs/architecture/phase-2a-status.md).
Latest checkpoint: [Phase 2B Laravel authentication](docs/architecture/phase-2b-status.md) is implemented following owner confirmation of development-only project use. Protected `/api/v1/me` and local UUID provisioning are available; real login remains unverified. Stopped before Phase 2C. Earlier Phase 2A statements below are historical.
The user has demonstrated emulator startup and authorized 2A. Historical Phase 1
status below is retained; no hosted CI result is claimed. Supabase SDK setup is
implemented; development-project confirmation and real auth validation
remain pending. No Phase 2B–2F implementation is included.

Re helps university students find academic study partners and competition teammates. MBTI is display-only and must never affect matching.

**Phase 1 is partially validated.** Real Flutter 3.50.0 and Laravel 12.72.0 projects exist. Flutter analysis/widget tests and Android debug APK build, Laravel tests, both HTTP health routes and live PostgreSQL/Redis connections pass. Emulator startup and hosted CI evidence remain open. See [validation](docs/testing/phase-1-validation.md), [checklist](task-checklist.md) and the approval-gated [Phase 2 proposal](docs/architecture/phase-2-plan.md).

## Structure

```text
apps/mobile/                 Flutter destination and public config templates
services/api/                Laravel destination and server env template
infrastructure/docker/       Local PostgreSQL and Redis
infrastructure/supabase/     Hosted integration notes
infrastructure/firebase/     FCM integration notes
infrastructure/scaffolding/  Prepared source overlays; NOT standalone apps
docs/architecture/           Preserved architecture kit and reconciliation
docs/product/                Product scope pointer
docs/design/                 UI boundaries
docs/testing/                Actual validation results
scripts/                     PowerShell setup, development, validation
app/, gradle/, *.gradle.kts   Preserved pre-existing native Android project
```

The original sibling architecture kit is untouched. Its documentation is copied into [docs/architecture](docs/architecture), including the original README as `KIT_README.md`. Historic relative links in that snapshot reflect its original location. [AGENTS.md](AGENTS.md) governs this repository. The preserved native Android project is not the Flutter app; do not use it as evidence that Flutter builds.

## Prerequisites

- Flutter stable and its bundled Dart; Android Studio, Android SDK, accepted SDK licenses, and an Android emulator.
- PHP 8.5.12 and Composer 2.11.2 were validated locally (Laravel 12 minimum PHP 8.2). Enable Laravel-required extensions plus `pdo_pgsql` and `pdo_sqlite`; Redis uses the Composer-installed Predis client, with no PhpRedis extension required.
- Docker Desktop using Linux containers, Docker Compose v2 or later, Git.
- Network access to official Flutter, Composer/Packagist, pub.dev, and container registries for initial downloads.

Laravel 12 is the selected major; Composer resolves compatible stable dependencies and creates a lockfile. Flutter uses the installed stable SDK's official generator. Record `flutter --version`, commit `pubspec.lock` and `composer.lock`, and pin the SDK in CI after generation. No Riverpod, Dio, router, Supabase, or Firebase SDK is added in this phase.

## Setup (PowerShell, from this repository)

These commands use a process-only execution policy override; they do not change machine policy.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/setup-local.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap.ps1 -Target api
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap.ps1 -Target mobile
```

Local environment files have already been generated on the implementation machine. Skip `setup-local` there. It refuses to replace either existing environment file. In a fresh clone it generates a random database password into ignored Compose and API `.env` files. To configure manually, copy each `.env.example`, set matching local database passwords, and generate Laravel's APP_KEY after scaffolding. Never print or commit these values.

Bootstrap uses official `composer create-project` / `flutter create`, stages output under ignored `.local`, and then applies the [source overlays](infrastructure/scaffolding). It refuses to overwrite an existing application manifest. If dependency installation fails after generation, resolve the reported issue and continue `composer install` or `flutter pub get` in the generated app; do not rerun bootstrap over edits. Laravel's default user/password migrations, model, factories, and seeders are excluded so Supabase remains the only identity authority. No application migrations are introduced in Phase 1.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev.ps1 -Target infra-up
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev.ps1 -Target infra-status
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev.ps1 -Target api
# In another terminal:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev.ps1 -Target smoke
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev.ps1 -Target mobile
```

Open `apps/mobile/android` in Android Studio after generation, launch an emulator, and use Flutter to run the shell. Android emulators reach the host via `10.0.2.2`; physical devices require separate development networking. The shell does not make HTTP calls yet. Do not enable production cleartext networking. Select an owned reverse-domain Android application ID before distribution; bootstrap's `com.example.re` is development-only.

The API runs on `127.0.0.1:8000`; PostgreSQL on `127.0.0.1:5433`; Redis on `127.0.0.1:6380`. Both services persist in named volumes. Redis is unauthenticated and loopback-only for this workstation setup: do not publish it remotely. `infra-down` stops services while retaining data. Changing the PostgreSQL environment password does not rotate an existing volume's database password.

## Health contract and checks

After bootstrap, `GET /api/v1/health` and the requested alias `GET /api/health` return HTTP 200 and exactly `{"status":"ok"}`. This is public process liveness, not database/Redis readiness or proof of Supabase integration. No protected endpoints exist yet.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1 -Target infra
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1 -Target api
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1 -Target mobile
# After the mobile checks pass:
cd apps/mobile
flutter build apk --debug
```

Checks include `docker compose config --quiet`, `php artisan route:list`, Pint, `php artisan test`, `flutter doctor`, Dart formatting, `flutter analyze`, and `flutter test`. Run `scripts/check.ps1 -Target connections` separately against running local services for actual PostgreSQL/Redis connectivity. Test results are recorded in [validation](docs/testing/phase-1-validation.md). The [CI workflow](.github/workflows/foundation.yml) is configured but has not been observed running remotely.

## Environment and ownership

Laravel owns domain rules and future application migrations in local Docker PostgreSQL. Flutter owns presentation and client sessions; Supabase Cloud Auth is the only identity provider; local Redis provides cache/queues. Do not migrate domain data to Supabase Cloud. Supabase UUID is the canonical user identifier. See [approved Phase 2A decisions](docs/architecture/phase-2a-decisions.md). Realtime, Storage and Firebase integrations remain future scope.

No cloud credentials are required for the shell or liveness route. Auth integration needs a confirmed development Supabase project, URL/public key and issuer/JWKS/audience configuration. JWKS verification requires neither a cloud database connection nor a server secret. Only public Supabase values may enter Flutter compile-time config. Never include APP_KEY, database passwords, service-role keys, or Google service-account credentials in Flutter.

This review created no cloud resources, production changes, paid services or Git commits. Existing commits predate the review. Review and commit this checkpoint after required application validation passes. Continue with identity only after Phase 1 is validated and the user approves the Phase 2 plan.

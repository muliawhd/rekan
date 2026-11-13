# Re — fullstack foundation

Re helps university students find academic study partners and competition teammates. MBTI is display-only and must never affect matching.

**Phase 1 is incomplete and blocked on toolchains.** This checkout contains the monorepo layout, infrastructure, setup scripts, and authored scaffold overlays. Flutter and Laravel have NOT been generated, installed, built, or started. See [validation](docs/testing/phase-1-validation.md) and [checklist](task-checklist.md).

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
- PHP 8.3 or 8.4 recommended (Laravel 12 minimum 8.2); Composer 2. Enable Laravel-required extensions plus `pdo_pgsql`, `pdo_sqlite` for framework test defaults, and `redis` (PhpRedis).
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

Checks include `docker compose config --quiet`, `php artisan route:list`, Pint, `php artisan test`, `flutter doctor`, Dart formatting, `flutter analyze`, and `flutter test`. Test results must be recorded in [validation](docs/testing/phase-1-validation.md). CI setup remains pending real scaffolds and lockfiles; do not report these scripts as executed CI.

## Environment and ownership

Laravel owns domain rules and future `public` schema migrations. Flutter owns presentation and client sessions; Supabase owns Auth/Postgres/Realtime/Storage; Firebase delivers push; Redis provides server cache/queues. Local PostgreSQL is only a development database, not Supabase Auth/Realtime/Storage.

No cloud credentials are required for the shell or liveness route. Later integration needs a dedicated development Supabase project (URL, public key, issuer/JWKS, least-privileged SSL database connection, server-only secret) and Firebase project/platform configuration. Only public Supabase values may enter Flutter compile-time config. Never include APP_KEY, database passwords, service-role keys, or Google service-account credentials in Flutter.

No cloud resources, production changes, paid services, or Git commits were created. Review and commit a checkpoint after required application validation passes. Continue with identity only after Phase 1 is validated.

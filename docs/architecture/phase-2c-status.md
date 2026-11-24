# Phase 2C: academic database foundation

Implemented 2026-11-15 after the user authorized Phase 2C.

## Scope and decisions

Laravel migrations remain the authority for local PostgreSQL application data. Supabase Auth UUIDs remain canonical; the existing users migration and identity provisioning are unchanged. No cloud database, authentication provider, API endpoint or Flutter screen was added.

The historical Phase 2 proposal includes intents, availability and competition roles. The user's narrower 2C table list takes precedence: those features and student verification workflows remain deferred. Existing users are extended with nullable display_name and university_id; no identities are recreated or backfilled.

The old model omitted academic_preferences. A clarification was offered; in the absence of a response, the implementation uses the stated minimal assumption: nullable study_mode (online/in_person/hybrid) and nullable preferred_language. Null means unspecified. These are schema choices for review, not a matching algorithm or ranking signal.

## Schema

| Table | Constraints and behavior |
| --- | --- |
| users (extended) | Existing Supabase UUID PK/status retained; nullable display_name (100), university_id FK with index. University deletion restricted while referenced. |
| universities | UUID PK, name (200), verified_domains JSONB array default []; timestamps with time zone. Domains are metadata, not proof of enrollment. |
| academic_profiles | user_id PK/FK, nullable program (150), semester 1–20, bio (2000), optional 16-value MBTI badge; visibility private/university/public, default private. |
| courses | UUID PK, optional university FK, uppercase trimmed nonempty code (40), name (200); unique university/code and partial unique index for global codes with null university. |
| skills | UUID PK; unique lowercase trimmed nonempty normalized_name (100). |
| user_skills | Composite user/skill PK; level 1–5; reverse skill index. |
| user_courses | Composite user/course PK; reverse course index. |
| academic_preferences | user_id PK/FK; nullable study_mode enum and preferred_language (35), with bounded language-tag syntax. No language registry claim or default preference. |

All new tables use timestamps with time zone. User-owned rows cascade only when their parent user is explicitly deleted. Referenced university/course/skill catalog deletion is restricted. Catalog UUIDs must be supplied by the application or future catalog imports; no fabricated seed data is inserted.

The migration explicitly requires PostgreSQL so JSONB, regex CHECK constraints and the partial uniqueness index cannot silently lose enforcement under another engine. Existing authentication unit tests still run on SQLite using the original identity migration. Course/university compatibility and owner-only writes require Phase 2D validation/policies; UUID foreign keys alone do not implement authorization. MBTI remains display-only.

## Validation

- Full Laravel suite with ACADEMIC_TEST_POSTGRES=1 and IDENTITY_TEST_POSTGRES=1: **50 tests passed, 306 assertions**.
- Includes **23 academic schema tests**: preexisting identity preservation, rollback/reapply, private/default-null behavior, cascades, global course uniqueness, duplicate associations, invalid ranges/enums, foreign keys, catalog delete restriction and normalized taxonomy constraints.
- PostgreSQL tests create random schemas inside transactions with a local-only search_path, then roll back. They do not reset public tables or delete real users.
- Default test run: existing 27 tests passed; 23 PostgreSQL-only tests explicitly skipped. Use the flags below for actual database verification.
- Pint passed; editor diagnostics reported no errors in the new PHP files.
- Live PostgreSQL SELECT 1 and Redis default/cache PING passed.
- New migration applied as batch 2 to local Docker PostgreSQL. Guarded user count was exactly 1 both before and after application.
- Route listing remains the two health routes and /api/v1/me.
- Docker Desktop was initially stopped; existing containers were started without deleting volumes. The initial PostgreSQL test attempt was interrupted while the database was unavailable; only the completed rerun is counted.
- Flutter tests and real Supabase login were not rerun for this database-only change. Phase 2B.1 evidence remains in its [report](../testing/phase-2b1-auth-e2e.md).

From services/api:

```powershell
$env:ACADEMIC_TEST_POSTGRES='1'
$env:IDENTITY_TEST_POSTGRES='1'
php artisan test
php vendor/bin/pint --test
php artisan foundation:check
```

## Rollback and next milestone

The migration down method removes the added academic schema/columns in dependency order while retaining the original users table. Rollback was exercised only in disposable test schemas. Once academic data exists, rollback would delete that data; do not roll back the live development schema without approval and a backup. No rollback was performed on existing application data.

Phase 2C database implementation is ready for review. Next is Phase 2D: authenticated GET/PUT /api/v1/me/academic-profile, validation and ownership policies. The older PATCH /me/profile proposal must be reconciled with the user's GET/PUT contract before implementation. No Phase 2D or onboarding, matching, chat, workspace or FCM implementation is included.


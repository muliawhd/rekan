# Phase 2D: academic profile API

Implemented 2026-11-15 after explicit user authorization. Phase 2E has not started.

## Audit and schema decision

The audit found only the identity User Eloquent model. Phase 2C created tables but did not create academic models or relationships. This change adds University, AcademicProfile, Course, Skill, AcademicPreference, UserCourse and UserSkill; the association models extend Eloquent Pivot for their composite keys. User now has university/profile/preference and course/skill relationships, with inverse relationships on the new models.

Global course-code uniqueness was reviewed before making any schema decision. The existing composite unique key permits CS101 at multiple universities. The partial unique index applies only to null-university rows, treating them as one curated shared catalog. Retain this constraint and interpretation for Phase 2D; no constraint or migration is changed. University-specific courses must always carry their university ID. If null later means “university unknown” rather than “shared canonical course,” recommend a separately reviewed source/namespace or explicit scope model before relaxing uniqueness; simply dropping the index would introduce ambiguous duplicate global courses. Catalog import policy remains future work.

All supported fields already exist in the Phase 2C schema. The response groups existing course/skill associations and preference columns; it adds no domain fields. Supabase remains the only identity authority. No generated client, new dependency, catalog mutation endpoint or Flutter code was added.

## API behavior

- Existing GET /api/v1/me retains its identity response and provisioning behavior.
- GET /api/v1/me/academic-profile returns the authenticated user's projection. A user without a stored profile receives nullable fields, empty associations and private visibility; GET does not create academic rows.
- PUT /api/v1/me/academic-profile performs a complete replacement of writable profile fields and selected associations. All fields must be explicit, including nulls and empty arrays. It returns 200 on both creation and update.
- Query/body identity selection is unsupported. GET rejects parameters; PUT rejects unknown/protected root and nested fields, including user_id/status/timestamps.
- Detailed fields, limits, example and error semantics are in the [API contract](04-api-contract.md).

## Security and persistence

Both endpoints use the existing Supabase verification middleware, including signature/issuer/audience/expiry/UUID checks, rate limiting and no-store/request-ID behavior. All lookups start with the authenticated user; an explicitly registered AcademicProfilePolicy also checks ownership for reads/writes. Even a profile marked public is only exposed to its owner by these self-service endpoints.

PUT uses explicit field assignment rather than request mass assignment. Academic models guard attributes; the skill pivot permits level for relationship updates. User identity/status mass-assignment rules are unchanged. Unknown references, cross-university courses and duplicate associations (including UUID case variants) return 422. Global courses may be selected with any university or with no university.

Writes lock the owning user and perform user fields, profile, preferences and pivot replacement in one transaction. Reads hold a shared user lock for a coherent projection with respect to these writes. Selected course rows are shared-locked while checking scope. Foreign-key/unique conflicts from catalog races return 409; other database failures return a generic 503 without SQL details. Rollback includes earlier user/profile/preference/pivot changes. Authentication's existing provisioning occurs before this domain transaction.

No optimistic version field is invented: simultaneous complete PUTs serialize and the last successful write wins. Editing catalog ownership outside this API requires a separate workflow that preserves course/university consistency.

## Validation

Completed on local Docker PostgreSQL using random transaction-scoped schemas; no public schema reset or destructive migration:

- Full suite with both PostgreSQL flags: **71 tests passed / 537 assertions** (21 new profile API cases).
- Real JWT verification with ephemeral RSA fixture keys and fake JWKS transport; authentication middleware was not bypassed.
- Retrieval/default privacy, creation, update, replacement, repeated PUT, missing/malformed/invalid-signature JWT, owner policy denial and attempted cross-user selection.
- Unknown university/course/skill references, invalid fields, protected-field injection, malformed lists, duplicate UUID relationships, cross-university course selection and incomplete PUT.
- A late PostgreSQL CHECK failure after earlier writes proves transaction rollback; response omits SQL details.
- Existing identity timestamps/status and the second user's data remain unchanged.
- Eloquent relationships exercised across all eight Phase 2C tables.
- Pint passed; requested editor diagnostics reported no errors.
- PostgreSQL SELECT 1 and Redis default/cache PING passed.
- Route list contains the original three routes plus the two profile routes.
- Existing real development UUID still has exactly one local record; migration status remains batches 1 and 2. No migration was run in Phase 2D.
- Initial new-test failures were overly strict expectations of Cache-Control; Symfony returns “no-store, private.” Assertions now check that actual privacy-preserving header.

Reproduce from services/api:

```powershell
$env:ACADEMIC_TEST_POSTGRES='1'
$env:IDENTITY_TEST_POSTGRES='1'
php artisan test
php vendor/bin/pint --test
php artisan foundation:check
php artisan route:list
```

Without ACADEMIC_TEST_POSTGRES=1, academic schema/API cases explicitly skip; a default SQLite run is not evidence of PostgreSQL integration. Tests use fake catalog rows only inside disposable schemas. No university/course/skill production seed data was invented.

Flutter tests, emulator interaction and real Supabase profile round trips were not run for this backend milestone. Prior authentication E2E evidence remains separate. No credentials or tokens were printed.

## Files and next step

New Academic module: seven models, profile controller and policy. Updated identity User relationships, policy registration and API routes. Added AcademicProfileApiTest. Updated API/data-model documentation, implementation plan, README, checklist and this report.

Phase 2D is ready for review. Next is separately authorized Phase 2E Flutter onboarding/profile integration. The tagged development authentication screen is unchanged. No matching, chat, workspace or FCM work is included.


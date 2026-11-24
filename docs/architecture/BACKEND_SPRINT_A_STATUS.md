# Backend Sprint A - Academic Catalog API

Date: 2026-11-16. Scope: Laravel catalog reads and tests only.

## Implementation

Added authenticated GET `/api/v1/universities`, `/api/v1/courses`, `/api/v1/skills` in the existing Supabase middleware group. [AcademicCatalogController](../../services/api/app/Modules/Academic/Http/AcademicCatalogController.php) reuses existing Eloquent models and error envelopes. No migrations, dependencies, auth changes or Flutter edits were made for this sprint.

See [API contract](04-api-contract.md#implemented-backend-sprint-a-academic-catalogs) for parameters, exact field allowlists, response examples and errors. All routes accept `q` (maximum 100), `limit` (1–50, default 20), and UUID `ids` lists (universities maximum 50, courses/skills maximum 100). Courses additionally accept a nullable existing `university_id`. Filters intersect. A university filter includes global courses and that university only; absent/null filter includes all scopes. Responses expose no private metadata or user relationships, and carry request IDs and private/no-store cache headers.

Search is parameterized, case-insensitive literal substring matching. Ordering is name/id, code/id, or normalized_name/id respectively. Unknown parameters, malformed lists/UUIDs, duplicate IDs, invalid limits and non-empty bodies are rejected. Existing middleware rate limits, disabled-account handling and initial identity provisioning remain unchanged. Catalog handlers perform no writes.

## Architecture and live schema audit

Read repository rules, README, plan/checklist, data model, API contract, screen matrix, implementation constraints, Iteration 3 status, academic models/migrations, profile controller and JWT middleware/tests. Development services were initially stopped; Docker Desktop and the existing Compose containers were started with their persisted volumes. No reset or development migration was run.

Read-only PostgreSQL transaction inspected `information_schema.columns`, `pg_indexes`, `pg_constraint`, and catalog counts. Live schema agrees with migrations:

- Universities: UUID primary key; name; JSONB verified_domains constrained to an array; timestamps. Only id/name may leave catalog API.
- Courses: UUID primary key; nullable university UUID FK with RESTRICT deletion; code/name/timestamps. Unique `(university_id, code)` and partial unique global code index where university_id is null. Codes must be non-empty, uppercase and trimmed.
- Skills: UUID primary key; unique normalized_name; timestamps. Names must be non-empty, lowercase and trimmed.
- Existing Eloquent university/course relationship and user-course/user-skill pivots are retained. Catalog queries do not load user relationships.

## Data readiness and seed proposal

| Development catalog | Record count |
| --- | ---: |
| Universities | 0 |
| Courses | 0 |
| Skills | 0 |

No useful catalog data exists. Empty responses are correct, but first-time onboarding still requires catalog data and a separately authorized Flutter catalog-fetch integration. No official institutional metadata was inferred or inserted.

Minimal proposed **dummy development dataset**, pending owner approval:

- Two fictional institutions: `Development University A (DUMMY)` and `Development University B (DUMMY)`; verified_domains stays `[]`.
- Three fictional courses: `DEV101` / `Development Programming (DUMMY)` scoped once to each institution, and global `DEV-G101` / `Development Study Foundations (DUMMY)`.
- Three illustrative skill taxonomy entries: `dart`, `flutter`, `technical writing`; these do not assert official institutional affiliation.
- Generate UUIDs at approved insertion time; do not reuse example UUIDs as supposed real records. Any later seed should be explicit, development-only and idempotent, with its exact rows reviewed before insertion. No seed implementation or insertion is part of this sprint.

## Validation

[AcademicCatalogApiTest](../../services/api/tests/Feature/AcademicCatalogApiTest.php) exercises actual PostgreSQL queries and the existing JWT middleware with signed fixture JWTs and fake JWKS. Each case creates a random `catalog_test_*` schema inside a transaction, sets a schema-only local search path, applies migrations there, and rolls everything back. No test resets development tables.

Coverage: valid users; missing/malformed/forged/expired JWTs; case-insensitive code/name/skill search; literal wildcard and injection-like search text; scoped/global courses; foreign-university scope bypass attempts via IDs/search; uppercase/unknown/invalid UUIDs; invalid query shapes/limits; size bounds; deterministic tie-breaking; empty results/catalogs; exact response keys; sensitive field exclusion; two-user equality; unknown user selector rejection; unsupported mutation methods; before/after snapshots of all eight domain tables.

Final validation:

- `ACADEMIC_TEST_POSTGRES=1 IDENTITY_TEST_POSTGRES=1 php artisan test --do-not-cache-result`: **87 passed, 1321 assertions, no skips**. PowerShell environment variables were set for this process; the option avoids sandbox-denied PHPUnit result-cache writes.
- Focused catalog suite: **14 passed, 770 assertions**.
- `php vendor/bin/pint --test`: passed. Pint formatted the new test file only.
- `php artisan foundation:check`: PostgreSQL SELECT 1 and both Redis PING checks passed.
- `scripts/check.ps1 -Target infra`: Compose configuration passed; existing PostgreSQL and Redis containers healthy.
- Route listing confirms all three catalog GET/HEAD routes inside the JWT middleware group; editor diagnostics are clear.
- `git diff --check`: passed. Existing unrelated worktree changes were preserved.

The first ordinary test run skipped PostgreSQL-only cases because the opt-in flags were absent. An initial integration run caught rejection of Laravel's empty JSON GET body; the controller now accepts empty JSON objects/lists and still rejects non-empty bodies. The complete final run above supersedes those intermediate results. No live Supabase account credentials or development profile writes were used.

## Remaining risks and stop boundary

- Catalog availability is blocked on approved data. Fictional seeds would support development only, not official university/course accuracy.
- Flutter was not changed or retested; no live device onboarding or production deployment claim is made.
- Existing middleware can create a missing local identity on first authenticated access. No-mutation assertions cover all domain tables for pre-existing identities; catalog handlers themselves never write.
- Bounded lists have no pagination; substring searches may scan larger catalogs because no text-search index exists. Reassess only when measured catalog size/performance warrants it.
- No discovery, matching, chat, rooms, Supabase Auth changes, PostgreSQL reset, or automatic seeding. Stop after Sprint A and wait for approval before seeds or other backend work.

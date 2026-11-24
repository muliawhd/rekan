# Backend Sprint A.1 - Safe development academic catalog seeding

Date: 2026-11-16. Complete; stopped after seeding and verification.

## Dataset and provenance

These are user-requested **development fixtures, not a verified academic catalog**. Institution names do not establish verified domains, enrollment eligibility or official course offerings. All eight courses are global (`university_id = null`); the `DEV-` codes below are invented development identifiers, not official course codes.

Universities: Telkom University; Universitas Indonesia; Institut Teknologi Bandung; Universitas Gadjah Mada. Each newly inserted `verified_domains` is `[]`.

| Development code | Global course name |
| --- | --- |
| DEV-ALG | Algoritma dan Pemrograman |
| DEV-STR | Struktur Data |
| DEV-DB | Basis Data |
| DEV-NET | Jaringan Komputer |
| DEV-SE | Rekayasa Perangkat Lunak |
| DEV-IS | Sistem Informasi |
| DEV-AI | Kecerdasan Buatan |
| DEV-STAT | Statistika |

Skills are stored lowercase to satisfy `normalized_name` constraints: java, python, sql, flutter, ui/ux design, data analysis, machine learning, public speaking, project management, web development.

## Environment and implementation safeguards

Audited repository rules, academic data model/API contract, Sprint A status, Phase 2E.2 plan, academic models/migrations and Laravel environment/database configuration. No seeders previously existed. Live read-only inspection verified UUID primary keys, JSON-array university domains, canonical code/name checks, university/course foreign key, scoped course uniqueness, partial global-code uniqueness and unique normalized skills.

[DevelopmentAcademicCatalogSeeder](../../services/api/database/seeders/DevelopmentAcademicCatalogSeeder.php) must be explicitly invoked:

```powershell
php artisan db:seed --class=DevelopmentAcademicCatalogSeeder
```

The seeder requires both application environment checks to be `local`, actual PostgreSQL connection host `127.0.0.1`, port `5433`, database `rekan_local`, and no database URL. Other environments, including production, staging and testing, fail closed even with `--force`. There is no automatic default seeder registration or environment-file change.

Stable UUIDv5 IDs derive from the URL namespace and `urn:rekan:development-catalog:v1:<table>:<lowercase-name>`. Before insertion, case-insensitive trimmed natural-name matches are retained. Courses match global names or development codes only, preserving unrelated university-scoped courses. Existing rows, metadata and timestamps are never updated, even when empty. UUID collisions fail and roll back the transaction.

The small insert-only transaction locks the three catalog tables against concurrent writes while retaining SELECT availability; universities do not have a unique name index. No deletes, resets, schema changes, user writes or profile writes occur.

## Actual application and preservation evidence

Before application, confirmed `APP_ENV=local`, `pgsql`, `127.0.0.1:5433/rekan_local`, no DB URL, and `public` schema. Pre-seed counts were shown before applying the authorized seed.

| Table | Before | First run inserted | Second run inserted | After commit |
| --- | ---: | ---: | ---: | ---: |
| universities | 0 | 4 | 0 | 4 |
| courses | 0 | 8 | 0 | 8 |
| skills | 0 | 10 | 0 | 10 |

Both explicit Artisan invocations ran within an outer verification transaction. Full-row snapshots (including IDs, timestamps and metadata) were compared in memory; the second run was exactly identical to the first. All expected names were present exactly once, and all courses were global. The transaction committed only after these checks; an independent read after commit reconfirmed 4/8/10.

Full-row before/after comparisons confirmed preservation of all existing non-catalog tables: **3 users, 1 academic profile, 1 academic preference, 0 user-course rows, 0 user-skill rows**. No personal field values or credentials were printed or written into this report.

## Verification

- Full Laravel suite with `ACADEMIC_TEST_POSTGRES=1` and `IDENTITY_TEST_POSTGRES=1`: `php artisan test --do-not-cache-result` — **92 passed, 1413 assertions**, no skips.
- Four new seeder tests cover complete/global dataset, idempotency and preservation, pre-existing natural keys/metadata, refusal outside local even with force, and collision rollback.
- An additional authenticated catalog feature test seeds the dataset in an isolated schema and verifies every expected name through the routes, including global-course visibility under a university filter.
- PostgreSQL tests use random transactional schemas and roll back; no development-table reset.
- Read-only verification against the committed development database, through Laravel's HTTP kernel and existing JWT middleware: `/api/v1/universities` returned HTTP 200 with 4 items; `/api/v1/courses` returned HTTP 200 with 8; `/api/v1/skills` returned HTTP 200 with 10. All returned request IDs and `Cache-Control: no-store, private`.
- That development-database check used a signed fixture JWT and fake JWKS configured **only in the short-lived verification process**, with an existing enabled local identity and a PostgreSQL READ ONLY transaction. No Supabase configuration changes, real user tokens or identity provisioning were used. This proves the middleware/query path, not a live Supabase login or network-server E2E flow.
- Laravel Pint passed after formatting the added test imports; editor diagnostics are clear.

## Known limitations and boundary

The schema has no fixture provenance flag; this seeder/report and development course-code prefix identify provenance. Do not promote this dataset to production or interpret global courses as official university offerings. Existing conflicts are preserved rather than corrected; future runs with curated records may skip an expected fixture name if its development code is already occupied. The environment guard relies on truthful deployment configuration and deliberately permits only this workstation's development database.

No Flutter work, discovery, matching, chat, rooms or Supabase Auth changes were made. This completes Sprint A.1; further implementation requires separate authorization.

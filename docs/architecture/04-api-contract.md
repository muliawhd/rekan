# REST API contract (implemented identity/profile/catalog subset; remaining routes proposed)

Backend Sprint A (2026-11-16): authenticated read-only catalog routes are implemented. See the contract below and [Sprint A status](BACKEND_SPRINT_A_STATUS.md). Historical phase notes describe earlier checkpoints.

Phase 2B update: `GET /api/v1/me` is implemented with Supabase bearer JWTs and returns `{data: {id, status, created_at}, request_id}`. Errors 401/403/429/503 use the envelope below; 401 includes `WWW-Authenticate: Bearer` and 429 includes `Retry-After`. Identity responses are `no-store`. See [Phase 2B report](phase-2b-status.md). Other domain endpoints remain proposals.

Prefix `https://api.example.invalid/api/v1` (replace with owned domain). `Authorization: Bearer <Supabase access JWT>`; UUID IDs; JSON ISO-8601 UTC; cursor pagination. Error envelope `{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": {} }, "request_id": "..." }`.

| Method / path | Purpose | Access / checks |
|---|---|---|
| GET /health | health | public but no internals exposed |
| GET /me | hydrate/provision account | valid JWT |
| GET /me/academic-profile | read own academic profile (implemented) | verified JWT, owner |
| PUT /me/academic-profile | replace own academic profile (implemented) | verified JWT, owner, complete validated payload |
| GET /universities | university directory | authenticated |
| GET /courses?university_id= | course directory | authenticated |
| GET /skills | skill catalog | authenticated |
| POST /intents | create study/competition intent | verified eligible user |
| GET /intents | list own intents | owner |
| PATCH /intents/{id} | change own intent | owner |
| GET /matches/recommendations?intent_id=&cursor= | filters + ranking | owner of intent; no hidden data leak |
| POST /invitations | send invite | sender, recipient eligible; idempotency key |
| GET /invitations?status= | list inbox/outbox | participating user |
| POST /invitations/{id}/accept | accept | recipient only, atomic |
| POST /invitations/{id}/decline | decline | recipient only, atomic |
| GET /connections | list accepted pairs | participating user |
| POST /materials | create upload intent | verified and authorized uploader |
| POST /materials/download-batches | request authorized ZIP | membership, rights and limits |
| GET /materials/download-batches/{id} | job status / expiring URL | requester only |
| GET /conversations (P1) | chat list | members only |
| GET /conversations/{id}/messages (P1) | cursor messages | members only |
| POST /conversations/{id}/messages (P1) | persist + trigger event | member; moderation; rate limit |
| POST /devices (P1) | register FCM token | JWT; device ownership |
| DELETE /devices/{id} (P1) | revoke token | owner only |
| POST /reports | safety report | authenticated |

### Invitation invariants
No self-invite. No repeated pending invitation for same sender/recipient/intent. Use unique DB strategy and transaction locking; idempotency key deduplicates retries. Accept only from `pending`; return 409 for conflicting states.

### Matching response
Return `user_id`, permitted public academic fields, `matched_criteria` (e.g., common courses, skill alignment, availability overlap), `score` optional and explainable; no sensitive verification documents or private schedule detail without consent. Deterministic tie-breaker.

### OpenAPI next step
Codex must convert this endpoint inventory into strict OpenAPI YAML BEFORE implementing generated clients. Include request/response JSON Schema, errors, auth scheme, cursor semantics, rate limits, and pagination.

## Implemented Phase 2D academic profile contract

The old PATCH /me/profile proposal is superseded by GET and PUT /me/academic-profile. Existing GET /me is unchanged. All three use verified Supabase bearer identity. Catalog reads are now implemented by Backend Sprint A below.

GET accepts no query/body parameters. It returns 200 with {data: PROFILE, request_id}. PROFILE contains read-only user_id plus all writable fields below. With no stored profile, nullable fields are null, courses/skills are empty and visibility is private; existing display_name/university_id are retained. GET does not create academic rows.

PUT accepts a complete JSON object with exactly the following writable fields. All must be present; nullable fields may be null. Missing fields and unknown/protected fields return 422. Send only the writable projection, not the response's user_id. Null clears a nullable value; [] replaces a relationship with an empty set.

| Field | Validation |
| --- | --- |
| display_name | nullable string, maximum 100 characters |
| university_id | nullable UUID referencing universities |
| program | nullable string, maximum 150 |
| semester | nullable integer, 1–20 |
| bio | nullable string, maximum 2000 |
| mbti_badge | nullable uppercase four-letter MBTI type; display-only |
| visibility | private, university or public; explicitly required on PUT |
| courses | UUID list, maximum 100, unique ignoring UUID letter case; existing global courses or courses at selected university |
| skills | list, maximum 100, each object exactly skill_id and level; existing unique skill UUIDs and integer level 1–5 |
| preferences | object exactly study_mode and preferred_language, both present and nullable |
| preferences.study_mode | online, in_person or hybrid |
| preferences.preferred_language | maximum 35, syntax ^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$; syntax validation, not a language registry |

Laravel's standard whitespace trimming/empty-string-to-null middleware applies. UUIDs are normalized to lowercase after validation; duplicate IDs are rejected rather than silently deduplicated. Global courses may be selected with a null university; university-scoped courses may not.

Minimal complete PUT example (no catalog seed data required):

```json
{
  "display_name": "Development student",
  "university_id": null,
  "program": null,
  "semester": null,
  "bio": null,
  "mbti_badge": null,
  "visibility": "private",
  "courses": [],
  "skills": [],
  "preferences": {
    "study_mode": null,
    "preferred_language": null
  }
}
```

PUT returns 200 with the same PROFILE representation as GET, plus request_id. Courses and skills are sorted by UUID. Repeated identical PUTs retain one profile/preference row and unique pivots; internal timestamps may change. No catalog fields, verification status or identity timestamp can be written here.

Optional safe initialization precondition: `X-Re-Require-Empty-Profile: true` requires every nullable writable field/preference to be null, courses/skills empty and visibility private. Laravel checks this under the same owner row lock before writing; non-empty content returns 409 `PROFILE_NOT_EMPTY` with no profile modifications. Other header values return 422. Ordinary PUTs without the header retain existing replacement behavior. The development dummy validation client always sends this header; it is not an authentication bypass or an account selector.

Both endpoints are owner-only regardless of visibility. Success and handled errors carry X-Request-ID and Cache-Control containing no-store. Errors retain {error: {code, message, details}, request_id}: 401 UNAUTHENTICATED, 403 FORBIDDEN, 422 VALIDATION_ERROR (field-to-message arrays in details), 409 REFERENCE_CONFLICT for catalog races, 429 RATE_LIMITED (Retry-After), and 503 AUTH_UNAVAILABLE/SERVICE_UNAVAILABLE. Existing shared rate limit is 60 attempts/minute/IP across authenticated endpoints. Authentication may provision the local identity before invalid domain input is rejected.

PUT serializes owner updates and atomically replaces profile/preferences/course/skill selections. No cross-user URL or client-selected owner is supported. These routes do not provide public-profile browsing, catalog CRUD or enrollment verification.

See [Phase 2D audit and validation](phase-2d-status.md). Generated Flutter clients and Phase 2E UI are not implemented.

## Implemented Backend Sprint A academic catalogs

All paths below include `/api/v1`. GET routes reuse `AuthenticateSupabase`, JWT verification, account status checks and the shared 60 attempts/minute/IP limit. Success and handled errors include `X-Request-ID`, matching JSON `request_id`, and `Cache-Control: no-store, private`. No new auth mechanism or catalog write routes exist.

| GET path | Allowed response item fields | Sort ascending | Maximum IDs |
| --- | --- | --- | --- |
| `/universities` | `id`, `name` | `name`, then `id` | 50 |
| `/courses` | `id`, `university_id`, `code`, `name` | `code`, then `id` | 100 |
| `/skills` | `id`, `normalized_name` | `normalized_name`, then `id` | 100 |

Common query parameters:

- `q`: optional nullable string, maximum 100 characters. Case-insensitive substring search; universities search name, courses search code or name, skills search normalized_name. `%`, `_`, and backslash are literal characters, not wildcard syntax. Standard Laravel trimming/empty-string-to-null applies; blank search does not filter.
- `limit`: optional integer 1–50, default 20. Empty, null, malformed and out-of-range limits return 422.
- `ids`: optional UUID list using `ids[]=UUID&ids[]=UUID` (or sequential numeric indices). Enforce the limits above and uniqueness ignoring UUID case. Unknown but valid IDs simply do not match. IDs are normalized to lowercase. An empty list, when represented, matches nothing. IDs never override other filters or the response limit; split label-resolution requests into batches of at most 50 and set `limit=50` as needed.
- Courses only: `university_id`, optional nullable UUID referencing an existing university. A supplied UUID returns that university's courses **plus global courses** (`university_id IS NULL`), never another university's courses. Missing/null/blank means no university restriction (all catalog scopes). Unknown or malformed university UUIDs return 422.

Filters intersect; the code/name search OR and university/global OR are grouped within that intersection. Ordering uses database collation with UUID tie-breaking, not input ID order. Responses are bounded lists, not cursor-paginated results; narrow `q` to find additional entries.

Unknown query parameters and non-empty request bodies return 422 `VALIDATION_ERROR` with field-to-message arrays in `error.details`. Empty JSON objects/lists are treated as no body. Only allowlisted columns are selected and serialized: no verified_domains, timestamps, users, enrollments, skill levels or private profiles.

Illustrative responses below use fictional development fixtures, not official institution/course records or existing development IDs:

```json
{"data":[{"id":"00000000-0000-4000-8000-000000000001","name":"Development University A (DUMMY)"}],"request_id":"<request-id>"}
```

```json
{"data":[{"id":"00000000-0000-4000-8000-000000000002","university_id":null,"code":"DEV-G101","name":"Development Study Foundations (DUMMY)"}],"request_id":"<request-id>"}
```

```json
{"data":[{"id":"00000000-0000-4000-8000-000000000003","normalized_name":"dart"}],"request_id":"<request-id>"}
```

No matches or empty catalogs return `200 {"data":[],"request_id":"<request-id>"}`. Errors preserve the existing envelope: 401 `UNAUTHENTICATED` (`WWW-Authenticate: Bearer`), 403 `FORBIDDEN`, 422 `VALIDATION_ERROR`, 429 `RATE_LIMITED` (`Retry-After`), 503 `AUTH_UNAVAILABLE` / `SERVICE_UNAVAILABLE`. Catalog database errors return a generic 503 without SQL details.

Catalog handlers are read-only. Existing JWT middleware can provision a missing local identity and update rate-limit/JWKS caches; this existing behavior is unchanged. Repeated reads for existing identities do not mutate domain tables. Catalogs are shared reference data, not user records; no user selector is accepted.

# Proposed REST API contract (design, not implemented)

Prefix `https://api.example.invalid/api/v1` (replace with owned domain). `Authorization: Bearer <Supabase access JWT>`; UUID IDs; JSON ISO-8601 UTC; cursor pagination. Error envelope `{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": {} }, "request_id": "..." }`.

| Method / path | Purpose | Access / checks |
|---|---|---|
| GET /health | health | public but no internals exposed |
| GET /me | hydrate/provision account | valid JWT |
| PATCH /me/profile | update academic profile | owner, validated fields |
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

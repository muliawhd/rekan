# Phase 2B: Laravel JWT authentication

## Implementation — 2026-11-13

The owner explicitly confirmed this configured Supabase project is exclusively for Re development/testing with no production use/data, and authorized Phase 2B. Classification is based on owner confirmation, not its URL/name. Phase 2C remains out of scope.

Supabase Cloud remains the sole identity provider; local Docker PostgreSQL stores application users and Redis handles cache/rate limits/queues. No academic tables, onboarding, matching, chat, cloud writes or production modifications are included.

## Security implementation

- `firebase/php-jwt` verifies signatures with explicit RS256/ES256 allowlist and matching public-key type/algorithm. Enforce bounded `kid`, exact configured issuer, authenticated audience/role, integer future expiration and non-nil UUID subject. Library checks future `nbf`/`iat`. Unverified headers are only key-selection hints; identity comes from verified claims. Remote key-location and critical headers are rejected.
- JWKS endpoint must match the configured HTTPS Supabase Cloud root. Redirects disabled; connect/total timeouts 2/5 seconds. Reject unsupported, invalid or ambiguous keys and responses over 64 KiB/20 keys.
- Redis cache TTL: 300 seconds. Atomic project-wide 30-second refresh cooldown bounds unknown-key traffic and rotation refreshes. New keys may wait for the cooldown; publish rotation keys before use. No expired-cache outage fallback. Old cached keys may remain valid until TTL expiry; provider/CDN caching is outside this cache.
- Middleware sets `$request->user()` from the verified UUID. Policies may use `Gate::forUser($request->user())`. Framework-merged password/session guards/providers/brokers are cleared; no Laravel password login exists.
- Rate limit: 60 attempts/minute/IP before token verification. Redis/key failures fail closed. Configure trusted proxies deliberately if topology changes.

## API and local provisioning

`GET /api/v1/me` returns `{data: {id, status, created_at}, request_id}` with `Cache-Control: no-store` and `X-Request-ID`. It ignores supplied user IDs and privilege metadata. Missing/malformed/invalid/expired tokens return 401 `UNAUTHENTICATED` plus `WWW-Authenticate: Bearer`. Disabled/rejected/unknown user statuses or denied policies return 403 `FORBIDDEN`; pending/verified users may read their identity. Errors use `{error: {code, message, details: {}}, request_id}`. Rate limiting returns 429 `RATE_LIMITED` with `Retry-After`; key/cache failure returns 503 `AUTH_UNAVAILABLE`; provisioning failure returns 503 `SERVICE_UNAVAILABLE`. No sensitive exception content is returned.

Local users have UUID primary key, pending status and UTC timestamps only, without passwords/email duplication or cloud schema FKs. `firstOrCreate` plus primary-key uniqueness and Laravel unique-conflict recovery provide idempotent provisioning without updating existing data. Applied the identity-only migration after verifying local environment, loopback PostgreSQL/5433 and no existing users table. Created migration repository and users table; no existing rows were overwritten.

## TLS and dependencies

Compatible Composer constraint `~7.0.0` resolves to locked `firebase/php-jwt` 7.0.5. Composer reported no vulnerability advisories. PHP initially rejected the real JWKS certificate chain (cURL 60). Optional `SUPABASE_CA_BUNDLE` points this workstation at Git's installed trusted CA bundle; empty uses PHP/system trust. TLS verification is never disabled. Other machines need their own valid trust configuration.

## Verification

Security tests cover missing/malformed tokens, forged signatures, expiry, issuer/audience/UUID/algorithm errors, RS256/ES256 success, privilege metadata isolation, two-user ID selection, disabled accounts, test-only owner-policy denial, rotation/cooldown/outage/malformed JWKS, endpoint pinning, stale-cache rejection, rate limits and reversible migration. PostgreSQL tests use random schemas inside rolled-back transactions and never reset existing tables.

Final rerun with locked JWT library 7.0.5 and TLS configuration: full Laravel suite passed **27 tests / 128 assertions**; isolated PostgreSQL suite passed **22 tests / 156 assertions**. Route list exposes only two health routes and protected `/api/v1/me`; Pint and Composer validation passed. Compose, live PostgreSQL SELECT 1, both Redis PING connections and both HTTP health routes passed. Public development JWKS publishes one ES256 key. The actual Laravel loader successfully fetched/parsed that key with TLS verification and read it back from Redis. `git diff --check` passed. No real user token was used.

Real Supabase login/access-token round trip and mobile recovery remain **unverified**. No test-user credentials/token were supplied and no accounts were created. Simultaneous multi-process provisioning was not load-tested; sequential idempotence and database uniqueness were tested. Flutter is unchanged and was not retested for this backend-only milestone.

## Changed files and rollback

Backend: Composer manifest/lock, `config/supabase.php`, `.env.example`, local ignored CA setting, application provider, new `app/Modules/Identity` verifier/JWKS/model/middleware/controller, identity migration, routes, exception handler, security tests and test OpenSSL configuration. Documentation: this report, prior confirmation notes, API contract, README and checklist. Existing unrelated changes are preserved.

Rollback access by reverting route/middleware wiring while retaining user rows. Migration down becomes destructive once users exist and must not run without data review/approval. Only disposable test schemas exercised rollback automatically.

Stop for review. Phase 2C has not started.

# Phase 2 proposal: Supabase Authentication and Academic Profile Database

Current checkpoint (2026-11-15): Phase 2B.1 manual evidence and regressions are recorded, and the user authorized Phase 2C. The bounded academic database migration is implemented and applied locally; see [Phase 2C status](phase-2c-status.md). The older checkpoint groups and cloud-database setup language below are historical: domain data remains in local Docker PostgreSQL. Phase 2D is not started.

Historical proposal below. The user authorized Phase 2A configuration on 2026-11-13 and reported successful emulator startup. See [current Phase 2A status](phase-2a-status.md) for implementation, scope reconciliation and blockers. The user's incremental 2A–2F sequence supersedes the checkpoint grouping below. No domain migrations or Laravel authentication have been implemented.

## Decisions and setup

Use a dedicated development Supabase project with dashboard-provided URL, public key, issuer/JWKS and SSL database connection. Separate migration/runtime roles; secrets remain server-only. Confirm login method (proposed email/password with confirmed email), mobile redirect identifiers, university seed data, profile visibility defaults and enrollment-review policy. Domain matching is only a signal; pending users cannot self-assign verified status. Select and lock Flutter 3.50-compatible Supabase dependencies with secure session storage.

## A. Identity checkpoint

1. Define OpenAPI schemas for `/api/v1/me`, auth errors, catalogs and profile mutations before generated clients. Preserve the documented error envelope and request IDs.
2. Add minimal accessible signup/login, confirmation, session restore/refresh and logout flows in Flutter.
3. Verify JWT signature, allowed algorithm, key ID, issuer, audience, expiry and UUID subject in Laravel. Bound JWKS caching, support controlled rotation refresh and fail closed. Never trust request-body identity or duplicate passwords in Laravel.
4. Add Laravel-owned public users, universities and student_verifications tables. User UUID equals Supabase UID; provisioning is idempotent under concurrent requests. Supabase continues to own auth.users. Explicitly gate disabled/unverified accounts while allowing onboarding.
5. Test forged/expired/wrong-project/wrong-audience/wrong-algorithm tokens, missing subject, key rotation, unauthenticated requests and attempted status elevation. Record real development Supabase signup/login/refresh/logout and Laravel account hydration.

## B. Academic profile checkpoint

1. Add reversible migrations for academic_profiles, courses, skills, user_courses, user_skills, intents, availability_slots, competition_roles and intent_roles. Use UUIDs, FK/unique/check constraints, UTC timestamps and documented indexes. Handle global course-code uniqueness explicitly when university_id is null.
2. Define bounded profile fields, semester/skill-level ranges, university/course consistency, visibility, supported time zones and nonoverlapping availability. MBTI is optional display-only metadata.
3. Implement authenticated catalog reads, owner-only profile writes and intent endpoints from the existing API contract. Derive ownership from verified JWT identity; whitelist input/output fields. Gate eligible-student actions separately from pending-user onboarding.
4. Deny mobile Data API access to business tables. Flutter uses Laravel for domain data; test database grants independently of Laravel policies.
5. Test PostgreSQL migrations/rollback and constraints, duplicate provisioning, two-user IDOR, invalid catalog/availability values and privacy fields. Add minimal accessible profile onboarding only after the database/API checkpoint is reviewed.

## Acceptance and rollback

- Two real development Supabase accounts complete identity/profile round trips; invalid and unauthorized requests fail with documented errors.
- Repeated/concurrent `/me` preserves one UUID account. Profile payloads cannot change identity or verification status.
- Owner profile/catalog/intent operations persist in PostgreSQL; cross-user writes and direct client table access are denied.
- Tests, analysis and CI pass; real integration evidence contains no credentials. No MBTI ranking, matching, invitations, materials, chat, Realtime, FCM or production deployment is included.
- Review migrations and rollback on disposable development data. Disable auth entry points or roll back releases while preserving identities and profile data; never automatically drop production tables.

Present each checkpoint with test results, integration evidence and rollback notes before continuing. User approval of this plan is still required after Phase 1 validation.

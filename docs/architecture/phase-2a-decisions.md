# Phase 2A architecture decisions — 2026-11-13

Approved by the user during configuration resolution:

| Responsibility | Decision |
| --- | --- |
| Identity and sessions | Supabase Cloud Auth; Flutter Supabase SDK manages sessions |
| Domain data | Existing local Docker PostgreSQL; no migration to Supabase Cloud |
| Cache and queue | Existing local Docker Redis |
| Canonical user identifier | Verified Supabase Auth UUID (`sub`); future Laravel `users.id` uses the same UUID |
| Authorization | Laravel middleware and policies; no client-supplied ownership IDs |
| JWT verification | Future Laravel server-side JWKS verification with issuer, audience, expiry and allowed algorithm checks |
| Current scope | Configuration resolution only; do not implement Phase 2B |

This supersedes the copied kit's Supabase-hosted domain database topology and connection guidance. Supabase-managed `auth.users` stays in the cloud; application users and academic data stay local, linked by UUID in service logic. Redis is not an identity store. No second password system is permitted.

## Project classification is still unconfirmed

**Superseded:** the owner's Phase 2B authorization confirms exclusive development/testing use with no production application/data. Phase 2B is now implemented; see [report](phase-2b-status.md). Findings below describe the earlier preflight, not a current blocker.

The non-secret local configuration identifies a hosted project endpoint, but no inspected documentation or configuration establishes that this particular project is development-only. Local `APP_ENV` and a Supabase URL do not establish the cloud project's intended environment. Obtain owner confirmation before creating test accounts or exercising real authentication. No cloud resources were modified or project-authenticated requests made during this resolution.

## Configuration contract

The ignored Laravel environment has one occurrence of each Supabase variable. Populated URL, public key, server secret and existing JWKS value were preserved; empty duplicate URL/JWKS entries were removed. Issuer is the HTTPS project root plus `/auth/v1`, JWKS is that root plus `/auth/v1/.well-known/jwks.json`, and expected user audience is `authenticated`. Runtime checks validated those relationships through Laravel configuration. These formats follow the official [JWT documentation](https://supabase.com/docs/guides/auth/jwts) and [claims reference](https://supabase.com/docs/guides/auth/jwt-fields).

`config/supabase.php` exposes configuration only; it does not verify or accept tokens. JWKS verification needs no privileged Supabase key. Existing server credentials remain server-only and are not copied into Flutter. The public mobile template remains unconfigured.

## Identity inspection finding

Laravel merges framework `web` guard, Eloquent `users` provider and password-broker defaults into the empty arrays in the application auth config. The default guard and password broker remain null. There are no application login routes, user model or password migrations; the only HTTP routes are health checks. Thus there is no implemented second identity provider, but the dormant merged defaults must be explicitly addressed when configuring the Phase 2B guard. No guard/middleware was implemented in this resolution.

## Readiness

Local configuration is ready for Phase 2B planning. Phase 2B execution is not authorized. Cloud project development classification and its actual signing-key algorithm/JWKS contents remain unverified. Real login, token verification and session recovery are not acceptance claims for Phase 2A.

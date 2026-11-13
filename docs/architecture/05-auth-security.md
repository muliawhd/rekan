# Security, authentication, and privacy

## Identity decision
Use Supabase Auth for one identity source. Flutter stores session using supported SDK secure session handling; Laravel **verifies JWT signature with Supabase JWKS**, algorithm/kid, issuer, audience and expiry, caches keys carefully, and maps `sub` to `users.id`. Never trust `user_id` from request body for ownership. Verify exact accepted token type and auth project configuration during implementation.

## Student verification
A university email domain is a *signal*, not guaranteed proof of enrollment. MVP: email confirmation + approved domain list + optional manual review or student SSO integration where available. Set explicit states pending/verified/rejected and define policy for universities without official SSO.

## Authorization matrix
- Profile: owner writes; public discovery gets explicitly whitelisted academic fields.
- Invitations: sender creates; recipient responds; both can view own records.
- Connections: only involved users can list.
- Conversation: members only; unauthorized user receives 403/404 without resource leakage.
- Materials: private storage; allow only entitled student with distribution rights; expire signed URL.
- Admin/moderator: separate scoped role, audit all sensitive operations.

## Supabase details
- Restrict exposed Data API privileges; Flutter should not issue arbitrary CRUD to business tables.
- For `realtime.messages`, enforce membership via RLS and private channels (`private: true`). Disable public access to channels before production, after policies/tests are in place. Test joining other conversations with a second user token.
- Supabase Storage private buckets + scoped RLS; do not give client service-role secret.
- Server Postgres account can bypass RLS: Laravel domain policies must be tested independently.

## General measures
TLS everywhere; strict CORS if later web frontend; input validation; API throttling; prepared queries; signed upload/download; content type + size + malware validation for uploads; secrets via environment/secret manager; key rotation; audit logs without PII/secrets; backup restore tests; data deletion policy; report/block feature before social communication release.

## Test scenarios
Cross-user IDOR (profile, invite, chat, materials), replayed invite acceptance, double click/idempotency race, JWT expired/wrong issuer/wrong audience, private Realtime channel unauthorized join, forged broadcast, revoked FCM token, path traversal in ZIP batches, malicious file types, sensitive data logging.

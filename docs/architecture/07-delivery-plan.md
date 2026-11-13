# Codex delivery milestones

## Iteration 0 — Repo and scaffolding
Make Flutter and Laravel projects boot; add formatter, CI, env examples and local Docker services. Define issue template. No production infra claims.

## Iteration 1 — Identity
Supabase Auth Flutter login, Laravel JWT verification, user provisioning, verified student gating, auth/negative tests.

## Iteration 2 — Academic profile
University/course/skill catalogs, profile mutations, availability and academic intent, validations, API tests and screen-reader accessibility.

## Iteration 3 — Matching
Hard constraints -> weighted explainable ranking; MBTI excluded; consistent tie-breaking; pagination; unit tests for edge cases.

## Iteration 4 — Invites and connections
Atomic invite lifecycle, idempotency, two-user ownership tests, notifications as durable outbox or after-commit queue.

## Iteration 5 — Materials P0
Rights-gated private uploads; authorized batch download jobs; ZIP sanitization; expiry; audit + cost limits.

## Iteration 6 — Chat, FCM, workspace P1
Only after P0 complete. Separate design/API/security reviews and multiuser realtime tests.

## Definition of Done
Code + migration + tests + documentation + real integration result + rollback note; no placeholders reported as functioning. Run one milestone per Codex task. Commit checkpoint per milestone.

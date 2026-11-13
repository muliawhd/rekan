# Codex Rules — Re:kan

Read `README.md` and task-relevant docs ONLY, not entire repository by default.
- Never change Flutter + Laravel + Supabase + FCM stack without user approval.
- Supabase Auth is source of identity; Laravel policies own domain authorization.
- Client must not access secrets, privileged DB roles, private data, or trusted broadcasts.
- Match weights cannot include MBTI, attractiveness, popularity, or unrelated social metrics.
- Implement one bounded task per change; edit only relevant modules.
- Write appropriate unit/integration/security tests and execute them; state which were NOT run.
- Never fabricate environment credentials, passing tests, deployment states, or working API endpoints.
- Follow API contract, migration ownership, and privacy/security docs.
- No premature microservices, abstractions, or unrelated refactors.
- After every task return changes, validation results, blockers, next actionable step.

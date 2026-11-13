# Codex kickoff task

Analyze `README.md`, `docs/01-product-scope.md`, `docs/02-system-architecture.md`, `docs/05-auth-security.md`, `docs/07-delivery-plan.md`, and `AGENTS.md`.

Implement **Iteration 0 only**:
1. Scaffold Flutter mobile in `apps/mobile` and Laravel API in `services/api` using installed supported toolchains.
2. Configure local Postgres and Redis via `infrastructure/docker/compose.yaml` without committing secrets.
3. Implement an unauthenticated `/api/v1/health` check, with test.
4. Add project README commands and basic formatter/linter/test scaffolding.
5. Run available checks and report exact outputs. If a toolchain is missing, stop that step and explain; do NOT simulate successful execution.

Do not implement authentication or other features in this iteration. Do not rewrite architecture. Do not create fake Supabase/Firebase credentials.

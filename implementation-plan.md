# Phase 1 implementation plan

1. Inspect the existing project and the complete architecture kit. **Done.**
2. Preserve the native Android project and kit; initialize a Git monorepo and required directories. **Done.**
3. Configure loopback-only local Postgres/Redis, health checks, safe environment templates and setup scripts. **Done; Compose configuration validated.**
4. Generate real Laravel 12 and Flutter stable projects using installed supported toolchains. **Blocked: PHP/Composer/Flutter absent.** Authored overlays and official-generator scripts are prepared, not generated application substitutes.
5. Apply the minimal public health controller/tests and feature-based Flutter shell/test. **Prepared; application execution pending step 4.**
6. Validate formatter, routes, Laravel tests, Flutter doctor/analyze/tests, Android debug build, running containers and HTTP smoke. **Partially checked; see validation report.**
7. Pin the actual Flutter SDK, commit generated lockfiles, add CI running the validated commands, and review a Git checkpoint. **Pending.**

No matching, authentication, chat, notifications, domain schema or full screens are implemented. No architectural stack changes are proposed. Infrastructure rollback is `scripts/dev.ps1 -Target infra-down`, preserving volumes. Generated source stays in its own directories and the existing Android project remains intact.

After all Phase 1 gates pass, the next phase is Supabase identity: JWT signature/issuer/audience/expiry verification, UUID provisioning, student gating, secure Flutter sessions and negative authorization tests. Product questions in the preserved architecture kit remain open.

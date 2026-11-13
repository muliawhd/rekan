# Phase 1 reconciliation — 2026-11-13

All ten requested kit documents were read before implementation. The selected stack and service responsibilities are consistent.

| Difference | Resolution within Phase 1 |
| --- | --- |
| User says Re; kit uses Re:kan | Use Re as the shell title; retain `rekan` directory and historic kit wording. |
| User requests `/api/health`; kit requires `api/v1` | Prepare canonical `/api/v1/health` plus `/api/health` alias using one controller. |
| Existing `rekan` is a native Kotlin/Compose Android scaffold | Preserve it in place; new Flutter app goes under `apps/mobile`. Root Android builds remain separate. |
| User groups documentation in subdirectories; kit has flat docs | Preserve a snapshot under `docs/architecture` and add pointers in other doc folders. |
| Kit requires supported installed toolchains; Flutter/PHP/Composer are missing | Stop generator steps as instructed. Prepare overlays and setup scripts without claiming app initialization. |

The kit's six-week workspace/forum schedule and narrow P0 scope remain unresolved product decisions, irrelevant to this foundation slice. Suggested Riverpod/go_router/Dio are not mandatory and are deferred until needed. No cloud provisioning or schema changes are made. Default Laravel password identity scaffolding is excluded by bootstrap to avoid conflicting with Supabase Auth.

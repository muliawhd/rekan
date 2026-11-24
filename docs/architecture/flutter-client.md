# Flutter client architecture — Phase 2E.1

## Audit and boundaries

Iteration B now routes normal startup through AuthBoundary using the Iteration A theme; the debug validation override remains unchanged. `features/auth` contains an injectable SDK gateway, ChangeNotifier controller and presentation. Existing SDK secure session storage is reused. Server getUser verification gates the safe placeholder; generation/revision checks reject stale account results. Public form navigation never selects protected content. There are no onboarding routes or profile requests in this boundary. See [Iteration B status](phase-2e2-iteration-b-status.md) for email confirmation and intentionally unavailable recovery behavior. Earlier A-only notes below describe that checkpoint.

Phase 2E.2 Iteration A adds opt-in design tokens/theme and presentational form primitives only. Active navigation, SDK initialization and debug validation routing are unchanged. See [Phase 2E.2 plan](phase-2e2-plan.md) for proposed later auth/onboarding layers and missing catalog/recovery contracts.

The existing Flutter app uses material_ui, the existing AppTheme/foundation shell, supabase_flutter and flutter_secure_storage. Riverpod, go_router and Dio were suggestions in the original architecture, not installed requirements. Phase 2E.1 adds no dependencies, generated clients or alternate session store. Native mobile dart:io HTTP plus small injectable interfaces fit the current architecture; web authentication remains unsupported by existing initialization.

Supabase initialization and project-scoped OS secure storage are unchanged. SupabaseApiSession adapts the existing GoTrueClient and exposes an in-memory snapshot; it never serializes tokens. SDK auto-refresh remains enabled. Sign-in/out and session-stream errors advance a session generation so pending requests cannot replay into a different login.

## Layers

- core/auth/api_session.dart: existing SDK session adapter; injectable session source for tests.
- core/network/laravel_api.dart: endpoint enum, typed decoder boundary, safe failures and native HTTP transport.
- features/academic_profile/data: immutable writable input, read DTO, preferences/skill DTOs and GET/PUT repository.
- features/academic_profile/presentation: ChangeNotifier controller and debug validation panel.
- Existing auth_validation_page: owns/disposes these objects; uses the typed client for /me and clears profile state on authentication boundaries.

The shell and theme are unchanged. The panel is reached through the existing kDebugMode + AUTH_E2E_ENABLED + configured-Supabase gate and also hides itself outside debug. No final onboarding UI exists.

## Request and session rules

The configured API root must be HTTPS, without userinfo/query/fragment, at /api/v1. Only debug builds permit the exact emulator root http://10.0.2.2:8000/api/v1. Endpoint paths come from an enum; the transport disables redirects and preserves TLS validation. Requests have a 15-second total transport timeout, a 5-second connection timeout and a 1 MiB response limit.

Bearer tokens are taken from the SDK immediately before sending and remain in memory. No token, raw SDK exception or response body is logged. Errors expose a fixed safe message and typed category/status, not arbitrary server text. Server validation still owns all business rules.

An expired cached session triggers one SDK refresh before sending. A first 401 can trigger one shared refresh and one replay if refresh has not already been attempted. Concurrent requests share a refresh future; an already-rotated token can be reused. A second 401, or a 401 after proactive refresh, terminates with an authentication failure. Redirects, network failures, 403/409/422/429/5xx are not retried. PUT bodies are copied before sending so a retry cannot change the approved payload.

Every response and refresh completion rechecks account ID and session generation. Logout/account changes discard pending results and prevent replay. Refresh failure asks for sign-in without inventing a second login system or deleting unrelated SDK state. A request already accepted by Laravel cannot be undone by logout; no such guarantee is made.

## Contract and state

DTOs match the actual [Phase 2D contract](04-api-contract.md). The read DTO has userId; AcademicProfileInput deliberately has no user_id/status/timestamps and always emits all ten writable fields, including nulls and empty lists. Visibility and study mode use enums. Repository responses must match the authenticated UUID. GET/PUT both pass through Laravel middleware; Flutter never queries PostgreSQL.

Controller states are idle, loading, empty, success and error. Empty means all profile content is empty/private; it does not claim there is no database row because the API does not expose that distinction. No profile disk cache is introduced. Clearing/disposal invalidates pending results, and failures clear previously displayed profile data.

The debug panel performs GET without mutation. Its approved dummy PUT/GET check verifies `/me`, requires a fresh empty profile, displays exact dummy values and session UUID, then rechecks after confirmation. It uses the atomic empty-profile header and compares both responses against submitted values. No automatic test-account creation or real profile modification occurs during startup. See the final Phase 2E.1 report for manual persistence evidence and limitations.

## Validation

See [Phase 2E.1 status](phase-2e1-status.md). Flutter tests inject session sources/transports; they do not prove real Supabase refresh or a live profile round trip. SDK storage tests continue using OS-storage mocks. Native platform/emulator validation remains separate.

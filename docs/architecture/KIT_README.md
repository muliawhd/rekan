# Re:kan — Architecture & Infrastructure Kit v1.0

**Source:** MCT abstract (Re:kan), supplied Campus Connect product-flow JPG. **Status:** design proposal, NOT deployed or tested code. Date: 2026-11-13.

## Architecture decisions
- Flutter/Dart mobile; Laravel REST API modular monolith; Supabase Postgres/Auth/Storage/Realtime; Firebase Cloud Messaging; Redis for server cache/queues.
- Laravel owns business writes and policies. Flutter uses Supabase SDK for authentication and authorized Realtime subscriptions only; client must not mutate business tables directly.
- One identity source: Supabase Auth UUID, represented as `users.id` UUID. Laravel verifies Supabase-issued JWT by JWKS and checks authorization using its own database records.
- Laravel migrations own `public` business schema. Supabase-managed `auth` and `realtime` schemas are not touched by Laravel migrations.
- Realtime uses private broadcast channels controlled by Supabase RLS; Laravel publishes authorized events AFTER DB commit via server credentials. Do not expose service role key on mobile.
- Laravel sends FCM through queued jobs. FCM tokens are sensitive, and sending must occur only on server.
- Scope: P0 login, onboarding, academic matching, invitations, batch material download subject to access rights; P1 chat, push, workspace; P2 forums and advanced workspace.

## Read order
1. `docs/01-product-scope.md`
2. `docs/02-system-architecture.md`
3. `docs/03-data-model.md`
4. `docs/04-api-contract.md`
5. `docs/05-auth-security.md`
6. `docs/06-infrastructure-deployment.md`
7. `docs/07-delivery-plan.md`
8. `AGENTS.md`

## Local prerequisites
Flutter stable + Android Studio SDK/emulator; PHP/Composer compatible with chosen Laravel version; Docker Desktop; Git; Supabase project for hosted integration; Firebase project for push. iOS build requires macOS/Xcode.

## Kickoff
1. Create repository and scaffold Flutter under `apps/mobile` and Laravel under `services/api` (this kit intentionally provides specs, not fake generated app code).
2. Copy `services/api/.env.example` to its Laravel `.env`, fill secure local secrets and DB endpoint; keep out of Git.
3. Run `docker compose -f infrastructure/docker/compose.yaml up -d` for local Redis/Postgres; DO NOT use local Postgres as proof of Supabase Auth/Realtime integration.
4. Implement Supabase JWT verification before protected API routes.
5. Use docs as contracts and implement iteration by iteration.

See `docs/08-open-questions.md` before shipping.

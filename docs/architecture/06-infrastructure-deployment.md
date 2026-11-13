# Infrastructure & deployment design

## Environments
- `local`: Flutter emulator + Laravel app + Docker local Postgres & Redis; Supabase cloud Auth/Realtime testing requires dedicated dev Supabase project. Never treat local Postgres as same as hosted Supabase project.
- `staging`: dedicated Supabase project, Firebase config, hosted Laravel API+worker, private Storage, test users and seeded data.
- `production`: separate Supabase and Firebase projects, secrets, domain/API TLS, managed Redis, monitored Laravel app and worker, backups and alerts.

## Topology
`Flutter app -> api.example domain -> HTTPS reverse proxy/managed ingress -> Laravel app container -> Supabase Postgres`; worker process for notifications/ZIP; Redis used by API/worker; external Supabase Auth/Realtime/Storage and FCM. Do not deploy Redis with unprotected public port.

## Database connection
For IPv4-only persistent Laravel hosting use Supabase shared **session** pooler and its dashboard-provided host/username/port; for IPv6 use direct connection if appropriate. Do not assume `db.project.supabase.co` IPv4 reachable. Copy exact settings from Supabase Connect. Prefer SSL and least-privileged DB role; migration permissions separated as practical.

## Local services
`infrastructure/docker/compose.yaml` includes local Postgres and Redis only. Secrets are sample-only. It is NOT a full clone of Supabase Auth/Realtime/Storage. Laravel and Flutter projects are intentionally unscaffolded in the kit.

## Delivery pipeline (proposal)
- PR: format/lint/analyze, PHPUnit feature+unit, Flutter tests, migration review, secret scan, dependency audits.
- Staging: deploy API + worker, run migrations with verified backup/rollback, smoke tests across real Supabase JWT, realtime, Storage and FCM device.
- Production: approved release, healthchecks, worker supervision, controlled database migrations, rollback strategy, backups/restore drills.

## Operational visibility
Request IDs; app error rates; P95 route latency; queue backlog/failure; DB connection saturation; realtime join errors; notification delivery; storage egress and ZIP job time. Alert on 5xx surge, queue age, backup failures, suspicious auth spikes.

## Cost control
Start with dev/free capacity where service limits permit. Profile actual load before moving to paid plans. Batch ZIP requires storage/egress budget, retention cleanup and size limits. Avoid FCM duplicate sends and aggressive realtime fanout.

## Provisioning checklist
[ ] Supabase dev + prod projects separated
[ ] Database regions chosen and documented
[ ] Firebase Android project configured; iOS APNs later
[ ] Laravel hosting and managed Redis selected
[ ] HTTPS/API DNS configured
[ ] Secrets and rotation configured
[ ] Storage bucket private and policy reviewed
[ ] Backups & restore tested
[ ] Realtime RLS multiuser test passed
[ ] Monitoring, logs, crash reporting set up

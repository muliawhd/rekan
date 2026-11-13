# Flutter configuration contract

Safe to compile as client configuration (still don't embed user secrets):
- `API_BASE_URL` (Laravel HTTPS endpoint)
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY` (public, project-scoped)
- platform Firebase configuration generated using supported FlutterFire tools

NEVER include: Supabase service-role key, Postgres passwords, Google service-account JSON/private key, FCM send credentials, Laravel APP_KEY.

Flutter local Android emulator often calls host backend through `http://10.0.2.2:8000` rather than `localhost`; use secure HTTPS URLs for shared environments and production. Avoid permissive production cleartext rules.

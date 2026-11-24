# Supabase integration boundary

Phase 2A update: Flutter SDK initialization and secure session storage are now
implemented. Supabase Cloud Auth plus local Docker domain PostgreSQL and Redis
are approved; only the configured cloud project's development status remains unconfirmed. See
[Phase 2A status](../../docs/architecture/phase-2a-status.md). No cloud resources
or existing database configuration were changed.

No Supabase project is provisioned or connected in Phase 1. Local PostgreSQL is not an emulator for Auth, Realtime or Storage.

Later use a separate development project, exact dashboard connection settings and SSL. Laravel migrations own application `public` tables; never migrate Supabase-managed `auth` or `realtime` schemas. UUID identity comes from Supabase Auth. Block mobile business-table writes, enforce private Storage/Realtime policies, and verify Laravel authorization independently of database RLS. Server secrets belong only in ignored server environment files or a secret manager.

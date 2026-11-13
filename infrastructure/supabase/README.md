# Supabase integration boundary

No Supabase project is provisioned or connected in Phase 1. Local PostgreSQL is not an emulator for Auth, Realtime or Storage.

Later use a separate development project, exact dashboard connection settings and SSL. Laravel migrations own application `public` tables; never migrate Supabase-managed `auth` or `realtime` schemas. UUID identity comes from Supabase Auth. Block mobile business-table writes, enforce private Storage/Realtime policies, and verify Laravel authorization independently of database RLS. Server secrets belong only in ignored server environment files or a secret manager.

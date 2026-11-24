# Re:kan — IMPLEMENTATION_CONSTRAINTS.md

## Non-negotiable architecture

Keep:

- Flutter/Dart frontend
- Supabase Cloud Auth only
- Laravel REST API
- local PostgreSQL domain data
- Redis infrastructure
- canonical Supabase UUID identity mapping

## AI implementation boundaries

### Allowed

- presentation-layer refactors
- reusable design tokens
- reusable Flutter widgets
- navigation improvements
- form UX improvements
- widget/unit tests
- documentation
- small backend read-only additions when explicitly approved

### Not allowed without approval

- database reset
- `migrate:fresh`
- `db:wipe`
- changing canonical user IDs
- replacing Supabase Auth
- direct Flutter-to-PostgreSQL access
- inventing endpoints
- changing JWT security
- changing profile ownership rules
- adding major dependencies
- implementing future modules early

## Existing logic preservation

For UI redesign work:

- do not rewrite auth logic unless necessary,
- do not rewrite repositories unless required by the approved API,
- preserve secure session storage,
- preserve current tests,
- keep development validation tools debug-only.

## Visual implementation rule

The approved wireframe is a visual direction, not permission to hardcode fake backend data into production flows.

Use mock data only in:
- tests,
- previews,
- explicitly marked development fixtures.

## Missing backend contracts

If a screen needs:
- university catalog,
- course catalog,
- skills catalog,
- search,
- matching,
- chat,
- rooms,

and the API does not support it:

1. stop that functional integration,
2. implement only safe UI scaffolding if approved,
3. report the missing contract,
4. propose the smallest backend extension.

## Quality gates

Every implementation iteration should run:

- `dart format`
- `flutter analyze`
- `flutter test`

When backend changes occur:
- Laravel tests
- Pint
- PostgreSQL integration tests as appropriate

Never claim E2E success unless observed.

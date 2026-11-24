# Integration 3.1 - Flutter academic catalog integration

Date: 2026-11-16. Scope: authenticated catalog selectors for academic onboarding only.

## Integration and audited contract

Read repository rules, the API contract, Backend Sprint A/A.1 reports, Iteration 3 report, onboarding page/draft, catalog DTOs, profile repository, LaravelApi and SupabaseApiSession. Checked the Laravel catalog controller's validation and explicit JSON projection against the documentation. Backend responses are `{data: [...], request_id: string}`; profiles retain their existing object envelope.

The typed read-only AcademicCatalogRepository reuses the **same LaravelApi instance** as AcademicProfileRepository. No second HTTP client, hardcoded catalog UUIDs, direct database access, user-ID authorization parameter or auth implementation was added.

| Endpoint | Integration |
| --- | --- |
| GET /api/v1/universities | Search `q`, `limit=50`, and existing university ID lookup |
| GET /api/v1/skills | Search and multi-selection, existing ID lookup, preserve levels 1–5 |
| GET /api/v1/courses | Search with `university_id`; unscoped ID lookup for saved selections |

Search is explicitly submitted by the search button or keyboard action, with a 100-character input limit. Results are bounded to 50 with guidance to narrow the search. ID lookups deduplicate case-insensitively and batch into 50-item `ids[]` requests; 100 saved selections therefore do not get silently truncated. Empty lookup lists make no request. Typed parsing rejects malformed response fields and envelopes.

Backend queries without a university filter return all scopes. The picker filters these to global courses until a university is selected; with a university, it requests and displays compatible global and university-scoped courses. The local seed contains 4 universities, 8 global courses and 10 skills as documented in Sprint A.1; these are **development fixtures**, not verified official offerings or institutional course affiliations.

## Onboarding behavior and consistency

- The production onboarding boundary creates the catalog repository from its existing profile API client. Static snapshot injection remains available for existing previews/tests.
- Steps 2–4 show search, loading, results, empty, error and retry states using ReTextField, ReChip, ReSecondaryButton and ReStatusBanner inside the existing RePageScaffold design. RePrimaryButton is used for confirmation. Selected skill level controls remain 1–5.
- Search results and accumulated labels are separate; a failed search or a result excluding a selected ID never erases selections. Saved UUIDs are looked up on the corresponding selector step. Unknown IDs remain in the draft rather than being silently discarded.
- University changes first resolve selected course IDs without a university filter. If any are unresolved or the request fails, the university and selections remain unchanged. Incompatible resolved courses are listed in a confirmation dialog. Cancel changes nothing; confirm changes the university and removes only those incompatible courses. Global courses remain selected. The old bulk-clear action was removed.
- Changing steps disposes pending selector work. Session user/generation checks discard stale API responses and multi-batch results. Draft account reset clears cached labels as well as selections. A confirmation dialog is dismissed when its owning selector/account screen is disposed.
- Existing complete profile payload construction, untouched field preservation, duplicate-save lock, recoverable-error draft preservation and `X-Re-Require-Empty-Profile` protection remain in place. All saves require the existing explicit user action; catalog reads never save profiles.
- The completed profile view reuses resolved draft labels after saving. On a fresh launch of an already-complete profile, unresolved labels may still appear as UUIDs until their selector is opened; loading a full read-only profile directory is outside this iteration.

## Changed files

| File | Change |
| --- | --- |
| [laravel_api.dart](../../apps/mobile/lib/core/network/laravel_api.dart) | Catalog endpoint enum entries, encoded GET queries and typed list-envelope decoding over the existing authenticated request pipeline |
| [academic_catalog_repository.dart](../../apps/mobile/lib/features/academic_profile/data/academic_catalog_repository.dart) | New typed read-only search/lookup repository and bounded batches |
| [academic_catalog_selector.dart](../../apps/mobile/lib/features/academic_profile/presentation/academic_catalog_selector.dart) | New selector state, cached labels, retry, course review confirmation and stale-response/dialog cleanup |
| [academic_onboarding_page.dart](../../apps/mobile/lib/features/academic_profile/presentation/academic_onboarding_page.dart) | Production repository wiring, selectors in Steps 2–4, removal of bulk course clearing, completed-view labels |
| [onboarding_draft_controller.dart](../../apps/mobile/lib/features/academic_profile/presentation/onboarding_draft_controller.dart) | Clear catalog cache on account reset |
| [academic_onboarding_completion.dart](../../apps/mobile/lib/features/academic_profile/domain/academic_onboarding_completion.dart) | Update obsolete catalog snapshot documentation |
| [academic_catalog_integration_test.dart](../../apps/mobile/test/academic_catalog_integration_test.dart) | New repository, widget, session, confirmation and submission tests |

Root implementation plan and checklist updated. No backend, database, auth gateway/session implementation or production data changes.

## Verification and remaining blockers

- Dart formatter applied through the editor tooling to all seven changed/new Dart files.
- `flutter analyze`: **No issues found**.
- `flutter test`: **68 passed**. Coverage includes typed parsing, search/query scope, existing UUID lookup and batching, empty/malformed/network responses, stale account responses, loading/retry/draft preservation, university confirmation/cancel, unresolved course protection, dialog disposal, skill levels and duplicate prevention, global course selection, profile UUID submission and duplicate save protection. Narrow 320×640 layout at 200% text scale passed.
- `git diff --check`: passed.
- Real E2E: **not performed**. Android SDK `adb devices` showed no connected emulator/device; TCP check found no Laravel server listening at `127.0.0.1:8000`. No real Supabase access token was read or used. Automated HTTP transports are fixtures, not live-session evidence.
- Remaining manual acceptance: start the existing Laravel API and Android emulator, use a real authenticated session, and observe catalog GETs and onboarding selection behavior. No production catalog accuracy claim is made.

Stopped after Integration 3.1. No swipe cards, discovery/matching, chat, rooms, authentication changes, database resets or new catalog data. Wait for owner approval before Iteration 4.

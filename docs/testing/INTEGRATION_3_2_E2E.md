# Integration 3.2 - Real academic onboarding validation

Date: 2026-11-16. Validation only; no product features or profile writes authorized by this report.

## Latest: academic-profile loading investigation (2026-11-17)

**Outcome: real authenticated read-only checks PASS; exact cause of the originally reported 5xx remains unconfirmed.** No speculative product-code fix was made. The installed app's existing Supabase session was recovered after reopening its process, and its actual profile controller was reloaded using GET only. No reinstall, storage clearing, sign-out, live PUT/POST/PATCH/DELETE, database reset, migration, seed or existing-user update was performed by this investigation.

### Failure evidence and limits

The reported Indonesian service-unavailable message corresponds to `ApiFailureKind.unavailable`; `LaravelApi` maps HTTP statuses >=500 to that kind. Network/transport failures and authentication failures use different messages. This supports a prior server 5xx, but the precise historical status, response error code, JWT stage and database stage were not captured. `storage/logs` contained only `.gitignore`, with no Laravel exception log. Authentication middleware catches failures into 503 responses, and profile `show` catches query exceptions into 503; the reported UI alone cannot distinguish them.

Host and emulator health checks both returned HTTP 200. Unauthenticated protected GETs returned HTTP 401 `UNAUTHENTICATED`. The configured CA bundle was readable. A separate PHP CLI JWKS GET inside the tool sandbox failed with `ConnectionException`, cURL error 7; the same GET outside the sandbox returned HTTP 200 with one signing key. **This proves a sandbox diagnostic connectivity limitation, not the root cause of the live app's earlier 5xx.** No API-server restart or authentication/configuration change was made in this investigation; live authenticated requests subsequently succeeded.

The old debugger port was unusable. Reopened the installed application process with `am force-stop` / `am start`, preserving secure storage, and used direct VM HTTP RPC to invoke existing repository methods. The diagnostic helper's WebSocket probe was removed after connection failures. This restored inspection access; it is not a proven product defect or product fix. No Flutter hot reload or APK installation was needed. The prior null-session evidence is historical: the current SDK contains a real session and Laravel successfully validates its JWT.

### Actual request trace

| Check | Result | Evidence |
| --- | --- | --- |
| API configuration | PASS | Ignored mobile configuration and live `LaravelApi.base` both equal `http://10.0.2.2:8000/api/v1` |
| Host health | PASS | GET `http://127.0.0.1:8000/api/v1/health`: HTTP 200 |
| Emulator connectivity | PASS | Android `toybox nc` GET `http://10.0.2.2:8000/api/v1/health`: HTTP 200, `{"status":"ok"}` |
| Live Supabase session | PASS | Existing SDK session present after app reopen; no credentials or token values printed/saved |
| Authenticated GET `/api/v1/me` | PASS | Existing app `LaravelApi.getIdentity` returned the active Supabase UUID; decoder enforces HTTP 200 and UUID equality |
| Authenticated GET `/api/v1/me/academic-profile` | PASS | Actual destination `http://10.0.2.2:8000/api/v1/me/academic-profile`; real repository decode succeeded repeatedly, which requires HTTP 200 |
| Request reached Laravel / JWT validation | PASS | Protected live `/me`, profile and catalogs returned accepted responses through unchanged JWT middleware; this establishes current validation success, not the historical failure stage |
| PostgreSQL profile reads | PASS | Actual profile response succeeded; independent READ ONLY relation queries also succeeded for existing users |
| UUID consistency | PASS | Supabase, `/me`, profile `user_id` all equal `e41527c8-7e48-46f6-8057-62420c6a4c80`; PostgreSQL has exactly one matching identity |
| Existing profile state | PASS | Full writable projection is content-empty. READ ONLY query found zero academic-profile rows for this UUID. Existing API default-empty behavior is unchanged; no fake response introduced. No personal field contents logged. |
| Authenticated GET `/api/v1/universities` | PASS | HTTP 200 required by production client; 4 typed catalog entries |
| Authenticated GET `/api/v1/courses` | PASS | HTTP 200 required by production client; 8 typed catalog entries |
| Authenticated GET `/api/v1/skills` | PASS | HTTP 200 required by production client; 10 typed catalog entries |
| Profile unchanged across reads | PASS | Compared complete serialized writable fields before/after catalog GETs in memory; equal |
| UI controller recovery | PASS | Existing `ProfileController.failure` was null; invoked `load()` (GET only) and it completed. This is controller evidence, not screenshot-based visual QA. |
| Original exact 5xx root cause | NOT TESTED | Original exception/response trace unavailable and failure no longer reproduced; no confirmed root-cause code change justified |
| `flutter analyze` | PASS | Fresh run: no issues found |
| `flutter test` | PASS | Fresh run: 68 tests passed; mocks are separate from real GET evidence |
| Relevant Laravel tests | PASS | Fresh run: 38 tests, 990 assertions, covering Supabase authentication, catalog GETs, and profile GET non-mutation; both PostgreSQL test flags enabled, `--do-not-cache-result` |
| `git diff --check` | PASS | Exit 0 |
| Android integration-test target | NOT TESTED | Not installed/launched under the no-reinstall restriction; real checks instead used the installed app's production repositories |
| Profile submission | NOT TESTED | No live write request authorized or sent |

Post-check READ ONLY counts remain 4 universities, 8 courses, 10 skills, 3 users, 1 academic profile (belonging to another account), 1 academic preference, 0 user_courses and 0 user_skills. This is count evidence, not a new assertion of historical full-row fingerprint equality. No unrelated users' contents were printed.

Only this report and an ignored local diagnostic helper were updated in this investigation; application/backend behavior was not changed. Therefore no new product regression test was added. The existing regression suite and real read-only path both pass. Stop before profile submission. The exact historical failure diagnosis remains open unless a future recurrence supplies a sanitized status/error-code/stage trace; do not claim a confirmed root-cause fix from the successful retry alone. Iteration 4 remains out of scope.

## Continuation: installed-app verification (2026-11-17)

This is a historical checkpoint; see the latest loading investigation above. The user's no-reinstall and no-PUT restrictions remain in force. No live profile submission has occurred and no save approval is being requested.

After the user reported a successful login on 2026-11-16, an in-memory debugger inspection of the running installed app found the actual Supabase `GoTrueClient._sessionState._session` to be null. Invoking the existing `LaravelApi.getIdentity` instance returned `ApiFailure(authentication)` with no HTTP status. With the observed null session, this is a client prerequisite failure before an authenticated HTTP request, not a Laravel 401 response. No UUID or current profile could be verified. This does not explain the discrepancy with the user's observed login and is not evidence that their credentials were invalid.

On resuming 2026-11-17, no Android device was connected, the API was unavailable, and both Re:kan containers were stopped. Opened the existing `Medium_Phone_API_37.0` AVD without wipe flags, started only the existing `rekan-local-postgres-1` and `rekan-local-redis-1` containers, and started Laravel on loopback port 8000. The installed app was brought forward; Android reported that its activity was already running. No APK build/install, package uninstall, hot reload, app-data clearing, sign-out or database migration/seed was performed.

| Check | Result | Evidence |
| --- | --- | --- |
| Existing emulator | PASS | `emulator-5554` connected, `sys.boot_completed=1` |
| Laravel health | PASS | `/api/v1/health` returned HTTP 200 after service startup |
| Secure-storage metadata | PASS | Existing files retained; session-data XML is 65 bytes, timestamp 2026-11-16 18:34. Contents were not read; size alone does not prove current session validity. |
| Current debugger connection | FAIL | The preserved VM announcement/forward produced a closed socket after emulator resume. No new current-session conclusion is inferred from this connection failure. |
| Emulator screen observation | FAIL | Both available computer-use entry points reported native pipe unavailable; screen state could not be verified |
| Authenticated GET `/api/v1/me` | NOT TESTED | Prior installed-app invocation was blocked by a null SDK session; current connection is unavailable |
| Authenticated GET `/api/v1/me/academic-profile` | NOT TESTED | No verified active identity |
| Authenticated GET `/api/v1/universities` | NOT TESTED | Same prerequisite |
| Authenticated GET `/api/v1/courses` | NOT TESTED | Same prerequisite |
| Authenticated GET `/api/v1/skills` | NOT TESTED | Same prerequisite |
| Supabase/Laravel UUID equality and existing profile | NOT TESTED | No authenticated response available |
| `flutter analyze` | PASS | Fresh 2026-11-17 run: no issues found |
| `flutter test` | PASS | Fresh 2026-11-17 run: all 68 tests passed; no Android integration target launched |
| `git diff --check` | PASS | Exit 0; existing line-ending notices only |
| Relevant Laravel regressions | PASS | Fresh run: 60 tests, 1,217 assertions; `--do-not-cache-result`, both PostgreSQL test flags enabled, rollback-isolated synthetic fixtures |
| PostgreSQL counts | PASS | READ ONLY transaction: 4 universities, 8 courses, 10 skills, 3 users, 1 academic profile, 1 preference row, 0 user_courses, 0 user_skills; counts match previous report |
| Full-row historical fingerprint equality | NOT TESTED | Counts are not full-row preservation evidence; prior serialization limitation remains |
| Live PUT / profile persistence | NOT TESTED | Explicitly prohibited; no live PUT issued |

The Android integration target was not launched because doing so through the normal test command can replace the installed APK. It must not be reported as passing based on host unit tests or debugger inspection. The temporary local debugger helper only attempted existing-app inspection/GET calls; no bearer token was printed or saved. Diagnostic compiler/attach attempts did not succeed and did not establish an authenticated session.

Pending manual prerequisite: inspect the now-open emulator. If it shows login, sign in directly using the existing development account; report whether the screen reaches onboarding/profile or shows an error. Never share credentials or tokens and do not submit the profile. Only after a live UUID and existing profile are read can exact proposed changes be presented for separate write approval. Iteration 4 has not started.

## Continuation: session diagnosis (2026-11-16)

This section is historical; see the 2026-11-17 checkpoint above. Real authenticated E2E remains incomplete.

### Session storage and runner findings

- **PASS (source inspection):** the normal app and Android integration target use application ID `com.example.re.re_mobile`, with no flavor/application-ID suffix. Both call `initializeAuth`, which explicitly supplies `SecureAuthStorage` using key `re.auth.<Supabase project host>.session` and default Android secure-storage options. The integration binding does not mock or clear this storage. A different Dart entry point/isolate does not create a separate Android app data directory. With the same project configuration and a data-preserving update, they share storage; a successful signed-in cross-launch demonstration is still **NOT TESTED**.
- **PASS (SDK inspection):** installed `supabase_flutter` 2.18.3 awaits storage initialization and `setInitialSession` before `Supabase.initialize` returns. Refresh/recovery continues asynchronously afterward. Thus an absent persisted session cannot be repaired by simply waiting longer; no evidence currently establishes a timing defect.
- **FAIL (session prerequisite):** at inspection, `adb shell run-as com.example.re.re_mobile ls -l shared_prefs` showed only `FlutterSecureKeyStorage.xml` (536 bytes) and `FlutterSecureStorageConfiguration:FlutterSecureStorage.xml` (240 bytes). The plugin's default session-data file, `FlutterSecureStorage.xml`, was absent. No file contents, tokens or credentials were extracted. This supports absence of persisted login data in the current installed app, consistent with the prior null-session assertion. It does not establish when or why the session disappeared, or prove an earlier manual login used this package/project.
- **PASS (preservation boundary):** no APK was installed, no app data cleared, and no sign-out, emulator reset or session deletion was requested in this continuation. Flutter's Android installer first tries `adb install -t -r` but has an uninstall fallback if that fails. A future session-preserving run must avoid that fallback: build the target, explicitly update with `adb install -t -r`, stop on failure, and attach/run with installation skipped (after checking the installed SDK's supported flags).
- Updated the GET-only integration test to check persisted-session presence before SDK initialization and explicitly compare `/me` identity with the active Supabase UUID. It emits only presence/UUID evidence, never session contents. The modified Android test is **NOT TESTED** on-device pending manual sign-in; static analysis passes.

### Checks executed in this continuation

| Check | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` | PASS | Final run after test edits: no issues, exit 0 |
| `flutter test` | PASS | 68 tests passed, exit 0; mocked tests are not real authenticated E2E |
| Relevant Laravel tests | PASS | `ACADEMIC_TEST_POSTGRES=1 IDENTITY_TEST_POSTGRES=1 php artisan test --filter='SupabaseAuthenticationTest\|AcademicProfileApiTest\|AcademicCatalogApiTest'`: 60 passed, 1,217 assertions; temporary transactional schemas rolled back |
| Editor diagnostics / Dart formatting | PASS | GET-only test formatted and no editor errors |
| `git diff --check` | PASS | Exit 0; existing LF/CRLF notices only |
| PostgreSQL counts | PASS | READ ONLY transaction: universities 4, courses 8, skills 10, users 3, academic_profiles 1, academic_preferences 1, user_courses 0, user_skills 0 |
| Historical full-row fingerprint equality | NOT TESTED | Exact original serialization procedure was not available in the report. New read-only hash attempts did not reproduce the nonempty-table historical hashes; neither unchanged rows nor mutations can be concluded from incompatible serialization. Historical preservation claims above are not extended to this continuation. |
| Authenticated `GET /api/v1/me` | NOT TESTED | Manual sign-in prerequisite pending |
| Authenticated `GET /api/v1/me/academic-profile` | NOT TESTED | Same prerequisite; current account profile has not been inspected |
| Authenticated `GET /api/v1/universities` | NOT TESTED | Same prerequisite |
| Authenticated `GET /api/v1/courses` | NOT TESTED | Same prerequisite |
| Authenticated `GET /api/v1/skills` | NOT TESTED | Same prerequisite |
| Supabase UUID equals Laravel identity | NOT TESTED | Explicit assertion added; no authenticated run yet |
| Profile PUT / persisted completion | NOT TESTED | No real profile write attempted or approved |

The first sandboxed Flutter analyzer produced no output and was interrupted; the unsandboxed final analyzer passed. The first Laravel run passed but could not write PHPUnit's cache; the permitted rerun passed without that warning. Laravel profile tests exercise synthetic fixture PUTs inside rollback-isolated schemas, not the development account or live HTTP server.

**Next action:** user signs in directly on the existing emulator using the existing development account and confirms readiness. Never send credentials or tokens. Then perform the GET-only run, inspect the returned profile and verify UUID equality. No profile submission is authorized. Before any future live PUT, present the exact UUID and exact proposed field changes for explicit approval. No Iteration 4 work was started.

## Environment and automated checks

| Check | Result | Evidence |
| --- | --- | --- |
| PostgreSQL and Redis | PASS | Existing rekan-local containers healthy; Laravel SELECT 1 and both Redis PING checks passed |
| Laravel HTTP server | PASS | Started existing API at 127.0.0.1:8000; both health routes returned HTTP 200 and the expected body |
| Android emulator boot | PASS | Existing Medium_Phone_API_37.0 AVD booted, emulator-5554 listed as device, sys.boot_completed=1; no wipe flags |
| Development configuration alignment | PASS | Mobile and Laravel use the same Supabase project URL; backend environment local; audience authenticated; mobile public key present; no credentials printed |
| Current debug APK build/install | PASS | Built with existing public .env.e2e.json and AUTH_E2E_ENABLED=false; adb install -r succeeded, retaining storage |
| Missing-token protection | PASS | Live host GET /me, /universities, /courses, /skills all returned 401 without credentials |
| Dart formatting | PASS | Editor Dart formatter applied to relevant onboarding/API files and the GET-only integration test |
| Flutter analyzer | PASS | No issues found on the regression run |
| Flutter unit/widget regressions | PASS | 68 passed; mocked transports are not real-session or visual E2E evidence |
| Git whitespace check | PASS | git diff --check clean |
| Emulator UI observation/control | FAIL | Computer-use capture returned the editor behind the emulator, then “window crop is outside captured monitor”; restarting visibly and restoring placement did not resolve capture. User asked to move window onto main monitor |

The local development catalog counts remain 4 universities, 8 global courses and 10 skills. These are fixtures, not verified official academic offerings. Other unrelated Docker containers were left untouched.

## Read-only baseline

Before any profile action, used a PostgreSQL READ ONLY transaction to snapshot counts and SHA-256 fingerprints of sorted full rows. No personal field contents or tokens were logged.

| Table | Count | Baseline SHA-256 |
| --- | ---: | --- |
| universities | 4 | 074fca4412cac27f5d1f2ae18d106876910499e5c871a591ea1b8c63ccfddfae |
| courses | 8 | 6bb5911552941893c598369544daa03e8e32ef78893d4685278c738b10b5479e |
| skills | 10 | dc41ef7cb32d8969e55d3b29ea2cd21eb35b2a10434492d707e87f9783153eca |
| users | 3 | 209684948938ce78dbbcb35966d58a0d6c7f07ca63d6e9d0db804e406092ea9e |
| academic_profiles | 1 | 154419bb76dede2897b7747e19d480040cb807035e20401e6d0c07a5bec07d29 |
| academic_preferences | 1 | 3aef7d8734831122ffc144ef7becb812f9909b13d93722bbe1de50ac9259ffa9 |
| user_courses | 0 | 4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945 |
| user_skills | 0 | 4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945 |

These fingerprints establish a preservation baseline; they are not an active-account UUID verification or a restorable database backup.

**PASS — resumed-run preservation check:** after restarting the existing services, recomputed all eight sorted full-row fingerprints. Every count and SHA-256 matched this baseline exactly. No profile submission has occurred.

The earlier Android command was interrupted before a terminal result was recoverable; it is not counted as PASS or FAIL. The resumed run repeats that GET-only validation. The emulator boots, but native capture again shows the editor rather than the Android screen; this remains a tool/observation failure, not evidence of an onboarding product failure.

## Real-session and UI checks

A new [GET-only Android integration test](../../apps/mobile/integration_test/catalog_readonly_test.dart) initializes the existing secure-storage-backed Supabase SDK, uses SupabaseApiSession and LaravelApi, and checks identity/profile consistency, expected catalog entries, search, scope and lookup. It never calls PUT, signs out, clears storage or prints credentials. It requires an existing restored session and reports a missing-session prerequisite rather than inventing credentials.

**FAIL — resumed real Android test prerequisite:** the build/install and test-runner attachment succeeded, then the assertion at the restored-session check failed: `Expected: not null; Actual: <null>`. The message was “No restored session: sign in manually using the normal UI before retrying.” No authenticated Laravel request was reached. This establishes that no session was available in this run; it does not establish a login or session-restoration product defect without a known previously valid persisted session. The normal production UI in debug mode is being restored for manual sign-in, without clearing storage.

| Check | Result | Reason / evidence |
| --- | --- | --- |
| Active-account UUID and real authenticated GETs | NOT TESTED | Android test stopped before GETs because no SDK session was restored |
| Step 1 name/optional field editing and validation | NOT TESTED | Emulator screen cannot yet be observed reliably |
| Step 2 university search, program, semester | NOT TESTED | Same UI capture blocker |
| Step 3 skill selection and levels | NOT TESTED | Same UI capture blocker |
| Step 4 course search/selection | NOT TESTED | Same UI capture blocker |
| Step 5 preferences/review | NOT TESTED | Same UI capture blocker |
| Forward/back navigation, draft preservation, duplicate selections | NOT TESTED | Automated coverage passes; real visual observations still unavailable |
| Approved PUT and persisted completion | NOT TESTED | No submission attempted; explicit user confirmation remains mandatory |
| Session restoration prerequisite | FAIL | SDK current session was null after initialization; manual development-account sign-in required |
| Logout and account switch on emulator | NOT TESTED | No logout or account change performed |
| Real network/catalog error recovery and duplicate submission | NOT TESTED | Automated coverage passes; no real failure injection or submission attempted |

## Boundaries

**PASS — normal app restored after testing:** `flutter run --debug -d emulator-5554 --dart-define-from-file=.env.e2e.json --dart-define=AUTH_E2E_ENABLED=false` rebuilt/installed the normal app and attached successfully to its running Flutter engine. Storage was retained. This is launch evidence only, not a visual observation of the sign-in/onboarding screen. Laravel remains available on port 8000 for the manual sign-in continuation. The final analyzer and whitespace checks passed.

Next required user action: bring the emulator fully onto the main display and sign in manually to the development account using the normal UI. Do not send passwords or bearer tokens in chat, and do not submit the academic profile yet. Then rerun the GET-only test, establish the account/profile state, and resume visual checks. Integration 3.2 remains incomplete; no real E2E success is claimed.

No Supabase Auth settings, database records or seeds were changed. No app storage was cleared. No discovery, matching, swipe cards, chat, rooms or Iteration 4 work. Before any future PUT, establish the active UUID and current profile, present exact proposed fields and obtain explicit approval; a non-empty profile needs a separately scoped update approval or a fresh development account.

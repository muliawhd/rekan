# Phase 2B.1 authentication E2E validation

Updated 2026-11-15. Initial implementation and device connectivity validation: 2026-11-13.

## Scope and result

Phase 2B.1 is complete for review based on user-observed real-account Android testing and independently corroborated database/regression evidence. The agent did not replay private login, logout or restart actions. Phase 2C has not started.

The owner confirmed that Supabase is exclusively for development/testing. Supabase remains the sole identity provider, Laravel owns authorization, local Docker PostgreSQL stores application data and Redis provides cache/queues. No production resources were modified.

## Verified and unverified scenarios

| Scenario | Result and evidence |
| --- | --- |
| Flutter/backend project match | Previously compared public URL and publishable key exactly; ignored mobile configuration contains only public values and emulator API URL. |
| Real login and UUID correspondence | User confirmed successful development-account login, repeated login and matching Supabase/Laravel/local PostgreSQL UUID. |
| Repeated authenticated requests | User confirmed restored-session verification twice using the harness's real `/me` check. |
| One local user / idempotent provisioning | Independent guarded read-only check after the reported sequence returned exactly one record for `e41527c8-7e48-46f6-8057-62420c6a4c80`; the earlier inspection also found one. This corroborates reported repeated requests without independently replaying authenticated calls. |
| Logout and missing-token rejection | User confirmed logout and rejected missing-token request; automated rejection tests also pass. |
| Recovery after new login | User confirmed repeated login and successful session recovery after Android force-stop/relaunch. This is manual device evidence, not inferred from storage mocks. |
| Separate signed-out restart | Not separately evidenced by the latest confirmation; no additional claim made. |
| Flutter regressions | Rerun: analyze reported no issues; all 6 tests passed. |
| Laravel regressions | Rerun: 27 tests / 128 assertions passed; Pint passed. |
| JWT security cases | Fixture suite covers missing/malformed tokens, invalid signature, expiry, wrong issuer/audience, unsupported algorithms, invalid UUID and authorization denial. Real expired Supabase tokens were not tested. |
| Infrastructure and routes | Independent foundation check passed PostgreSQL SELECT 1 and Redis default/cache PING; route listing succeeded with health routes and `/api/v1/me`. |
| Android connectivity | Earlier emulator-5554 integration run passed 1 test: health 200 and missing/invalid-token 401 through `10.0.2.2:8000`. Not rerun during final review. |
| Final live HTTP check | Both loopback health probes could not connect to port 8000, including outside the sandbox. The smoke script was blocked by PowerShell execution policy; equivalent direct HTTP probes confirmed unavailability. No fresh live HTTP success is claimed. |

Earlier native UI inspection failed because the native service was unavailable. The user subsequently completed the sequence and supplied the results above. Those results supersede the pending-login boundary, but are not agent-observed UI evidence.

Session restoration does not prove long-lived refresh-token rotation was exercised. Local SDK logout does not guarantee immediate invalidation of an already-issued access JWT. Neither real-token expiry nor immediate revocation was tested. No credentials, session storage or tokens were extracted for this review.

## Regression commands

Run from `apps/mobile`: `flutter analyze` and `flutter test`.

Run from `services/api`:

```powershell
php artisan test
php vendor/bin/pint --test
php artisan identity:check-local-user e41527c8-7e48-46f6-8057-62420c6a4c80
php artisan foundation:check
php artisan route:list
```

The count command guards local PostgreSQL configuration and is read-only. Current regressions use the default fixture suite; earlier isolated PostgreSQL integration results are recorded in the [Phase 2B report](../architecture/phase-2b-status.md), not claimed as rerun here.

## Harness and optional reproduction

The debug-only harness supports Supabase email/password login, two bearer `/me` calls with UUID comparison, restored-session verification and local-scope logout. It reuses secure SDK session storage, displays no tokens and requires both `kDebugMode` and `AUTH_E2E_ENABLED=true`.

The bearer destination is pinned to `http://10.0.2.2:8000/api/v1` with redirects refused. Android debug networking permits cleartext only to that emulator host. Supabase uses HTTPS with certificate validation; Laravel's development launch binds to loopback. No privileged backend credentials are supplied to Flutter.

For an optional future replay, start existing local infrastructure and Laravel on loopback, then run from `apps/mobile`:

```powershell
flutter run -d emulator-5554 --dart-define-from-file=.env.e2e.json --dart-define=AUTH_E2E_ENABLED=true
```

Enter test credentials privately in the emulator. Tap **Log in and verify /me**, then **Verify restored session with /me** twice. Compare the displayed UUID using the guarded count command above. Force-stop/relaunch without clearing storage:

```powershell
& "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" -s emulator-5554 shell am force-stop com.example.re.re_mobile
& "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" -s emulator-5554 shell am start -n com.example.re.re_mobile/.MainActivity
```

Verify the restored session with `/me`. After **Log out**, restored-session verification should report no session and **Check connection and token rejection** should pass. A separate signed-out restart can be checked with the same commands. Never clear app data or share credentials/tokens for validation.

The earlier passing connectivity command was `flutter test integration_test/auth_connectivity_test.dart -d emulator-5554 --dart-define-from-file=.env.e2e.json`. Windows cross-drive Kotlin cache failures required `kotlin.incremental=false`; a later daemon diagnostic was followed by successful fallback compilation, APK installation and device-test completion. No data/cache deletion was performed.

## Changes and Phase 2C readiness

This final review changes only this report and [the task checklist](../../task-checklist.md). Earlier Phase 2B.1 work added the debug harness, destination restrictions, debug Android networking, automated tests and read-only local-user count command. Existing data is preserved.

Core E2E scenarios have user-confirmed manual evidence, passing regressions and a single matching database row. Phase 2C is ready for review and explicit authorization. The untested scenarios and unavailable final HTTP runtime remain recorded above. No Phase 2C, matching, chat or academic onboarding work was performed.

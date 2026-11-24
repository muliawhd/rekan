# Phase 2E.1 real integration validation — 2026-11-15

## Result

### Final acceptance — Phase 2E.1 complete (2026-11-15)

This final acceptance supersedes the historical pending/not-tested PUT statements below. The owner manually observed the real Android Emulator reporting **Profile state: success**, matching authenticated/profile UUIDs, and **PASS: submitted dummy values match PUT and GET**. This is owner-reported real E2E evidence, not an agent-observed emulator capture or a mocked test.

Independent PostgreSQL verification used a guarded local connection and a repeatable-read, read-only transaction. It found exactly one complete match for the documented dummy payload: UUID `968b47d4-a6eb-4972-a25c-4d5ffcd7776d`. There is one identity, one academic profile and one preference row for that UUID, with zero course/skill associations. Every scalar, null field, visibility and preference matches the submitted dummy values. The owner reported UUID equality but did not supply the numeric UUID in the final message; the UUID above is the unique database match, not a separately captured `/me` response.

| Final check | Result | Evidence / limit |
| --- | --- | --- |
| Real Android authenticated PUT/GET | PASS (manual) | Owner's observed success and submitted-value comparison. |
| PostgreSQL persistence | PASS | Exact dummy payload and empty relationships independently verified read-only, before and after final regressions. |
| Identity provisioning | PASS | Exactly one identity record for the matching UUID; three total users. |
| First development account still exists | PASS | Previously recorded UUID `e41527c8-7e48-46f6-8057-62420c6a4c80` still has exactly one identity row. |
| Other existing users/profiles unchanged by the manual PUT | NOT VERIFIED historically | No pre-PUT field snapshot found. There are currently zero academic profile rows for the other users, but current counts cannot prove prior fields or rows were unchanged. Fixture-based ownership/preservation tests pass separately. |
| Flutter analyze / tests | PASS | No issues; 29 tests. |
| Full Laravel tests | PASS | 73 tests / 507 assertions; PostgreSQL tests use isolated transactional schemas. Initial sandbox cache-write warning resolved by rerun outside sandbox. |
| Laravel Pint / infrastructure | PASS | Pint passed; local PostgreSQL SELECT 1 and both Redis PING checks passed. |

No development profile data was changed during finalization; no reset, real PUT, logout, or session clearing was performed. Database regression fixtures were isolated from application records. Historical Phase 2B.1 restart/logout evidence remains valid for that earlier test; real profile-specific logout clearing and live refresh were not newly exercised here. These are documented coverage limits, not newly claimed passes. Phase 2E.1 is complete with these evidence limits recorded. Phase 2E.2 remains unstarted and requires review/authorization.

## Historical validation record

### Latest: development dummy validation fixed

This section supersedes the earlier loaded-value-only harness descriptions below. The debug panel now creates explicit dummy values and displays the exact JSON plus the session-derived target UUID for confirmation. It verifies `/me`, fetches an empty profile before presenting approval, and fetches again after confirmation. A changed account/login generation aborts. No hardcoded account UUID is used: the operator must confirm the displayed UUID is the approved second development account.

The payload is `display_name: Development student`, `program: Integration test program`, `semester: 1`, `bio: Dummy academic profile for development validation.`, private visibility, null university/MBTI, no courses/skills, and preferences `online` / `en`. Null university and empty relationship lists are permitted by the existing contract; no catalog fixtures or database seeds are needed.

The guarded PUT sends `X-Re-Require-Empty-Profile: true`. Laravel checks all writable profile content under the existing user row lock and returns 409 before writes if any content is present. This closes the GET-to-PUT race for writes through the profile API. Both PUT and immediate GET must match the submitted payload, not merely one another. On errors, the panel shows only safe diagnostics and does not issue rollback writes. A lost response may mean the write committed; reload rather than blindly retry. Requests already sent cannot be cancelled by switching accounts; their bearer identity remains the original account, and stale completion is rejected.

| Check | Result | Evidence |
| --- | --- | --- |
| Flutter analyze | PASS | No issues after final changes. |
| Flutter tests | PASS | 29 tests; mocked API/session data. Empty approval/cancel, non-empty rejection, session switches, payload comparison and failure handling covered. |
| Laravel academic profile tests | PASS | 23 tests / 245 assertions in isolated PostgreSQL schemas; includes empty precondition, rejection without mutations and existing transaction rollback tests. |
| Laravel Pint | PASS | Modified controller and feature test checked. |
| Real second-account dummy PUT/GET | NOT TESTED | No real account PUT sent; no emulator E2E success claimed. |

Manual continuation: rebuild/run the debug validation app with the existing development configuration. Sign into the approved second account, verify `/me`, then load the profile. Only an empty result enables validation. Tap **Validate PUT / GET (approval required)**, verify the target UUID and exact values, then **Approve PUT**. Expect **PASS: submitted dummy values match PUT and GET.** A non-empty result must remain unwritable through this harness. No database reset or development-record modification was performed during these automated checks. Stop before Phase 2E.2.

### Approved second-account test: pending identity verification

The owner explicitly approved a development-only dummy-profile PUT/GET for the currently authenticated second account. This supersedes the earlier pending-approval notes below; it does not authorize writes for an unidentified or different account. No PUT has been sent. The intended second UUID has been requested so it can be compared with verified `/me` identity before writing.

| Approved validation step | Result | Evidence / boundary |
| --- | --- | --- |
| Inspect existing development payload | PASS | The current panel saves `profile.input`: unchanged loaded writable fields, not dummy data. Its comparison checks PUT response versus GET, not both against the original submitted values. |
| Define safe dummy payload | PASS (contract review only) | Contract's minimal example uses `display_name: Development student`, private visibility, null university/program/semester/bio/MBTI, empty courses/skills and null preference values. No catalog references are needed. Not submitted. |
| Confirm second account through /me | NOT TESTED | Intended UUID pending; emulator capture again showed VS Code rather than Android. No reliable app control interaction. |
| Verify empty academic profile | NOT TESTED | Requires authenticated GET for the verified intended UUID. |
| PUT, immediate GET and submitted-value comparison | NOT TESTED | Stopped before writing at identity/empty-profile prerequisites. |
| Other users unchanged / current identity not duplicated | NOT TESTED | No before/after database comparison for this approved test has run. No database writes, resets or migrations performed by this attempt. |

Next manual step: on the second account, tap **Verify restored session with /me**, then **Load academic profile (GET)**. Provide only the verified UUID and profile state/result. Do not press the existing PUT button yet: it only resubmits loaded values. Approval remains valid once account and empty-profile prerequisites are established. Phase 2E.2 has not begun.

Environment preparation and regressions pass. **Real authenticated profile E2E is NOT TESTED** because emulator UI interaction could not be completed. No profile PUT was sent and no profile modification approval was requested prematurely. Phase 2E.2 was not started.

| Step | Result | Evidence / limitation |
| --- | --- | --- |
| Docker Desktop / PostgreSQL / Redis | PASS | Existing containers healthy; PostgreSQL SELECT 1 and both Redis PING checks passed. No volume reset/recreation. |
| Development API | PASS | Started Laravel on 127.0.0.1:8000; health HTTP 200; listener confirmed loopback only. |
| Android emulator | PASS | Existing Medium_Phone_API_37.0 launched; emulator-5554 reported device. No wipe/uninstall. |
| Current validation build | PASS | Debug APK built, installed as update and launched with existing .env.e2e.json and AUTH_E2E_ENABLED=true. App process observed running. |
| Existing local identity | PASS | Guarded read-only check found exactly one record for the previously validated development UUID. This does not prove current app authentication. |
| Real Supabase authentication via screen | NOT TESTED | Current login/session state could not be observed. Earlier Phase 2B.1 evidence is historical. |
| Authenticated profile GET / DTO parsing | NOT TESTED | No successful real authenticated profile response observed. |
| Real empty-profile state | NOT TESTED | Actual profile content unknown; mocked empty-state test passes separately. |
| Profile PUT / GET / persisted values | NOT TESTED | Explicit approval still required; no PUT sent. |
| Missing-token profile request | PASS | Live loopback GET /api/v1/me/academic-profile returned HTTP 401. |
| Invalid-token profile request | PASS | Same endpoint returned HTTP 401 for a deliberately invalid test token. |
| Client refresh/retry against real Supabase | NOT TESTED | Bounded retry behavior remains covered by mocks only. |
| Session restoration after app restart | NOT TESTED | No authenticated recovery observed in this validation. |
| Logout clears profile data/access | NOT TESTED | No logout performed; existing session data preserved. |
| Sampled app logs | PASS (bounded scan) | 71 lines for the running app process scanned; zero JWT/Bearer/credential-assignment pattern matches. Only counts emitted. This is not proof about all logs or unknown literal passwords. |
| Laravel log scan | NOT TESTED | storage/logs/laravel.log was absent at scan time. Server launch/request output inspected contained no credentials. |
| flutter analyze | PASS | No issues. |
| flutter test | PASS | All 22 tests passed; API/session tests are mocked. |

## UI blocker

Continuation on 2026-11-15: Docker, the emulator and Laravel were stopped when rechecked. Restarted Docker Desktop, the existing AVD, and Re's existing PostgreSQL/Redis containers without resetting volumes. Laravel is running on loopback port 8000 again. PostgreSQL SELECT 1, both Redis PING checks and HTTP health 200 passed again; the guarded identity count remains exactly one. Launched the installed app without clearing its data. Unrelated Docker services were not modified.

The updated Windows helper now returns an emulator accessibility tree, but its screenshot shows VS Code instead of the Android display. Reselecting and activating the emulator once produced the same mismatch. No app controls were clicked from these unreliable captures. Authenticated GET, restart recovery and logout remain NOT TESTED; the manual continuation below still applies. The RAM notice may no longer be present.

The Windows computer-use helper discovered the emulator window, but screenshot capture failed with **window crop is outside captured monitor**. Recovery obtained an accessibility tree showing a RAM compatibility notice (suggested 16384 MiB, available 15658 MiB). Attempting its OK button failed with **coordinate input geometry is unavailable**. A refreshed window inventory still found the emulator, but no app screen was observed or operated. A successful APK launch is not proof of an authenticated API round trip.

The existing services and emulator were left running for manual validation. No passwords, tokens or secure session storage were extracted. Logs were scanned in memory without emitting matched text. Backend application records were not reset or changed by this task; profile requests used only absent/invalid credentials.

## Exact manual continuation

Regression rerun during this continuation: Flutter analysis passed with no issues (49.7 seconds); all 22 Flutter tests passed again. These remain mocked tests, not authenticated E2E evidence.

1. Bring **Android Emulator - Medium_Phone_API_37.0:5554** fully onto the visible desktop. Dismiss the RAM compatibility notice with **OK**. The current debug build is already launched.
2. On **Re development auth validation**, tap **Check connection and token rejection**. Expect PASS for emulator-host connectivity and missing/invalid-token rejection.
3. Tap **Verify restored session with /me**. If no session is available, enter the development account email/password privately in the app and tap **Log in and verify /me**. Never send credentials or tokens through chat.
4. Tap **Load academic profile (GET)**. Expect state **empty** or **success** and a profile UUID matching the authenticated /me UUID. Empty describes content, not confirmed absence of a database row.
5. **Stop before PUT.** Report the guest check result, /me result, profile state and UUID only. Explicit approval is still needed before replacement; the app's approval dialog is not permission for the agent to click it automatically.
6. After explicit approval for the loaded development profile, tap **Validate PUT / GET (approval required)** and **Approve PUT**. It resubmits the loaded writable fields/relationships; concurrent edits could be overwritten. Expect **PASS: PUT response matches subsequent GET.** Reload once more to confirm persistence. Cancel if the loaded profile should not be replaced.
7. While signed in, force-stop/relaunch without clearing app data (PowerShell):

```powershell
& "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" -s emulator-5554 shell am force-stop com.example.re.re_mobile
& "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" -s emulator-5554 shell am start -n com.example.re.re_mobile/.MainActivity
```

Tap **Verify restored session with /me**, then **Load academic profile (GET)** again; expect the same UUID/content.
8. Tap **Log out**. The loaded profile UUID/data must clear. Tap **Load academic profile (GET)**; expect a sign-in error and no cached profile. Guest token rejection checks should still PASS. Restart once more and confirm signed out.
9. Report PASS/FAIL and non-secret messages for these steps. Do not provide raw logs, passwords or bearer tokens.

If the app/server is later closed, use the launch commands in [Phase 2E.1 status](../architecture/phase-2e1-status.md). The existing public development configuration is unchanged.

## Changes and next step

Added this report and updated the Phase 2E.1 status/checklist. No application source, schema, credentials or final UI changes were required. Continue manual evidence collection and obtain concrete profile-write approval before PUT; do not claim E2E acceptance or start Phase 2E.2 yet.

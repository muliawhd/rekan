# Re mobile

Current normal UI: Phase 2E.2 Iteration B provides welcome/login/registration, email status and a session-verified academic placeholder. Use the existing public config with `AUTH_E2E_ENABLED=false`; set true only for the debug validation harness. Missing Supabase configuration shows a safe unavailable welcome state. Recovery remains explanatory until callbacks are configured. See [Iteration B status and manual checks](../../docs/architecture/phase-2e2-iteration-b-status.md). Older foundation setup notes below are historical.

Phase 2A adds Supabase SDK initialization with native secure session storage.
Without public configuration the existing foundation screen remains available.

After confirming a dedicated development project, copy `.env.example` to the
ignored `.env` and populate only its public URL and publishable key. Run from
this directory:

```powershell
flutter run --dart-define-from-file=.env
```

Flutter compile-time values are public. Never use the Laravel `.env` as the
define file: it includes privileged server credentials. The SDK manages session
recovery and refresh. Login/signup, callbacks and profile UI are future work.
The existing `scripts/dev.ps1 -Target mobile` command starts the unconfigured
foundation; use the command above for Supabase configuration.

Android is the current validation target. Web authentication is not enabled.
See [Phase 2A status](../../docs/architecture/phase-2a-status.md) for blockers,
database strategy and verification limits.

## Development authentication/profile validation screen

The debug harness is selected only when all three conditions hold: debug mode,
`AUTH_E2E_ENABLED=true`, and valid Supabase compile-time configuration. The
existing ignored `.env.e2e.json` supplies public Supabase/API configuration but
does not set the opt-in flag. Loading that file alone still shows the foundation
screen. Flutter does not load it automatically, and the default mobile script
only supplies the API URL.

From `apps/mobile`, stop the current Flutter run and start a new debug run:

```powershell
flutter run --debug -d emulator-5554 --dart-define-from-file=.env.e2e.json --dart-define=AUTH_E2E_ENABLED=true
```

Use the attached emulator ID reported by `flutter devices` if different. These
are compile-time settings: use a new run/build, not hot reload of the old build.
Keep the existing application ID, signing key and Supabase project configuration;
install as an update. Do not uninstall, clear app data, wipe the AVD or log out.
The existing project-scoped secure session storage is reused; session recovery
still depends on the stored session being valid. No database reset is needed.

Opening the screen does not submit an academic profile PUT. Production/release
navigation remains the foundation screen because the harness is debug-only.

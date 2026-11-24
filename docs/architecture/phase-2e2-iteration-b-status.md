# Phase 2E.2 Iteration B - authentication UI

Implemented 2026-11-15. Stop before Iteration C. No academic forms, catalog APIs, migrations or domain-data writes were introduced.

## Screens and integration

- Welcome: Re identity, academic value proposition, Daftar and Masuk.
- Login: email/password validation, native autofill, visibility control, safe errors, disabled/loading actions and recovery entry point.
- Registration: email/password/confirmation, 8-character local UX minimum (not a claim about server policy), SDK signup, both session/no-session outcomes.
- Email status: generic “Periksa emailmu”; return to login after completing email confirmation. No false account-existence or email-delivery guarantee.
- Recovery entry: explanatory unavailable state; no email sent and no fabricated redirect/reset flow. Unexpected SDK recovery events do not open the authenticated placeholder.
- Authenticated placeholder: Bahasa Indonesia academic context and explicit local logout; no profile completion routing, catalog access or future-module controls.
- Missing config/session failures: explanatory state and retry; no protected content exposed while verification fails.

The existing Supabase singleton and secure storage are reused. The gateway wraps SDK calls, refreshes an expired session before getUser verification, and never stores credentials separately. The controller reacts to SDK auth events and verifies on restoration/resume. Async revision checks discard stale results across account switches. Normal token refresh events do not recursively trigger verification. Stream errors lock protected content; local logout occurs only on user action. Password controllers are cleared after attempts and disposed when leaving a form.

Navigation replaces the root page; there is no history containing a previous account's protected page. Public screen selection cannot select the authenticated state. A cached SDK user alone cannot open the placeholder until server verification succeeds. Future Laravel requests still require existing JWT middleware; this iteration does not bypass it or load academic profiles.

The explicit debug gate (`kDebugMode`, AUTH_E2E_ENABLED=true and Supabase config) still selects the original validation screen/theme. Normal UI uses the Iteration A theme. The legacy FoundationPage source remains preserved; the normal route now uses the safe authenticated placeholder.

## Configuration actually inspected

Ignored `.env.e2e.json` contains a public HTTPS project URL/publishable key and emulator API base. Values were not printed. A read-only request to the configured project's public `/auth/v1/settings` returned email enabled=true, signup disabled=false and mailer_autoconfirm=false: email confirmation is required. No management credentials or cloud settings were changed.

Repository callback handling remains `detectSessionInUri: false`; Android manifest has no auth VIEW/BROWSABLE intent filter. The hosted Site URL, redirect allowlist, email templates/delivery configuration and exact server password policy cannot be established from the public response inspected. Registration delegates confirmation to the configured hosted Supabase email flow without inventing a redirect; real email delivery/link completion is unverified. Recovery remains safely unavailable.

### Required configuration before enabling recovery

1. Owner chooses an owned callback URI (or verified HTTPS app link) and a real hosted confirmation landing URL. Do not use a guessed project name, example URI or emulator host as a production callback.
2. In the development Supabase project's Authentication URL Configuration, inspect/set Site URL to the owned landing URL and add the exact selected callback to Redirect URLs. Review email confirmation and recovery templates so their destinations match. Verify email delivery/SMTP limits with development accounts. Confirm the Email provider's confirmation/password policy; adjust local registration guidance if needed.
3. Register the chosen URI in Android's activity VIEW intent filter with DEFAULT/BROWSABLE and exact scheme/host/path; configure equivalent platform registrations before supporting other platforms. For HTTPS links, configure domain association as required by the platform.
4. In a separately reviewed change, enable SDK callback detection, supply the approved redirect to recovery requests, and implement a password-recovery session screen with new-password confirmation. Handle invalid/expired links and recovery events before normal session routing. Never log callback URLs containing auth parameters.
5. Test actual confirmation, cold/warm recovery links, password update and return to login against the development project before marking recovery functional. No recovery request should be enabled until that path works.

References: [Supabase native mobile links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter), [redirect configuration](https://supabase.com/docs/guides/auth/redirect-urls), [password authentication](https://supabase.com/docs/guides/auth/passwords). Configuration alone does not implement the missing reset screen.

## Verification and evidence

- Dart files formatted with the editor formatter. Final flutter analyze: no issues; flutter test: **45 passed** (33 prior tests plus 12 auth cases); editor diagnostics clean. An initial brace lint and a test requiring an explicit scroll to off-screen large-text content were corrected before the successful final run.
- Tests inject AuthGateway, not live credentials. Coverage: login/register/confirmation validation, safe SDK failure mapping, loading/duplicate blocking, visibility, stored-session verification, failure/expired-session boundary, logout, switched-account/stale results, both verification outcomes, recovery-event isolation, protected navigation, small-screen large text and recovery explanation.
- Existing design/session/API/profile tests continue to run. No PostgreSQL or real user writes are part of these Flutter tests.
- Android debug APK built, installed as an update and launched successfully on emulator-5554 with existing public configuration and AUTH_E2E_ENABLED=false. No uninstall, app-data clearing or automated logout was performed. Build/launch is not authentication E2E proof.
- Computer-use capture could not start: native pipe unavailable (Windows error 2). No actual login, registration, confirmation delivery, recovery, logout or session-restoration success is claimed for the new UI. Prior Phase 2E.1 manual evidence remains a separate historical validation.

## Manual acceptance

The updated normal UI is launched. A saved valid session should reach “Ruang akademikmu”; a failure should show safe session retry controls, without deleting storage. Observe this before deciding to log out. Do not clear data to reach Welcome. Only with owner permission to end that session, use Keluar, then check Welcome/Login/Register, validation, password visibility and disabled loading buttons. Use only a development account and enter credentials privately. Registration may create an account/send email; do this only for an authorized test account. Confirm the email, return to login, then check successful access and restart restoration. “Lupa kata sandi?” must explain unavailability and must not claim email sent. Test back navigation after logout and account switches. Report nonsecret outcomes only.

Normal launch from apps/mobile:

```powershell
flutter run --debug -d emulator-5554 --dart-define-from-file=.env.e2e.json --dart-define=AUTH_E2E_ENABLED=false
```

Use true only to opt into the existing development validation harness. Neither route automatically submits a profile PUT.

## Files changed and next checkpoint

New: `features/auth/auth_gateway.dart`, `auth_controller.dart`, `auth_boundary.dart`, `auth_form.dart`, `test/auth_ui_test.dart`, this status report.
Updated: `lib/app.dart`, `lib/main.dart`, `test/widget_test.dart`, Phase 2E.2 plan, Flutter architecture, implementation plan and checklist. No dependencies, backend code, migrations, session storage keys or auth credentials changed.

Iteration B implementation is ready for review with recovery/configuration and live-device acceptance limitations above. Wait for owner approval before Iteration C. Completion rules/catalog APIs remain deferred and are not used for routing in B.

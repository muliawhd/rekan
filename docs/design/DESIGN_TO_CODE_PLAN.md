# Re:kan — Phased Design-to-Code Implementation Plan (`DESIGN_TO_CODE_PLAN.md`)

## 1. Guiding Principles & Non-Negotiable Guardrails

This plan governs the transition from the approved FigCraft design system (`d:/Mulia/rekan ui ux/Re_kan_Mobile_UI_Design_System_v0.1.figcraft`) to the live **Re:kan** repository at `D:/Mulia/hackgdgocitb/rekan`.

### 1.1 Architectural Guardrails (`IMPLEMENTATION_CONSTRAINTS.md` & `AGENTS.md`)
1. **Preserve Core Stack**: Keep Flutter 3.50 (`apps/mobile`, `package:re_mobile`, `ChangeNotifier`/`ListenableBuilder`, `material_ui`, `supabase_flutter`, `flutter_secure_storage`), Laravel 12 (`services/api`), local Docker PostgreSQL (`127.0.0.1:5433`), local Redis (`127.0.0.1:6380`), and canonical Supabase UUID identity mapping. Do **not** add Riverpod, Dio, or router packages without approval.
2. **Preserve Existing Auth & Profile Infrastructure**:
   - Keep `lib/core/auth/*`, `lib/core/network/laravel_api.dart`, `lib/features/auth/auth_gateway.dart`, `lib/features/auth/auth_controller.dart`, `lib/features/academic_profile/data/*`, and `lib/features/academic_profile/presentation/profile_controller.dart` intact.
   - Keep the debug validation gate (`kDebugMode && bool.fromEnvironment('AUTH_E2E_ENABLED') && configured` → `AuthValidationPage`) in `lib/app.dart` untouched.
3. **Preserve All 45 Flutter Tests & 73 Laravel Tests**:
   - Existing widget/integration tests in `apps/mobile/test/` (`design_foundation_test.dart`, `auth_ui_test.dart`, `academic_profile_integration_test.dart`, `auth_configuration_test.dart`, `development_api_test.dart`, `development_profile_validation_test.dart`, `widget_test.dart`) must continue passing at every checkpoint.
4. **Backend Contract Authority**:
   - `PUT /api/v1/me/academic-profile` (`AcademicProfileController.php`) requires the exact 10 fields (`display_name`, `university_id`, `program`, `semester`, `bio`, `mbti_badge`, `visibility`, `courses`, `skills`, `preferences`) and rejects unknown fields with `422`. Never send `user_id` or unimplemented fields (`interests`, `portfolio`, `schedule`) in `PUT` payloads.
5. **No Fake Production Data**:
   - Mock/fixture data is permitted **only** in widget tests or explicitly isolated development fixtures for screens whose backend routes are not yet implemented (`Discover`, `Collaboration Outcome`, `Chat Inbox`, `Room Chat`).

---

## 2. Target Flutter Directory Structure (`D:/Mulia/hackgdgocitb/rekan/apps/mobile/lib`)

```text
apps/mobile/lib/
├── app.dart                               # Update title: 'Re:kan', preserve AUTH_E2E_ENABLED gate
├── main.dart                              # Unchanged (Supabase + secure storage init)
├── core/
│   ├── auth/                              # Unchanged (api_session, initialize_auth, secure_auth_storage)
│   ├── config/                            # Unchanged (app_config)
│   ├── network/                           # Unchanged (laravel_api; add catalog endpoints only when approved)
│   ├── theme/
│   │   ├── re_tokens.dart                 # Upgrade to Academic Neo-Brutalist tokens (keep existing constant names)
│   │   ├── rekan_design_tokens.dart       # Copied from exports/rekan_design_tokens.dart
│   │   └── app_theme.dart                 # Upgrade AppTheme.onboarding to Neo-Brutalism; keep AppTheme.light
│   └── widgets/
│       ├── re_form_components.dart        # Upgrade ReFormPage, ReFormHeading, RePrimaryAction, ReStatusNotice
│       ├── re_page_scaffold.dart          # Component #1 (Neo-brutalist page scaffold with optional bottom nav)
│       ├── re_brand_mark.dart             # Component #2 ("Re:kan" wordmark badge)
│       ├── re_secondary_button.dart       # Component #4 (Secondary, Destructive, Tertiary variants)
│       ├── re_text_field.dart             # Component #5 (2px/3px #111111 border, visible label, visibility toggle)
│       ├── re_search_and_filter_bar.dart  # Supporting Component (Search + Filter badge)
│       ├── re_chip.dart                   # Component #6 (Neutral, Selected, Skill, Course, Availability, Status)
│       ├── re_section_header.dart         # Component #10 (Accent bar + uppercase heading)
│       ├── re_empty_state.dart            # Component #16 (Badge, title, 1-sentence desc, >=48dp CTA)
│       ├── re_bottom_navigation.dart      # Component #18 (5 destinations, #FFE500 active block, #F22DBB badge)
│       ├── re_top_app_bar.dart            # Supporting Component (3px bottom border, >=44dp actions)
│       ├── re_segmented_tabs.dart         # Supporting Component (50dp outer / 44dp inner tabs)
│       └── re_unread_badge.dart           # Supporting Component (#F22DBB fill + #111111 text)
└── features/
    ├── auth/
    │   ├── auth_gateway.dart              # Unchanged
    │   ├── auth_controller.dart           # Unchanged
    │   ├── auth_boundary.dart             # Iteration 2: Neo-Brutalist WelcomePage (434) & status screens ("Re:kan")
    │   └── auth_form.dart                 # Iteration 2: Neo-Brutalist Login/Register (473)
    ├── auth_validation/                   # Unchanged (debug-only)
    ├── academic_profile/
    │   ├── data/                          # Unchanged (academic_profile.dart, academic_profile_repository.dart)
    │   └── presentation/
    │       ├── profile_controller.dart    # Unchanged
    │       ├── onboarding_draft_controller.dart # Iteration 3: Separate in-memory 5-step draft controller
    │       ├── academic_onboarding_page.dart    # Iteration 3: Screen 9 (id: 760)
    │       ├── my_academic_profile_page.dart    # Iteration 6: Screen 8 (id: 679)
    │       ├── profile_detail_page.dart         # Iteration 6: Screen 4 (id: 611)
    │       └── re_info_row.dart                 # Component #11 (id: 668)
    ├── shell/
    │   └── main_shell_page.dart           # Iteration 4: Authenticated 5-tab shell + onboarding completion guard
    ├── discover/
    │   ├── widgets/
    │   │   ├── re_profile_card.dart       # Component #7 (id: 531)
    │   │   ├── re_swipe_deck.dart         # Component #8 (id: 528)
    │   │   ├── re_swipe_stamp.dart        # Drag stamp (id: 370, 372)
    │   │   └── re_discover_action_bar.dart# Component #9 (id: 571)
    │   └── presentation/
    │       └── discover_page.dart         # Iteration 5: Screen 3 (id: 518)
    ├── collaboration/
    │   └── presentation/
    │       └── collaboration_outcome_page.dart  # Iteration 7: Screen 5B (841) & Screen 5A (805)
    ├── chat/
    │   ├── widgets/
    │   │   └── re_conversation_tile.dart  # Component #12 (id: 894, 915)
    │   └── presentation/
    │       └── chat_inbox_page.dart       # Iteration 8: Screen 6 (id: 871)
    └── rooms/
        ├── widgets/
        │   ├── re_room_header.dart        # Component #13 (id: 949)
        │   ├── re_pinned_purpose.dart     # Component #14 (id: 971)
        │   └── re_message_bubble.dart     # Component #15 (id: 990, 1000, 1004, 1051)
        └── presentation/
            └── room_chat_page.dart        # Iteration 9: Screen 7 (id: 945)
```

---

## 3. Sequential Execution Plan (`Iterations 1–11`)

> **Note**: **Iteration 0 (Context & Codebase Audit)** is now **complete**, having inspected both `d:/Mulia/rekan ui ux` and `D:/Mulia/hackgdgocitb/rekan`. Do not start Iteration 1 until the user explicitly approves this handoff package.

### Iteration 1 — Design Tokens & Shared Neo-Brutalist Components
- **Scope**:
  1. Evolve `apps/mobile/lib/core/theme/re_tokens.dart` as the **single canonical token source** (`ink: #111111`, `paper: #FFFDF5`, `surface: #FFFFFF`, `mutedSurface: #F2F0E8`, `muted: #626262`, `accentPrimary: #FFE500`, `accentTeal: #16C7C1`, `accentMagenta: #F22DBB`, `success: #1FA86A`, `danger: #E5484D`, `error: #B42318` for AA text contrast, `warning: #F2A900`, `borderStandard: 2.0`, `borderEmphasized: 3.0`, `contentWidth: 520.0`, `minTouchTarget: 48.0`, hard-offset `BoxShadow`s) without creating duplicate theme systems.
  2. Update `AppTheme.onboarding` in `lib/core/theme/app_theme.dart` to use the Neo-Brutalist palette, `2px`/`3px` `#111111` input borders, and `#FFE500` primary buttons (`onPrimary: #111111`).
  3. Upgrade `ReFormPage`, `ReFormHeading`, `RePrimaryAction`, and `ReStatusNotice` in `re_form_components.dart` and add `RePageScaffold`, `ReBrandMark`, `RePrimaryButton`, `ReSecondaryButton`, `ReTextField`, `ReChip`, `ReSectionHeader`, `ReStatusBanner`, and `ReEmptyState`.
- **Verification**:
  - Run `dart format`, `flutter analyze`, and `flutter test` in `D:/Mulia/hackgdgocitb/rekan/apps/mobile` (all 45 existing tests + new component/token/large-text tests must pass).
  - **Stop after Iteration 1 and wait for review.**

### Iteration 2 — Authentication UI Redesign (`Welcome`, `Login`, `Register`, `Verification`, `Recovery`)
- **Scope**:
  1. Update `lib/app.dart` (`title: 'Re:kan'`).
  2. Refactor `WelcomePage` (`id: 434`), `AuthForm` (`id: 473`), and status screens (`checking`, `verification`, `recovery`, `sessionError`) in `lib/features/auth/auth_boundary.dart` and `auth_form.dart` to match the approved FigCraft Neo-Brutalist designs.
  3. Replace every user-facing `'Re'` string with `'Re:kan'` and `ReBrandMark`.
  4. Preserve `AuthGateway`, `AuthController`, `PopScope`, `AutofillGroup`, password controller clearing, and the `AUTH_E2E_ENABLED` debug flag.
- **Verification**:
  - Run `dart format`, `flutter analyze`, and `flutter test` (updating any `'Re'` text finders in `test/auth_ui_test.dart` / `test/widget_test.dart` to `'Re:kan'`).
  - **Stop before onboarding and wait for review.**

### Iteration 3 — Academic Onboarding (`Screen 9`, `Steps 1–5`) & Read-Only Catalog Check
- **Scope**:
  1. Inspect/confirm whether the small read-only catalog endpoints (`GET /api/v1/universities`, `GET /api/v1/courses`, `GET /api/v1/skills` proposed in `docs/architecture/04-api-contract.md` and `phase-2e2-plan.md` lines `25–26`) are approved to be added to `services/api/routes/api.php`.
  2. If catalog endpoints are not yet added, **do not fabricate catalog UUIDs**; report the blocker and implement `OnboardingDraftController` + `AcademicOnboardingPage` (`Screen 9`, `id: 760`) preserving existing loaded `university_id`, `courses`, and `skills` while editing supported fields (`display_name`, `program`, `semester`, `bio`, `mbti_badge`, `visibility`, `preferences`).
  3. Ensure draft survives back navigation and recoverable network errors, blocks duplicate submit, never auto-overwrites a non-empty profile, and clears on account switch.
- **Verification**:
  - Widget & unit tests for 5-step progression, back draft retention, full PUT payload preservation, catalog failure handling, duplicate submit lock, and account switch invalidation.
  - **Stop after Iteration 3 and wait for review.**

### Iteration 4 — Authenticated Main App Shell & `ReBottomNavigation`
- **Scope**:
  1. Implement `ReBottomNavigation` (`Jelajah`, `Cari`, `Kolaborasi`, `Pesan`, `Profil`), `ReTopAppBar`, and `ReSearchAndFilterBar`.
  2. Wire `AuthScreen.authenticated` in `AuthBoundary` to check profile completion (`display_name`, `university_id`, `program`, `semester`): incomplete → `AcademicOnboardingPage` (`Screen 9`); complete → `MainShellPage`.
  3. Provide safe, clearly labeled development placeholders for `Cari` and `Kolaborasi`.
- **Verification**:
  - Auth boundary, onboarding completion boundary, tab switching, logout, and session restoration tests.
  - **Stop before Discover functionality.**

### Iteration 5 — Discover / Swipe Card UI (`Screen 3`)
- **Scope**:
  1. Implement `ReProfileCard` (`id: 531`), `ReSwipeDeck` (`id: 528`), `ReSwipeStamp` (`id: 370, 372`), `ReDiscoverActionBar` (`id: 571`), and `DiscoverPage` (`id: 518`).
  2. Because `GET /api/v1/matches/recommendations` is not yet implemented in Laravel, supply candidate cards via test/dev fixtures only (strictly isolated from production repositories).
  3. Ensure `Lewati`, `Simpan`, `Detail`, and `+ Ajak Kolaborasi` have full tap-button parity with swipe gestures and preserve deck index when opening `Profile Detail`.
- **Verification**:
  - Gesture drag/snap-back tests, button alternative tests, duplicate action lock tests, and deck state preservation tests.
  - **Stop before backend matching.**

### Iteration 6 — Profile Detail (`Screen 4`) & My Academic Profile (`Screen 8`)
- **Scope**:
  1. Implement `ReInfoRow` (`id: 668`), `ProfileDetailPage` (`id: 611`), and `MyAcademicProfilePage` (`id: 679`).
  2. Bind `MyAcademicProfilePage` to `ProfileController` + `AcademicProfileRepository` (`GET /api/v1/me/academic-profile`) using real schema fields (`display_name`, `university_id`, `program`, `semester`, `bio`, `mbti_badge`, `visibility`, `courses`, `skills`, `preferences`).
  3. Connect `Edit Profil` (`id: 699`) to open `AcademicOnboardingPage` (`Screen 9`) pre-populated with the loaded profile snapshot.
- **Verification**:
  - Loading, empty, partial, and full profile tests, edit entry tests, account-change cache clearing tests, and `200%` text scaling scroll tests.
  - **Stop before Collaboration / Chat iterations.**

### Iteration 7 — Collaboration Invite & Success States (`Screen 5B` & `Screen 5A`)
- **Scope**:
  1. Implement `CollaborationOutcomePage` supporting both `Pending` (`Screen 5B`, `id: 841`, `"UNDANGAN KOLABORASI TERKIRIM"`) and `Accepted` (`Screen 5A`, `id: 805`, `"KOLABORASI TERBENTUK!"`) states with isolated dev fixtures.
  2. Enforce CTA hierarchy (`1. Mulai Chat`, `2. Lihat Profil`, `3. Kembali ke Jelajah`) and neutral academic terminology.
- **Verification**:
  - Separate widget tests for `Pending` and `Accepted` states.

### Iteration 8 — Chat Inbox UI (`Screen 6`)
- **Scope**:
  1. Implement `ReSegmentedTabs` (`id: 885`), `ReUnreadBadge` (`id: 364..368`), `ReConversationTile` (`id: 894, 915`), and `ChatInboxPage` (`id: 871`) with isolated dev fixtures behind an abstract repository interface.
- **Verification**:
  - Tab filter (`Semua` / `Chat 1-1` / `Room`), search filter, unread badge contrast, and empty state (`id: 1044`) widget tests.

### Iteration 9 — Room Chat UI (`Screen 7`)
- **Scope**:
  1. Implement `ReRoomHeader` (`id: 949`), `RePinnedPurpose` (`id: 971`), `ReMessageBubble` (`id: 990, 1000, 1004, 1051`), and `RoomChatPage` (`id: 945`).
  2. Keep `Tugas`, `File`, and `Catatan` tabs (`ids: 979, 981, 983`) disabled (`#F2F0E8` muted fill) or omitted in production.
  3. Preserve composer text draft on send failure (`id: 1053`).
- **Verification**:
  - Message bubble variant tests, disabled tab assertion tests, and composer error draft preservation tests.

### Iteration 10 — Laravel Backend Contract Planning (`Discovery`, `Invitations`, `Conversations`)
- **Scope**:
  1. Audit `services/api/routes/api.php` and `docs/architecture/04-api-contract.md` against the implemented UI.
  2. Produce a concrete OpenAPI / endpoint specification for:
     - Read-only catalogs (`GET /api/v1/universities`, `/courses`, `/skills`)
     - Discovery & filters (`GET /api/v1/matches/recommendations`, skip/save)
     - Invitations & connections (`POST /api/v1/invitations`, `GET /api/v1/invitations`, `POST /api/v1/invitations/{id}/accept|decline`, `GET /api/v1/connections`)
     - Conversations & rooms (`GET /api/v1/conversations`, `GET/POST /api/v1/conversations/{id}/messages`)
  3. **Stop and request user approval before implementing any Laravel backend endpoints or migrations.**

### Iteration 11 — Controlled Integration & Final QA
- **Scope**:
  1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1 -Target mobile` and `-Target api` in `D:/Mulia/hackgdgocitb/rekan`.
  2. Verify `dart format`, `flutter analyze`, `flutter test`, `php artisan test`, and Pint.
  3. Produce final PASS / FAIL / NOT TESTED QA matrix without claiming unobserved E2E flows.

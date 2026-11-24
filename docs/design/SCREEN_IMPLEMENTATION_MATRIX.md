# Re:kan — Screen Implementation & Backend Readiness Matrix (`SCREEN_IMPLEMENTATION_MATRIX.md`)

## 1. Verified Laravel REST API Contract (`D:/Mulia/hackgdgocitb/rekan/services/api`)

Inspection of `services/api/routes/api.php`, `app/Modules/Academic/Http/AcademicProfileController.php`, and `docs/architecture/04-api-contract.md` in `D:/Mulia/hackgdgocitb/rekan` confirms the exact implemented vs. unimplemented backend surface:

### 1.1 Currently Implemented Routes (`services/api/routes/api.php`)
| HTTP Method & Route | Controller | Auth / Middleware | Implemented Behavior |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/health` & `GET /api/health` | `HealthController` | Public | Returns `200 {"status": "ok"}`. |
| `GET /api/v1/me` | `MeController` | `AuthenticateSupabase` | Verifies Supabase Bearer JWT via JWKS, provisions local `users` UUID row if needed, returns `{data: {id, status, created_at}, request_id}`. |
| `GET /api/v1/me/academic-profile` | `AcademicProfileController@show` | `AuthenticateSupabase` + `AcademicProfilePolicy@view` | Owner-only. Returns `{data: PROFILE, request_id}` containing `user_id` and the 10 writable fields (`display_name`, `university_id`, `program`, `semester`, `bio`, `mbti_badge`, `visibility`, `courses`, `skills`, `preferences`). |
| `PUT /api/v1/me/academic-profile` | `AcademicProfileController@update` | `AuthenticateSupabase` + `AcademicProfilePolicy@update` | Owner-only complete replacement under row lock (`lockForUpdate`). Requires all 10 writable fields; rejects any unknown field with `422 VALIDATION_ERROR`. Supports optional `X-Re-Require-Empty-Profile: true` header (`409 PROFILE_NOT_EMPTY`). |

### 1.2 Proposed Routes in `04-api-contract.md` That Are **NOT YET Implemented** in `routes/api.php`
- **Catalogs**: `GET /api/v1/universities`, `GET /api/v1/courses?university_id=`, `GET /api/v1/skills` *(PostgreSQL tables `universities`, `courses`, `skills` exist from Phase 2C, but read-only HTTP routes are not yet registered in `routes/api.php`)*.
- **Intents & Discovery**: `POST /api/v1/intents`, `GET /api/v1/intents`, `PATCH /api/v1/intents/{id}`, `GET /api/v1/matches/recommendations?intent_id=&cursor=`.
- **Invitations & Connections**: `POST /api/v1/invitations`, `GET /api/v1/invitations?status=`, `POST /api/v1/invitations/{id}/accept`, `POST /api/v1/invitations/{id}/decline`, `GET /api/v1/connections`.
- **Chat & Materials**: `GET /api/v1/conversations`, `GET /api/v1/conversations/{id}/messages`, `POST /api/v1/conversations/{id}/messages`, `POST /api/v1/materials`, `POST /api/v1/materials/download-batches`, `GET /api/v1/materials/download-batches/{id}`.

---

## 2. Screen Backend Readiness Classification Summary

| Screen # | Screen Name | FigCraft Page & Frame ID | Existing Flutter File (`apps/mobile/lib/`) | Readiness Classification | Backend & Architectural Rationale |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **1** | **Welcome / Landing** | Page `03` (`id: 434`, `390×844`) | `features/auth/auth_boundary.dart` (`WelcomePage`) | **Ready for real backend integration** | Already wired to `AuthController.go(AuthScreen.register / login)`. Needs Neo-Brutalist presentation refactor & `"Re"` → `"Re:kan"` fix. |
| **2** | **Login** *(+ Register, Verification, Recovery, SessionError)* | Page `03` (`id: 473`, `390×844`) | `features/auth/auth_form.dart` & `auth_boundary.dart` | **Ready for real backend integration** | Already wired to `SupabaseAuthGateway` + `AuthController` (45 passing tests). Needs Neo-Brutalist presentation refactor (`ReTextField`, `RePrimaryButton`, `ReStatusBanner`, `ReBrandMark`). |
| **3** | **Discover / Swipe Cards** | Page `04` (`id: 518`, `390×844`) | *Not yet created* (`features/discover/`) | **UI-only implementation possible** *(Blocked on Discovery API for live data)* | `ReProfileCard`, `ReSwipeDeck`, and `ReDiscoverActionBar` can be built and widget-tested with isolated dev/test fixtures, but live candidate decks are **blocked on unimplemented `GET /api/v1/matches/recommendations` and `POST /api/v1/invitations`**. |
| **4** | **Profile Detail** | Page `05` (`id: 611`, `390×844`) | *Not yet created* (`features/discover/` or `features/academic_profile/`) | **UI-only implementation possible** *(Blocked on Candidate Read & Invite API)* | `GET /api/v1/me/academic-profile` is **owner-only** (`AcademicProfilePolicy`). No public candidate profile endpoint (`GET /api/v1/profiles/{id}`) or invite endpoint exists yet. UI can be built against `AcademicProfile` DTO / fixtures. |
| **5A** | **Collaboration Success (Mutual Match Concept)** | Page `06` (`id: 805`, `390×844`) | *Not yet created* (`features/collaboration/`) | **Blocked by missing API capabilities** *(UI-only dev fixture state possible)* | Requires `POST /api/v1/invitations/{id}/accept` and `GET /api/v1/connections` (not implemented in `routes/api.php`). |
| **5B** | **Pending Collaboration Invite** | Page `06` (`id: 841`, `390×844`) | *Not yet created* (`features/collaboration/`) | **UI-only implementation possible** *(Blocked on `POST /api/v1/invitations`)* | Visual state (`UNDANGAN KOLABORASI TERKIRIM`) can be built and widget-tested with dev fixtures; persistent invite creation is blocked on `POST /api/v1/invitations`. |
| **6** | **Chat Inbox (`Pesan`)** | Page `07` (`id: 871`, `390×844`) | *Not yet created* (`features/chat/`) | **Blocked by missing API capabilities** *(UI-only presentation with dev fixtures)* | Blocked on `GET /api/v1/conversations` (not implemented in `routes/api.php`). Can be built as a pure presentation layer with dev fixtures in Iteration 8. |
| **7** | **Room Chat** | Page `07` (`id: 945`, `390×844`) | *Not yet created* (`features/rooms/`) | **Blocked by missing API capabilities** *(UI-only presentation for `Chat` tab; `Tugas/File/Catatan` disabled)* | Blocked on `GET/POST /api/v1/conversations/{id}/messages`. Sub-tabs `Tugas`, `File`, and `Catatan` (`ids: 979..983`) have no backend module and must remain disabled (`#F2F0E8`) or omitted in production. |
| **8** | **My Academic Profile (`Profil Saya`)** | Page `05` (`id: 679`, `390×844`) | `features/academic_profile/presentation/profile_controller.dart` | **Ready for real backend integration** *(Partially blocked on Catalog label resolution)* | Backed by implemented `GET/PUT /api/v1/me/academic-profile` (`AcademicProfileRepository` + `ProfileController`). Note: resolving UUID names for `university_id`, `courses`, and `skills` requires the read-only catalog endpoints (`GET /universities`, `/courses`, `/skills`). |
| **9** | **Academic Onboarding (`Steps 1–5`)** | Page `05` (`id: 760`, `390×844`) | `features/academic_profile/` (`AcademicProfileInput`) | **Ready for real backend integration** *(Catalog selectors blocked on read-only Catalog routes)* | `PUT /api/v1/me/academic-profile` is implemented and tested (`71` Laravel tests, `29` Flutter tests). Selecting new `university_id`, `courses` UUIDs, or `skills` UUIDs is **blocked until read-only `GET /api/v1/universities`, `/courses`, `/skills` routes are approved and added**. |

---

## 3. Detailed Screen-by-Screen Handoff Specifications

---

### Screen 1 — Welcome / Landing
- **FigCraft Frame Reference**:
  - Page: `03 - Authentication` (`page: 4`), Frame `id: 434` (`390×844`)
  - Key Nodes: `Brand Header` (`439`), `Hero Value Card` (`445`), `Academic Collaboration Preview Card` (`450`), `Daftar Primary CTA` (`464`), `Masuk Secondary CTA` (`467`)
  - Preview: `exports/preview_screen_01_welcome.png`
- **Existing Code Reference**:
  - `apps/mobile/lib/features/auth/auth_boundary.dart` (`WelcomePage`, lines `174–217`).
- **UI Component Requirements**:
  - `RePageScaffold` / `ReFormPage` (`#FFFDF5` paper background)
  - `ReBrandMark` (`Re:kan` — replaces `Text('Re')` at line `182`)
  - Hero Neo-Brutalist Value Card (`3px` `#111111` border, `6×6px` hard shadow, `#FFFFFF` surface)
  - `ReStatusNotice` / `ReStatusBanner` (including unconfigured service error state at line `197`)
  - `RePrimaryAction` / `RePrimaryButton` (`"Daftar"` / `"DAFTAR AKUN MAHASISWA ->"`)
  - `ReSecondaryButton` (`"Sudah punya akun? Masuk"`)
- **State Requirements**:
  - `Default (Configured)`: Both `Daftar` and `Masuk` enabled.
  - `Unconfigured (controller == null)`: Displays error `ReStatusNotice` (`"Layanan akun belum dikonfigurasi. Hubungi pengelola Re:kan."`) and disables CTAs.
- **Navigation Behavior**:
  - `Daftar` → `controller.go(AuthScreen.register)`
  - `Masuk` → `controller.go(AuthScreen.login)`
- **Required Backend Data**: None.
- **Implementation Dependencies**: Iteration 1 (`ReTokens`, `AppTheme`, `ReBrandMark`, `RePrimaryAction`, `ReSecondaryButton`).
- **Testing Criteria**: Update `test/auth_ui_test.dart` & `test/widget_test.dart` to verify `'Re:kan'` branding, unconfigured disabled state, and navigation to login/register.

---

### Screen 2 — Login *(+ Auth Suite: Register, Verification, Recovery, SessionError)*
- **FigCraft Frame Reference**:
  - Page: `03 - Authentication` (`page: 4`), Frame `id: 473` (`390×844`)
  - Key Nodes: `Back Button` (`479`, `44×44px`), `ReBrandMark` (`481`), `Login Heading Block` (`484`), `Login Form Container Card` (`487`), `Email Input` (`488`), `Password Input` (`495`), `Toggle Visibility` (`500`, `56×44px`), `Lupa Kata Sandi` (`502`, `140×44px`), `MASUK KE RE:KAN CTA` (`504`, `52px`), `Registration Row` (`507`, `Daftar Pill` `509` `80×44px`)
  - Preview: `exports/preview_screen_02_login.png`
- **Existing Code Reference**:
  - `apps/mobile/lib/features/auth/auth_form.dart` (`AuthForm`, lines `7–198`) and `auth_boundary.dart` (`checking`, `verification`, `recovery`, `sessionError`, lines `68–166`).
- **UI Component Requirements**:
  - `RePageScaffold` / `ReFormPage` with `ReTopAppBar` (back button `44×44dp` + `ReBrandMark`)
  - Neo-Brutalist Form Card (`#FFFFFF` surface, `3px` `#111111` border, `6×6px` hard shadow) wrapping the `AutofillGroup` & `Form`
  - `ReTextField` / styled `TextFormField` (`Email`, `Kata sandi`, and `Konfirmasi kata sandi` when `registration == true`, preserving existing tooltips `'Tampilkan kata sandi'` / `'Sembunyikan kata sandi'`)
  - `RePrimaryAction` / `RePrimaryButton` (`'Masuk'` / `'Buat akun'`, busy labels `'Memeriksa akun…'` / `'Mendaftarkan akun…'`)
  - `ReSecondaryButton` / `TextButton` for `'Lupa kata sandi?'` and `'Belum punya akun? Daftar'` (`>=44dp` height)
  - `ReStatusNotice` / `ReStatusBanner` for `controller.message`, `verification`, `recovery`, and `sessionError`
- **State Requirements**:
  - Preserves all 8 `AuthScreen` states in `AuthController`: `welcome`, `login`, `register`, `checking`, `authenticated`, `verification`, `recovery` (explanatory unavailable state—no fake email sent), and `sessionError`.
- **Navigation Behavior**:
  - Single-page `PopScope` replacement in `AuthBoundary` (`auth_boundary.dart:54`) prevents back-button leakage into prior accounts after logout.
- **Required Backend Data**:
  - Existing `SupabaseAuthGateway` (`signIn`, `signUp`, `restoreSession`, `signOut`).
- **Implementation Dependencies**: Iteration 1 foundation widgets.
- **Testing Criteria**: All 45 existing tests in `apps/mobile/test/` (`auth_ui_test.dart`, `design_foundation_test.dart`, etc.) must pass, plus Narrow/Large-Text (`200%` text scaling) + Keyboard inset tests.

---

### Screen 3 — Discover / Swipe Cards (`Jelajah`)
- **FigCraft Frame Reference**:
  - Page: `04 - Discover & Swipe` (`page: 5`), Frame `id: 518` (`390×844`)
  - Key Nodes: `Discover Header & Filter Bar` (`522`), `Filter Control` (`526`, `102×44px`), `ReSwipeDeck` (`528`), `ReProfileCard` (`531`), `Tujuan Kolaborasi Box` (`565`), `ReDiscoverActionBar` (`571`: `Lewati` `572`, `Simpan` `575`, `Detail` `578`, `Ajak Kolaborasi` `581`), `ReBottomNavigation` (`584`)
  - Companion Empty State: `ReEmptyState / Discover Deck Empty` (`id: 1038`, Page `09`)
  - Preview: `exports/preview_screen_03_discover.png`
- **UI Component Requirements**:
  - `RePageScaffold`, `ReTopAppBar`, `ReSwipeDeck`, `ReSwipeStamp`, `ReProfileCard`, `ReDiscoverActionBar`, `ReBottomNavigation`, `ReEmptyState`.
- **State Requirements**:
  - `Active Deck`, `Dragging Left (LEWATI)`, `Dragging Right (AJAK KOLABORASI)`, `Snap-Back`, `In-Flight Action Lock`, `Empty Deck` (`id: 1038`), `Loading`, `Error`.
- **Navigation Behavior**:
  - Tap card or `Detail` (`id: 578`) → push `Screen 4 — Profile Detail` while preserving deck index and active filters.
  - Swipe right or tap `+ Ajak Kolaborasi` (`id: 581`) → navigate to `Screen 5B` (`Pending Invite`) or `Screen 5A` (`Collaboration Success`).
- **Required Backend Data**:
  - **Missing API Contract**: Proposed `GET /api/v1/matches/recommendations?intent_id=&cursor=` and `POST /api/v1/invitations` in `04-api-contract.md` are **not yet implemented** in `services/api/routes/api.php`.
  - Implement in Iteration 5 using isolated dev/test fixtures only.
- **Implementation Dependencies**: Iteration 1 (Foundation), Iteration 4 (`ReBottomNavigation` shell).
- **Testing Criteria**: Drag threshold & snap-back widget tests, `ReDiscoverActionBar` button parity tests, duplicate action lock tests, and deck position retention after returning from `Profile Detail`.

---

### Screen 4 — Profile Detail (`Detail Profil`)
- **FigCraft Frame Reference**:
  - Page: `05 - Academic Profile` (`page: 6`), Frame `id: 611` (`390×844`)
  - Key Nodes: `ReTopAppBar - Detail Profil` (`615`), `Identity & Primary CTA Card` (`622` with single primary CTA `+ AJAK KOLABORASI` `633` `216×44px`), `Tujuan Kolaborasi Card` (`1031`), `Tentang` (`635`), `Keahlian & Mata Kuliah` (`640`), `Preferensi Belajar` (`657`), `Portofolio` (`666` with `ReInfoRow` `668`), `Bottom Sticky Bar` (`674` with `Simpan` `675` `52×48px` and `<- Kembali ke Dek Jelajah` `677` `280×48px`)
  - Preview: `exports/preview_screen_04_profile_detail.png`
- **UI Component Requirements**:
  - `RePageScaffold` (`scrollable: true` per `Finding J-02`), `ReTopAppBar`, `RePrimaryButton`, `ReSecondaryButton`, `ReSectionHeader`, `ReChip`, `ReInfoRow`.
- **State Requirements**:
  - `Loaded (Full / Partial Profile)`, `Invite Submitting Lock`, `Loading`, `Error`.
- **Navigation Behavior**:
  - Back (`id: 616` / `677`) returns to `Screen 3 — Discover` at the same card index.
- **Required Backend Data**:
  - **Schema Mapping (`Finding J-03`)**: Maps to `display_name`, `university_id` (resolved name), `program`, `semester`, `bio`, `mbti_badge` (display-only), `skills` (`level 1..5`), `courses`, and `preferences` (`study_mode`, `preferred_language`).
  - **Missing API Contract**: Viewing *another* user's profile requires a candidate profile read endpoint (current `GET /api/v1/me/academic-profile` is owner-only).
- **Implementation Dependencies**: Iteration 1 (Foundation), Iteration 6 (`ReInfoRow`).
- **Testing Criteria**: Single primary CTA hierarchy check, partial/null field rendering, `200%` text scaling scroll test.

---

### Screen 5A & Screen 5B — Collaboration Outcome (`Collaboration Success` & `Pending Invite`)
- **FigCraft Frame Reference**:
  - Page: `06 - Collaboration` (`page: 7`), Frames `id: 805` (`Screen 5A — Collaboration Success`, `390×844`) and `id: 841` (`Screen 5B — Pending Collaboration Invite`, `390×844`)
  - Previews: `exports/preview_screen_05_collab_success.png`, `exports/preview_screen_05b_pending_invite.png`
- **UI Component Requirements**:
  - `RePageScaffold`, Academic Identity Summary Cards (`3px` border, `6×6px` shadow), `ReStatusBanner`, `RePrimaryButton`, `ReSecondaryButton`, `ReTertiaryButton`.
- **State Requirements**:
  - `Pending Invite (`Screen 5B`, `id: 841`)`: Unilateral invite sent (`"UNDANGAN KOLABORASI TERKIRIM"`).
  - `Accepted Collaboration (`Screen 5A`, `id: 805`)`: Mutual/accepted collaboration (`"KOLABORASI TERBENTUK!"`).
- **Navigation Behavior**:
  - CTA priority: `1. Mulai Chat` → `2. Lihat Profil` → `3. Kembali ke Jelajah`.
- **Required Backend Data**:
  - **Missing API Contract**: Blocked on `POST /api/v1/invitations`, `POST /api/v1/invitations/{id}/accept`, and `GET /api/v1/connections` (`04-api-contract.md`). Implement with isolated dev fixtures in Iteration 7.
- **Implementation Dependencies**: Iteration 1, Iteration 5/6.
- **Testing Criteria**: Separate widget tests for `Pending` and `Accepted` states; verifies zero dating/heart terminology.

---

### Screen 6 — Chat Inbox (`Pesan`)
- **FigCraft Frame Reference**:
  - Page: `07 - Chat & Rooms` (`page: 8`), Frame `id: 871` (`390×844`)
  - Key Nodes: `ReTopAppBar - Pesan` (`875`), `ReSearchAndFilterBar` (`883`), `ReSegmentedTabs` (`885`, `50px` outer / `44px` inner tabs `886, 888, 890`), `Section - Chat 1-1` (`892` with `ReConversationTile` `894, 906`), `Section - Room Kolaborasi` (`913` with `ReConversationTile` `915, 927`), `ReBottomNavigation` (`934`)
  - Companion Empty State: `ReEmptyState / Chat Inbox Empty` (`id: 1044`, Page `09`)
  - Preview: `exports/preview_screen_06_chat_inbox.png`
- **UI Component Requirements**:
  - `RePageScaffold`, `ReTopAppBar`, `ReSearchAndFilterBar`, `ReSegmentedTabs`, `ReSectionHeader`, `ReConversationTile`, `ReUnreadBadge`, `ReEmptyState`, `ReBottomNavigation`.
- **State Requirements**:
  - `Default`, `Filtered by Tab (Semua / Chat 1-1 / Room)`, `Search Filtered`, `Empty Inbox` (`id: 1044`), `Loading`, `Error`.
- **Navigation Behavior**:
  - Tap conversation tile → push 1-to-1 chat or `Screen 7 — Room Chat` (`id: 945`).
- **Required Backend Data**:
  - **Missing API Contract**: Blocked on `GET /api/v1/conversations` (`04-api-contract.md`). Build UI in Iteration 8 using isolated dev fixtures behind a repository interface.
- **Implementation Dependencies**: Iteration 1, Iteration 4, Iteration 8.
- **Testing Criteria**: Tab filter tests, search filter tests, unread badge contrast (`#111111` on `#F22DBB`), and empty state widget tests.

---

### Screen 7 — Room Chat (`Room Kolaborasi`)
- **FigCraft Frame Reference**:
  - Page: `07 - Chat & Rooms` (`page: 8`), Frame `id: 945` (`390×844`)
  - Key Nodes: `ReRoomHeader` (`949`), `Member Strip Bar` (`958` with `Btn Add Member (+)` `959` `44×44px`), `RePinnedPurpose` (`971`), `Room Mode Segmented Tabs` (`976`: `Chat` active `977` `44px`; `Tugas` `979`, `File` `981`, `Catatan` `983` muted `#F2F0E8` `44px`), `Messages Stream` (`985` with `ReMessageBubble` `990, 1000, 1004`), `Composer Bar` (`1006`)
  - Companion System Nodes (Page `09`, `id: 1035`): `ReMessageBubble / System Event` (`1051`), `ReStatusBanner / Network Retry & Draft Safe` (`1053`)
  - Preview: `exports/preview_screen_07_room_chat.png`
- **UI Component Requirements**:
  - `RePageScaffold`, `ReRoomHeader`, `RePinnedPurpose`, `ReSegmentedTabs`, `ReMessageBubble` (`self`, `other`, `attachment`, `system`), `ReStatusBanner`, Composer Bar.
- **State Requirements**:
  - `Default (Chat Active)`, `Sending Lock`, `Send Error / Disconnected with Draft Preserved` (`id: 1053`), `Unsupported Tabs Disabled` (`Tugas`, `File`, `Catatan` disabled in production).
- **Navigation Behavior**:
  - Back button (`id: 950`) returns to `Screen 6 — Chat Inbox`.
- **Required Backend Data**:
  - **Missing API Contract**: Blocked on `GET/POST /api/v1/conversations/{id}/messages` (`04-api-contract.md`). Implement UI with dev fixtures in Iteration 9.
- **Implementation Dependencies**: Iteration 1, Iteration 8, Iteration 9.
- **Testing Criteria**: All 4 `ReMessageBubble` variants, disabled `Tugas/File/Catatan` tabs assertion, composer draft retention on error.

---

### Screen 8 — My Academic Profile (`Profil Saya`)
- **FigCraft Frame Reference**:
  - Page: `05 - Academic Profile` (`page: 6`), Frame `id: 679` (`390×844`)
  - Key Nodes: `ReTopAppBar - Profil Saya` (`683`), `Identity Summary & Edit Action Card` (`688` with `Edit Profil` `699` `220×44px`), `Completion Banner` (`700`), `Informasi Akademik Card` (`702`), `Keahlian & Minat` (`713` with `+` buttons `722, 733` `44×44px`), `Ketersediaan & Mode Belajar` (`735`), `Portofolio` (`744`), `ReBottomNavigation (Profil Active)` (`749`)
  - Preview: `exports/preview_screen_08_my_profile.png`
- **Existing Code Reference**:
  - `apps/mobile/lib/features/academic_profile/data/academic_profile.dart`, `academic_profile_repository.dart`, `presentation/profile_controller.dart`.
- **UI Component Requirements**:
  - `RePageScaffold` (`scrollable: true`), `ReTopAppBar`, `ReSecondaryButton`, `ReStatusBanner`, `ReSectionHeader`, `ReInfoRow`, `ReChip`, `ReBottomNavigation`.
- **State Requirements**:
  - Maps directly to `ProfileStatus { idle, loading, empty, success, error }` in `ProfileController`.
  - When `status == ProfileStatus.empty` or fields are null, shows clear `"Lengkapi profil"` / `"Tambah"` affordances.
- **Navigation Behavior**:
  - Tapping `Edit Profil` (`id: 699`) opens the 5-step Academic Onboarding / Edit flow (`Screen 9`, `id: 760`) pre-populated with the current `AcademicProfileInput` snapshot.
  - Logout action clears `ProfileController.clear()` and returns to `WelcomePage`.
- **Required Backend Data**:
  - **Implemented**: `GET /api/v1/me/academic-profile` (`AcademicProfileRepository.get()`).
  - **Schema Constraint (`Finding J-03`)**: Render the 10 implemented fields (`display_name`, `university_id`, `program`, `semester`, `bio`, `mbti_badge` [display-only], `visibility`, `courses`, `skills[{skill_id, level}]`, `preferences{study_mode, preferred_language}`). Do not invent unsupported profile fields (`interests`, `portfolio`, `schedule`) in production requests.
  - **Catalog Resolution Dependency**: Displaying human-readable labels for `university_id`, `courses` UUIDs, and `skills` UUIDs requires the proposed read-only `GET /api/v1/universities`, `/courses`, `/skills` endpoints (`phase-2e2-plan.md` line 25).
- **Implementation Dependencies**: Iteration 1, Iteration 4, Iteration 6.
- **Testing Criteria**: `ProfileStatus` (`loading`, `empty`, `success`, `error`) widget tests, partial profile rendering, account switch `clear()` verification, `200%` text scaling scroll test.

---

### Screen 9 — Academic Onboarding (`Steps 1–5`)
- **FigCraft Frame Reference**:
  - Page: `05 - Academic Profile` (`page: 6`), Frame `id: 760` (`Screen 9 - Academic Onboarding Step 2/5 (390x844)`)
  - Key Nodes: `Onboarding Progress Header Bar` (`764`), `Segmented 5-Step Progress Bar` (`771`), `Step Title & Explanation` (`777`), `Form Card` (`780`), `Draft Safe Banner` (`798`), `Bottom Navigation Controls` (`800`: `<- KEMBALI` `801` `112×48px`, `LANJUTKAN ->` `803` `220×48px`)
  - Preview: `exports/preview_screen_09_onboarding.png`
- **Existing Code Reference**:
  - `apps/mobile/lib/features/academic_profile/data/academic_profile.dart` (`AcademicProfileInput.toJson()`) & `academic_profile_repository.dart` (`put(input, requireEmpty: ...)`).
  - Step breakdown aligned with `docs/architecture/phase-2e2-plan.md` (lines `44–55`):
    - **Step 1 (`Identitas akademik`)**: `display_name` (max 100), `university_id` (UUID), `program` (max 150), `semester` (1–20).
    - **Step 2 (`Keahlian`)**: `skills` (`List<SkillSelection>` with `skill_id` UUID and `level` 1–5).
    - **Step 3 (`Mata kuliah`)**: `courses` (UUID list; changing `university_id` prompts review/removal of incompatible university-scoped courses).
    - **Step 4 (`Cara belajar`)**: `preferences.study_mode` (`online`, `in_person`, `hybrid`), `preferences.preferred_language`, `bio` (max 2000), `mbti_badge` (optional 4-letter regex, display-only), `visibility` (`private` default, `university`, `public`).
    - **Step 5 (`Tinjau profil`)**: Summary review + single `"Simpan profil"` (`PUT /api/v1/me/academic-profile`).
- **State Requirements**:
  - Separate in-memory `OnboardingDraftController` (never mutate `ProfileController.profile` directly because `ProfileController` clears `profile` during `load()`/errors — `phase-2e2-plan.md` line 18).
  - Moving backward (`<- KEMBALI`) or encountering a recoverable `PUT` error preserves the entire draft and untouched loaded fields (`courses`/`skills` UUIDs must never be silently wiped if catalog labels fail to load).
  - First-time empty profile initialization can use `requireEmpty: true` (`X-Re-Require-Empty-Profile: true`); editing an existing non-empty profile pre-populates the draft and saves on explicit submit.
  - Account switch immediately disposes/clears the memory draft.
- **Navigation Behavior**:
  - Proposed completion rule (`phase-2e2-plan.md` line 27): persisted non-blank `display_name`, non-null `university_id`, non-blank `program`, and `semester` `1..20`. Incomplete profiles route to `Screen 9`; completed profiles route to the Main App Shell.
- **Required Backend Data**:
  - **Implemented**: `GET /api/v1/me/academic-profile` and `PUT /api/v1/me/academic-profile`.
  - **Blocker for Catalog Pickers (`phase-2e2-plan.md` lines 25–26 & `IMPLEMENTATION_CONSTRAINTS.md`)**: `university_id`, `courses.*`, and `skills.*.skill_id` are validated by `AcademicProfileController.php` against `Rule::exists('universities', 'id')`, `Rule::exists('courses', 'id')`, and `Rule::exists('skills', 'id')`. Because `GET /api/v1/universities`, `/courses`, and `/skills` are **not yet implemented** in `services/api/routes/api.php`, catalog selectors cannot be populated in production until that small read-only catalog API extension is approved and implemented.
- **Implementation Dependencies**: Iteration 1 (Foundation), Iteration 3 (Onboarding Draft Controller + Read-Only Catalog API approval).
- **Testing Criteria**: Step navigation, back draft preservation, full-payload preservation on partial edit, catalog-failure selection preservation, duplicate submit lock, `409 PROFILE_NOT_EMPTY` handling, and account-switch draft invalidation.

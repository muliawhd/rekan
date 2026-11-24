# Re:kan — Post-FigCraft Visual Quality & Technical Audit (`FIGCRAFT_AUDIT.md`)

## 1. Executive Summary & Inspected Document Metadata

This audit inspects the completed **Re:kan** mobile UI/UX design system (`Re_kan_Mobile_UI_Design_System_v0.1.figcraft`) created via FigCraft MCP and cross-references it against:
1. The approved design specifications in `docs/design/*.md`, and
2. The live **Re:kan** monorepo at `D:/Mulia/hackgdgocitb/rekan` (`apps/mobile/` Flutter `re_mobile` package + `services/api/` Laravel 12 REST API).

| Property | Verified Value |
| :--- | :--- |
| **Document Name** | `Re:kan - Mobile UI Design System v0.1` (`id: 1`) |
| **File Path** | `d:/Mulia/rekan ui ux/Re_kan_Mobile_UI_Design_System_v0.1.figcraft` (`187,372` bytes, `dirty: false`) |
| **Target Code Repository** | `D:/Mulia/hackgdgocitb/rekan` (`apps/mobile` + `services/api`) |
| **Color Profile** | `sRGB` |
| **Pages Inspected** | `10` (`00 - References & Direction` through `09 - Design QA`) |
| **Ready-for-Dev Boards & Screens** | `16` top-level frames (`status: "readyForDev"`, `changed: false`) |
| **Mobile Screen Frames (`390×844`)** | `10` screens (`Screen 1` through `Screen 9`, including `Screen 5A` & `Screen 5B`) |
| **Design Variables** | `26` (`11` in `Re:kan Colors`, `15` in `Re:kan Spacing & Layout`) |
| **Shared Styles** | `25` (`11` Paint styles `S:1..S:11`, `10` Text styles `S:12..S:21`, `4` Effect styles `S:22..S:25`) |
| **Reusable `COMPONENT` Nodes** | `56` main `COMPONENT` definitions across all 18 `COMPONENT_SPEC.md` families |
| **Verified `INSTANCE` Nodes** | `6` live `INSTANCE` nodes (`ids: 1057, 1059, 1061, 1063, 1065, 1067`) inside `09B` (`id: 1035`) |
| **Flutter Code Connect Links** | `21` component families linked to `package:re_mobile/...` (`exports/figcraft.connect.json`) |
| **Font Availability** | `Montserrat` (`400` Regular, `500` Medium, `600` SemiBold, `700` Bold, `800` ExtraBold, `900` Black) — `0` missing fonts |
| **Exported Token Artifacts** | `exports/rekan_design_tokens.dart`, `exports/rekan_design_tokens.json`, `exports/figcraft.connect.json` |
| **Exported `2x` Previews** | `20` PNG files (`10` mobile screens + `10` full-page specification boards) in `exports/` |

---

## 2. Page-by-Page & Frame Inventory

| Page ID | Page Name | Top-Level Frame IDs | Frame Dimensions | `devStatus` | Purpose & Inspected Contents |
| :---: | :--- | :--- | :---: | :---: | :--- |
| `1` | `00 - References & Direction` | `11` | `1440×1060` | `readyForDev` | Product direction, Academic Neo-Brutalism rules, approved vs. banned vocabulary, 10-page architecture. |
| `2` | `01 - Foundations` | `56` | `1440×1769` | `readyForDev` | 11 color swatches (`VariableID:1..11`), 10 typography specimens (`S:12..S:21`), spacing rulers (`4–48px`), border/radius/shadow tokens (`S:22..S:25`). |
| `3` | `02 - Components` | `220` | `1440×1957` | `readyForDev` | 43 master `COMPONENT` nodes covering buttons, discover actions, text fields, search bar, chips, status banners, unread badges, swipe stamps, bottom nav, top app bar, segmented tabs, and section headers. |
| `4` | `03 - Authentication` | `413`, `434`, `473`, `513` | `390×844` (screens) | `readyForDev` | `Screen 1 — Welcome / Landing` (`id: 434`), `Screen 2 — Login` (`id: 473`), plus Auth specification card (`id: 513`). |
| `5` | `04 - Discover & Swipe` | `416`, `518`, `595` | `390×844` (screen) | `readyForDev` | `Screen 3 — Discover / Swipe Cards` (`id: 518`) with `ReSwipeDeck` (`id: 528`), `ReProfileCard` (`id: 531`), `ReDiscoverActionBar` (`id: 571`), and interaction spec card (`id: 595`). |
| `6` | `05 - Academic Profile` | `419`, `611`, `679`, `760` | `390×844` (screens) | `readyForDev` | `Screen 4 — Profile Detail` (`id: 611`), `Screen 8 — My Academic Profile` (`id: 679`), `Screen 9 — Academic Onboarding Step 2/5` (`id: 760`). |
| `7` | `06 - Collaboration` | `422`, `805`, `841`, `866` | `390×844` (screens) | `readyForDev` | `Screen 5A — Collaboration Success (Concept)` (`id: 805`), `Screen 5B — Pending Collaboration Invite (MVP)` (`id: 841`), and state spec card (`id: 866`). |
| `8` | `07 - Chat & Rooms` | `425`, `871`, `945`, `1013` | `390×844` (screens) | `readyForDev` | `Screen 6 — Chat Inbox` (`id: 871`), `Screen 7 — Room Chat` (`id: 945`), and messaging spec card (`id: 1013`). |
| `9` | `08 - Prototype Flows` | `428`, `1017` | `1250×360` | `readyForDev` | End-to-end flow map (`id: 1017`) + 10 interactive prototype noodles (`onClick` -> `navigate` / `back`). |
| `10` | `09 - Design QA` | `431`, `1035` | `1250×226`, `1250×520` | `readyForDev` | QA summary banner (`id: 431`) and `09B - System States & 14-Point Audit Board` (`id: 1035`) with `ReEmptyState` (`1038, 1044`), `ReMessageBubble / System Event` (`1051`), `ReStatusBanner / Network Retry` (`1053`), and live `INSTANCE` verification row (`1056`). |

---

## 3. 14-Point Visual & Technical Quality Audit

### 3.1 Re:kan Branding Consistency — **PASS IN FIGCRAFT / ACTION REQUIRED IN FLUTTER (`J-03`)**
- **In FigCraft**: Every brand mark and copy reference across all 10 pages renders the full string **`Re:kan`** (`ReBrandMark` `id: 224`, `Screen 1` `id: 441`, `Screen 2` `id: 480`, `Page 00` `id: 15`). Zero instances of shortened `"Re"` exist in FigCraft.
- **In Existing Flutter Code (`D:/Mulia/hackgdgocitb/rekan/apps/mobile/lib/`)**:
  - `lib/app.dart` (line 25) currently sets `title: 'Re'`.
  - `lib/features/auth/auth_boundary.dart` (lines 79, 109, 126, 182, 199) and `lib/features/auth/auth_form.dart` (line 64) currently render `'Re'` instead of `'Re:kan'`.
  - During Iteration 2 (Authentication UI Redesign), all occurrences of `'Re'` in Flutter UI strings must be replaced with `'Re:kan'` and `ReBrandMark`.

### 3.2 Neo-Brutalist Design Consistency — **PASS IN FIGCRAFT / THEME UPGRADE REQUIRED IN FLUTTER**
- **In FigCraft**:
  - **Borders**: Every container, card, button, chip, input field, and banner uses explicit inside strokes bound to `color/ink` (`#111111`) at `2px` (`border/standard`, `VariableID:24`) or `3px` (`border/emphasized`, `VariableID:25`).
  - **Elevation**: Zero blurred drop shadows, glassmorphism, or gradients exist. All shadows use `0px` blur hard offsets (`3×3px`, `4×4px`, or `6×6px` `#111111`, plus `4×4px` `#FFE500` on the dark `Re:kan` brand badge).
  - **Corner Radii**: Constrained to `0px`, `6px` (`radius/small`), `8–10px` (`radius/medium`), `12–16px` (`radius/large`), and `999px` (`radius/full`).
- **In Existing Flutter Code (`lib/core/theme/re_tokens.dart` & `app_theme.dart`)**:
  - `ReTokens` currently uses the earlier Phase 2E.2 Iteration A forest-green palette (`forest: #245C45`, `ink: #182B24`, `paper: #F7F8F4`, `outline: #718078`, `1px` borders, no hard offset shadows).
  - Iteration 1 will upgrade `re_tokens.dart` and `app_theme.dart` to the approved Academic Neo-Brutalist tokens (`exports/rekan_design_tokens.dart`).

### 3.3 Typography Hierarchy — **PASS WITH MINOR FINDING (`M-01`)**
- Master typography scale (`S:12` `displayLarge` `38px` down to `S:21` `caption` `11px`) is defined in `Montserrat` and matches `DESIGN_SYSTEM.md` §4.
- **Observation (`M-01`)**: Inside dense fixed-height (`844px`) screen frames (`Screen 3, 4, 6, 7, 8`), individual text layers use `8` to `13` distinct `(fontSize, fontStyle)` pairs (including `9px`, `10px`, `13px`, `15px`, `21px`, and `Black` `900` weight) to prevent vertical clipping without scrolling. Flutter implementation must normalize these back to the 10 semantic `ReKanTypography` tokens.

### 3.4 Spacing and Alignment — **PASS**
- All frames use native FigCraft Auto Layout (`mode: "vertical"` or `"horizontal"`) with consistent `20px` horizontal screen padding (`344px` inner content width inside `390px` screens with `3px` outer border) and `4px`-grid spacing (`4, 8, 12, 16, 24, 32, 48`).

### 3.5 Color Usage and Contrast — **PASS**
- **100% Variable Binding**: Automated inspection across all 10 mobile screens confirmed **`0` unbound fills** and **`0` off-palette hex colors**.
- **Contrast Verification**:
  - `color/ink` (`#111111`) on `color/paper` (`#FFFDF5`): **`18.30:1`** (WCAG AAA)
  - `color/ink` (`#111111`) on `color/surface` (`#FFFFFF`): **`18.88:1`** (WCAG AAA)
  - `color/ink` (`#111111`) on `color/accentPrimary` (`#FFE500`): **`16.45:1`** (WCAG AAA)
  - `color/ink` (`#111111`) on `color/accentTeal` (`#16C7C1`): **`8.91:1`** (WCAG AAA)
  - `color/ink` (`#111111`) on `color/accentMagenta` (`#F22DBB`): **`5.25:1`** (WCAG AA — remediated from `#FFFFFF` on `#F22DBB` which was `3.60:1`)
  - `color/mutedText` (`#626262`) on `color/paper` (`#FFFDF5`): **`5.74:1`** (WCAG AA)
  - `color/mutedText` (`#626262`) on `color/surface` (`#FFFFFF`): **`5.92:1`** (WCAG AA)

### 3.6 Component Reuse — **PASS WITH MAJOR FINDING (`J-01`)**
- `56` reusable `COMPONENT` nodes exist across `02 - Components` (`43` components) and Pages `04–09` (`13` components), covering all 18 families in `COMPONENT_SPEC.md`.
- `21` primary component families are wired with FigCraft **Code Connect** (`language: "flutter"`, `package:re_mobile/...`, exported to `exports/figcraft.connect.json`), and `6` live `INSTANCE` nodes (`ids: 1057..1067`) are verified on Page `09 - Design QA` (`id: 1056`).
- **Observation (`J-01`)**: Inside the 10 mobile screen frames (`ids: 434..945`), child UI elements (buttons, chips, inputs, bottom navs) were constructed as Auto Layout `FRAME` hierarchies bound to the shared design variables (`VariableID:1..26`) rather than `INSTANCE` references to the Page `02` master `COMPONENT`s.

### 3.7 Mobile Safe Areas — **PASS**
- Every `390×844` mobile frame reserves an explicit top status bar safe area (`ReStatusBar`, `38–44px` height) and a bottom safe area (`Bottom Safe Area Home Indicator` `24px`, `ReBottomNavigation` `68–74px`, or sticky bottom action/composer bar `68–72px`).

### 3.8 Responsive Constraints & Scrollability — **PASS WITH MAJOR FINDING (`J-02`)**
- Horizontal sizing uses `sizing.horizontal: "fill"` on cards, inputs, banners, and buttons, and `wrap: true` on all `ReChip` containers (`ids: 317, 331, 642, 659, 715, 726, 737`), allowing layouts to adapt from `360px` to `560px` (`ReTokens.contentWidth`) widths.
- **Observation (`J-02`)**: Because FigCraft screen frames are static `390×844` viewports, `Screen 4 — Profile Detail` (`id: 611`) and `Screen 8 — My Academic Profile` (`id: 679`) compress vertical section gaps to `6–10px` to fit all 6–7 sections without scrolling. In Flutter, these screens must use scrollable bodies (`ListView` / `SingleChildScrollView` inside `RePageScaffold` / `ReFormPage`) with standard `16–24px` section spacing and `textScaler` support.

### 3.9 Touch Targets (`>= 44×44px`) — **PASS (REMEDIATED IN FIGCRAFT + MINOR NOTE `M-04`)**
- Automated script inspection initially detected compact interactive controls below `44px` height on `Screen 2` (`id: 509` `36px`), `Screen 4` (`id: 633` `38px`), `Screen 6` (`id: 886..890` `38px`), `Screen 7` (`id: 959` `36×36px`, `id: 977..983` `34px`), and `Screen 8` (`id: 699` `36px`, `id: 722, 733` `31×30px`).
- **Remediated in FigCraft**: All interactive buttons, segmented tabs, and `+` add-tag buttons (`ids: 509, 633, 699, 722, 733, 885..890, 958, 959, 976..983`) have been upgraded to **`>= 44×44px`** directly in the FigCraft document while keeping `0` frame overflows.
- **Minor Note (`M-04`)**: Read-only display chips (`ReChip` on `Screen 3, 4, 8`) have a compact visual height of `22–30px` so chips do not become mini-cards (`DESIGN_SYSTEM.md` §12). Whenever `ReChip` is used interactively (e.g., filter chips or onboarding selection), Flutter must enforce `MaterialTapTargetSize.padded` (`>= 48×48dp` hit area) around the `28–32dp` visual pill.

### 3.10 Text Overflow & Clipping — **PASS**
- Automated bounds check across all 10 mobile screens (`ids: 434, 473, 518, 611, 679, 760, 805, 841, 871, 945`) verified **`0` overflowing child layers** horizontally or vertically, and **`0` truncated/clipped text nodes**.

### 3.11 Loading, Empty, Error, and Disabled States — **PASS**
- **Buttons**: `RePrimaryButton / Default` (`237`), `Pressed` (`239`), `Loading` (`241`), `Disabled` (`243`).
- **Inputs**: `ReTextField / Default` (`273`), `Focused` (`279`), `Password` (`285`), `Error` (`294`), `Disabled ReadOnly` (`300`).
- **Banners**: `ReStatusBanner / Info` (`345`), `Success` (`349`), `Warning` (`354`), `Error` (`358`), and `Network Retry & Draft Safe` (`1053`).
- **Empty States**: `ReEmptyState / Discover Deck Empty` (`1038`) and `ReEmptyState / Chat Inbox Empty` (`1044`) on Page `09 - Design QA` (`id: 1035`).
- **System Chat Event**: `ReMessageBubble / System Event` (`1051`) on Page `09 - Design QA` (`id: 1035`).

### 3.12 Swipe Card Hierarchy & Gesture Alternatives — **PASS**
- `Screen 3 — Discover / Swipe Cards` (`id: 518`) places academic identity (`Nadiya R. [S1]`, `Universitas Indonesia`, `Ilmu Komputer • Semester 5`), skill/course chips, and the yellow-highlighted **`TUJUAN KOLABORASI AKADEMIK`** box (`id: 565`) as the primary visual hierarchy, with a compact `112px` academic identity header (`id: 532`).
- `ReDiscoverActionBar` (`id: 571`) provides explicit `>=44px` tap buttons for every gesture: `Lewati` (`56×52px`), `Simpan` (`56×52px`), `Detail` (`56×52px`), and `+ Ajak Kolaborasi` (`146×52px`).

### 3.13 Chat and Room Navigation Consistency — **PASS (REMEDIATED)**
- `Screen 6 — Chat Inbox` (`id: 871`) separates `CHAT 1-1` (`id: 892`) and `ROOM KOLABORASI` (`id: 913`) with segmented filter tabs (`Semua (4)`, `Chat 1-1 (2)`, `Room (2)`).
- `Screen 7 — Room Chat` (`id: 945`) displays `ReRoomHeader` (`id: 949`), member strip (`id: 958`), `RePinnedPurpose` (`id: 971`), mode tabs (`id: 976`), message list (`id: 985`), and composer (`id: 1006`).
- **Remediated in FigCraft**: Planned room tabs `Tugas`, `File`, and `Catatan` (`ids: 979, 981, 983`) use `color/mutedSurface` (`#F2F0E8`) fill to visually distinguish them from the active `Chat` tab (`#FFE500`, `id: 977`) per `SCREEN_SPEC.md` §7.

---

## 4. Classified Audit Findings (`Critical`, `Major`, `Minor`, `Suggestion`)

| ID | Severity | Category | Location / Node IDs | Finding Description | Required Action in Flutter Implementation |
| :---: | :---: | :--- | :--- | :--- | :--- |
| `J-01` | **Major** | Component Reuse (`INSTANCE` vs `FRAME`) | Pages `03–07` (`ids: 434..945`) vs. Page `02` (`id: 220`) | Master components (`56` `COMPONENT` nodes) are defined on Page `02` and Page `09` (with `6` verified `INSTANCE` nodes in `id: 1056` and `21` Flutter Code Connect links), but the elements inside the 10 screen frames (`ids: 434..945`) are variable-bound Auto Layout `FRAME` trees rather than linked `INSTANCE`s. | Do **not** generate screen-local widget trees from `inspect.code` on full screens. Implement the shared `Re*` widgets in `apps/mobile/lib/core/widgets/` and `lib/features/*/widgets/` once, and compose all screens strictly from those shared Flutter widgets. |
| `J-02` | **Major** | Scrollability & Section Rhythm | `Screen 4` (`id: 611`), `Screen 8` (`id: 679`) | To fit 6–7 profile sections inside a static `390×844` canvas without clipping, vertical section spacing in FigCraft was compressed to `6–10px`. Under `UI_HIERARCHY.md` §9 and `DESIGN_SYSTEM.md` §14, sections require `16–24px` separation and `textScaler` (`200%`) resilience. | Wrap screen bodies in `ListView` / `SingleChildScrollView` inside `RePageScaffold` (extending `ReFormPage`), keep top app bars and bottom CTA/navigation bars pinned, and restore `16–24px` section spacing. |
| `J-03` | **Major** | Design-vs-Backend Schema Differences on Profile | `Screen 4` (`611`), `Screen 8` (`679`), `Screen 9` (`760`) vs. `AcademicProfileController.php` | FigCraft Profile & Onboarding screens show `Jenjang (S1/D4/S2)`, `Minat & Topik`, `Ketersediaan (Sen-Jum/Malam/Weekend)`, `Tujuan Kolaborasi`, and `Portofolio (GitHub)`. However, `PUT /api/v1/me/academic-profile` strictly validates **10 fields only** (`display_name`, `university_id`, `program`, `semester`, `bio`, `mbti_badge`, `visibility`, `courses`, `skills[{skill_id, level}]`, `preferences{study_mode, preferred_language}`) and rejects unknown fields with `422`. | Per `README_DESIGN_HANDOFF.md` (*"the backend/API contract wins"*), bind `Screen 8` and `Screen 9` strictly to the 10 implemented `AcademicProfileInput` fields (`bio` for academic focus/goal, `preferences.study_mode` + `preferred_language` for study preferences, `skills` with `level 1..5`). Omit or clearly mark unsupported profile fields (`Jenjang`, `Minat`, `Ketersediaan` schedule, `Portofolio`) until schema extensions are approved. |
| `M-01` | **Minor** | Typography Token Normalization | `Screen 3, 4, 6, 7, 8` text layers | Individual screen text nodes use `8–13` `(fontSize, fontStyle)` combinations (including `9px`, `10px`, `13px`, `15px`, `21px`, and `Black` `900`) rather than strictly the 10 `Typography/*` text styles (`S:12..S:21`). | Map every text widget in Flutter strictly to the 10 `ReKanTypography` tokens (`displayLarge` through `caption`) defined in `DESIGN_SYSTEM.md` §4 (`max 4` distinct text levels per screen). |
| `M-02` | **Minor** | Auxiliary Auth & Onboarding Screens | Page `03` (`id: 4`), Page `05` (`id: 6`) vs. `auth_boundary.dart` | `Welcome` (`434`), `Login` (`473`), and `Onboarding Step 2/5` (`760`) have full `390×844` frames, whereas `Register`, `Email Verification` (`AuthScreen.verification`), `Password Recovery` (`AuthScreen.recovery`), `Session Error` (`AuthScreen.sessionError`), and `Onboarding Steps 1, 3, 4, 5` are specified via shared components. | Restyle all 7 `AuthScreen` states in `lib/features/auth/auth_boundary.dart` and `auth_form.dart` using `RePageScaffold`, `ReBrandMark`, `ReTextField`, `RePrimaryButton`, `ReSecondaryButton`, and `ReStatusBanner`. |
| `M-03` | **Minor** | `Cari` & `Kolaborasi` Bottom Nav Surfaces | `ReBottomNavigation` (`id: 378, 584, 749, 934`) | `ReBottomNavigation` defines 5 tabs (`Jelajah`, `Cari`, `Kolaborasi`, `Pesan`, `Profil`), while standalone screens exist for `Jelajah` (`518`), `Pesan` (`871`), and `Profil` (`679`). `Cari` and `Kolaborasi` do not have separate `390×844` frames. | In Iteration 4 (Main App Shell), render clearly labeled development placeholder views (`ReEmptyState` + `ReSearchAndFilterBar`) for `Cari` and `Kolaborasi`. |
| `M-04` | **Minor** | Display Chip Height vs. Interactive Chip Hit Area | `ReChip` (`id: 318..340`, `22–32px` visual height) | `ReChip` visual height is `22–32px` so chips remain compact tags (`DESIGN_SYSTEM.md` §12). When used as an interactive filter or onboarding selector, `<44px` height violates touch accessibility unless padded. | In `ReChip`, keep the `28–32dp` visual container (`padding: 6×12`, `border: 2px`), and wrap interactive variants (`onTap != null`) in a `ConstrainedBox(minHeight: 44, minWidth: 44)` / `MaterialTapTargetSize.padded` hit target. |
| `S-01` | **Suggestion** | Skeleton / Shimmer Loading Card | `ReSwipeDeck` (`id: 528`) | Initial deck fetch loading state is described in specs (`INTERACTION_MODEL.md` §7) but does not have a dedicated skeleton card variant on Page `09`. | Implement a neo-brutalist `ReProfileCardSkeleton` (`#F2F0E8` muted blocks inside a `3px` `#111111` card outline) for initial deck/profile loading. |
| `S-02` | **Suggestion** | Destructive Action Confirmation Modal | Page `02` (`id: 251` `ReDestructiveButton`) | `ReDestructiveButton` (`id: 251`) is defined, and `INTERACTION_MODEL.md` §11 requires confirmation modals for leaving/deleting a room or discarding unsaved onboarding changes. | Create a reusable `ReConfirmDialog` (`#FFFFFF` surface, `3px` `#111111` border, `6×6px` hard shadow, `ReSecondaryButton` `"Batal"` + `ReDestructiveButton` `"Buang / Keluar"`). |
| `S-03` | **Suggestion** | Font Strategy (`Montserrat` vs. Native System Font) | `Montserrat` (`file.fontReport`) vs. `phase-2e2-plan.md` | FigCraft uses `Montserrat` (`400–800`), whereas `phase-2e2-plan.md` line 66 notes *"No external font/network dependency"*. | Either bundle offline `Montserrat` `.ttf` weights under `apps/mobile/assets/fonts/` in `pubspec.yaml` (zero network dependency) OR fall back cleanly to the platform sans-serif font with matching `FontWeight.w700`/`w800` metrics. |

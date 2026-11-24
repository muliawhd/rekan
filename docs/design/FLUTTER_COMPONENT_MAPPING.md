# Re:kan — FigCraft-to-Flutter Component & Token Mapping (`FLUTTER_COMPONENT_MAPPING.md`)

## 1. Existing Flutter Codebase Inventory (`D:/Mulia/hackgdgocitb/rekan/apps/mobile`)

Inspection of `D:/Mulia/hackgdgocitb/rekan/apps/mobile` (`package:re_mobile`) confirms the following existing files and architecture:

| Existing File in `apps/mobile/lib/` | Current Responsibility | Action Required for Re:kan Neo-Brutalist Handoff |
| :--- | :--- | :--- |
| `lib/app.dart` (`ReApp`) | Selects `AuthValidationPage` when `kDebugMode && AUTH_E2E_ENABLED && configured`; otherwise renders `AuthBoundary` with `AppTheme.onboarding`. Currently sets `title: 'Re'`. | Preserve debug gate (`AUTH_E2E_ENABLED`). Update `title: 'Re:kan'` and wire updated Neo-Brutalist `AppTheme.rekan` / `AppTheme.onboarding`. |
| `lib/core/theme/re_tokens.dart` (`ReTokens`) | Phase 2E.2 Iteration A forest-green tokens (`forest: #245C45`, `ink: #182B24`, `paper: #F7F8F4`, `surface: #FFFFFF`, `outline: #718078`, `error: #B42318`, `minTouchTarget: 48.0`, `contentWidth: 520.0`). | Consolidate into a single canonical `ReTokens` class combining exported FigCraft tokens (`#111111` `ink`, `#FFFDF5` `paper`, `#FFE500` `accentPrimary`, `#16C7C1` `accentTeal`, `#F22DBB` `accentMagenta`, `#1FA86A` `success`, `#E5484D` `danger`, `#F2A900` `warning`, `2px/3px` borders, `0px`-blur hard shadows) while retaining `error: #B42318` (WCAG AA `7.09:1` text contrast), `contentWidth: 520.0`, and `forest` compatibility aliases so `test/design_foundation_test.dart` passes without duplicate token classes. |
| `lib/core/theme/app_theme.dart` (`AppTheme`) | Defines `AppTheme.onboarding` (Material 3 forest green) and `AppTheme.light` (for debug validation). | Keep `AppTheme.light` untouched for debug `AuthValidationPage`. Update `AppTheme.onboarding` (and/or `AppTheme.rekan`) to apply Neo-Brutalist `2px`/`3px` `#111111` borders, `#FFFDF5` paper background, `#FFE500` primary fills, and `ReKanTypography`. |
| `lib/core/widgets/re_form_components.dart` | Defines `ReFormPage`, `ReFormHeading`, `RePrimaryAction`, and `ReStatusNotice` (tested in `test/design_foundation_test.dart`). | **Refactor in-place & extend**: Upgrade `ReFormPage`, `ReFormHeading`, `RePrimaryAction`, and `ReStatusNotice` to Neo-Brutalist styling while preserving their exact constructor signatures and semantics so all 33+ existing foundation/auth tests continue to pass! |
| `lib/features/auth/auth_gateway.dart` & `auth_controller.dart` | Supabase Cloud Auth wrapper, session restoration, revision counter, and `AuthScreen` state machine. | **Reuse 100% unchanged** (`IMPLEMENTATION_CONSTRAINTS.md`). |
| `lib/features/auth/auth_boundary.dart` & `auth_form.dart` | Implements `WelcomePage`, `AuthForm` (`login`/`register`), `checking`, `verification`, `recovery`, `sessionError`, and `authenticated` placeholder. Currently displays `'Re'` instead of `'Re:kan'`. | **Presentation refactor in Iteration 2**: Replace `'Re'` with `ReBrandMark` (`'Re:kan'`), apply Neo-Brutalist cards, `ReTextField`, `RePrimaryButton`, `ReSecondaryButton`, and `ReStatusBanner` while preserving `PopScope`, `AutofillGroup`, and `AuthController` bindings. |
| `lib/features/academic_profile/data/academic_profile.dart` & `academic_profile_repository.dart` | Typed DTOs (`AcademicProfile`, `AcademicProfileInput`, `SkillSelection`, `AcademicPreferences`, `ProfileVisibility`, `StudyMode`) and `GET/PUT /api/v1/me/academic-profile` repository. | **Reuse 100% unchanged**. |
| `lib/features/academic_profile/presentation/profile_controller.dart` | `ChangeNotifier` managing `ProfileStatus { idle, loading, empty, success, error }` and versioned async calls. | **Reuse 100% unchanged** for reading/saving; add a separate in-memory onboarding/edit draft controller (`phase-2e2-plan.md` line 18) so form edits are never bound directly to transient read state. |
| `lib/features/auth_validation/*` & `development_profile_validation.dart` | Debug-only validation harnesses (`AUTH_E2E_ENABLED`). | **Preserve untouched** (`IMPLEMENTATION_CONSTRAINTS.md`). |

---

## 2. Design Token Mapping (`exports/rekan_design_tokens.dart` → `lib/core/theme/re_tokens.dart`)

### 2.1 Color Tokens

| FigCraft Variable | Hex Value | Exported Dart Constant (`ReKanColors`) | Mapping to `ReTokens` (`lib/core/theme/re_tokens.dart`) | Semantic Usage in Flutter |
| :--- | :---: | :--- | :--- | :--- |
| `color/ink` (`VariableID:1`) | `#111111` | `ReKanColors.colorInk` | `ReTokens.ink = Color(0xFF111111)` | Primary text, all `2px`/`3px` borders, hard offset shadows, primary icons |
| `color/paper` (`VariableID:2`) | `#FFFDF5` | `ReKanColors.colorPaper` | `ReTokens.paper = Color(0xFFFFFDF5)` | Main `Scaffold` background (`RePageScaffold` / `ReFormPage`) |
| `color/surface` (`VariableID:3`) | `#FFFFFF` | `ReKanColors.colorSurface` | `ReTokens.surface = Color(0xFFFFFFFF)` | Cards, input backgrounds, secondary buttons, `Other` chat bubbles |
| `color/mutedSurface` (`VariableID:4`) | `#F2F0E8` | `ReKanColors.colorMutedSurface` | `ReTokens.mutedSurface = Color(0xFFF2F0E8)` | Disabled controls, neutral chips, avatar placeholders, planned tabs |
| `color/mutedText` (`VariableID:5`) | `#626262` | `ReKanColors.colorMutedText` | `ReTokens.muted = Color(0xFF626262)` | Secondary copy, placeholders, timestamps, helper text (`5.74:1` contrast) |
| `color/accentPrimary` (`VariableID:6`) | `#FFE500` | `ReKanColors.colorAccentPrimary` | `ReTokens.accentPrimary = Color(0xFFFFE500)` | Primary CTA, active bottom-nav block, collaboration goal box, `Self` bubble |
| `color/accentTeal` (`VariableID:7`) | `#16C7C1` | `ReKanColors.colorAccentTeal` | `ReTokens.accentTeal = Color(0xFF16C7C1)` | Degree/role badges, availability chips, info banners, room badges |
| `color/accentMagenta` (`VariableID:8`) | `#F22DBB` | `ReKanColors.colorAccentMagenta` | `ReTokens.accentMagenta = Color(0xFFF22DBB)` | Unread count badges (`ReUnreadBadge`, always paired with `#111111` text) |
| `color/success` (`VariableID:9`) | `#1FA86A` | `ReKanColors.colorSuccess` | `ReTokens.success = Color(0xFF1FA86A)` | Verified status, online availability dot, success status banner |
| `color/danger` (`VariableID:10`) | `#E5484D` | `ReKanColors.colorDanger` | `ReTokens.danger = Color(0xFFE5484D)` (`ReTokens.error = Color(0xFFB42318)` kept for AA text contrast `>= 4.5:1`) | Destructive button/banner fill & error border (`#E5484D` with `#111111` text/border); `ReTokens.error` (`#B42318`) used for standalone error text on paper/surface |
| `color/warning` (`VariableID:11`) | `#F2A900` | `ReKanColors.colorWarning` | `ReTokens.warning = Color(0xFFF2A900)` | Warning banners, pending/offline retry alerts |

### 2.2 Spacing, Radius, Border, Shadow & Touch Tokens

| FigCraft Token | Value | `ReTokens` Constant (`lib/core/theme/re_tokens.dart`) | Usage |
| :--- | :---: | :--- | :--- |
| `space/4` (`VariableID:12`) | `4.0` | `ReTokens.spaceXs = 4.0` | Micro icon/text gap |
| `space/8` (`VariableID:13`) | `8.0` | `ReTokens.spaceSm = 8.0` | Tightly related items, chip wrap gap |
| `space/12` (`VariableID:14`) | `12.0` | `ReTokens.spaceCompact = 12.0` | Compact component padding |
| `space/16` (`VariableID:15`) | `16.0` | `ReTokens.spaceMd = 16.0` | Normal component padding |
| `space/24` (`VariableID:16`) | `24.0` | `ReTokens.spaceLg = 24.0` | Section separation & form page gutter |
| `space/32` (`VariableID:17`) | `32.0` | `ReTokens.spaceXl = 32.0` | Major content separation |
| `space/48` (`VariableID:18`) | `48.0` | `ReTokens.spaceHero = 48.0` | Hero/landing separation |
| `radius/none` (`VariableID:19`) | `0.0` | `ReTokens.radiusNone = 0.0` | App bars, bottom navigation bar |
| `radius/small` (`VariableID:20`) | `6.0` | `ReTokens.radiusSmall = 6.0` | `ReChip`, compact badges, swipe stamps |
| `radius/medium` (`VariableID:21`) | `10.0` | `ReTokens.radiusMedium = 10.0` (`cornerRadius`) | Buttons, text fields, conversation tiles |
| `radius/large` (`VariableID:22`) | `16.0` | `ReTokens.radiusLarge = 16.0` | `ReProfileCard`, hero cards, modals |
| `radius/full` (`VariableID:23`) | `999.0` | `ReTokens.radiusFull = 999.0` | Circular avatars, status dots |
| `border/standard` (`VariableID:24`) | `2.0` | `ReTokens.borderStandard = 2.0` | Standard neo-brutalist border (`#111111`) |
| `border/emphasized` (`VariableID:25`) | `3.0` | `ReTokens.borderEmphasized = 3.0` | Hero cards, focused inputs, app/bottom bars |
| `touch/minTarget` (`VariableID:26`) | `44.0` | `ReTokens.minTapTarget = 44.0` (`controlHeight = 48.0`) | Accessible minimum tap target (`44×44dp`) |
| `Shadow/shadowSubtle` (`S:22`) | `3×3px #111111` | `ReTokens.shadowSubtle` | Secondary buttons, compact chips/cards |
| `Shadow/shadowHard` (`S:23`) | `4×4px #111111` | `ReTokens.shadowHard` | Primary buttons, standard cards, unread tiles |
| `Shadow/shadowHero` (`S:24`) | `6×6px #111111` | `ReTokens.shadowHero` | Active swipe card, hero welcome card, modals |
| `Shadow/shadowAccentYellow` (`S:25`) | `4×4px #FFE500` | `ReTokens.shadowAccentYellow` | Dark `ReBrandMark` container emphasis |

---

## 3. Complete Component-to-Widget Mapping Matrix

All 21 component groups below are connected in FigCraft via `codeConnect.set` (`exports/figcraft.connect.json`) using package name `package:re_mobile/...`.

| # | `COMPONENT_SPEC.md` Family | FigCraft Node IDs | Existing Widget in `apps/mobile` | Target Flutter Widget & Path | Classification | Required Props, States & Accessibility Rules |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `RePageScaffold` | Screens `434..945` | `ReFormPage` (`lib/core/widgets/re_form_components.dart`) | `RePageScaffold` (`lib/core/widgets/re_page_scaffold.dart`) + keep `ReFormPage` delegating to it | **Refactor & Extend Existing Widget** (Iteration 1) | Wraps `Scaffold` (`backgroundColor: ReTokens.paper`), `SafeArea`, `ConstrainedBox(maxWidth: 560)`, configurable `padding` (`20–24dp`), optional `appBar`, `bottomNavigationBar`, `stickyBottomBar`, and `scrollable` (`ListView` vs. fixed column). |
| 2 | `ReBrandMark` | `id: 224`, `1057` (`INSTANCE`) | Plain `Text('Re')` in `auth_boundary.dart:182` | `ReBrandMark` (`lib/core/widgets/re_brand_mark.dart`) | **New Shared Widget** (Iteration 1) | Renders **`Re:kan`** (never `'Re'`). Variants: dark `#111111` box with `#FFE500` text + `4×4px` `#FFE500` offset shadow, or `#FFE500` box with `#111111` text + `4×4px` `#111111` offset shadow. |
| 3 | `RePrimaryButton` | `id: 237` (`Default`), `239` (`Pressed`), `241` (`Loading`), `243` (`Disabled`), `1059` (`INSTANCE`) | `RePrimaryAction` (`lib/core/widgets/re_form_components.dart`) | `RePrimaryButton` / `RePrimaryAction` (`lib/core/widgets/re_form_components.dart`) | **Refactor & Extend Existing Widget** (Iteration 1) | Keep `RePrimaryAction({label, onPressed, busy, busyLabel})` signature intact and alias/expose `RePrimaryButton`. Style: `#FFE500` fill, `#111111` text (`w800`), `2px` `#111111` border, `4×4px` hard shadow (`0` shadow when `busy` or disabled), `minHeight: 48dp`, `Semantics(liveRegion: busy)`. |
| 4 | `ReSecondaryButton`, `ReDestructiveButton`, `ReTertiaryButton` | `id: 247, 249, 251, 253, 1061` | `TextButton` in `auth_boundary.dart` & `auth_form.dart` | `ReSecondaryButton` (`lib/core/widgets/re_secondary_button.dart`) | **New Shared Widget** (Iteration 1) | Variants: `secondary` (`#FFFFFF` fill, `2px` `#111111` border, `3×3px` hard shadow), `destructive` (`#E5484D` fill/border), `tertiary` (underlined bold link). `minHeight: 48dp`. |
| 5 | `ReTextField` | `id: 273, 279, 285, 294, 300` | `TextFormField` + `InputDecorationTheme` in `auth_form.dart` & `app_theme.dart` | `ReTextField` (`lib/core/widgets/re_text_field.dart`) + `AppTheme` `InputDecorationTheme` | **New Shared Widget + Theme Upgrade** (Iteration 1) | Persistent visible label above field (or Neo-Brutalist `InputDecoration` with `2px` `#111111` enabled border, `3px` `#111111` focused border, `3px` `#E5484D` error border, `#FFFFFF` fill, `#F2F0E8` disabled fill, and `>=48×48dp` password visibility `IconButton`). |
| 6 | `ReSearchAndFilterBar` | `id: 305`, `id: 883` (`Screen 6`) | *None* | `ReSearchAndFilterBar` (`lib/core/widgets/re_search_and_filter_bar.dart`) | **New Shared Widget** (Iteration 4/8) | Search input (`2px` `#111111` border, `#FFFFFF` fill) + optional filter button (`>=44×44dp`) with active filter count badge. |
| 7 | `ReChip` | `id: 318..340`, `1063, 1065` (`INSTANCE`) | *None* | `ReChip` (`lib/core/widgets/re_chip.dart`) | **New Shared Widget** (Iteration 1) | Variants: `neutral` (`#F2F0E8`), `selected` (`#FFE500` + `2×2px` shadow), `skill` (`#FFFFFF`, optional `level 1..5` badge), `course` (`#FFFDF5` + `MK:` prefix), `availability` (`#16C7C1` or `#1FA86A` dot), `status` (`#16C7C1`). Interactive chips wrap in `minHeight: 44dp` tap target. |
| 8 | `ReProfileCard` | `id: 531` (`Screen 3`) | *None* | `ReProfileCard` (`lib/features/discover/widgets/re_profile_card.dart`) | **New Feature Widget** (Iteration 5) | Strictly ordered per `UI_HIERARCHY.md` §2: (1) `112dp` identity header, (2) `display_name`, `university`, `program • semester`, (3) limited `skills` & `courses` chips, (4) yellow `#FFE500` `TUJUAN KOLABORASI AKADEMIK` box. |
| 9 | `ReSwipeDeck` & `ReSwipeStamp` | `id: 528` (`Deck`), `id: 370, 372` (`Stamps`) | *None* | `ReSwipeDeck` & `ReSwipeStamp` (`lib/features/discover/widgets/re_swipe_deck.dart`) | **New Feature Widget** (Iteration 5) | Stacked cards (`3px` `#111111` border, `6×6px` hard shadow), horizontal pan gesture, proportional rotation (`max ±6°`), snap-back below threshold, `LEWATI` / `AJAK KOLABORASI` stamp overlay, in-flight lock, and index preservation across `Profile Detail` navigation. |
| 10 | `ReDiscoverActionBar` | `id: 257..266`, `id: 571` (`Screen 3`) | *None* | `ReDiscoverActionBar` (`lib/features/discover/widgets/re_discover_action_bar.dart`) | **New Feature Widget** (Iteration 5) | 4 explicit `>=48dp` buttons (`Lewati`, `Simpan`, `Detail`, `+ Ajak Kolaborasi`) with semantic labels providing full tap parity for swipe gestures. |
| 11 | `ReSectionHeader` | `id: 410` (Page 02) | `ReFormHeading` (`lib/core/widgets/re_form_components.dart`) | `ReSectionHeader` (`lib/core/widgets/re_section_header.dart`) + `ReFormHeading` | **New Shared Widget** (Iteration 1) | Left vertical accent bar (`#FFE500` or `#16C7C1`, `2px` border) + uppercase `ExtraBold` section title + optional trailing action (`>=44dp`). |
| 12 | `ReInfoRow` | `id: 668` (`Screen 4`), `id: 702, 745` (`Screen 8`) | *None* | `ReInfoRow` (`lib/features/academic_profile/presentation/re_info_row.dart`) | **New Feature Widget** (Iteration 6) | Structured key-value row (`icon/badge`, `label`, `value`, optional trailing `UBAH >` / `BUKA >` action `>=44dp`). |
| 13 | `ReConversationTile` | `id: 894` (`1-to-1`), `id: 915` (`Room`) | *None* | `ReConversationTile` (`lib/features/chat/widgets/re_conversation_tile.dart`) | **New Feature Widget** (Iteration 8) | Avatar initials box (`46×46dp`), title, `[ROOM • N ANGGOTA]` teal badge or campus subtitle, preview text, timestamp, and `ReUnreadBadge`. Unread tiles use `3px` border + `4×4px` shadow. |
| 14 | `ReRoomHeader` & `ReTopAppBar` | `id: 393` (Page 02), `id: 949` (`Screen 7`) | `AppBar` in `auth_boundary.dart` & `auth_form.dart` | `ReTopAppBar` (`lib/core/widgets/re_top_app_bar.dart`) & `ReRoomHeader` (`lib/features/rooms/widgets/re_room_header.dart`) | **New Shared / Feature Widgets** (Iteration 4/9) | `PreferredSizeWidget` with `3px` `#111111` bottom border, `44×44dp` back button, bold title/subtitle status pill, and `44×44dp` trailing action buttons. |
| 15 | `RePinnedPurpose` | `id: 971` (`Screen 7`) | *None* | `RePinnedPurpose` (`lib/features/rooms/widgets/re_pinned_purpose.dart`) | **New Feature Widget** (Iteration 9) | `#FFFDF5` card (`2px` `#111111` border) with `#FFE500` `[PIN] TUJUAN ROOM` badge and room goal summary. |
| 16 | `ReMessageBubble` | `id: 990, 1000, 1004, 1051` | *None* | `ReMessageBubble` (`lib/features/rooms/widgets/re_message_bubble.dart`) | **New Feature Widget** (Iteration 9) | 4 variants (`self` `#FFE500` right-aligned, `other` `#FFFFFF` left-aligned with avatar, `attachment` with `#F2F0E8` file card, `system` centered `#F2F0E8` pill). |
| 17 | `ReEmptyState` | `id: 1038, 1044` (Page 09) | *None* | `ReEmptyState` (`lib/core/widgets/re_empty_state.dart`) | **New Shared Widget** (Iteration 1) | Category badge, bold title, concise 1-sentence reason, and `>=48dp` primary/secondary action button. |
| 18 | `ReStatusBanner` | `id: 345, 349, 354, 358, 1053` | `ReStatusNotice` (`lib/core/widgets/re_form_components.dart`) | `ReStatusBanner` / `ReStatusNotice` (`lib/core/widgets/re_form_components.dart`) | **Refactor & Extend Existing Widget** (Iteration 1) | Keep `ReStatusNotice({message, isError})` working and extend with `ReStatusBannerVariant { info, success, warning, error }`, `2px` `#111111` border, explicit `[INFO]/[BERHASIL]/[PERINGATAN]/[GALAT]` badge + icon (never color alone), and optional `onRetry` CTA (`>=44dp`). |
| 19 | `ReBottomNavigation` | `id: 378, 584, 749, 934` | *None* | `ReBottomNavigation` (`lib/core/widgets/re_bottom_navigation.dart`) | **New Shared Widget** (Iteration 4) | 5 destinations (`Jelajah`, `Cari`, `Kolaborasi`, `Pesan`, `Profil`), `3px` top border, `#FFE500` active accent block with `2px` `#111111` border & `2×2px` shadow, `>=44dp` tap height per item, and `ReUnreadBadge` on `Pesan`. |
| 20 | `ReSegmentedTabs` | `id: 401, 885, 976` | *None* | `ReSegmentedTabs` (`lib/core/widgets/re_segmented_tabs.dart`) | **New Shared Widget** (Iteration 8/9) | `50dp` outer frame (`#F2F0E8`, `2px` border) with `44dp` inner tab buttons (`#FFE500` active, `#FFFFFF` enabled inactive, `#F2F0E8` disabled/planned). |
| 21 | `ReUnreadBadge` | `id: 364, 366, 368, 1067` | *None* | `ReUnreadBadge` (`lib/core/widgets/re_unread_badge.dart`) | **New Shared Widget** (Iteration 4/8) | `#F22DBB` (`accentMagenta`) fill, `2px` `#111111` border, `#111111` (`ink`) text (`5.25:1` contrast). |

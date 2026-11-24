# Re:kan — Iteration 1 Status: Canonical Design Tokens & Shared Neo-Brutalist Components (`ITERATION_1_STATUS.md`)

**Date:** 2026-11-16
**Scope:** Iteration 1 — Canonical Design Tokens & Shared Neo-Brutalist Components (`apps/mobile/lib/core/`)
**Status:** Complete (Stop before Iteration 2 Authentication UI Redesign pending owner approval)

---

## 1. Implemented Canonical Design Tokens (`lib/core/theme/re_tokens.dart` & `app_theme.dart`)

`ReTokens` (`apps/mobile/lib/core/theme/re_tokens.dart`) has been refactored into the **single canonical token source** for `package:re_mobile`, integrating the exported FigCraft variable collections (`Re:kan Colors` and `Re:kan Spacing & Layout`) without introducing a competing token class:

### 1.1 Color Tokens
| Token Constant | Hex Value | Role & Contrast |
| :--- | :---: | :--- |
| `ReTokens.ink` | `#111111` | Primary text, `2px`/`3px` borders, icons, and hard-offset shadows (`19.3:1` on `paper`). |
| `ReTokens.paper` | `#FFFDF5` | Main warm paper scaffold background. |
| `ReTokens.surface` | `#FFFFFF` | Cards, inputs, secondary buttons, and elevated containers. |
| `ReTokens.mutedSurface` | `#F2F0E8` | Disabled controls, neutral chips, and secondary sections. |
| `ReTokens.mutedText` / `ReTokens.muted` | `#626262` | Secondary text, metadata, captions, and helper copy (`5.97:1` on `paper`, `6.07:1` on `surface`). |
| `ReTokens.primaryYellow` / `ReTokens.accentPrimary` | `#FFE500` | Primary CTA fill, active blocks, and brand emphasis (always paired with `#111111` ink text, `17.0:1` contrast). |
| `ReTokens.accentTeal` | `#16C7C1` | Academic tags, status chips, and info banner accents (paired with `#111111` ink text/borders). |
| `ReTokens.accentMagenta` | `#F22DBB` | Notification and unread badges (paired with `#111111` ink text/borders). |
| `ReTokens.success` | `#1FA86A` | Semantic success banner and availability indicator dot. |
| `ReTokens.warning` | `#F2A900` | Semantic warning banner accent. |
| `ReTokens.danger` | `#E5484D` | Neo-Brutalist destructive button fill and error border (paired with `#111111` ink text/borders). |
| `ReTokens.error` | `#B3261E` | Standalone accessible error text color (`5.84:1` on `paper`, `5.94:1` on `surface` — kept separate from `danger` fills to satisfy WCAG AA normal-text contrast). |
| `ReTokens.outline` | `#111111` | Alias to `ReTokens.ink` for Neo-Brutalist container/input outlines. |
| `ReTokens.forest` | `#245C45` | Preserved Iteration A compatibility token for unmigrated `auth_boundary.dart` references until Iteration 2. |

### 1.2 Spacing, Borders, Radii, Hard Shadows & Layout Tokens
- **Spacing Scale (`4 px` base):** `space4` (`4`), `space8` (`8`), `space12` (`12`), `space16` (`16`), `space24` (`24`), `space32` (`32`), `space48` (`48`) + aliases `spaceXs`, `spaceSm`, `spaceCompact`, `spaceMd`, `spaceLg`, `spaceXl`, `spaceHero`.
- **Borders:** `borderStandard = 2.0`, `borderEmphasized = 3.0`, `standardBorderSide`, `emphasizedBorderSide`, `standardBorder`, `emphasizedBorder`.
- **Corner Radii:** `radiusNone = 0.0`, `radiusSmall = 6.0`, `radiusMedium = 10.0` (`cornerRadius`), `radiusLarge = 16.0`, `radiusFull = 999.0`.
- **Hard-Offset Shadows (`0 px` blur):** `shadowPressed` (`2×2 dp`), `shadowSubtle` (`3×3 dp`), `shadowHard` (`4×4 dp`), `shadowHero` (`6×6 dp`), `shadowAccentYellow` (`4×4 dp` `#FFE500`).
- **Touch Targets & Layout:** `minTouchTarget = 44.0`, `controlHeight = 48.0`, `contentWidth = 560.0`, `transition = Duration(milliseconds: 180)`.

### 1.3 Typography (`AppTheme.textTheme` & `AppTheme.onboarding`)
- Implemented the full `DESIGN_SYSTEM.md` §4 hierarchy (`displayLarge` `36/w800`, `displayMedium` `32/w800`, `headlineLarge` `26/w800`, `headlineMedium` `24/w800`, `headlineSmall` `20/w700`, `titleLarge` `20/w700`, `titleMedium` `17/w700`, `titleSmall` `15/w700`, `bodyLarge` `16/w400`, `bodyMedium` `14/w400`, `bodySmall` `12/w500`, `labelLarge` `15/w700`, `labelMedium` `12/w700`, `labelSmall` `11/w600`) using system fonts without adding external font packages.
- Preserved `AppTheme.light` untouched for the debug `AuthValidationPage`.

---

## 2. Implemented & Refactored Shared Components (`lib/core/widgets/`)

| Component | File Path | Status | Behavior & Accessibility |
| :--- | :--- | :--- | :--- |
| **`RePageScaffold`** | `lib/core/widgets/re_page_scaffold.dart` | **Implemented (New)** | Paper background (`#FFFDF5`), `SafeArea`, `560 dp` max-width constraint, configurable gutters (`24 dp` default), optional `appBar`, sticky `bottomBar`, `bottomNavigationBar`, and scrollable (`ListView` / `SingleChildScrollView`) or fixed layout. |
| **`ReFormPage`** | `lib/core/widgets/re_form_components.dart` | **Refactored (Reused)** | Preserves exact constructor signature and delegates directly to `RePageScaffold` with zero code duplication. |
| **`ReBrandMark`** | `lib/core/widgets/re_brand_mark.dart` | **Implemented (New)** | Always renders **`Re:kan`** (never `'Re'`). Supports `badge` (`#FFE500` fill + `4×4` `#111111` shadow), `inverted` (`#111111` fill + `4×4` `#FFE500` shadow), and `wordmark` variants, sizes `sm/md/lg`, optional `subtitle`, and semantic labels. |
| **`RePrimaryButton`** / **`RePrimaryAction`** | `lib/core/widgets/re_form_components.dart` | **Refactored & unified (`typedef RePrimaryAction = RePrimaryButton`)** | `#FFE500` fill, `#111111` text & `2px`/`3px` border, `4×4` hard shadow in default state, `2×2` pressed translation, `0` shadow when disabled/busy, `>= 48 dp` height, wraps `FilledButton` + `Semantics(liveRegion: busy)`. |
| **`ReSecondaryButton`** | `lib/core/widgets/re_secondary_button.dart` | **Implemented (New)** | Supports `surface` (`#FFFFFF`), `destructive` (`#E5484D`), and `subtle` (`#FFFDF5`) variants, default/pressed/focused/busy/disabled states, `3×3` hard shadow, and `>= 48 dp` height. |
| **`ReTextField`** | `lib/core/widgets/re_text_field.dart` | **Implemented (New)** | Persistent visible label above input, `2px` `#111111` enabled border, `3px` `#111111` focused border with `3×3` shadow, `2px`/`3px` `#E5484D` error border with `#B3261E` error text, `#F2F0E8` disabled/read-only fill, and accessible `>= 48×48 dp` password visibility toggle. |
| **`ReChip`** | `lib/core/widgets/re_chip.dart` | **Implemented (New)** | Supports `neutral`, `selected` (`#FFE500` + check icon + `2×2` shadow), `skill` (`Lv.1..5` badge), `course` (`MK` prefix badge), `availability` (`#1FA86A` dot), and `status` (`#16C7C1`) variants; enforces `>= 44×44 dp` tap target when interactive. |
| **`ReSectionHeader`** | `lib/core/widgets/re_section_header.dart` | **Implemented (New)** | Left vertical accent bar (`2px` `#111111` border), header semantics, optional `badgeText` pill, subtitle, and `>= 44×44 dp` trailing action button. |
| **`ReFormHeading`** | `lib/core/widgets/re_form_components.dart` | **Refactored (Reused)** | Preserves existing constructor (`title`, `description`) and adds optional Neo-Brutalist `eyebrow` pill badge. |
| **`ReStatusBanner`** / **`ReStatusNotice`** | `lib/core/widgets/re_form_components.dart` | **Implemented & unified (`ReStatusNotice` delegates to `ReStatusBanner`)** | Supports `info`, `success`, `warning`, and `error` variants; combines semantic icon + explicit status badge (`INFO`, `BERHASIL`, `PERINGATAN`, `GALAT`) + message + optional `>= 44 dp` action button inside `Semantics(liveRegion: true)`. |
| **`ReEmptyState`** | `lib/core/widgets/re_empty_state.dart` | **Implemented (New)** | Bordered icon box, optional category badge, header title, single-sentence description, and optional `RePrimaryButton` or `ReSecondaryButton` CTA (`>= 48 dp`). |

---

## 3. Changed & Created Files

### Created in `apps/mobile/lib/core/widgets/`:
- `apps/mobile/lib/core/widgets/re_page_scaffold.dart`
- `apps/mobile/lib/core/widgets/re_brand_mark.dart`
- `apps/mobile/lib/core/widgets/re_secondary_button.dart`
- `apps/mobile/lib/core/widgets/re_text_field.dart`
- `apps/mobile/lib/core/widgets/re_chip.dart`
- `apps/mobile/lib/core/widgets/re_section_header.dart`
- `apps/mobile/lib/core/widgets/re_empty_state.dart`

### Updated in `apps/mobile/`:
- `apps/mobile/lib/core/theme/re_tokens.dart`
- `apps/mobile/lib/core/theme/app_theme.dart`
- `apps/mobile/lib/core/widgets/re_form_components.dart`
- `apps/mobile/test/design_foundation_test.dart`

### Updated Documentation:
- `docs/design/ITERATION_1_STATUS.md` (New)
- `implementation-plan.md`
- `task-checklist.md`

---

## 4. Validation & Tests Executed

- **`dart format`**: Formatted all new and modified Dart files (`0` changes needed on re-check).
- **`flutter analyze`**: `No issues found!`
- **`flutter test`**: **`51` passed, `0` failed** (`45` prior tests preserved untouched + `6` new Iteration 1 test groups covering canonical FigCraft tokens & contrast, `ReBrandMark`, `ReSecondaryButton` states, `ReTextField` validation & password visibility, `ReChip`/`ReSectionHeader`/`ReStatusBanner`/`ReEmptyState` semantics & touch targets, and `2.0x` large-text scaling on `320×640` screens).
- **`git diff --check`**: `Exit code 0` (clean).

---

## 5. Compatibility Issues & Remaining Risks

- **Zero Existing Tests Modified:** All 45 pre-existing tests pass without modification because `ReTokens.error` (`#B3261E`), `ReTokens.forest` (`#245C45`), `ReTokens.contentWidth` (`560.0`), `ReTokens.controlHeight` (`48.0`), `RePrimaryAction` (`FilledButton`), and `'Re'` strings in `auth_boundary.dart` were preserved for compatibility.
- **Next Actionable Step (Iteration 2):** Upon owner approval, refactor `lib/app.dart`, `lib/features/auth/auth_boundary.dart`, and `lib/features/auth/auth_form.dart` to use `ReBrandMark` (`'Re:kan'`), `ReTextField`, `RePrimaryButton`, `ReSecondaryButton`, and `ReStatusBanner`, and update `test/widget_test.dart` from `find.text('Re')` to `find.text('Re:kan')`.

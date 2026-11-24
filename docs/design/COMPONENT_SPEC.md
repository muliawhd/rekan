# Re:kan — COMPONENT_SPEC.md

## 1. `RePageScaffold`

Responsibilities:
- paper background
- safe area
- consistent horizontal gutters
- optional app bar
- bottom navigation slot
- scrolling behavior

## 2. `ReBrandMark`

Content:
- `Re:kan`

Style:
- bold black wordmark
- thick outline container optional
- yellow offset emphasis optional

Never render only `Re`.

## 3. `RePrimaryButton`

States:
- default
- pressed
- loading
- disabled

Rules:
- yellow fill
- dark border
- dark text
- explicit label

## 4. `ReSecondaryButton`

- surface fill
- dark border
- dark label

## 5. `ReTextField`

Supports:
- label
- placeholder
- helper
- error
- prefix icon
- suffix action
- password visibility
- disabled/read-only states

## 6. `ReChip`

Variants:
- neutral
- selected
- skill
- course
- availability
- status

Avoid using accent colors arbitrarily.

## 7. `ReProfileCard`

Core data:
- profile image
- name
- institution
- program
- semester
- skill/course tags
- collaboration goal
- optional status

Actions are separate from information hierarchy.

## 8. `ReSwipeDeck`

Responsibilities:
- stacked-card presentation
- drag handling
- threshold detection
- safe action lock
- snap-back
- callback for skip/invite
- current-index persistence while screen remains alive

## 9. `ReDiscoverActionBar`

Actions:
- Lewati
- Simpan
- Detail
- Ajak Kolaborasi

Each action:
- visible icon
- visible label when space permits
- >=44px target
- semantic label

## 10. `ReSectionHeader`

Used for:
- Tentang
- Keahlian
- Mata Kuliah Aktif
- Preferensi Belajar
- Portofolio

## 11. `ReInfoRow`

For structured profile data:
- icon
- label
- value
- optional chevron/action

## 12. `ReConversationTile`

Data:
- avatar
- title
- preview
- timestamp
- unread count
- room/person indicator

## 13. `ReRoomHeader`

Data:
- room name
- member count
- room category
- active status
- actions menu

## 14. `RePinnedPurpose`

Displays:
- room goal
- important context
- pinned summary

## 15. `ReMessageBubble`

Variants:
- self
- other
- attachment
- system

## 16. `ReEmptyState`

Content:
- concise title
- one sentence
- action

## 17. `ReStatusBanner`

Variants:
- info
- success
- warning
- error

Must not rely on color only.

## 18. `ReBottomNavigation`

Suggested items:
- Jelajah
- Cari
- Kolaborasi
- Pesan
- Profil

Active state uses an accent block.

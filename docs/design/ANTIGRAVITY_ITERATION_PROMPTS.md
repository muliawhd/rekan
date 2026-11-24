# Re:kan — Antigravity Iteration Prompts

Use these prompts sequentially. Do not run the next iteration until the previous one has been reviewed.

---

# Iteration 0 — Context & Guardrails

```text
You are continuing the existing Re:kan Flutter + Laravel project.

Before changing code, read:
- AGENTS.md
- README.md
- implementation-plan.md
- task-checklist.md
- docs/architecture/*
- the Re:kan UI handoff markdown files:
  - README_DESIGN_HANDOFF.md
  - TASTE.md
  - DESIGN_SYSTEM.md
  - UI_HIERARCHY.md
  - INTERACTION_MODEL.md
  - NAVIGATION_ARCHITECTURE.md
  - COMPONENT_SPEC.md
  - SCREEN_SPEC.md
  - IMPLEMENTATION_CONSTRAINTS.md

Treat the approved wireframe and these markdown files as the source of truth for presentation.

Do not rewrite backend/auth architecture.

Audit the current Flutter implementation against the new design direction.

Deliver:
1. current-state UI inventory,
2. reusable components already present,
3. components to replace/refactor,
4. missing API dependencies,
5. implementation sequence,
6. risks.

Do not implement production screens yet.

Stop after the audit.
```

---

# Iteration 1 — Design Tokens & Shared Components

```text
Implement the Re:kan neo-brutalist design foundation.

Read all UI handoff markdown files first.

Scope:
- color tokens
- typography
- spacing
- radii
- borders
- hard-offset shadows
- icon rules
- theme integration
- RePageScaffold
- ReBrandMark
- RePrimaryButton
- ReSecondaryButton
- ReTextField
- ReChip
- ReSectionHeader
- ReStatusBanner
- ReEmptyState

Requirements:
- preserve existing auth/API logic
- do not change navigation behavior yet
- keep debug validation intact
- no new major dependency
- responsive at common Android phone sizes
- support text scaling
- >=44px tap targets

Tests:
- widget tests for core components
- theme/token tests
- accessibility/large-text smoke tests
- flutter analyze
- flutter test

Stop after the shared foundation is complete.
```

---

# Iteration 2 — Authentication UI Redesign

```text
Redesign the existing production authentication UI to match the approved Re:kan design system.

Screens:
- Welcome
- Login
- Register
- Email verification
- Password recovery explanation/state

Requirements:
- brand must render as "Re:kan"
- academic-first copy
- preserve Supabase Auth behavior
- preserve secure session storage
- preserve session restoration
- safe auth errors
- no fake recovery callback
- keep development auth validation behind its debug flag
- do not implement onboarding in this iteration

Use existing authentication controller/gateway when possible.
Refactor presentation only unless a functional bug blocks completion.

Validate:
- forms
- loading
- error states
- password visibility
- session restoration
- logout
- large text
- narrow device

Run flutter analyze and flutter test.

Stop before onboarding.
```

---

# Iteration 3 — Academic Onboarding

```text
Implement the Re:kan academic onboarding using the approved design system.

First inspect the current academic profile API contract.

Proposed steps:
1. Basic identity
2. University / program / semester
3. Skills and interests
4. Active courses
5. Study preferences + review

Rules:
- use backend-supported fields only
- do not fabricate catalog IDs
- preserve form draft while moving backward
- preserve draft on recoverable network errors
- prevent duplicate submit
- no automatic overwrite of an existing non-empty profile
- account switching invalidates stale draft
- MBTI remains optional and not used for matching

If catalog endpoints do not exist:
- do not hardcode production catalogs
- report the blocker
- propose the smallest read-only catalog API extension
- continue only with fields that can be safely implemented

Tests:
- step navigation
- validation
- draft preservation
- account switching
- API error handling
- submit protection

Stop after onboarding.
```

---

# Iteration 4 — Main App Shell & Navigation

```text
Implement the authenticated Re:kan main shell using the approved navigation architecture.

Primary destinations:
- Jelajah
- Cari
- Kolaborasi
- Pesan
- Profil

Requirements:
- use ReBottomNavigation
- preserve auth boundary
- incomplete onboarding must not enter the full shell
- no fake production data
- unsupported destinations may use clearly labeled development placeholders only if necessary
- do not implement matching/chat logic yet

Implement route/state restoration where appropriate.

Tests:
- auth boundary
- onboarding boundary
- tab switching
- logout
- session restoration

Stop before Discover functionality.
```

---

# Iteration 5 — Discover / Swipe Card UI

```text
Implement the approved Discover / Swipe Card experience.

Read:
- TASTE.md
- UI_HIERARCHY.md
- INTERACTION_MODEL.md
- COMPONENT_SPEC.md
- SCREEN_SPEC.md

Build:
- ReProfileCard
- ReSwipeDeck
- ReDiscoverActionBar
- stacked-card visual
- left/right drag behavior
- snap-back
- tap alternatives
- Profile Detail entry

Actions:
- Lewati
- Simpan
- Detail
- Ajak Kolaborasi

Critical:
- do not use dating terminology
- do not use heart as the main collaboration action
- academic identity and collaboration goal must dominate
- swipe must not be the only interaction
- prevent duplicate action submission
- preserve current card when returning from Profile Detail

If matching/discovery backend endpoints do not exist:
- implement UI with test/dev fixtures only
- keep fixtures out of production data paths
- document the required API contract
- do not invent backend behavior

Add gesture/widget tests.

Stop before implementing backend matching.
```

---

# Iteration 6 — Profile Detail & My Profile

```text
Implement:
1. Profile Detail
2. My Academic Profile

Profile Detail hierarchy:
- identity
- collaboration CTA
- about
- skills
- active courses
- study preferences
- portfolio

My Profile hierarchy:
- identity
- edit action
- academic information
- skills
- interests
- availability
- portfolio when supported

Use real existing profile API fields.
Do not invent unsupported profile fields.

Reuse:
- ReSectionHeader
- ReChip
- ReInfoRow
- shared buttons

Add empty/loading/error states.

Tests:
- loading
- empty data
- partial profile
- edit entry
- account change

Stop before chat/room implementation.
```

---

# Iteration 7 — Collaboration Success / Invite State

```text
Implement the collaboration result state shown in the approved wireframe.

Important:
First inspect actual backend semantics.

Do not call the state a mutual "match" unless the backend really supports mutual acceptance.

Preferred neutral language:
- Kolaborasi terbentuk
- Undangan terkirim
- Minat kolaborasi tercatat

CTA hierarchy:
1. Mulai Chat
2. Lihat Profil
3. Kembali ke Jelajah

If collaboration APIs are missing:
- implement only the visual states with development fixtures
- document required endpoints/events
- do not create fake persistent behavior

Test all states separately.
```

---

# Iteration 8 — Chat Inbox

```text
Implement the approved Chat Inbox UI.

Sections:
- search
- tabs/filters
- Chat 1–1
- Room Kolaborasi
- unread badges
- timestamps

Build reusable ReConversationTile.

Do not implement fake networking.

If chat backend/realtime is not available:
- use development fixtures only for presentation
- clearly isolate data provider interfaces
- document the required API/realtime contract

Preserve the design hierarchy and limited accent palette.

Add widget tests.

Stop before Room Chat.
```

---

# Iteration 9 — Room Chat UI

```text
Implement the Room Chat presentation.

Required:
- room title
- member strip
- room purpose
- chat messages
- message composer

Planned tabs:
- Chat
- Tugas
- File
- Catatan

Only enable tabs backed by real capabilities.
Unsupported tabs should remain disabled or omitted in production.

Build:
- ReRoomHeader
- RePinnedPurpose
- ReMessageBubble

Do not invent file upload, tasks, or realtime behavior.

Add loading, empty, error, and disconnected states.

Stop before backend chat integration.
```

---

# Iteration 10 — Backend Contract Planning for Discovery / Collaboration / Chat

```text
Audit the current Laravel API against the implemented Re:kan UI.

Do not add endpoints immediately.

Produce a proposed contract for:
- profile discovery
- filters
- skip/save
- collaboration invite
- accepted collaboration
- one-to-one conversations
- rooms
- messages
- unread counts

For every proposed endpoint document:
- method
- path
- authentication
- request body
- response
- pagination
- authorization
- idempotency
- errors
- privacy considerations

Preserve existing UUID identity and authorization model.

Stop and request approval before backend implementation.
```

---

# Iteration 11 — Integration & QA

```text
Perform a controlled integration and QA pass.

Validate:
- auth
- onboarding
- navigation
- profile
- discover
- detail
- collaboration states
- chat/room surfaces that are actually backed by APIs

Check:
- visual consistency
- spacing
- typography
- contrast
- semantic labels
- 44px tap targets
- text scaling
- keyboard behavior
- loading
- empty
- errors
- offline/retry
- account switching
- session restoration

Run:
- dart format
- flutter analyze
- flutter test
- Laravel tests when backend changed
- Pint
- PostgreSQL tests when applicable

Do not claim E2E success for flows not manually observed.

Produce a final UI/UX QA report with:
- PASS
- FAIL
- NOT TESTED
- known limitations
- recommended next actions
```

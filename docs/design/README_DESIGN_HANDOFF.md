# Re:kan — UI/UX Design Handoff v0.1

## Purpose

This folder translates the approved Re:kan wireframe direction into implementation-ready guidance for AI coding agents such as Antigravity and Codex.

The approved product direction combines:

- academic-first collaboration,
- swipe-card discovery,
- neo-brutalist visual language,
- strong information hierarchy,
- limited accent colors,
- mobile-first navigation,
- one-to-one chat and collaboration rooms,
- profile-driven academic matching.

This package is a visual and interaction specification. It does **not** replace the existing backend, Supabase Auth, Laravel API, PostgreSQL schema, or Flutter architecture.

## Source of truth

For visual decisions, use this priority order:

1. Approved Re:kan wireframe board.
2. `TASTE.md`
3. `DESIGN_SYSTEM.md`
4. `UI_HIERARCHY.md`
5. `INTERACTION_MODEL.md`
6. `NAVIGATION_ARCHITECTURE.md`
7. `COMPONENT_SPEC.md`
8. `SCREEN_SPEC.md`
9. Existing project architecture/API documentation.

If visual guidance conflicts with implemented backend contracts, the backend/API contract wins. Report the conflict instead of inventing fields or endpoints.

## Core product statement

Re:kan helps university students find:

- study partners,
- project collaborators,
- competition teammates,
- discussion partners,
- academic communities and rooms.

The experience may borrow the familiarity of swipe-card discovery, but must never feel like a dating app.

## Approved primary surfaces

1. Welcome / Landing
2. Login
3. Discover / Swipe Card
4. Profile Detail
5. Collaboration Success
6. Chat Inbox
7. Room Chat
8. My Academic Profile

Future onboarding screens should reuse the same design language.

## Implementation philosophy

- Reuse existing auth/session/API logic.
- Replace presentation progressively.
- Prefer reusable tokens and components.
- Do not generate screen-specific styling when a shared component can solve it.
- Keep every major action understandable without gesture-only interaction.
- Preserve state across navigation where appropriate.
- Report missing API contracts before adding UI that depends on them.

## Files

- `TASTE.md` — visual personality and anti-slop rules.
- `DESIGN_SYSTEM.md` — tokens and visual rules.
- `UI_HIERARCHY.md` — information priority and layout rhythm.
- `INTERACTION_MODEL.md` — swipe, tap, motion and feedback.
- `NAVIGATION_ARCHITECTURE.md` — app-level navigation.
- `COMPONENT_SPEC.md` — reusable component definitions.
- `SCREEN_SPEC.md` — approved screen requirements.
- `IMPLEMENTATION_CONSTRAINTS.md` — what AI coding agents may and may not change.
- `ANTIGRAVITY_ITERATION_PROMPTS.md` — phased execution prompts.

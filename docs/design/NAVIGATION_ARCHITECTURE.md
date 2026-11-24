# Re:kan — NAVIGATION_ARCHITECTURE.md

## 1. Proposed primary app navigation

Recommended 5-destination bottom navigation:

1. Jelajah
2. Cari / Explore
3. Kolaborasi / Rooms
4. Pesan
5. Profil

This may be reduced if product scope requires fewer destinations.

## 2. Auth boundary

Unauthenticated:
- Welcome
- Login
- Register
- Email Verification
- Recovery explanation / recovery flow when configured

Authenticated + onboarding incomplete:
- Academic onboarding

Authenticated + onboarding complete:
- Main app shell

## 3. Main flows

### Discover flow

Jelajah
→ Swipe Card
→ Detail Profil
→ Ajak Kolaborasi
→ Pending / Collaboration Success
→ Chat

### Search flow

Cari
→ filters
→ results
→ Profile Detail
→ collaboration action

### Collaboration flow

Kolaborasi
→ collaboration list / rooms
→ Room Chat
→ Chat / Tugas / File / Catatan

### Messaging flow

Pesan
→ Chat 1–1
or
→ Room Chat

### Profile flow

Profil
→ Edit Profil
→ Academic information
→ Skills
→ Interests
→ Availability
→ Portfolio

## 4. Back behavior

- Detail returns to previous card/result.
- Chat returns to inbox.
- Room child views return to the same room.
- Onboarding back preserves entered draft.
- Auth back never reveals protected screens.

## 5. Deep-link readiness

Future deep links may target:
- verification,
- password recovery,
- profile,
- invite,
- room.

Do not implement deep-link behavior unless configured in Supabase/mobile routing.

## 6. Debug navigation

Development Auth Validation remains:
- debug-only,
- behind explicit flag,
- excluded from production user navigation.

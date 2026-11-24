# Re:kan — SCREEN_SPEC.md

## 1. Welcome / Landing

### Purpose
Explain the product and move users into registration/login.

### Required
- Re:kan wordmark
- academic collaboration value proposition
- `Daftar` primary CTA
- `Masuk` secondary CTA

### Avoid
- long feature explanation
- decorative carousel
- romantic imagery

---

## 2. Login

### Required
- email
- password
- visibility toggle
- `Lupa kata sandi?`
- `Masuk`
- route to registration

Optional future:
- campus/SSO login only if backend/auth support exists.

---

## 3. Discover / Swipe Card

### Purpose
Quickly evaluate academic collaboration relevance.

### Required
- card stack
- identity
- university
- program
- semester
- limited tags
- collaboration goal
- `Lewati`
- `Simpan`
- `Detail`
- `Ajak Kolaborasi`

### Important
Card is not a full profile.

---

## 4. Profile Detail

### Required
- identity
- main collaboration CTA
- about
- skills
- active courses
- study preferences
- portfolio

Use backend-supported fields only.

---

## 5. Collaboration Success

### Purpose
Confirm that collaboration can proceed.

### Required
- clear success message
- counterpart identity
- `Mulai Chat`
- `Lihat Profil`
- return to discover

Wording must reflect actual backend state.

---

## 6. Chat Inbox

### Required
- search
- filters/tabs
- one-to-one chats
- room chats
- timestamps
- unread badges

---

## 7. Room Chat

### Required
- room title
- members
- room purpose
- chat content
- message composer

Planned tabs:
- Chat
- Tugas
- File
- Catatan

Do not implement unsupported tabs as real functionality.

---

## 8. My Academic Profile

### Required
- identity
- academic information
- skills
- interests
- availability
- edit action

Future:
- portfolio
- badges/proof
- project history

---

## 9. Academic Onboarding

Recommended steps:

1. Identity
2. University + program + semester
3. Skills / interests
4. Active courses
5. Preferences + review

Only persist fields supported by current API.

Draft must survive back navigation and recoverable network errors.

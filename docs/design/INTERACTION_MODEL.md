# Re:kan — INTERACTION_MODEL.md

## 1. Discover / swipe

Primary gestures:

- swipe left → Lewati
- swipe right → Ajak Kolaborasi
- tap card / Detail button → open Profile Detail
- bookmark button → Simpan

Swipe is optional convenience, not the only interaction.

Every swipe action must also have a visible button.

## 2. Swipe thresholds

Recommended implementation behavior:

- card follows pointer/finger horizontally,
- slight rotation proportional to horizontal displacement,
- below threshold → spring/snap back,
- above threshold → complete action,
- disable repeated submission until result returns,
- prevent action if card is no longer current.

Do not use exaggerated rotation.

## 3. Swipe feedback

During drag:

Left:
- subtle `LEWATI` indicator

Right:
- subtle `AJAK KOLABORASI` indicator

Use color and text/icon together.

Do not use romantic visual language.

## 4. Invite / collaboration outcome

Possible outcomes:

### Pending
User has expressed interest but no mutual/accepted collaboration exists.

### Accepted / formed
Show collaboration success screen.

CTA priority:
1. Mulai Chat
2. Lihat Profil
3. Kembali ke Jelajah

Do not call every right swipe a “match” unless backend semantics truly support mutual matching.

## 5. Profile detail

Profile detail should open without losing discover position.

Back returns to same card/deck state.

## 6. Chat interactions

1-to-1:
- tap conversation → open chat
- unread badge clears according to backend behavior

Room:
- tap room → room chat
- tabs: Chat / Tugas / File / Catatan

Do not implement tabs without backend or local model support. Placeholder tabs must be clearly marked in development.

## 7. Loading

Use local loading indicators.

Avoid blanking the entire screen when only one control is waiting.

Examples:
- invite button shows progress
- message send button disables temporarily
- pagination/loading appears below content

## 8. Errors

Errors should:
- explain what failed,
- tell user what they can do,
- preserve entered data.

Avoid:
- raw exceptions,
- HTTP stack traces,
- generic “Something went wrong” when a safe specific category is known.

## 9. Empty states

Empty states should contain:
- what is empty,
- why that may be normal,
- one useful next action.

## 10. Motion timing

Keep most UI transitions between roughly 120–250 ms.

Longer motion is acceptable only for:
- collaboration success,
- meaningful state transition.

## 11. Destructive actions

Require confirmation for:
- leaving/deleting room,
- destructive profile reset,
- deleting account,
- irreversible removals.

## 12. Accessibility

Gesture alternatives are mandatory.

Interactive icon buttons require semantic labels.

Animations should not be required to understand state.

# Product scope and provenance

## Confirmed in provided abstract
Re:kan serves active university students seeking coursework study partners or competition teams, with inclusion of disabled students. Its academic-first intent matching considers courses, skills and competition roles; MBTI is *display-only*. Card-based discovery and direct search filters are proposed. Academic collaboration workspaces and course discussion hub are in the broader product concept. The abstract explicitly calls **core peer matching and batch material downloading** initial MVP scope. 6-week target: W1-2 onboarding/matching, W3-4 workspace/forums, W5-6 accessibility/refinement. The supplied JPG mentions Flutter, Android Studio, Laravel, Supabase, Firebase, and flows for login, profile, matching, chat.

## Proposed release slicing (not facts asserted by source)
- **P0** verified academic signup, profile/onboarding, academic filters, matching rank, invitation accept/reject, material download bundles subject to copyright and membership policy.
- **P1** realtime messaging, FCM notifications, minimal workspace.
- **P2** course discussion hub, task checklists, deadlines, advanced matching transparency.

Resolve mismatch between abstract six-week workspace/forum schedule and its narrow MVP definition: define demo acceptance gates before iteration.

## Guardrails
Academic-only fields dominate matching; no attractiveness scores, MBTI weights, popularity weights, or photo-first cards. Report/block and moderation available no later than chat/forum launch. Accessibility: screen-reader labels, scalable type, color contrast, reduced motion, keyboard/switch-friendly behavior and user research before asserting full compliance.

## Success criteria (proposed)
- Authenticated student can complete profile and search/filter eligible peers.
- Ranking never depends on MBTI.
- Invitations cannot be duplicated, forged or accepted by non-recipient.
- A user cannot read other users' private messages/files by manipulating IDs.
- Batch download only includes authorized materials and informs user of unavailable files.

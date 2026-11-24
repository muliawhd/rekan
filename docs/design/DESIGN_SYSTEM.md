# Re:kan — DESIGN_SYSTEM.md

## 1. Design direction

System: Academic Neo-Brutalism  
Platform: Flutter mobile-first  
Status: Approved conceptual direction v0.1

## 2. Color tokens

Use semantic tokens rather than raw colors inside feature screens.

Suggested starting palette:

| Token | Suggested value | Usage |
|---|---:|---|
| `ink` | `#111111` | Primary text, borders, icons |
| `paper` | `#FFFDF5` | Main background |
| `surface` | `#FFFFFF` | Cards, forms |
| `mutedSurface` | `#F2F0E8` | Secondary sections |
| `mutedText` | `#626262` | Secondary text |
| `accentPrimary` | `#FFE500` | Primary CTA, active nav, emphasis |
| `accentTeal` | `#16C7C1` | Tags, availability, secondary state |
| `accentMagenta` | `#F22DBB` | Notification badges, special state |
| `success` | `#1FA86A` | Success / available |
| `danger` | `#E5484D` | Destructive/error |
| `warning` | `#F2A900` | Warning |

Exact colors may be refined in Figma later. Token names should remain stable.

## 3. Contrast

- Primary text should strongly contrast with paper/surface.
- Accent yellow should usually be paired with dark text, not white.
- Magenta and teal should not be used for long body copy.
- Do not use color as the only indicator of state.

## 4. Typography scale

Suggested mobile scale:

| Token | Size | Weight | Usage |
|---|---:|---|---|
| `displayLarge` | 36–40 | 800 | Landing hero |
| `displayMedium` | 30–34 | 800 | Major screen title |
| `headingLarge` | 24–28 | 800 | Main section |
| `headingMedium` | 20–22 | 700 | Card/person title |
| `headingSmall` | 17–18 | 700 | Subsection |
| `bodyLarge` | 16 | 400–500 | Primary body |
| `bodyMedium` | 14 | 400–500 | Supporting copy |
| `labelLarge` | 14–16 | 700 | Button |
| `labelMedium` | 12–13 | 600–700 | Chip / metadata |
| `caption` | 11–12 | 500 | Timestamps / tertiary |

Use no more than 4 visibly different text levels on one ordinary screen.

## 5. Spacing scale

Base unit: 4 px.

Preferred tokens:

`4 / 8 / 12 / 16 / 24 / 32 / 48`

Rules:
- 4: icon/text micro-gap
- 8: tightly related items
- 12: compact component padding
- 16: normal component padding
- 24: section separation
- 32: major content separation
- 48: hero/landing separation

Avoid arbitrary values unless required for optical alignment.

## 6. Border system

Neo-brutalist identity relies on borders.

Suggested:
- standard border: 2 px
- emphasized border: 3 px
- selected/hero emphasis: 3 px + accent offset/shadow

Border color:
- primarily `ink`

## 7. Radius system

Keep shapes assertive.

Suggested:
- `radiusSmall`: 6
- `radiusMedium`: 10
- `radiusLarge`: 16

Avoid 24–32 px rounded cards as a default.

Circular shapes are appropriate for:
- avatars,
- icon buttons,
- notification dots,
- status indicators.

## 8. Shadow / offset

Avoid soft blur as the primary elevation language.

Preferred:
- hard offset shadow,
- 3–6 px,
- dark or accent color,
- no/very low blur.

Use hard offset selectively:
- logo mark,
- primary CTA,
- highlighted card,
- modal emphasis.

## 9. Iconography

Style:
- simple,
- readable,
- slightly bold,
- consistent stroke.

Prefer recognizable Material-style symbols adapted to the design.

Avoid mixing:
- thin outline icons,
- filled emoji,
- detailed illustrations,
inside the same navigation system.

## 10. Buttons

### Primary
- accent yellow fill
- dark border
- dark label
- bold text
- visible pressed state

### Secondary
- paper/surface fill
- dark border
- dark label

### Destructive
- danger fill or danger border
- clear destructive copy

### Icon action
- square or circular
- 44 px minimum tap area
- label below when meaning may be ambiguous

## 11. Inputs

- visible 2 px border
- clear label above
- no placeholder-only labeling
- error text under field
- focus state clearly visible
- password visibility control must be accessible
- minimum tap target 44 px

## 12. Chips

Use for:
- skills,
- courses,
- study modes,
- availability,
- filters,
- status.

Chips should not become mini-cards.

## 13. Navigation

Bottom navigation:
- 4–5 primary destinations
- active state uses accent block/fill
- notification badges use magenta
- icon + optional label depending screen density

## 14. Accessibility

- minimum 44x44 touch target
- swipe actions must have tap alternatives
- focus states must be visible
- support text scaling
- do not rely only on color
- semantic labels for icon-only actions
- avoid gesture-only critical actions

# reskin-provisions-press — ACTIVE: UI/UX Overhaul (Provisions Press Identity)

**PRD**: OpenSpec change `openspec/changes/reskin-provisions-press/` (proposal via `/opsx:propose`)
**Branch**: `feature/reskin-provisions-press`
**Problem**: Meet with Apple (2026-07-02) established that the 4.3(a) rejection is driven by the **design surface** — UI, color scheme, and overall look reading as over-saturated / already-used — not by code or functionality duplication. The current warm-cream + forest-green + SF Rounded system is the category's default visual space (and the most common AI-generated design cluster). Functionality is not in question and must not change.

---

## The Direction: Provisions Press

Bold editorial print grounded in **grocery-world vernacular** — crate labels, butcher paper, printed category tags, market signage. Explicitly NOT generic neo-brutalism (no acid yellow/pink/lime, no thick black borders + hard shadows); the grocer's palette and print metaphor keep it subject-specific and defensible as original work.

### Palette (light mode)
| Token role | Hex | Name |
|---|---|---|
| Canvas | `#E8E6DF` | butcher-paper grey |
| Ink / text | `#201D1A` | ink |
| Primary accent / CTA | `#C8402E` | tomato |
| Secondary accent | `#D89A2B` | mustard |
| Tertiary / category | `#1F6E6A` | teal |

Dark mode: to be derived (ink-paper inversion, keep accents saturated).

### Typography
- Display / titles: SF Compact heavy or condensed (crate-label voice; web stand-ins: Anton / Archivo Narrow)
- Body: SF Pro Text (Archivo/Work Sans stand-in)
- Quantities & counts: SF Mono (functional signature — the app is full of amounts)
- **Replaces** SF Pro Rounded chrome typography (CLAUDE.md + design-system docs must be updated)

### Layer split (KEY DECISION — preserves Liquid Glass)
| Layer | Treatment |
|---|---|
| Chrome: tab bar, nav bars, toolbars, sheets, primary CTAs | **Liquid Glass retained**, re-tinted by new palette |
| Content: list rows, category tags, store headers, quantities, empty states | Provisions Press flat print / matte |

Matte print content under glossy glass chrome is itself the signature pairing. Do not stack glass on glass; do not flatten the chrome.

---

## What's Done
- 3-direction comparison mockup: `docs/mockups/ui-overhaul-directions.html` (Field Guide / Larder / Provisions Press)
- Direction chosen: Provisions Press (user preference + research validation)
- Research: category is uniformly warm/green/minimal — bold editorial print is an outlier within grocery/recipe apps; guardrail identified (avoid generic neo-brutalist clichés)
- Liquid Glass compatibility confirmed (chrome vs. content layer split)

## What's Left
- [ ] Revised mockup: Provisions Press content + Liquid Glass chrome, 2+ screens (grocery list, recipe detail), incl. reduced-transparency fallback
- [ ] `/opsx:propose reskin-provisions-press` — full proposal, design, tasks, delta specs
- [ ] Full token map: every existing `ForagerTheme` token → new value (incl. dark mode, category colors, status colors — keep AA/AAA contrast discipline)
- [ ] Typography scale replacement (Rounded → Compact/Mono system)
- [ ] View sweep: verify no hardcoded colors leak (all views use semantic tokens per M15.1)
- [ ] Update design-system docs: `docs/mockups/forager-design-system.html`, CLAUDE.md UI Patterns section
- [ ] New App Store screenshots + withdraw-and-refile fresh submission

## Key Design Decisions
1. **Content-layer identity, chrome-layer glass** — Liquid Glass artifacts are all retained and re-tinted; Provisions Press applies to content only.
2. **Grocery vernacular over trend** — every element must trace to the grocery world (crate label, butcher paper, price tag), not to neo-brutalism.
3. **Functionality frozen** — zero behavior/service/model changes in this change; visual layer only.
4. **Monospace quantities** — carried over from Field Guide exploration; functional, not decorative.

## Key Files
- `forager/Theme/ForagerTheme.swift` — token system (colors, type, spacing, radius)
- `forager/Theme/ForagerTheme+StoreColors.swift`, `ForagerButtonStyles.swift`, `ForagerCard.swift`, `ForagerSectionHeader.swift`, `ForagerProgressRing.swift`, `Color+Extensions.swift`
- `docs/mockups/ui-overhaul-directions.html` — direction comparison
- `docs/prds/complete/m15-ux-design-system.md` — outgoing design system (reference for token coverage)
- `docs/app-store-rejection-43a-response.md` — §7 history; log Meet with Apple outcome

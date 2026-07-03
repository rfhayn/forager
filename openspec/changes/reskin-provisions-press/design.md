# Design: reskin-provisions-press

## Context

The app's visual identity was established in M15.1 as a centralized token system (`ForagerTheme`): warm cream canvas (`#EDE8DF`), forest-green accent family (`#2D5016` / `#4A7C2E` / `#6B9B37`), SF Pro Rounded chrome typography, soft cards. Views consume semantic tokens — colors are (with few exceptions to be verified) not hardcoded in views. FUI-1 later added the Liquid Glass 4-tab chrome.

Meet with Apple (2026-07-02) established that this identity is the 4.3(a) blocker: the warm-green-rounded look is both the category default (Mealime, Paprika, AnyList, Crouton, Mela all live in the warm/green/minimal space) and the most common AI-generated design cluster. The fix is a full identity replacement that departs on temperature, hue, shape, and typography simultaneously.

Three directions were explored in `docs/mockups/ui-overhaul-directions.html` (Field Guide / Larder / Provisions Press). **Provisions Press** was chosen: bold editorial print grounded in grocery-world vernacular — crate labels, butcher paper, printed category tags, market signage.

Constraint that shapes everything: **functionality is frozen.** No service, model, navigation, or behavior changes. The token architecture (M15.1) makes this tractable — most of the reskin is a token-value swap plus a typography role swap.

## Goals / Non-Goals

**Goals:**
- A visual identity that cannot be mistaken for any other app in the grocery/recipe category, defensible to App Review as original, subject-specific design work.
- Complete replacement of the color system (light + dark) and typography scale in `ForagerTheme`.
- Retain all Liquid Glass chrome artifacts, re-tinted by the new palette.
- Preserve the M15.1 contrast discipline (AA minimum, AAA for primary text).
- Survive accessibility settings: Reduce Transparency, Increase Contrast, Dynamic Type.
- New App Store screenshot set; withdraw-and-refile fresh.

**Non-Goals:**
- Any behavior, service, Core Data, or CloudKit change.
- Navigation restructuring (tab count, screen hierarchy stay as-is).
- App icon redesign is a separate deliverable decision (see Open Questions).
- Generic neo-brutalism (thick black borders, hard shadows, acid yellow/pink/lime) — explicitly avoided; see Decision 2.

## Decisions

### 1. Chrome/content layer split — Liquid Glass retained
The print identity applies to the **content layer** only (list rows, category tags, store-section headers, quantities, empty states, cards). The **chrome layer** (tab bar, nav bars, toolbars, sheets, primary CTAs) remains Liquid Glass, re-tinted by the new palette.

- *Why*: Apple's own HIG says glass floats above content; a matte-print content layer under glossy glass chrome is itself a distinctive pairing no category competitor has. It also preserves all existing FUI-1 glass work.
- *Alternative considered*: flat opaque chrome (as drawn in the first mockup) — rejected; fights the platform, discards working chrome, and reads as a web app.

### 2. Grocery vernacular over trend
Every visual element must trace to the grocery world: crate-label condensed display type, butcher-paper canvas, printed flat category tags, price-tag monospace numerals. The neo-brutalist trend palette (acid yellow/pink/lime, 2–5px black borders, hard black shadows) is explicitly banned.

- *Why*: bold-editorial is itself a 2026 trend with recognizable clichés; a generic brutalist skin would swap one template for another. Subject-specific vernacular is what makes the identity defensible as original work — the exact argument made to Apple.

### 3. Palette
Light mode: butcher-paper grey `#E8E6DF` canvas, ink `#201D1A` text, tomato `#C8402E` primary/CTA, mustard `#D89A2B` secondary, teal `#1F6E6A` tertiary/category anchor. Dark mode is an ink-paper inversion (near-black warm ink canvas, paper-grey text) with accents kept saturated and lightened only as far as contrast requires. Full token map (all ~40 existing `ForagerTheme` tokens: backgrounds ×4, surfaces ×6, text ×5, accents ×4, status ×8, borders ×4, buttons ×5, categories ×11) is produced as the first implementation task and contrast-verified before any view work.

- *Why tomato as primary rather than green*: severs the category's reflexive green=food association; red is a grocer's color (tomatoes, meat labels, sale tags) so it stays subject-grounded.

### 4. Typography
- Display/titles: SF Compact, heavy/condensed weights (crate-label voice) — replaces SF Pro Rounded.
- Body: SF Pro Text (unchanged role, unchanged face).
- **Quantities, counts, prices: SF Mono semibold** — a functional signature; the app is dense with amounts and mono numerals make them scannable and tabular.
- *Why system fonts only*: zero dependencies (project rule), full Dynamic Type support for free, and SF Compact/Mono ship with iOS.

### 5. Token-first implementation order
Phase order: (1) revised mockup approval → (2) `ForagerTheme` token + typography swap → (3) build & visual sweep of all screens, fixing leaks (hardcoded colors, Rounded references outside the theme) → (4) chrome re-tint verification → (5) accessibility pass → (6) screenshots + refile.

- *Why*: M15.1's semantic-token architecture means step 2 restyles ~90% of the app in one file; the sweep then catches the residue. Cheaper and safer than view-by-view restyling.
- *Alternative considered*: per-tab incremental reskin across multiple PRs — rejected; a half-converted app is worse for screenshots and review than either identity, and the change must land atomically for the App Store refile anyway.

## Risks / Trade-offs

- [Bold identity polarizes some users] → It's the point: distinctiveness is the approval requirement. Beta group feedback via TestFlight before refiling.
- [Dark mode inversion muddies the "print" metaphor] → Design dark mode deliberately in the token map (ink paper, not generic dark grey); verify in mockup before implementation.
- [Contrast regressions vs. M15.1's verified ratios] → Token map includes computed contrast ratios per token pair before any code lands; AA minimum enforced.
- [Reduce Transparency turns glass chrome opaque] → Verify the palette's tinted-opaque fallback renders acceptably; include in accessibility pass.
- [Hardcoded colors / Rounded fonts hiding outside the theme] → Grep sweep (`Color(hex`, `design: .rounded`, named `Color.` literals) is an explicit task; anything found moves into the token system.
- [Category colors (11 tokens) are user-visible data anchors] → Re-derive the category palette inside the new gamut but keep hue-family associations (produce≈green→teal family, meat≈red, dairy≈blue→?) so existing users aren't disoriented; validated in mockup.
- [Screenshots against a reskin that Apple still rejects] → The reskin is the response to Apple's own stated objection, captured same-day; if a 4th rejection still comes, the record shows direct engagement with their feedback — strengthens any further escalation.

## Migration Plan

No data or schema migration — visual layer only. Rollback = revert the squash commit. The change ships as one PR to `main`; the App Store refile (withdraw + fresh submission with new build + screenshots) happens after merge via `/release-prep`.

## Open Questions

- App icon: redesign to match Provisions Press in this change, or as an immediate follow-up? (Screenshots include the icon on device; a mismatched icon weakens the first impression. Leaning: include a simple crate-label icon refresh in-scope.)
- Onboarding/walkthrough assets (M9.34 first-import guide) contain rendered UI — verify whether they're screenshots (need regen) or live views (restyle for free).
- Landing page (`docs/index.html`) restyle to match — in-scope or follow-up?

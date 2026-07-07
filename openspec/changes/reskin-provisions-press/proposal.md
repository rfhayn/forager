# Proposal: reskin-provisions-press

## Why

Meet with Apple (2026-07-02, from Appeal Ticket APL466617) reframed the 4.3(a) blocker: the objection is the **design surface** — UI, color scheme, and overall look reading as over-saturated / already-used — not code or functionality duplication. The current identity (warm cream `#EDE8DF` canvas, forest-green accents, SF Pro Rounded chrome) sits in the exact visual space the rest of the grocery/recipe category occupies, so the first-impression screenshots cannot be distinguished from competitors. A complete visual-identity replacement is the concrete, actionable path to approval; functionality is explicitly not in question.

## What Changes

- **Replace the entire color system** in `ForagerTheme` with the Provisions Press palette — bold editorial print grounded in grocery-world vernacular (crate labels, butcher paper, printed tags): butcher-paper grey `#E8E6DF`, ink `#201D1A`, tomato `#C8402E` (primary/CTA), mustard `#D89A2B` (secondary), teal `#1F6E6A` (tertiary/category), plus derived dark mode, status, category, and border tokens. AA/AAA contrast discipline is retained.
- **Replace the typography scale**: SF Pro Rounded chrome typography → SF Compact heavy/condensed display (crate-label voice), SF Pro Text body, **SF Mono for quantities and counts** (functional signature).
- **Layer split (key decision)**: the print identity applies to the **content layer** (list rows, category tags, store headers, quantities, empty states). **Liquid Glass chrome is retained** — tab bar, navigation bars, toolbars, sheets, primary CTAs stay glass, re-tinted by the new palette. No glass-on-glass; no flattened chrome.
- **Re-skin all views** to the new tokens (views already consume semantic tokens per M15.1; sweep verifies no hardcoded colors leak).
- **Update design-system documentation**: CLAUDE.md UI Patterns, `docs/mockups/forager-design-system.html` successor mockup.
- **New App Store screenshots** against the re-skinned build, then withdraw-and-refile a fresh submission.
- **Explicitly frozen**: all functionality, services, Core Data model, navigation structure, and CloudKit behavior. Visual layer only.

## Capabilities

### New Capabilities
- `design-system`: The app's visual identity contract — semantic color token system (light + dark), typography scale and role assignments, chrome-vs-content layer treatment (Liquid Glass chrome / print content), contrast requirements, and the prohibition on hardcoded colors outside the token system.

### Modified Capabilities

None. `app-store-assets` requirements (privacy policy, landing page, listing metadata) are unchanged at spec level — new screenshots are execution against existing REQ-004 guidance. No other capability's requirements change; this is a visual-layer replacement.

## Impact

- **Code**: `forager/Theme/` (ForagerTheme.swift, ForagerTheme+StoreColors.swift, ForagerButtonStyles.swift, ForagerCard.swift, ForagerSectionHeader.swift, ForagerProgressRing.swift, Color+Extensions.swift); view-level polish across `forager/Views/**` where type roles or one-off styling apply; no service, model, or repository changes.
- **Docs**: CLAUDE.md (UI Patterns section — Rounded typography rule replaced), design-system mockups in `docs/mockups/`, `docs/app-store-rejection-43a-response.md` (§7 history — log Meet with Apple outcome).
- **App Store**: new screenshot set; withdraw-and-refile fresh submission (new build, new submission ID).
- **Risk**: perceptual regression (contrast, dark mode, accessibility reduced-transparency fallback) — mitigated by contrast-verified token map and mockup-first workflow; no behavioral risk by construction (functionality frozen).
- **Dependencies**: none added — pure Apple frameworks, system fonts only (SF Compact, SF Pro, SF Mono all ship with iOS).

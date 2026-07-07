# Tasks: reskin-provisions-press

## 1. Design Approval (mockup-first)

- [x] 1.1 Revise `docs/mockups/ui-overhaul-directions.html` → new `docs/mockups/provisions-press-liquid-glass.html`: Provisions Press content layer under simulated Liquid Glass chrome (translucent tinted tab bar + nav), grocery list + recipe detail screens
- [x] 1.2 Add dark mode (ink-paper inversion) and Reduce Transparency fallback panels to the mockup
- [x] 1.3 Add re-derived 11-category color set (hue-family continuity) to the mockup; user sign-off on the full direction

## 2. Token Map

- [x] 2.1 Produce the complete token map: every existing `ForagerTheme` token (backgrounds, surfaces, text, accents, status, borders, buttons, categories) → new light + dark hex values
- [x] 2.2 Compute and record contrast ratios for all text-on-background and accent-on-surface pairs; fix any pair below AA (AAA for primary text)

## 3. Theme Implementation

- [x] 3.1 Rewrite `ForagerTheme` color tokens to the Provisions Press map (light + dark)
- [x] 3.2 Replace typography roles: SF Compact heavy/condensed display, SF Pro Text body, SF Mono quantity role; remove all `design: .rounded`
- [x] 3.3 Update `ForagerTheme.categoryColor(for:)` defaults to the re-derived category set
- [x] 3.4 Update theme components: `ForagerButtonStyles`, `ForagerCard`, `ForagerSectionHeader`, `ForagerProgressRing`, `ForagerTheme+StoreColors`
- [x] 3.5 Leak sweep: grep for `Color(hex`, inline `Color.` literals, and `design: .rounded` outside `Theme/`; route findings through tokens

## 4. View Sweep & Chrome

- [x] 4.1 Build and walk all screens (4 tabs + Settings + Import + Household flows); fix per-view styling residue — no functional edits
- [x] 4.2 Apply the mono quantity role at quantity/count render sites (grocery rows, recipe ingredients, store headers, badges)
- [x] 4.3 Verify Liquid Glass chrome picks up the new tint correctly (tab bar, nav bars, sheets, CTAs); no glass-on-glass, no flattened chrome
- [x] 4.4 Restyle empty states (`ContentUnavailableView`) and onboarding/walkthrough views; regenerate any baked-in UI assets (M9.34 guide check from design.md open question)

## 5. Accessibility & QA

- [x] 5.1 Accessibility pass: Reduce Transparency, Increase Contrast, Dynamic Type (incl. accessibility sizes), light/dark
- [x] 5.2 Full manual smoke test of all flows to confirm zero behavior change; run test suite
- [x] 5.3 TestFlight build to beta group for identity feedback (builds 142-154)

## 6. Docs & Refile

- [x] 6.1 Update CLAUDE.md UI Patterns (typography rule, palette summary) + create successor design-system mockup doc; update memory design-system notes
- [x] 6.2 Log Meet with Apple outcome in `docs/app-store-rejection-43a-response.md` §7/§11.8; update insights log + dev journal
- [x] 6.3 App icon redesign (leaf abandoned): concept mockup → user pick → generate AppIcon + LaunchIcon assets in the print vocabulary
- [x] 6.3b Landing page (`docs/index.html`) restyle — final pass 2026-07-07 (5 new screenshots, user-approved)
- [x] 6.4 New App Store screenshot set against the re-skinned build (build 153 captures, Provisions Press composites)
- [x] 6.5 PR #157 squash-merged; build 155 from main; RESUBMITTED in place 2026-07-07 (response doc §7/§12)

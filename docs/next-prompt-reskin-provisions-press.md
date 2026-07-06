# reskin-provisions-press — ACTIVE: UI/UX Overhaul (Provisions Press Identity)

**OpenSpec**: `openspec/changes/reskin-provisions-press/` (proposal/design/specs/tasks + style-contract.md + token-map.md)
**Branch**: `feature/reskin-provisions-press` (34+ commits, all pushed; `/review` verdict: READY FOR PR)
**Why**: Meet with Apple (2026-07-02) — 4.3(a) is a design-surface objection (UI/color scheme over-saturated/already-used), NOT functionality. Full visual overhaul; functionality frozen.

---

## ⏸️ RESUME POINT (session ended 2026-07-06)

**THE PENDING DECISION — release-prep held at the merge gate.**
`/release-prep` was requested and is ready to fire (review passed clean), but it squash-merges to
main. Held for Rich's call: **proceed** (merge now, behavior-test against main) or **hold**
(behavior test on build 145 first, then merge). Ask this FIRST on resume.

**PENDING USER ACTIONS (Rich, tracked as session task #7):**
1. **Behavior/functionality smoke test (task 5.2)** — NOT yet done. Build 145 on TestFlight is the vehicle.
   Checklist: import (URL/text/photo), grocery loop (generate-from-plan, quick-add, check-off,
   celebration, swipe actions, STORE GROUPING toggle — restructured, test carefully), meal planning,
   household sync, recipe scaling, cold-launch Home population.
2. **Reduce Transparency check** (Settings → Accessibility) — the one a11y item simctl can't script.

## State

- **TestFlight**: build **145** live (Public Beta Testers). 142→145 all this branch. Icon `fgr` since 143.
- **Icon FINAL**: clean `fgr` (Space Mono Bold on tomato). Collision research: LOW risk (no brand
  confusion; Flipboard/FGR/category all cleared). Basket-g concept approved but deferred —
  full design spec at `docs/mockups/icon-basket-g/DESIGN-SPEC.md` (icon swaps don't need App Review).
- **All screens in print grammar**: bands everywhere, broadsheet de-boxing, Settings row grammar,
  paper-skinned Form sheets, square swatches, mono numerals, flat progress bars, checklist/fork.knife tabs.
- **5.1 accessibility DONE** (dark/Dynamic Type/Increase Contrast; 3 type roles made DT-relative).
- **Style contract clean** app-wide (last content-glass fixed in `/review`, e9558ee).

## Remaining tasks (openspec tasks.md — 18/23 done)

- [ ] 5.2 user behavior smoke test (above)
- [ ] 5.3 — done for now (145); more builds as fixes land
- [ ] 6.1 docs sync: CLAUDE.md UI Patterns (typography/palette rules), design-system doc successor, memory design-system note
- [ ] 6.2 log Meet-with-Apple outcome in `docs/app-store-rejection-43a-response.md` §7/§11.8
- [ ] 6.3b landing page final pass (icon.png done; screenshots inherit from 6.4)
- [ ] 6.4 App Store screenshot set (use ReskinScreenshotTests harness + seeded data; include icon-uniqueness
      note in review notes: "original typographic mark, no Food & Drink competitor uses letterform icon")
- [ ] 6.5 PR → squash merge → withdraw-and-refile fresh submission (`/release-prep` covers merge+TestFlight)

## Queued next changes (user-committed)
1. `establish-test-planning-workflow` (PRD drafted; also fix pre-existing CategoryDeduplicator/StoreSchema test-isolation failures)
2. `decide-view-layer-scope-architecture` (ADR 016)

## Key artifacts
- Style contract: `openspec/changes/reskin-provisions-press/style-contract.md`
- Token map (69 verified contrast pairs): `openspec/changes/reskin-provisions-press/token-map.md`
- Screenshot harness: `foragerUITests/ReskinScreenshotTests.swift` (10 screens; boot sim → set `simctl ui` state → run for a11y matrices)
- Mockups: `docs/mockups/provisions-press-liquid-glass.html` + icon rounds a–a5 + `icon-basket-g/`
- Stray branch note: `docs/memory-committed-boundary` exists (one docs commit, other session) — untouched.

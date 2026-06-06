> **ARCHIVE NOTE (2026-06-06) — APPLIED but strategy SUPERSEDED.** The metadata changes in this change were executed in full and shipped to App Store Connect on 2026-04-23 (new subtitle, rewritten description, new keywords, 5 captioned screenshots, competitor-named Resolution Center reply). The strategy was then **disproven**: two subsequent re-reviews returned verbatim-identical 4.3(a) boilerplate (non-engagement loop). The effort pivoted to a formal App Review Board appeal — see change `escalate-43a-to-app-review-board` and `docs/app-store-rejection-43a-response.md` § 11. The branch `feature/reposition-app-store-listing` carried code regressions (would have reverted #152) and a now-superseded response doc; only the reusable `Tools/compose-screenshots.py` and the `docs/index.html` landing-page update were salvaged to main. The original delta spec below was NOT promoted into the living `app-store-assets` spec (the repositioning requirements describe a disproven approach); it is retained here for the record only.

## Why

forager was rejected under App Store Guideline 4.3(a) "Design - Spam" on 2026-04-21 (v2.0 build 134, submission `e5e960e5-2797-4d0c-a768-581576a70214`). Apple's finding: the app "shares a similar binary, metadata, and/or concept as apps submitted to the App Store by other developers, with only minor differences." Research confirms forager is genuinely differentiated from the 12 closest competitors — but the current App Store listing headlines the three category tropes ("Grocery Lists", "Recipes", "Meal Planning") that every competitor leads with. The 4.3(a) signal is positioning, not code. The fix is metadata surgery before Apple's response window closes; Apple Developer Forum precedent (thread 772135) shows replies on unchanged generic listings entrench the rejection.

## What Changes

All changes are to customer-facing metadata and marketing. **No binary change** (per precedent: binary rewrites without metadata changes typically fail to flip 4.3(a); metadata rewrites without binary changes typically succeed in 1-3 rounds).

- **App Store name**: `forager - Smart Meal Planner` → `forager - Shared Shopping`
- **App Store subtitle**: `Grocery Lists & Meal Planning` → `Household Sync, Multi-Store`
- **App Store description**: full rewrite (~1,450 chars) in human voice leading with three noun-phrase owned positions (household without account, multi-stop shopping, on-device parsing). Drops six ALL-CAPS section headers that read as "AI manifesto."
- **App Store keywords**: lead with `household, shared grocery, multi store` (drop `ingredients, food, weekly, pantry` as low-value generics)
- **What's New copy**: rewritten to match the positioning
- **App Store screenshots**: replace all 5 with new shots showing (1) household invite flow, (2) Group-by-Store grocery view, (3) on-device parser preview, (4) Dashboard, (5) recipe scaling. Each composited with a noun-phrase overlay caption.
- **App Preview video**: new 30-sec version for ASC permanent slot + 45-sec version as Resolution Center attachment, demonstrating the three owned positions end-to-end.
- **Resolution Center reply letter**: ~1,200-char bug-fix-changelog-style response to Apple naming specific competitor apps (AnyList, Plan to Eat, Samsung Food, BigOven, Mealime, Crouton, Mela) for concrete differentiation.
- **Landing page** (`docs/index.html`): rewritten to align with the new positioning; new Screenshots section added.
- **Canonical listing doc** (`docs/app-store-listing.md`): updated to reflect the rewrites as the source of truth that feeds ASC.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `app-store-assets`: modifies REQ-002 (landing page), REQ-004 (ASC metadata reference). New requirements cover the repositioning artifacts themselves (differentiation-led listing copy, replacement screenshot set, walkthrough video, Resolution Center reply record).

## Impact

- **No code changes**. No binary rebuild. No test changes. No Core Data or service-layer impact.
- **Documents modified**: `docs/app-store-listing.md`, `docs/index.html`, `openspec/specs/app-store-assets/spec.md`, new `docs/app-store-rejection-43a-response.md` holding the reply letter + video script + screenshot shot-list.
- **External systems**: App Store Connect (text fields + screenshots + App Preview video), App Store Connect Resolution Center (reply thread + attachments).
- **Review cycle impact**: Apple resumes review automatically on metadata-cited rejections once the reply is submitted with updated ASC fields — no Resubmit click required (per `reference_appstore_resubmit_workflow.md` memory).
- **Escalation fallback**: if the repositioned listing is rejected again with the same 4.3(a) template, escalate to App Review Board with the documented paper trail; not addressed in this change.

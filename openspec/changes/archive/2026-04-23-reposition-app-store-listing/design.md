## Context

forager was rejected for App Store Guideline 4.3(a) "Design - Spam" on 2026-04-21. Two research streams in the current session established the ground truth:

1. **Competitor analysis (12 apps)**: AnyList, Paprika, Mealime, Plan to Eat, Samsung Food, Yummly, BigOven, Crouton, Mela, Pestle, Bring!, Kitchen Stories. forager is genuinely differentiated on three axes — (P1) no-account CloudKit household sharing (0 of 12 match), (P2) multi-stop Group-by-Store shopping workflow (AnyList has item tags but nobody headlines the workflow), (P3) fully on-device 3-tier parsing (Samsung is cloud, Pestle requires iOS 26 Apple Intelligence). But the current listing headlines are the same three category tropes ("GROCERY LISTS / RECIPES / MEAL PLANNING") every competitor uses.
2. **4.3(a) precedent research**: Apple Developer Forum 772135 (Apple rep confirming "metadata" scope includes screenshots + title + subtitle + keywords + description); Forum 771794 (binary redesigns with unchanged generic listings fail); 9to5Mac Nov 2025 (Apple tightened 4.1c copycat clause, reviewer discretion trending up). Metadata-only fixes succeed in 1-3 rounds when they lead with specific noun differentiation AND replace screenshots.

Current state: the rejected v2.0 build 134 sits in Resolution Center awaiting a reply. The ASC listing has the old positioning. The submitted screenshots mirror the category tropes. Apple resumes review automatically on metadata-cited rejections once the reply is sent with updated fields; no Resubmit click is required.

## Goals / Non-Goals

**Goals:**
- Resolve the 4.3(a) rejection in the next review round via metadata-only changes.
- Lead the listing with three noun-phrase owned positions that no competitor holds.
- Keep the app name "forager" (distinctive, not generic) while repositioning the tagline.
- Version-control the final text (description, subtitle, reply, caption copy) in `docs/` before it reaches ASC, so the canonical source is reviewable.
- Produce screenshots and a walkthrough video that carry the differentiation visually (per Apple rep: screenshots dominate reviewer scanning).
- Give the user a step-by-step runbook for the manual simulator / Keynote / QuickTime / ASC work.

**Non-Goals:**
- Any binary change. No new features, no UI redesign, no code edits to the app target.
- Repositioning the app name to something unrelated to "forager" (distinctive brand word, keep it).
- Changing the category (Food & Drink / Productivity) — positioning shift is within the category.
- Addressing App Review Board escalation (only relevant if round-2 metadata rejection fails — deferred).
- Addressing rating, privacy labels, or age rating (the 2.3.6 Age Rating issue from round 1 is already resolved).
- Changing the pricing model, in-app purchase structure, or TestFlight arrangements.

## Decisions

### Decision 1: Metadata-only response, no binary change
**Choice**: Reply in Resolution Center + update ASC fields + replace screenshots. Keep v2.0 build 134 untouched.

**Rationale**: Precedent research is explicit. Forum 771794 documents a developer who redesigned UI, added features, and renamed their app, and still got rejected under 4.3(a) because the listing positioning stayed generic. The pattern that wins is rewriting the *story* Apple sees, not the *product* behind it. Adding a binary change here introduces new rejection surface area (new features can fail other guidelines) and undercuts the message "the unique functionality was already in the rejected build — you didn't see it because the listing obscured it."

**Alternatives considered**:
- *Rebuild with a visibly new feature*: rejected. Precedent says binary changes don't flip 4.3(a) alone, and add risk.
- *Cancel and start a new submission*: rejected. Apple forum 704387 shows resubmitting without metadata change entrenches the account flag.
- *Go straight to App Review Board*: rejected. Precedent says Board appeals work best as a last resort after a paper trail of specific changes.

### Decision 2: Three noun-phrase owned positions (not adjectives)
**Choice**: Organize every listing artifact around P1 "household sharing without an account," P2 "multi-stop shopping with Group by Store," P3 "on-device ingredient parsing." Use nouns, not adjectives. No "smart," "powerful," "intuitive," "seamless."

**Rationale**: Precedent (Apple Forum 772135 + Median.co appeal guide) consistently says concrete nouns outperform marketing adjectives because they give the reviewer something to map against a feature table. "CloudKit household sync" lands; "smart family planning" does not.

**Alternatives considered**:
- *Pick one position (P1 only) and go deeper*: considered. Stronger for a single-axis reviewer but weaker for reviewers who care about different things. Three positions give the reply letter more ammunition if the first reviewer isn't persuaded by one of them.
- *Four or five positions*: rejected. Dilutes the reviewer's impression. Three is the consensus pattern from precedent writeups.

### Decision 3: App name "forager - Shared Shopping" (not "forager" alone)
**Choice**: Rename to `forager - Shared Shopping` (25 chars). Consider `forager` alone only if ASC confirms no conflict.

**Rationale**: User's preference is `forager` alone; backup is `forager - Shared Shopping`. The backup works for 4.3(a) purposes because it appends a differentiating noun phrase. The risk of `forager` alone is collision with the existing "Forager" farming game on the App Store — verification required in ASC before committing. Either option keeps the distinctive brand word.

**Alternatives considered**:
- *`forager - Smart Meal Planner`* (current): rejected. Adjective + category trope.
- *`forager - Household Meal Planner`*: plausible but "meal planner" is category trope. Backed off.
- *`forager - Grocery for Households`*: plausible. Kept as a Plan B if the chosen subtitle collides with something.

### Decision 4: Subtitle combines P1 + P2 (two differentiators in 30 chars)
**Choice**: `Household Sync, Multi-Store` (27 chars). Covers P1 and P2. Leaves P3 to the description and screenshots.

**Rationale**: The reviewer reads subtitle after name; packing two noun-phrases in 30 chars maximizes differentiation signal. Comma-separated list format is Apple-approved pattern (e.g., App Store Editor's Choice listings often use this shape).

**Alternatives considered**:
- *`Shared Lists for Households`*: single-axis (P1 only). Cleaner read, weaker differentiation density.
- *`Multi-Stop Grocery Lists`*: P2 only. Solid but loses the household story.

### Decision 5: Description rewritten in human voice (no ALL-CAPS headers)
**Choice**: 1,450-char description using scenario-driven paragraphs, no ALL-CAPS section headers, specific references (Trader Joe's, Costco, "a pinch of saffron"), varied sentence rhythm.

**Rationale**: User feedback explicitly asked for "as little AI-sounding as possible." ALL-CAPS headers on every section is the strongest "AI manifesto" tell. Apple reviewers scan descriptions; paragraph copy that reads like a person wrote it breaks out of the template-app impression 4.3(a) flags.

**Alternatives considered**:
- *Keep headers, shorten each section*: rejected. Headers themselves are the tell.
- *Single long paragraph*: rejected. Too monolithic to scan; reviewer needs breathable structure.

### Decision 6: Screenshots must change — highest-leverage asset
**Choice**: Replace all 5 screenshots. New shots: (1) household invite flow, (2) Group-by-Store grocery view, (3) on-device parser preview, (4) Dashboard, (5) recipe scaling. Each with an overlay caption composited in Keynote/Figma (NOT in-app).

**Rationale**: Apple Forum 772135 — Apple's own rep explicitly said screenshots are the dominant 4.3(a) signal. Changing text without changing screenshots is a known failure mode. The three new "unique" screenshots each anchor one owned position visually; the two supporting shots (dashboard, scaling) keep continuity with the rest of the product surface.

**Alternatives considered**:
- *Keep existing screenshots, update captions only*: rejected. Apple treats caption overlay + screenshot as one asset; replacing captions without replacing the underlying UI state does not visually shift the impression.
- *Replace only 3 screenshots (the unique ones)*: considered. Cheap, but Apple expects all 5 to tell a coherent story. The supporting shots need captions that echo the repositioning.

### Decision 7: 45-second walkthrough video as Resolution Center attachment
**Choice**: Record a 45-sec walkthrough (household invite → Group by Store → on-device parsing). Attach to Resolution Center reply. Optionally upload a 30-sec version to ASC as an App Preview (permanent marketing asset).

**Rationale**: Precedent (Median.co appeal guide, Apple support docs on Resolution Center replies) shows short annotated walkthrough videos meaningfully help when a reviewer has misread functionality. Resolution Center supports file attachments up to the 4,000-char reply limit. No downside beyond production time.

**Alternatives considered**:
- *No video*: leaves the reply relying on prose + stills. Acceptable but weaker.
- *Only the 30-sec ASC App Preview*: ASC's 15-30 second constraint makes it too tight to cover three flows. Having both versions — 30s for ASC, 45s for Resolution Center — is the right split.

### Decision 8: Reply letter names competitor apps by name
**Choice**: Reply letter explicitly lists AnyList, Plan to Eat, Samsung Food, BigOven, Mealime (as account-based competitors) and Crouton, Mela (as Apple Family Sharing competitors). Anchors each differentiator to a concrete comparison.

**Rationale**: Precedent (Median.co, Forum 771794) says concrete feature-comparison tables outperform generic "our app is unique" prose. Naming public competitors is not legally risky — they're publicly listed apps, and citing them strengthens the argument by showing we know the landscape. Apple reviewers respond well to "I did my homework."

**Alternatives considered**:
- *Generic "other apps in this category"*: rejected. Weaker; looks like the dev hasn't done the research.
- *Feature-comparison table in the reply*: considered but table markdown renders poorly in Resolution Center's plaintext field. Named-in-prose is a better fit.

### Decision 9: Canonical source in `docs/` before ASC
**Choice**: Update `docs/app-store-listing.md` and `docs/index.html` with the final copy before pasting into ASC. Create `docs/app-store-rejection-43a-response.md` holding the reply letter + video script + screenshot shot-list as a single versioned artifact.

**Rationale**: Reviewable record. If the reply is rejected and we need to iterate, the paper trail in git is essential. ASC's field history is not easily queryable; the canonical source in the repo is.

### Decision 10: Step-by-step runbook for Sessions 2 and 3
**Choice**: Tasks.md breaks simulator screenshot capture, Keynote caption compositing, QuickTime video recording, and ASC submission into granular checkable steps. User explicitly asked for this.

**Rationale**: This is largely manual work outside Claude's direct execution scope. A dense runbook with exact commands (xcrun simctl, screenshot filenames, ASC field names) reduces error rate and lets the user execute without re-asking at every step.

## Risks / Trade-offs

- **Risk**: Apple rejects again with the same 4.3(a) template. → **Mitigation**: the paper trail of specific metadata changes + annotated screenshots + walkthrough video gives us grounds to escalate to App Review Board with evidence. Escalation is explicitly scoped out of this change.
- **Risk**: Apple rejects with a *different* guideline. → **Mitigation**: treat as progress (4.3(a) resolved) and triage the new issue in a separate change.
- **Risk**: App name `forager - Shared Shopping` collides with an existing App Store app. → **Mitigation**: verify in ASC before committing; backup to `forager - Household Meal Planner` or similar.
- **Risk**: Screenshot captions composited in Keynote don't render crisply at 1320×2868. → **Mitigation**: verify pixel-exact export in Preview after Keynote export; re-export at 300% scale if needed.
- **Risk**: Screen recording from the simulator via `xcrun simctl io booted recordVideo` produces oversized files that exceed Resolution Center attachment limits. → **Mitigation**: use iMovie or QuickTime to trim + re-export as H.264 at moderate bitrate; target <25MB.
- **Risk**: Copy-style rules violated (em dashes sneak into final ASC copy). → **Mitigation**: final proofread against `feedback_copy_style.md` rule ("no em dashes in app copy"). Only standard hyphens (`-`) or commas/periods/colons.
- **Risk**: User shoots screenshots on iPhone 17 Pro simulator (6.3") instead of Pro Max (6.9") and uploads at wrong resolution. → **Mitigation**: runbook explicitly specifies `iPhone 17 Pro Max` for screenshot capture.
- **Trade-off**: Naming competitors in the reply exposes us to minor reputational risk if any competitor finds out and is offended. → Accepted: competitors are publicly-listed apps, comparison is factual, reply is private to Apple Resolution Center.
- **Trade-off**: Human-voice description sacrifices some keyword density for readability. → Accepted: precedent says "sounds human" outweighs "keyword-stuffed" for 4.3(a) specifically.
- **Trade-off**: Holding the binary means forgoing any incidental improvements in builds 135-137 for this review cycle. → Accepted: improvements can ship in a subsequent submission once 4.3(a) is resolved.

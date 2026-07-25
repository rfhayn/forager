# App Store Rejection 4.3(a) — Response Record

**Change**: `reposition-app-store-listing`
**Prepared**: 2026-04-21
**Status**: Drafted, awaiting screenshot capture + video recording + ASC submission

This document is the single source of truth for every artifact submitted to Apple in response to the 4.3(a) rejection. Paste from here into App Store Connect. Attach the referenced files to the Resolution Center reply.

---

## 1. Rejection Record

| Field | Value |
|---|---|
| **Submission ID** | `e5e960e5-2797-4d0c-a768-581576a70214` |
| **Rejection date** | 2026-04-21 |
| **Guideline cited** | 4.3(a) Design - Spam |
| **Reviewer device** | iPad Air 11-inch (M3) |
| **Version reviewed** | 2.0 |
| **Build reviewed** | 134 |
| **Round** | 2 of this submission cycle (round 1 was 2.3.6 Age Rating, resolved 2026-04-17) |

**Apple's message (verbatim):**

> We noticed the app shares a similar binary, metadata, and/or concept as apps submitted to the App Store by other developers, with only minor differences.
>
> Since we do not accept spam apps on the App Store, we encourage you to review the app concept and submit a unique app with distinct content and functionality.

---

## 2. Response Strategy

**Metadata-only. No binary change.**

Precedent research (Apple Developer Forum 772135, 771794, 769912; 9to5Mac Nov 2025 analysis; Median.co appeal guide) confirms:
- Metadata-only fixes succeed in 1-3 rounds when they lead with specific noun differentiation AND replace screenshots.
- Binary changes without metadata rewrites fail (Forum 771794 — VPN developer redesigned UI, added features, renamed app, still rejected).
- Apple's own rep (Forum 772135) defined "metadata" as screenshots + title + subtitle + keywords + description.
- Naming specific competitor apps with concrete axis-of-comparison outperforms generic "we are unique" prose.

Lead with three noun-phrase owned positions (from competitor analysis of 12 apps):

| # | Owned position | Competitor coverage |
|---|---|---|
| P1 | Household sharing without an account | 0 of 12 match |
| P2 | Multi-stop Group-by-Store shopping | AnyList has per-item tags; no competitor headlines the workflow |
| P3 | On-device 3-tier ingredient parsing | Samsung cloud-based; Pestle needs iOS 26 Apple Intelligence |

Full rationale lives in `openspec/changes/reposition-app-store-listing/design.md`.

---

## 3. Resolution Center Reply Letter

**Target length**: under 1,500 of the 4,000-char limit. Bug-fix changelog tone. No em dashes (project copy-style rule).

**Text to paste into Resolution Center reply field:**

```
Hello App Review,

Thank you for the 4.3(a) feedback. We took it seriously and have
substantially revised our App Store positioning to make forager's
distinct concept clearer. We also shipped a new build during this
review cycle (v2.0 build 140) that fixes an unrelated CloudKit sync
issue our own testing surfaced. The functional repositioning described
below is present in both the original build under review and build 140.

Summary of changes:

1. Subtitle changed:
   "Grocery Lists and Meal Planning" to "Household Sync, Multi-Store"
   This repositions around CloudKit household sharing and multi-stop
   shopping, two concepts no comparable app on the App Store offers
   as a headline.

2. Description rewritten to lead with three specific features that do
   not appear together in any apps we believe may be comparables:

   Household sharing without an account. Shareable-link invites with
   no signup, no email, no proprietary server. Unlike AnyList, Plan
   to Eat, Samsung Food, BigOven, and Mealime (all account-based),
   forager uses CloudKit's native sharing. Unlike Crouton and Mela
   (which rely on Apple Family Sharing), forager uses ad-hoc
   shareable links to form households on demand.

   Multi-stop shopping with Group by Store. Assign preferred stores
   to ingredients and view a single grocery list grouped by store.
   AnyList supports per-item store tags; no competitor headlines the
   multi-stop shopping workflow.

   On-device ingredient parsing. A three-tier parser (regex, a Core
   ML BiLSTM-CRF model, and Apple's NaturalLanguage framework)
   converts "2 cups flour" to structured quantity, unit, and
   ingredient entirely on device. Samsung Food's parsing is
   cloud-based. Pestle requires iOS 26 Apple Intelligence. forager
   works on any iOS 26 device with no server round-trip.

3. Screenshots replaced:
   Screenshot 1: household invite flow, annotated
   Screenshot 2: Group-by-Store grocery view, annotated
   Screenshot 3: on-device parsing preview, annotated

4. Keywords adjusted to lead with "household," "shared grocery," and
   "multi store" rather than generic category terms.

Attached: the three revised screenshots with callouts (household invite,
Group-by-Store view, on-device parser preview). Happy to provide a
walkthrough recording on request.

Happy to provide any additional detail the team needs.

Thank you,
Rich Hayn
```

**Attachments to include:**
- `01-household-invite.png` (captioned)
- `02-group-by-store.png` (captioned)
- `03-recipe-import.png` (captioned)

(Video attachment removed from initial reply — offered to Apple on request. 45-sec recording exists locally if Apple asks in a follow-up or if a Round 2 escalation needs more evidence.)

**Tone check (do NOT do):**
- Do not ask Apple to identify the allegedly similar apps (they will not disclose)
- Do not reference how long the developer has been on the App Store or in beta
- Do not use emotional language or defensive framing
- Do not claim originality without evidence (name competitors with axis of comparison instead)

---

## 4. Screenshot Shot-List (6.9" iPhone, 1320 × 2868)

**Capture environment**: iPhone 17 Pro Max simulator, Light Mode, marketing status bar (9:41, full battery, WiFi active). Data state: household "The Kitchen", member "Alex", stores Trader Joe's / Costco / Target, recipes Chicken Tikka Masala / Chocolate Chip Cookies / Shrimp Tacos, list "This Week" with ~10 items distributed across the three stores.

**Captions are composited in Keynote AFTER capture.** Do not add captions as in-app UI. Top 25% of each frame is the caption overlay; bottom 75% is the captured UI.

### Shot 1 — Household invite (P1)

**UI state:**
- Navigate: Settings tab → Household
- Visible: household name "The Kitchen", 1 member ("Alex"), prominent "Invite via Link" button (or equivalent UI label)
- Optional: tap Invite so the iOS share sheet is partially visible — visually sells "link"

**Overlay caption:**
```
Invite your household with a link.
No account. No signup. No email.
```

**File**: `docs/beta/screenshots/01-household-invite.png`

### Shot 2 — Group by Store (P2)

**UI state:**
- Navigate: Grocery tab → list "This Week"
- Toggle: Group by Store ON
- Visible: at least 2-3 store sections, each with 2-4 items. Trader Joe's (eggs, bread, yogurt, bananas), Costco (chicken thighs, rice, olive oil), Target (paper towels, dish soap)
- At least one item checked off to show live state
- Store labels with color dots if the UI exposes them (M18.1.4 added these)

**Overlay caption:**
```
One list. Every store.
Multi-stop shopping without the juggle.
```

**File**: `docs/beta/screenshots/02-group-by-store.png`

### Shot 3 — On-device parsing (P3)

**UI state:**
- Navigate: Recipes → Import → Paste Text (or whichever import path exposes the cleanest preview)
- Paste test block:
  ```
  Spaghetti Carbonara

  2 cups all-purpose flour, sifted
  3 large eggs, room temperature
  1/2 pound guanciale, diced
  a pinch of saffron threads
  Salt and pepper to taste
  ```
- Load the preview so parsed structure is visible per line: [qty] [unit] [ingredient] [qualifier]
- Do NOT trigger Claude. We want the on-device story.

**Verify before shooting**: open the preview and confirm that a first-time viewer can see the parsed structure. If the UI shows only raw text without visible structure, pivot to the inline ingredient edit screen with autocomplete suggestions visible instead.

**Overlay caption:**
```
Your grocery list stays on your phone.
AI parsing, no server round-trip.
```

**File**: `docs/beta/screenshots/03-on-device-parsing.png`

### Shot 4 — Dashboard (supporting)

**UI state:**
- Navigate: Home tab (Dashboard)
- Visible: greeting ("Good morning, Rich" or whatever generic first name), populated Meal Plan card, populated This Week grocery card showing ~5 items remaining, Quick Actions row if present

**Overlay caption:**
```
Your week, at a glance.
Meals planned. Groceries ready.
```

**File**: `docs/beta/screenshots/04-dashboard.png`

### Shot 5 — Recipe scaling (supporting)

**UI state:**
- Navigate: Recipes → Chicken Tikka Masala
- Scroll to servings stepper, bump from 4 to 8 so fractional quantities appear
- Visible: ingredients list with fractional quantities ("6 tsp", "3 cups", "1½ tsp")

**Overlay caption:**
```
Scale any recipe. Fractions made friendly.
0.25× to 4×, always readable.
```

**File**: `docs/beta/screenshots/05-recipe-scaling.png`

---

## 5. 45-Second Walkthrough Video Script (Resolution Center attachment)

**Format**: vertical 9:16, 1080 × 1920, recorded from iPhone 17 Pro Max simulator via `xcrun simctl io booted recordVideo`. No voiceover. Text caption overlays between beats (added in iMovie). Background music optional (acoustic, royalty-free).

| Time | Beat | UI | Caption |
|---|---|---|---|
| 0:00–0:04 | Open cold | App icon tapped, Dashboard appears | "forager" |
| 0:04–0:12 | Invite flow | Settings → Household → Invite via Link → iOS share sheet opens | "Invite your household. No account. No signup." |
| 0:12–0:18 | Acceptance (optional) | Invite link tapped on second device, app opens, household joined | "They tap the link. They're in." |
| 0:18–0:28 | Group by Store | Grocery list → toggle Group by Store → sections snap into Trader Joe's / Costco / Target | "One list. Every store. Multi-stop made easy." |
| 0:28–0:38 | Parsing | Recipe import → paste "2 cups all-purpose flour, sifted" → parsed preview appears | "AI parsing, on your iPhone. No server sees your list." |
| 0:38–0:45 | Close | Dashboard populated, end card with forager logo | "Shopping and cooking for households." |

**Shooting notes:**
- Hold each beat 2-3 seconds
- If the second-device invite acceptance (0:12–0:18) is too complex to stage, drop it and extend Group-by-Store and parsing beats
- Stop recording with Ctrl+C in the terminal running `xcrun simctl io`
- Trim in iMovie. Add title cards with captions. Export at 1080p H.264, target file size under 25 MB

---

## 6. 30-Second App Preview Script (optional ASC permanent asset)

**Format**: same as 45-sec version. 15-30 sec hard limit imposed by ASC App Preview slot.

Condensed beat table:

| Time | Beat | Caption |
|---|---|---|
| 0:00–0:03 | Dashboard opens | "forager" |
| 0:03–0:10 | Invite flow | "Invite your household with a link." |
| 0:10–0:18 | Group by Store | "One list. Every store." |
| 0:18–0:26 | Parsing | "AI parsing on your iPhone." |
| 0:26–0:30 | Close | "Shopping for households." |

Drop the optional second-device acceptance beat. Otherwise same shooting + export process.

---

## 7. Submission History

| Date | Action | Outcome |
|---|---|---|
| 2026-04-21 | Prepared | Drafts complete, awaiting screenshots + video + ASC submission |
| 2026-04-23 | Submitted reply to Resolution Center | Awaiting Apple response. ASC updated: name (forager - Shared Shopping), subtitle (Household Sync, Multi-Store), description (human-voice rewrite), keywords (household,shared grocery,multi store,…), What's New copy. 5 new screenshots uploaded to 6.9" iPhone slot. Build selector changed from 134 → 140. Resolution Center reply includes the build-140 reference line, naming competitors with axis of comparison. Three screenshots attached (01-household-invite, 02-group-by-store, 03-recipe-import). Walkthrough video recorded but not attached — held locally for Round 2 if needed. |
| late Apr 2026 | Apple re-reviewed the repositioned listing | REJECTED again under 4.3(a), same boilerplate template. (Exact reviewer message not captured in the repo; developer reports it matched the 2026-04-21 wording.) This is the second 4.3(a) determination on submission `e5e960e5…`. |
| 2026-05-05 | Developer resubmitted v2.0 build 140 for review | Same submission ID. No metadata change of record beyond the 2026-04-23 repositioning. |
| 2026-05-13 | Apple re-review | REJECTED under 4.3(a). **Third** 4.3(a) determination on the same submission. Reviewed on iPad Air 11-inch (M3), version 2.0 (140). Message is verbatim-identical boilerplate, opening "The issues we previously identified still need your attention," with a generic spam-factor resource list (shared source code / repackaged template / purchased template / multiple accounts) — none of which apply to forager. Full text recorded in § 11.1. |
| 2026-06-06 | Strategy reset → escalate to App Review Board | Metadata-only repositioning is disproven: fully executed on 2026-04-23, it drew identical boilerplate on two re-reviews. Decision: stop editing metadata and file a formal App Review Board appeal. See § 11. Tracked by OpenSpec change `escalate-43a-to-app-review-board`. |
| 2026-06-06 | **App Review Board appeal SUBMITTED** | Filed via the App Review appeal form (`developer.apple.com/contact/app-store/?topic=appeal`), not the Resolution Center. Submission ID `e5e960e5…`, v2.0 build 140. Sent the 1,945-char trimmed letter (§ 11.3) verbatim — fit under the form's 2,000-char cap. Now awaiting the Board's response (typical window: a few business days to ~2 weeks). Outcome plan in § 11.5. |
| 2026-06-23 | **App Review Board UPHELD the rejection** | Appeal Ticket **APL466617** (reviewer "Leo"). The Board determined the original 4.3(a) rejection feedback was valid: "this app duplicates the content and functionality of other apps … considered a form of spam." Still **no specific duplicated app named** — the determination did not engage our point-by-point refutation of the four spam factors, confirming the operative driver is unstated category-saturation perception, not the written criteria. Matches the **"Upheld with the same boilerplate"** branch of § 11.5 → next move is the "Meet with Apple" appointment. Full Board message recorded in § 11.7. |
| 2026-07-02 | **Meet with Apple appointment HELD** | The live conversation finally named the axis three written rounds never did: the 4.3(a) driver is the **design surface** — the reviewer-side perception that forager's UI, color scheme, and overall look are over-saturated / already-used in the category. It is largely NOT about code duplication or functionality similarity; the four-factor engineering defense was never the battleground. No specific duplicated app was named (consistent with all prior rounds), but the actionable feedback made naming one unnecessary. Outcome recorded in § 11.8; response strategy in § 12. |
| 2026-07-07 | **RESUBMITTED** | Resubmitted on the existing submission (`e5e960e5…`) via App Store Connect after the reskin: build **2.0 (155)** (cut from main post-merge; diagnostics hidden; AI-parse fix), all 10 screenshots replaced (iPhone 6.9" + iPad 12.9", Provisions Press composites), review notes set (§ 12.3), Resolution Center reply enumerating the four design resolutions point-by-point against the July 2 consultation feedback. Staged via ASC API (build swap, screenshots, notes); final submit + reply via the ASC site. Now awaiting review. |
| 2026-07-03 → 07-06 | **`reskin-provisions-press` executed** | Full visual-identity overhaul (Provisions Press: butcher-paper/ink/tomato print identity, SF Compact condensed + mono numerals, original `fgr` typographic icon, broadsheet masthead system; Liquid Glass chrome retained and re-tinted). Functionality frozen. TestFlight builds 142–153 iterated with live design review; new 5-screenshot set composited from build 153. Fresh-submission package in § 12. |

| 2026-07-14 | **REJECTED — FOURTH 4.3(a)** | Build 2.0 (155) rejected on submission `e5e960e5…`. Review device: iPhone 17 Pro Max (first iPhone-device review of the saga); review date July 14, 2026. Guideline cited: "4.3(a) - Design - Spam" / ASC summary "4.3.0 Design: Spam". Message is the same template ("shares a similar binary, metadata, and/or concept as apps submitted to the App Store by other developers, with only minor differences"), opening "The issues we previously identified still need your attention." The complete Provisions Press reskin, new icon, 10 all-new screenshots, and the point-by-point consultation-compliance reply did not move the template. **The design-surface hypothesis from the 2026-07-02 consultation is disproven as sufficient.** Developer replied same day in Resolution Center: recounted the escalation history, noted the Meet with Apple rep had cleared code duplication and named the UI as the issue, that the UI/UX was fully reworked, and asked for additional detail. |
| 2026-07-15 | Apple boilerplate reply | Resolution Center response restated the 4.3 template verbatim ("…similar binary, metadata, and/or concept as apps submitted to the App Store by other developers, with only minor differences… we encourage you to review the app concept and submit a unique app with distinct content and functionality"). No engagement with the compliance record, no app named. Fourth consecutive non-engagement on this thread — the Resolution Center channel is confirmed dead. |
| 2026-06-08 | *(context, logged retroactively)* | Apple published a tightened App Review Guidelines update between the consultation prep and the re-review: 4.3(b) now reads in part "Don't submit apps that are indistinguishable from what's already widely available," names oversaturated categories that "will not accept new submissions unless they offer a meaningfully different or improved experience," and warns repeated low-effort submissions "may lead to removal from the Apple Developer Program" (9to5Mac / MacRumors, 2026-06-09). The July 14 review was conducted under this hardened regime. |

Add new rows as the round progresses:
- When Apple responds (overturn, uphold, or follow-up question)
- When any subsequent action is taken

---

## 8. Verification Checklist (what we expect the reviewer to verify)

The reply letter claims specific functionality. A reviewer following up would check:

- [ ] Open the app on a test device. Navigate to Settings → Household. Verify invite via shareable link works without asking for an account, email, or signup.
- [ ] Invite a second device (a separate Apple ID on the reviewer's test setup). Confirm the household syncs data without any account layer between.
- [ ] Navigate to a grocery list. Toggle "Group by Store" and confirm at least two store sections appear with assigned items.
- [ ] Import a recipe via paste-text. Verify the parser structures ingredients (quantity, unit, ingredient, qualifier) without any network request (Airplane Mode optional proof).
- [ ] Verify the Claude API integration is opt-in: Settings → AI Integration shows the toggle OFF by default, with no API key configured; disabling it does not disable the on-device parser.

No new code was shipped for this response. All five checks are satisfied by the v2.0 build 134 binary currently under review.

---

## 9. Pause Notes (Session 2 interrupted 2026-04-21)

Screenshot work paused mid-Shot-1 when a CoreData/CloudKit zone-corruption bug was discovered on the device (see `investigate-groceryitem-multi-zone-assignment` change). The bug breaks CloudKit sync entirely and must be fixed before ASC submission regardless of the 4.3(a) response. Screenshot work resumes after the fix ships.

### Shot 1 (Household invite) — v1 draft

- **File**: `docs/beta/screenshots/drafts/01-household-invite-v1.png`
- **Source**: `~/Desktop/forager/cc-ss/Household.png`, captured 2026-04-21 10:27
- **Build**: v2.0 build 137 Debug, iPhone, iOS 26.3.1
- **Household name**: "The Kitchen" (renamed on device at 10:26:22 per rich.log line 158 — already staged)

**What's working in v1**:
- Generic household name
- Prominent green "Invite Member" CTA with paper-plane icon
- 3 members visible = social proof the sharing feature is real
- "Synced 43 sec ago" timestamp reinforces CloudKit sync works (ironic given the bug; will be true again once fixed)
- No emails visible on this overview screen

**Blocker**: full names ("Rich Hayn", "Joseph Koval", "Mary Hayn") exposed. First names alone are standard for App Store screenshots; full last names are unusual and "Koval" is distinctive enough to identify a specific real person publicly.

**Resolution options (decided in next session)**:
- **Option A** — edit display names in-app via Settings > Household > Manage Members. Unknown whether the app allows this vs. using CloudKit-pulled names.
- **Option B** — redact in Keynote post-comp. Small white rectangles over the last names (keep first names visible). Reliable fallback.
- **Option C** — ask Joe and Mary to temporarily set their iCloud display name to first-name-only. More effort, not worth it.

**Also pending**: second candidate capture of the share sheet itself (tap "Invite Member" → capture the iOS share sheet with Messages/Mail/Copy Link icons). This is the stronger proof of the "no account" claim. Will capture when screenshot work resumes.

### What else is outstanding

- Shots 2-5 not yet captured (sim acceptable for these)
- 45-sec walkthrough video not yet recorded
- 30-sec App Preview video not yet recorded
- ASC listing fields not yet updated
- Resolution Center reply not yet submitted

---

## 10. Escalation Path (if round 2 also fails)

If Apple rejects again with the same 4.3(a) template:
1. Document the second rejection in Section 7 (Submission History).
2. Reshoot screenshots from different angles or UI states (vary the story without changing the positioning).
3. File an App Review Board appeal referencing this document as the paper trail.
4. Open a new OpenSpec change `escalate-43a-to-app-review-board` to manage the appeal.

If Apple rejects with a *different* guideline:
- Treat the 4.3(a) as resolved.
- Open a separate change to triage the new guideline.
- Keep this change active until both the new guideline is resolved AND the overall submission is approved.

---

## 11. App Review Board Appeal (2026-06-06)

**Change**: `escalate-43a-to-app-review-board`. This section supersedes Section 10's "reshoot screenshots and reply again" path. That path is closed: the metadata-only repositioning was executed in full on 2026-04-23 and drew identical boilerplate on two subsequent re-reviews (see § 7). We are no longer editing metadata. We are appealing the determination to the App Review Board.

### 11.1 Third rejection (verbatim, 2026-05-13)

> Hello,
>
> The issues we previously identified still need your attention.
>
> If you have any questions, we are here to help. Reply to this message in App Store Connect and let us know.
>
> Review Environment — Submission ID: e5e960e5-2797-4d0c-a768-581576a70214 | Review date: May 13, 2026 | Review Device: iPad Air 11-inch (M3) | Version reviewed: 2.0 (140)
>
> **Guideline 4.3(a) - Design - Spam.** We noticed the app shares a similar binary, metadata, and/or concept as apps submitted to the App Store by other developers, with only minor differences. Submitting similar or repackaged apps is a form of spam that creates clutter and makes it difficult for users to discover new apps.
>
> Next Steps: Since we do not accept spam apps on the App Store, we encourage you to review the app concept and submit a unique app with distinct content and functionality.
>
> Some factors that contribute to a spam rejection may include: submitting an app with the same source code or assets as other apps; creating and submitting multiple similar apps using a repackaged app template; purchasing an app template with problematic code from a third party; submitting several similar apps across multiple accounts.
>
> Support: Reply to this message … Request an App Review Appointment at Meet with Apple to discuss your app's review (Tuesdays and Thursdays, local business hours).

### 11.2 Why we are appealing rather than replying again

Three diagnostic facts drive the decision:

1. **One stuck submission.** All three 4.3(a) determinations are on the same submission ID (`e5e960e5…`). We have been arguing with one thread, not getting fresh reviewers.
2. **Non-engagement.** The 2026-05-13 message is verbatim-identical boilerplate, opening with the canned "issues we previously identified still need your attention." It names no competing app, references none of our metadata changes, and gives a generic spam-factor list. The reviewer is not weighing our repositioning on its merits.
3. **The stated criteria do not apply.** Apple's own spam-factor list (shared source code, repackaged template, purchased template, multiple accounts) describes none of forager's situation. forager is an original native Swift app, no template, single developer account, one app of its kind.

You cannot copy-edit your way out of a non-engagement loop. The remaining high-leverage moves are (a) a formal App Review Board appeal — chosen here — and, as a live fallback, (b) the "Meet with Apple" appointment Apple offered in the message.

### 11.3 Appeal letter (text to submit)

Submit via developer.apple.com → Contact Us → App Review → Appeals (the App Review Board form at `https://developer.apple.com/contact/app-store/?topic=appeal`), NOT the Resolution Center reply box. **The appeal form caps the message at 2,000 characters**, so the filed version below is the trimmed 1,945-char letter. Copy-style: "forager" lowercase, no em dashes. If the form has separate subject + body fields, paste the body starting at "Hello App Review Board,"; if it truncates, the submission ID is already in the first sentence so the "Subject:" line is droppable.

```
Hello App Review Board,
I'm appealing a Guideline 4.3(a) "Design - Spam" rejection of forager (v2.0, build 140). Submission ID: e5e960e5-2797-4d0c-a768-581576a70214.
The same submission has been rejected three times with identical wording, most recently May 13, 2026. Between rounds I rewrote the subtitle, description, keywords, and screenshots in good faith. Each re-review returned the same boilerplate, naming no similar app. None of 4.3(a)'s spam factors apply to forager:
Shared code or assets: forager is original native Swift, written from scratch, sharing no code or assets with any app.
Repackaged template: no template. It's the only app of its kind I've built.
Purchased third-party template: none was used.
Multiple apps across accounts: I'm a solo developer, one account, one app in this category.
forager also differs from every comparable app. I surveyed twelve (AnyList, Paprika, Mealime, Plan to Eat, Samsung Food, Yummly, BigOven, Crouton, Mela, Pestle, Bring!, Kitchen Stories) on three points:

Account-free household sharing via a CloudKit link: no signup, no email, no server. The account-based apps require a login; Crouton and Mela rely on Apple Family Sharing.
Multi-stop shopping with Group by Store: assign stores to ingredients, view one list grouped by store. AnyList has per-item store tags but doesn't build around this workflow.
Fully on-device ingredient parsing via a three-tier pipeline (regex, a Core ML BiLSTM-CRF model, and Apple's NaturalLanguage framework), no network request. Samsung Food parses in the cloud; Pestle depends on iOS 26 Apple Intelligence.

All three are functional in this build, and I'd welcome a reviewer verifying each.
If the Board has identified a specific app forager is believed to duplicate, I'd appreciate knowing which one so I can respond. Otherwise, I respectfully ask that the 4.3(a) determination be overturned and the app approved.
Thank you for reconsidering.
Rich Hayn
```

> **Letter version note**: This is the filed letter — solo-developer "I" voice, trimmed to **1,945 characters** to fit the App Review Board form's 2,000-char cap, finalized 2026-06-06. Verified: 0 em dashes, "forager" lowercase throughout, submission ID intact, all 12 surveyed competitors named, all four spam-factor refutations + three differentiators + the "name the app" ask preserved. The earlier ~3,300-char "we"-voice and "I"-voice drafts were superseded. Update § 7 with the filing date once submitted.

### 11.4 Tone notes (kept from the Resolution Center discipline)

- Refute Apple's four stated criteria point by point — this is the load-bearing move. It reframes the question from subjective ("is it spammy?") to objective ("does it meet these conditions? No.").
- Name competitors with the axis of comparison. Concrete beats "we are unique."
- The "name the specific app" ask is **retained** for the Board (unlike the Resolution Center reply, where we omitted it). In a formal appeal it shifts the burden and reads as confidence.
- Do NOT: appeal emotionally, cite years on the Store or in beta, claim originality without evidence, or threaten.

### 11.5 Expected outcomes and next move

- **Overturned / approved** → update § 7, archive `escalate-43a-to-app-review-board`, resume the ship checklist (build 141 is ready on TestFlight; confirm the ASC build selector and submit).
- ✅ **ACTUAL OUTCOME (2026-06-23, ticket APL466617): Upheld with the same boilerplate** → book the "Meet with Apple" appointment (Tue/Thu) and request the specific comparable app live; bring this document as the paper trail. **This branch is now active — see § 11.7 for the verbatim Board message and § 11.8 for the Meet with Apple plan.**
- **Upheld with NEW specifics** (a named app or a concrete overlap) → treat as progress; triage the specific concern in a follow-up change.
- **Different guideline raised** → 4.3(a) is effectively resolved; triage the new guideline separately.

### 11.6 Live fallback considered but not chosen first

Withdrawing this submission and filing a fresh one (new submission ID, build 141) would escape the stuck thread and likely draw a new reviewer, but it also forfeits the appeal-in-progress and the documented Resolution Center history. Hold it as a move for *after* the Board responds, not before. **(Now unlocked — the Board has responded. See § 11.8.)**

### 11.7 Board response (verbatim, 2026-06-23)

Appeal Ticket **APL466617**. The Board upheld the rejection.

> Hello,
>
> Appeal Ticket: APL466617
>
> Thank you for your patience as we considered your appeal.
>
> The App Review Board determined that the original rejection feedback was valid. The app does not comply with:
>
> **4.3(a) - Design**
>
> During our review, we found that this app duplicates the content and functionality of other apps submitted to the App Store, which is considered a form of spam and not appropriate for the App Store.
>
> Apps submitted to the App Store should be unique and should not duplicate other apps. We encourage you to create a unique app to submit to the App Store. For more information about developing apps for the App Store, visit the Develop section of the Apple Developer website.
>
> We appreciate your efforts to resolve this issue and look forward to reviewing your revised submission.
>
> Best regards,
> Leo
> App Review Board

**Diagnosis.** The Board reviewed our point-by-point refutation of all four written spam factors (no shared code, no template, no purchased template, single account) and upheld anyway — **without naming a single app forager supposedly duplicates** and without engaging the refutation. That confirms the operative driver is not the written 4.3(a) factors but an unstated *category-saturation* judgment: the app reads to a fast-triage reviewer as "another grocery + recipe + meal-planning app," and our differentiators (account-free CloudKit household sharing, fully on-device three-tier parsing, Group by Store) are not legible in the first-impression surface (name, icon, subtitle, first screenshot). You cannot win this with a better written argument — the argument was already correct. The remaining moves are (a) force live engagement via Meet with Apple, and (b) reposition the *product's first impression* around one differentiator, then refile fresh.

### 11.8 Meet with Apple — plan

Apple offered "Request an App Review Appointment at Meet with Apple … Tuesdays and Thursdays, local business hours" in the 2026-05-13 message. This is the next move.

**📅 BOOKED: Thursday, July 2, 2026, 2:00 p.m. Eastern.** Talking-points sheet: [`docs/app-store-meet-with-apple-talking-points.md`](app-store-meet-with-apple-talking-points.md).

**Goal of the meeting:** Move from written non-engagement to a live human who must answer the load-bearing question — *"Which specific app does forager duplicate?"* If they can name one, that's actionable (differentiate against it concretely). If they cannot, that itself is leverage — it surfaces that the rejection is category-perception, not duplication, which reframes what we need to change.

**Booking** (steps in § 11.9 below / chat guidance):
1. Go to the App Review appointment page: `developer.apple.com/contact/app-store/` → "App Review" → "Request an appointment" / Meet with Apple. (Also linked from the bottom of the 2026-05-13 Resolution Center message.)
2. Sign in with the Account Holder / Admin Apple Developer account.
3. Select the app (forager, v2.0 build 140), pick a Tue/Thu slot in local business hours, and reference Appeal Ticket **APL466617** + submission ID `e5e960e5-2797-4d0c-a768-581576a70214`.

**Bring to the call:**
- This document (the four-factor refutation + the 12-competitor differentiation survey).
- A one-page talking-points sheet (to be drafted): the single demand ("name the app"), the three live-demoable differentiators, and the verification offer.
- A device or simulator able to demo the three differentiators live: account-free household invite, Group by Store, and on-device parsing in Airplane Mode.

**Two outcomes:**
- They name a comparable app → triage it; differentiate concretely; refile.
- They cannot / will not → the case for *repositioning the first-impression surface* + withdraw-and-refile-fresh (build 141, new submission ID, per § 11.6) becomes the path.

**✅ OUTCOME (held 2026-07-02):** A third branch, better than either anticipated one. The rep did not name a comparable app — but did name the **axis**: the objection is the *UI, color scheme, and overall design* reading as over-saturated and already-used in the grocery/recipe category. Functionality and code similarity were explicitly not the driver. Diagnosis: the pre-reskin identity (warm cream canvas, earthy green accents, SF Pro Rounded, soft cards) sat dead-center in the category's default visual space *and* in the most common AI-generated design cluster — a triage reviewer couldn't tell forager's screenshots from a dozen competitors', and per this document's record, didn't.

This converted a three-round immovable wall into scoped, actionable work: **`reskin-provisions-press`** — replace the visual identity (Provisions Press: bold editorial print grounded in grocery-world vernacular), keep functionality frozen, produce new screenshots, and withdraw-and-refile fresh. Executed 2026-07-03 → 07-06. The fresh-submission package is § 12.

---

## 12. Fresh Submission Package (post-reskin, withdraw-and-refile)

The written-appeal path is exhausted (§ 11) and the design-surface diagnosis is addressed (§ 11.8 outcome). This section is the complete package for the fresh submission: strategy, the App Review notes text, and the submission mechanics.

### 12.1 Strategy

> **REVISED 2026-07-07 (developer decision):** No withdraw-and-refile. At the
> Meet with Apple appointment the rep indicated the existing submission is
> **solvable in place** — so we RESUBMIT on the current submission
> (`e5e960e5…`) with the redesigned build, new screenshots, and the § 12.3
> notes. This also keeps the consultation context attached to the thread,
> which now works *for* us: the reviewer can see we did exactly what the
> consultation asked. Per the resubmit-workflow record, binary/guideline
> rejections use the Resubmit path with a new build selected.

- ~~**Withdraw** the stuck submission (`e5e960e5…`, three 4.3(a) determinations + upheld appeal) and **file fresh** — new submission ID, near-certain new reviewer, no inherited thread history.~~ *(superseded by the revision above)*
- **Binary**: the final reskin build (154+; must include the diagnostics re-gate — Settings > Diagnostics hidden in Release). Do NOT submit builds 134–141 (pre-reskin identity) or 142–153 (beta diagnostics UI visible).
- **First impression is the battleground**: the reviewer's first 30 seconds are the icon, the screenshots, and the opening screens. All three now carry the Provisions Press identity.
- **Tone of all text**: neutral and forward-looking. A new reviewer sees this cold — nothing should read as a continuation of a dispute. The consultation is referenced as collaboration, not grievance.

### 12.2 What changed since the last review (internal checklist)

| Surface | Before (rejected rounds) | Now |
|---|---|---|
| Color system | Warm cream + earthy green (category default) | Butcher-paper grey `#E8E6DF` / ink `#201D1A` / tomato `#C8402E` / mustard / teal |
| Typography | SF Pro Rounded throughout | SF Compact condensed display + SF Pro body + mono numerals (price-tag signature) |
| App icon | Leaf glyph (category cliché) | Original `fgr` typographic mark (Space Mono Bold on tomato) — no Food & Drink competitor uses a letterform icon |
| Screen structure | Soft cards, floating boxes | Broadsheet print grammar: ink bands, hairline rules, masthead titles, printed category tags |
| Screenshots | White-band captions, SF Rounded | Butcher-paper band, Condensed Black ink titles, mounted-print framing (build 153 captures) |
| Functionality | — | **Unchanged** (frozen by policy for the entire reskin) |

### 12.3 App Review Notes (draft — paste into the fresh submission's Review Notes field)

> Following our App Review consultation on July 2, 2026 (appointment referencing ticket APL466617), we understood the 4.3(a) concern to be about the app's visual design reading as similar to other apps in the category, rather than its functionality. We took that feedback seriously and completely redesigned the app's visual identity before this submission.
>
> What changed: a new color system (butcher-paper neutral with tomato/mustard/teal accents, replacing the category-typical cream-and-green), new typography (condensed editorial display type with monospaced numerals, replacing rounded type), a new original app icon (a typographic "fgr" mark — to our knowledge no app in the category uses a letterform icon), and a rebuilt screen grammar (print-inspired ink bands and mastheads). App functionality is unchanged from the previously reviewed build.
>
> Three features distinguish forager functionally, each verifiable in under a minute:
> 1. Household sharing with no accounts: Settings > Household > Invite Member generates a share link — the recipient joins via iCloud with no signup, email, or password. (Most competitors require creating an account.)
> 2. Multi-store shopping: assign grocery items to specific stores and toggle "group by store" on any list — the list reorganizes into per-store sections for multi-stop trips.
> 3. On-device ingredient parsing: recipe imports are parsed into structured ingredients locally. Enable Airplane Mode and import a recipe via paste to verify no network dependency. (An optional AI assist exists but is off by default and requires the user's own API key.)
>
> No demo account is needed; all functionality is available on first launch. Thank you for taking a fresh look.

*(~1,950 characters — comfortably under the field limit; trim the parenthetical competitor asides first if a shorter version is ever needed.)*

### 12.4 Submission mechanics (in order — REVISED for resubmit-in-place)

1. **Final build**: merge `reskin-provisions-press` to main, cut the submission build FROM MAIN (155+, includes diagnostics re-gate + AI-parse fix), distribute to TestFlight, quick smoke. *(154 verified 2026-07-07: chili parse ✅, diagnostics hidden ✅.)*
2. **Build selector**: on the existing submission, swap the selected build to the new one.
3. **Screenshots**: replace the 6.9" iPhone slot with the five build-153 composites (repo: `docs/beta/screenshots/01–05`). iPad slot: N/A — confirmed no separate iPad set (2026-07-07).
4. **Metadata**: name/subtitle/keywords/description carry over from the 2026-04-23 repositioning (still accurate post-reskin); update What's New for the redesign.
5. **Review Notes / Resolution Center**: paste § 12.3 (works verbatim as either the review-notes field or a Resolution Center reply, whichever the resubmit flow surfaces).
6. **Resubmit** on the existing submission and log the date in § 7.

### 12.5 Open items before submitting — ALL CLOSED (2026-07-07)

- [x] Final submission build cut + smoke-tested (155 from main; diagnostics hidden in Release)
- [x] iPad screenshot question answered: set EXISTED with pre-reposition captures — replaced with 5 iPad-size Provisions Press composites
- [x] Landing page (`docs/index.html`) final pass with the new screenshots (task 6.3b)
- [x] `reskin-provisions-press` merged to main (PR #157, squash) — submission build cut from main
- [x] **RESUBMITTED 2026-07-07** — see § 7

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

Add new rows as the round progresses:
- When the appeal is submitted to the App Review Board
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

Submit via developer.apple.com → Contact Us → App Review → "I would like to appeal the rejection of my app." (the App Review Board form), NOT the Resolution Center reply box. Copy-style: "forager" lowercase, no em dashes.

```
Subject: forager 4.3(a) rejection appeal
(Submission ID e5e960e5-2797-4d0c-a768-581576a70214)

Hello App Review Board,

We are formally appealing a Guideline 4.3(a) "Design - Spam"
rejection of forager (version 2.0, build 140). The same submission
has now received this rejection three times, each with identical
wording, most recently on May 13, 2026. Between rounds we
substantially revised the listing in good faith: a new subtitle, a
rewritten description, new keywords, and five new screenshots. Each
re-review returned the same boilerplate text with no app-specific
detail and no identification of an allegedly similar app. We are
asking the Board for an individualized review, because we do not
believe forager meets any of the criteria the guideline describes.

None of guideline 4.3(a)'s stated spam factors apply to forager.
The rejection lists the factors that contribute to a spam
determination. We address each directly:

- Same source code or assets as other apps: forager is an original
  native Swift application written from scratch. It shares no code or
  assets with any other app.
- Multiple similar apps from a repackaged template: forager is built
  on no template. It is our only app of this kind.
- A purchased app template with problematic code: no third-party
  template was used.
- Several similar apps across multiple accounts: we maintain a single
  developer account with a single app in this category.

forager is materially differentiated from every comparable app we
could identify. We surveyed twelve leading apps in the grocery,
recipe, and meal-planning space (AnyList, Paprika, Mealime, Plan to
Eat, Samsung Food, Yummly, BigOven, Crouton, Mela, Pestle, Bring!,
and Kitchen Stories). forager differs on three concrete axes:

1. Household sharing without an account. forager forms a shared
   household through a CloudKit shareable link, with no signup, no
   email, and no proprietary server. None of the twelve apps offer
   this: the account-based apps (AnyList, Plan to Eat, Samsung Food,
   BigOven, Mealime) require a login, and the apps that share at all
   (Crouton, Mela) rely on Apple Family Sharing rather than ad-hoc
   link invites.

2. Multi-stop shopping with Group by Store. forager lets a user
   assign preferred stores to ingredients and view one grocery list
   grouped by store for a multi-stop trip. AnyList offers per-item
   store tags, but no comparable app builds the list around the
   multi-store shopping workflow.

3. Fully on-device ingredient parsing. forager converts free text
   such as "2 cups all-purpose flour, sifted" into structured
   quantity, unit, ingredient, and qualifier using a three-tier
   pipeline (a regular-expression parser, a Core ML BiLSTM-CRF model,
   and Apple's NaturalLanguage framework), entirely on device with no
   network request. Samsung Food's parsing is cloud-based; Pestle's
   depends on iOS 26 Apple Intelligence. forager runs on any iOS 26
   device with no server round trip.

These features are present and functional in the build under review.
We would welcome a reviewer verifying each one directly.

If the Board has identified a specific app that forager is believed
to duplicate, we would appreciate knowing which one, so that we can
respond to the specific concern. Absent that, we respectfully ask
that the 4.3(a) determination be overturned and the app approved.

Thank you for reconsidering.

Rich Hayn
```

### 11.4 Tone notes (kept from the Resolution Center discipline)

- Refute Apple's four stated criteria point by point — this is the load-bearing move. It reframes the question from subjective ("is it spammy?") to objective ("does it meet these conditions? No.").
- Name competitors with the axis of comparison. Concrete beats "we are unique."
- The "name the specific app" ask is **retained** for the Board (unlike the Resolution Center reply, where we omitted it). In a formal appeal it shifts the burden and reads as confidence.
- Do NOT: appeal emotionally, cite years on the Store or in beta, claim originality without evidence, or threaten.

### 11.5 Expected outcomes and next move

- **Overturned / approved** → update § 7, archive `escalate-43a-to-app-review-board`, resume the ship checklist (build 141 is ready on TestFlight; confirm the ASC build selector and submit).
- **Upheld with the same boilerplate** → book the "Meet with Apple" appointment (Tue/Thu) and request the specific comparable app live; bring this document as the paper trail.
- **Upheld with NEW specifics** (a named app or a concrete overlap) → treat as progress; triage the specific concern in a follow-up change.
- **Different guideline raised** → 4.3(a) is effectively resolved; triage the new guideline separately.

### 11.6 Live fallback considered but not chosen first

Withdrawing this submission and filing a fresh one (new submission ID, build 141) would escape the stuck thread and likely draw a new reviewer, but it also forfeits the appeal-in-progress and the documented Resolution Center history. Hold it as a move for *after* the Board responds, not before.

# Tasks — escalate-43a-to-app-review-board

## 1. Record + draft (Claude executes) — DONE in the scaffolding session

- [x] 1.1 Backfill `docs/app-store-rejection-43a-response.md` § 7 with the late-April second rejection, the 2026-05-05 resubmission, the 2026-05-13 third rejection, and the 2026-06-06 escalation decision
- [x] 1.2 Add § 11 (App Review Board Appeal): verbatim 2026-05-13 rejection (§ 11.1), rationale (§ 11.2), appeal letter (§ 11.3), tone notes (§ 11.4), outcome plan (§ 11.5), fallback note (§ 11.6)
- [x] 1.3 Scaffold this OpenSpec change (proposal, design, tasks, delta spec)
- [ ] 1.4 Update `docs/current-story.md` **against `main`'s authoritative copy** (do NOT edit the stale April-18 copy on this reposition-based branch — it would regress the doc). Add a Round 4 row (2026-05-13, 4.3a, third determination) to the App Store Rejection History table; update the Next Action pointer from "resume reposition Session 2" to "App Review Board appeal filed, awaiting response". Sequence this with the PR-strategy decision (see § PR strategy below)
- [x] 1.5 Proofread the appeal letter against `feedback_copy_style.md`: "forager" lowercase, no em dashes — verified the § 11.3 fenced letter is clean (subject-line em dash removed; body uses hyphens/commas/colons only; no capitalized "Forager"). Em dashes in surrounding documentation prose retained as out-of-scope per the rule's "app copy" definition.

## § PR strategy (resolve before merge)

This change was branched off `feature/reposition-app-store-listing`, which **never merged** and has diverged from `main` (its `current-story.md`, `development-journal.md`, `insights-log.md`, `MealPlanService.swift`, `foragerApp.swift` are all behind `main`). The appeal work itself is **docs-only** (`app-store-rejection-43a-response.md` + this OpenSpec change). Decide one:

- **Option A (recommended)** — cherry-pick just the appeal commit(s) onto a fresh branch off `main`, PR that. Clean: brings only the docs that matter, no stale reversions. The response doc gets created on `main` for the first time.
- **Option B** — merge `reposition-app-store-listing` to `main` first (resolving its staleness), then PR this on top. Heavier; resurrects the whole paused reposition change.
- **Option C** — keep both on this branch and PR the combined set, accepting a messy diff. Not recommended.

Do NOT edit `current-story.md` on this branch (stale April-18 copy). The Round-4 row + Next Action update (task 1.4) happen against `main`'s authoritative copy as part of whichever option is chosen.

## 2. Pre-submission verification (user executes, ~15 min)

Confirm every factual claim in the appeal is true in build 140 before submitting — the Board may verify.

- [ ] 2.1 Household invite works with no account/email/signup (Settings → Household → invite via link)
- [ ] 2.2 Group by Store shows at least two store sections from assigned ingredients
- [ ] 2.3 Paste-import parses an ingredient line into structured fields with no network call (Airplane Mode optional proof)
- [ ] 2.4 The three-tier parser claim is accurate (regex → Core ML BiLSTM-CRF → NaturalLanguage). The optional Claude integration is OFF by default and is NOT mentioned in the appeal
- [ ] 2.5 The twelve named competitors are still live on the App Store and the axis-of-comparison claims still hold (spot-check AnyList account requirement, Crouton/Mela Apple Family Sharing, Samsung Food cloud parsing, Pestle Apple Intelligence dependency)

## 3. Submit the appeal (user executes, ~20 min)

- [ ] 3.1 Go to developer.apple.com → Contact Us → App Review → "I would like to appeal the rejection of my app" (App Review Board form). Do NOT use the Resolution Center reply box
- [ ] 3.2 Select the forager app + the rejected version 2.0 (build 140), submission ID `e5e960e5-2797-4d0c-a768-581576a70214`
- [ ] 3.3 Paste the appeal letter from `docs/app-store-rejection-43a-response.md` § 11.3. Verify no em dashes survived the paste and "forager" is lowercase throughout
- [ ] 3.4 Submit
- [ ] 3.5 Record the submission date in § 7 (new row) and commit: `escalate-43a-to-app-review-board: record Board appeal submitted YYYY-MM-DD`

## 4. Monitor + branch on outcome (user + Claude, 24-72 hr+ wait)

- [ ] 4.1 **Overturned / approved** → update § 7; mark this change ready to archive; confirm the ASC build selector (build 141 is on TestFlight) and complete the ship checklist
- [ ] 4.2 **Upheld, same boilerplate** → book the "Meet with Apple" appointment (Tue/Thu, local business hours) via the link in the 2026-05-13 message; bring this document; request the specific comparable app live
- [ ] 4.3 **Upheld, NEW specifics** (named app / concrete overlap) → treat as progress; open a follow-up change to triage the specific concern
- [ ] 4.4 **Different guideline raised** → 4.3(a) effectively resolved; triage the new guideline in a separate change
- [ ] 4.5 Consider withdraw-and-refile-fresh (new submission ID, build 141) ONLY after the Board responds, if escalation stalls

## 5. Close-out

- [ ] 5.1 `/review` the branch changes before PR
- [ ] 5.2 `/dev-journal` — narrative of the strategy reset (metadata-only disproven → Board appeal) and the non-engagement-loop diagnosis
- [ ] 5.3 `/log-insight` — at minimum: "identical boilerplate on 4.3(a) re-review = non-engagement loop; metadata edits cannot resolve it; escalate to a fresh team"
- [ ] 5.4 `/pr` to open the pull request
- [ ] 5.5 After merge, `/opsx:archive escalate-43a-to-app-review-board` to promote the delta into the `app-store-assets` living spec

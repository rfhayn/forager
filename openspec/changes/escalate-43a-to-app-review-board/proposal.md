## Why

forager's App Store submission (`e5e960e5-2797-4d0c-a768-581576a70214`, v2.0 build 140) has now been rejected under Guideline 4.3(a) "Design - Spam" three times: 2026-04-21, again on re-review in late April, and most recently 2026-05-13. The parent change `reposition-app-store-listing` executed a full metadata-only repositioning on 2026-04-23 (new subtitle, rewritten human-voice description, new keywords, five new captioned screenshots, competitor-named Resolution Center reply). That strategy is now disproven: two subsequent re-reviews returned verbatim-identical boilerplate, opening "The issues we previously identified still need your attention," naming no competitor and referencing none of the changes.

Three diagnostic facts establish that further metadata edits cannot resolve this:
1. **One stuck submission.** All three determinations are on the same submission ID — we never reached a fresh reviewer.
2. **Non-engagement.** Identical boilerplate on re-review = the listing is not being weighed on its merits. This is a category-saturation pattern-match, not an individualized judgment.
3. **Stated criteria do not apply.** Apple's own spam-factor list (shared source code, repackaged template, purchased template, multiple accounts) describes none of forager's situation: original native Swift, no template, single developer account, one app.

You cannot copy-edit out of a non-engagement loop. The escalation path scoped out of `reposition-app-store-listing` is now in scope here: a formal App Review Board appeal.

## What Changes

**No binary change. No further metadata change.** The artifact is a formal appeal and its supporting record.

- **App Review Board appeal letter** — formal written appeal submitted via developer.apple.com → Contact Us → App Review (NOT the Resolution Center reply box). Refutes Apple's four stated spam factors point by point, then proves differentiation against twelve named competitors on three concrete axes. Retains the "name the specific app you believe we duplicate" ask (appropriate for a Board appeal; omitted in the earlier Resolution Center reply). Canonical text lives in `docs/app-store-rejection-43a-response.md` § 11.3.
- **Submission history completed** — `docs/app-store-rejection-43a-response.md` § 7 now records the second (late-Apr) and third (2026-05-13) rejections and the 2026-05-05 resubmission, closing a ~5-week gap in the paper trail. § 11 records the verbatim 2026-05-13 message, the appeal rationale, the letter, tone notes, and the outcome-branching plan.
- **Living-spec delta** — `app-store-assets` gains a requirement that a versioned App Review Board appeal record exists when a 4.3(a) rejection survives a metadata-only response.
- **Core-doc sync** — `docs/current-story.md` rejection-history table and next-action pointer updated to reflect the third rejection and the escalation.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `app-store-assets`: ADD a requirement that the repository hold a versioned App Review Board appeal record (letter as submitted + verbatim rejection + outcome plan) once a 4.3(a) rejection survives a metadata-only response.

## Impact

- **No code changes.** No binary rebuild. No tests, Core Data, or service-layer impact.
- **Documents modified**: `docs/app-store-rejection-43a-response.md` (§ 7 history + new § 11 appeal), `docs/current-story.md` (rejection history + next action). New OpenSpec change dir.
- **External systems**: App Store Connect / Apple Developer App Review appeal form (user-executed). Build 141 stands ready on TestFlight if approval requires a build-selector update.
- **Decision reversed from parent change**: `reposition-app-store-listing` § 10 prescribed "reshoot screenshots and reply again." That path is explicitly closed here; see `docs/app-store-rejection-43a-response.md` § 11.
- **Fallbacks not chosen first**: the "Meet with Apple" appointment (live, Tue/Thu) and withdraw-and-refile-fresh (new submission ID) are documented as post-Board moves, not pre-Board moves.

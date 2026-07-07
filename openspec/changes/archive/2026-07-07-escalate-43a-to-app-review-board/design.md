## Context

The parent change `reposition-app-store-listing` bet that 4.3(a) was a positioning problem solvable with metadata surgery, backed by Apple Developer Forum precedent (772135, 771794) that metadata rewrites flip 4.3(a) in 1-3 rounds. We executed that bet in full on 2026-04-23. It failed twice on re-review. This change records the diagnosis that the bet was incomplete and the decision to escalate.

The decisive new evidence is the 2026-05-13 rejection text (verbatim in `docs/app-store-rejection-43a-response.md` § 11.1): identical boilerplate, opening "The issues we previously identified still need your attention," with a generic spam-factor resource list. Identical-boilerplate-on-re-review is the signature of a reviewer (or automated pass) not engaging with the listing — a non-engagement loop. Metadata is the wrong lever for a loop where the metadata is not being read.

## Goals / Non-Goals

**Goals:**
- File a formal App Review Board appeal that refutes Apple's four stated spam criteria point by point and proves differentiation with named competitors.
- Complete the submission-history paper trail (the second and third rejections were never recorded).
- Keep the canonical appeal text version-controlled before it reaches Apple, consistent with the parent change's "docs precede ASC" discipline.
- Leave a clear outcome-branching plan so the next session knows what to do on overturn / uphold / new-specifics / different-guideline.

**Non-Goals:**
- Any binary change, feature, or UI work. (If the Board raises a concrete functional overlap, that triages into a separate change.)
- Any further metadata edit — explicitly disproven.
- The iPad-optimization hypothesis (reviewed on iPad Air both times). Plausible contributing cause; deliberately deferred — the user chose the appeal path first and skipped the iPad check. Revisit only if the Board upholds.
- Executing the appeal submission itself (user-performed via the Apple web form). This change produces the text and the runbook.

## Decisions

### Decision 1: Appeal to the App Review Board, not another Resolution Center reply
**Choice**: File via developer.apple.com → Contact Us → App Review appeal form. Stop replying in the Resolution Center thread.
**Rationale**: A Board appeal routes to a different team than the original reviewer — the only written path that escapes the non-engagement loop on this submission ID. Another Resolution Center reply re-enters the same stuck thread.
**Alternatives considered**:
- *Reshoot screenshots + reply again* (parent change § 10): rejected. Disproven twice; the metadata is not being read.
- *Meet with Apple appointment*: strong, and Apple explicitly offered it. Held as the primary **fallback** if the Board upholds, because the written appeal creates a durable record first and does not consume a scheduled slot.
- *Withdraw and refile fresh* (new submission ID): held as a post-Board move; forfeits the appeal-in-progress and Resolution Center history if done first.

### Decision 2: Lead the appeal by refuting Apple's four stated criteria
**Choice**: Structure the letter as a point-by-point refutation of the spam-factor list (shared source / template / purchased template / multiple accounts), then differentiation.
**Rationale**: The criteria are objective and demonstrably inapplicable to forager. Refuting them reframes the appeal from a subjective "is it spam?" argument (which the Board can wave away with boilerplate) to an objective "does it meet these conditions? No" argument (which is much harder to dismiss).
**Alternatives considered**:
- *Lead with differentiation prose*: weaker opener; reads like the emotional "my app IS unique" appeals the Board sees constantly.

### Decision 3: Retain the "name the specific app" request
**Choice**: Keep the closing ask that, if the Board has identified a specific duplicative app, they name it.
**Rationale**: In a formal appeal this shifts the burden to the Board and reads as confidence. (The parent change omitted it from the Resolution Center reply, where it risked reading as deflection; the Board context is different.) User confirmed keeping it.
**Alternatives considered**:
- *Omit it*: safer-feeling but cedes the burden. Rejected.

### Decision 4: Complete the paper trail as part of this change
**Choice**: Backfill § 7 with the late-April and 2026-05-13 rejections and the 2026-05-05 resubmission; record the verbatim third rejection in § 11.1.
**Rationale**: A Board appeal's credibility rests on a clean, documented history. The repo had a ~5-week gap. The fix belongs with the escalation, not deferred.

## Risks / Trade-offs

- **Risk**: Board upholds with the same boilerplate. → **Mitigation**: documented outcome plan (§ 11.5) routes to the Meet with Apple appointment with this document as evidence.
- **Risk**: Board upholds but names a real overlap or functional concern. → **Mitigation**: treat as progress; triage the specific concern in a new change. The appeal explicitly invites this by asking them to name the app.
- **Risk**: The true cause is the iPad-Air presentation (scaled iPhone layout reads as generic), which the appeal does not address. → **Accepted for now**: user chose appeal-first and deferred the iPad check; revisit on uphold. Documented as a Non-Goal so it is not forgotten.
- **Trade-off**: Filing the appeal forecloses withdraw-and-refile-fresh until the Board responds. → **Accepted**: the durable written record and fresh-team routing outweigh the speed of a blind refile.
- **Trade-off**: Naming competitors in a formal appeal carries minor reputational exposure. → **Accepted**: same rationale as the parent change; the comparison is factual and the appeal is private to Apple.

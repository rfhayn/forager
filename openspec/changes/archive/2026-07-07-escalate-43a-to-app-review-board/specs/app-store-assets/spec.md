## ADDED Requirements

### Requirement: App Review Board appeal record exists when a 4.3(a) rejection survives a metadata-only response
When an App Store submission is rejected under Guideline 4.3(a) and a completed metadata-only response (revised name, subtitle, description, keywords, and screenshots) draws a repeat 4.3(a) determination on re-review, the repository SHALL hold a versioned App Review Board appeal record before the appeal is filed. The record SHALL live in `docs/app-store-rejection-43a-response.md` and SHALL contain the verbatim text of the rejection being appealed, the appeal letter exactly as submitted, and an outcome-branching plan covering overturn, uphold-with-boilerplate, uphold-with-new-specifics, and different-guideline cases.

#### Scenario: Appeal letter refutes the stated spam criteria
- **WHEN** a contributor reads the appeal letter in the record
- **THEN** the letter addresses each of guideline 4.3(a)'s stated spam factors (shared source code or assets, repackaged template, purchased third-party template, multiple similar apps across accounts) and states why it does not apply to the app

#### Scenario: Appeal letter proves differentiation with named comparisons
- **WHEN** a contributor reads the appeal letter
- **THEN** it names specific comparable apps with a concrete axis of comparison for each owned differentiator, rather than asserting uniqueness without evidence

#### Scenario: Submitted via the App Review Board form, not the Resolution Center
- **WHEN** the appeal is filed
- **THEN** it is submitted through the Apple Developer App Review appeal form (Contact Us → App Review), not as a reply in the Resolution Center thread of the stuck submission

#### Scenario: Submission history is complete before filing
- **WHEN** the appeal record is finalized
- **THEN** the document's submission-history section records every prior determination on the submission (date, guideline, reviewer device, build) with no undated gaps, so the appeal rests on a complete paper trail

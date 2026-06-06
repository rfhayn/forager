## Context

CloudKit's `NSPersistentCloudKitContainer` maintains a mirroring delegate that exports Core Data changes into CloudKit zones. On forager's dual-store + owner/member asymmetric architecture (ADR 008 M9.24), objects live in one of two persistent stores (`forager.sqlite` private, `forager_shared.sqlite` shared), and the mirroring delegate routes records into either the default private zone (`ownerName=__defaultOwner__`) or a CKShare-backed custom zone. An object that appears to belong to *both* zones — because Core Data assigned it to one store but its parent relationship points into another store — causes the mirroring delegate to fail initialization with error 134040 "Object graph corruption detected".

The failure is fatal for sync: no records export, no records import, CloudKit state diverges permanently from local state. The only user-visible recovery is an app reinstall.

Evidence captured 2026-04-21 10:30 on a device running v2.0 build 137 Debug:

```
A Core Data error occurred.
NSLocalizedFailureReason=Object graph corruption detected.
Objects related to '0xa38ee6e58b0f34e6
<x-coredata://C3E2EB60-9D6C-49F4-8BB9-FAB4576FEBC9/GroceryListItem/p20>'
are assigned to multiple zones:
  <CKRecordZoneID: zoneName=com.apple.core-data.cloudkit.zone,
   ownerName=__defaultOwner__>,
  <CKRecordZoneID: zoneName=com.apple.core-...  (truncated)
```

Session history (rich.log) shows the user was on the **owner device** (per ADR 008 M9.24: private store holds household data). The household was renamed on 2026-04-21 10:26:22 in preparation for the reposition-app-store-listing screenshot session; the error surfaced ~4 minutes later.

Grep reveals 11 production sites that construct `GroceryListItem(context:)` directly:

| File | Approximate line |
|---|---|
| `Services/GroceryListItemService.swift` | 130, 239 |
| `Services/MealPlanService.swift` | 959 |
| `Services/HouseholdService.swift` | 1357, 1972, 2167 |
| `Services/WeeklyListService.swift` | 93 |
| `Services/QuantityMergeService.swift` | 232 |
| `forager/Views/Grocery/WeeklyListsView.swift` | 222 |
| `forager/Views/Grocery/AddIngredientsToListView.swift` | 519 |

Each site follows the ADR 014 child-pattern (relate to parent, set `householdKey`, save). None call `context.assign(item, to: targetStore)` explicitly. Core Data is expected to infer store membership from relationships, but that inference runs at save time and can disagree with the zone the mirroring delegate has already chosen.

## Goals / Non-Goals

**Goals:**
- Eliminate the zone-conflict class of bugs at its root: at every `GroceryListItem(context:)` site, explicitly assign the object to the parent's persistent store before the first save.
- Apply the same audit + fix to `Ingredient` (same child pattern, same risk).
- Add a regression test that fails today on shared-store creation and passes after the fix.
- Detect and remediate the corrupted state on the user's device (at minimum: diagnose; ideally: auto-repair).
- Clarify ADR 014 so the invariant becomes impossible to miss in future code reviews.
- Ship a new binary (build 138+) to App Store Connect alongside the `reposition-app-store-listing` metadata rewrite.

**Non-Goals:**
- Converting all HouseholdScoped creation to route through `ManagedObjectFactory.make()`. The child pattern (inherit from parent) remains a valid ADR 014 path; we're fixing the store-assignment gap, not replacing the pattern.
- Fixing unrelated architectural drift discovered during audit (track separately).
- Any Core Data schema change. No v12 migration.
- CloudKit production schema changes (it's append-only per ADR 007).
- Retroactively changing the 4.3(a) response strategy. The reposition change remains metadata-only; this change ships as an incidental quality improvement in the same ASC submission.

## Decisions

### Decision 1: Explicit `context.assign(object, to: parentStore)` at each creation site

**Choice**: At every `GroceryListItem(context:)` and `Ingredient(context:)` production site, add an explicit `context.assign(item, to: parentStore)` call immediately after construction, where `parentStore` comes from the parent's `objectID.persistentStore`. Guard against the rare case where the parent has no store (brand-new unsaved object) by assigning to the first persistent store of the store coordinator as a fallback that mirrors current Core Data default behavior.

**Rationale**: Minimally invasive. The child pattern stays; we're making the store-assignment step that was implicit-and-unreliable into an explicit-and-correct one. Matches what `ManagedObjectFactory.make()` does internally via the same API (`context.assign`).

**Alternatives considered**:
- *Route everything through the factory*: invasive (services would need factory injection), violates ADR 014's current guidance that children can inherit from parents without factory. Deferred to a future harden change.
- *Set the parent relationship first, save, then set household / relationships*: the two-save pattern had historical issues with timing and doesn't solve the underlying assignment gap.
- *Use `NSPersistentStoreCoordinator.managedObjectModel` with per-configuration store URIs*: doesn't apply here; the dual-store config already exists.

### Decision 2: Ingredient audited in the same change

**Choice**: Include `Ingredient` creation sites in this change's scope. Don't defer.

**Rationale**: Same child pattern, same risk, same fix. Splitting into two changes doubles the review/test burden with no architectural benefit. Ingredient crashes are less user-visible today because most ingredient creation happens during recipe import (which runs in a fresh context), but the same latent risk exists.

**Alternatives considered**: a separate follow-up change for Ingredient. Rejected — no value from splitting.

### Decision 3: Runtime remediation — diagnose now, auto-repair deferred

**Choice**: For the 2026-04-21 rejection cycle, add a launch-time diagnostic that detects the "mirroring delegate failed with zone-assignment error" case and logs it to `DiagnosticLogger` with enough detail for us to triage (which entity, which zones). Do **not** attempt to auto-repair the corrupted object in this change — auto-repair is risky and needs its own design pass.

For the user's device specifically (where the error was observed), plan a manual cleanup sequence: (1) identify the specific GroceryListItem(s) in conflict via diagnostics, (2) delete locally via developer tools or a one-off launch flag, (3) verify sync resumes. Detailed runbook in tasks.md.

**Rationale**: The immediate goal is to make new builds not create new corrupted objects. Repairing pre-existing corruption is valuable but lower-urgency — and a badly-designed auto-repair could destroy user data worse than the bug. Defer to a follow-up change (`repair-cloudkit-zone-conflicts`) once we have production telemetry on how common this is.

**Alternatives considered**:
- *Delete all conflicting objects on next launch*: too aggressive; could lose data silently.
- *Wipe and re-sync from CloudKit*: only works if CloudKit's copy is clean (unclear), and destroys offline changes.
- *Ask user to confirm deletion via UI*: reasonable long-term but out of scope for this change.

### Decision 4: Architecture audit skill update

**Choice**: Extend `/architecture-audit` to flag `GroceryListItem(context:)` or `Ingredient(context:)` followed by a set of property assignments but no `context.assign(`. Treat test files as exempt (they use in-memory stores).

**Rationale**: The codebase has 11 production sites today. Prevent regression as new creation paths are added. The audit skill is the documented guardrail per ADR 014; this extends its coverage.

**Alternatives considered**: SwiftLint rule. Rejected — harder to configure for context-aware check; the architecture-audit skill already runs on PRs.

### Decision 5: Ship as binary change alongside reposition-app-store-listing

**Choice**: New build (137+1 = 138 or user's next CURRENT_PROJECT_VERSION bump) uploaded to ASC. Update the `reposition-app-store-listing` reply letter to mention "we also shipped a new build fixing a CloudKit sync issue our testing uncovered" as a one-line incidental addition.

**Rationale**: The 4.3(a) strategy was "metadata-only, no binary change" because *unneeded* binary changes introduce new rejection surface. A *needed* binary change that fixes a crash is different — Apple reviewers see attention-to-quality positively. The reply letter's core argument (functional differentiation) is unchanged.

**Alternatives considered**:
- *Ship the metadata change now, fix the bug in a later submission*: unacceptable. If Apple approves build 134, users hit the crash immediately. We'd have to pull it from sale.
- *Hold the metadata change until the bug is fixed*: delays the 4.3(a) response past Apple's typical reply window. Better to do both at once.

## Risks / Trade-offs

- **Risk**: The fix might introduce new test-context failures if test setup doesn't properly configure stores. → **Mitigation**: audit `foragerTests/Services/` base classes; most tests already use a single in-memory store where `context.assign()` is a no-op.
- **Risk**: Existing CloudKit state contains zone-conflicted records that survive the app-side fix (because the bad records are already in iCloud). → **Mitigation**: design.md § Remediation; plan the launch-time detection now, full auto-repair deferred to a separate change.
- **Risk**: A new build could introduce unrelated regressions that fail App Review for a different guideline. → **Mitigation**: scope this change narrowly (store-assignment only, no other touch-ups); run full test suite + smoke-test on device before upload.
- **Risk**: Assigning to `list.objectID.persistentStore` when `list` is a newly-created in-memory object (no store yet) → assign-to-nil. → **Mitigation**: fallback to coordinator's first store, matching current default behavior. Add assertion + log when falling back to catch regressions.
- **Risk**: Child `Ingredient` audit reveals creation paths that don't have a parent at creation time (e.g., during recipe-import batch processing). → **Mitigation**: for those paths, route through `ManagedObjectFactory.make()` with explicit scope (the path ADR 014 already allows).
- **Risk**: Running `architecture-audit` after the fix flags dozens of false-positives because of how the child pattern is written. → **Mitigation**: tune the audit rule to check for `context.assign` within ±10 lines of the `Entity(context:)` call.
- **Trade-off**: Not auto-repairing corrupted state means affected users (including dev) must manually intervene. → Accepted: safer than auto-repair; diagnostics give us a path.
- **Trade-off**: Extra `context.assign()` call at 11+ sites adds a small amount of boilerplate. → Accepted: the alternative (invisible-and-fragile) is worse.

## Migration Plan

1. **Investigation** — confirm hypothesis on the user's device: enable verbose CloudKit logging, reproduce the error, verify which GroceryListItem persistent ID is implicated. If the hypothesis is wrong, update design before writing code.
2. **Fix code at 11 production sites** — add explicit `context.assign()` at each `GroceryListItem(context:)` site. Audit `Ingredient(context:)` sites and apply the same pattern where applicable.
3. **Regression test** — add `GroceryListItemServiceTests.testNewItemInSharedStoreListLandsInSameStore()` that reproduces the cross-store creation path.
4. **Test pass** — run the full test suite; require green build.
5. **ADR 014 update** — clarify the child pattern with explicit `context.assign()` requirement and example.
6. **Architecture audit skill** — extend to detect the pattern.
7. **Device remediation** — on the dev's iPhone, identify GroceryListItem/p20 (and any other conflicted objects), delete locally, verify sync resumes.
8. **Build bump** — user bumps CURRENT_PROJECT_VERSION. Archive. TestFlight-distribute. Verify on device that CloudKit sync works end-to-end.
9. **ASC upload** — new build replaces build 134 in the v2.0 submission. 
10. **Update reply letter** — add one line to `docs/app-store-rejection-43a-response.md` referencing the crash fix.
11. **Resume reposition-app-store-listing** — screenshots + video + reply against the new build.

## Open Questions

- **Q1**: Does the corrupted state on the dev's device require intervention beyond a fresh install? If a fresh install pulls the bad state back from CloudKit, we need a CloudKit-side cleanup too. *Test: install the new build on a second device signed into the same iCloud; does sync come up clean?*
- **Q2**: Are there `Ingredient(context:)` sites in the recipe-import pipeline that don't have a parent at creation time (batch processing)? If so, those need `ManagedObjectFactory.make()` with explicit scope rather than parent inference. *Investigate during the code changes.*
- **Q3**: Is the architecture audit skill able to detect multi-line property configuration after `Entity(context:)` reliably? If false-positive rate is high, we may need to use a simpler rule. *Test the audit after updating.*
- **Q4**: Should the launch-time diagnostic be gated behind `#if DEBUG` or run in Release? Leaning toward Release — the diagnostic is just logging, and catching it in Release means affected users generate telemetry. *Decide before implementation.*

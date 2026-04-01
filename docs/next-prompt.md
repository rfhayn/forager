# Next Implementation Prompt

**Last Updated**: April 1, 2026
**Launch Path**: M18 (remaining) → FUI-1 → M9.28 → M7.7

---

## Active Milestones

### M18 — Store-Aware Shopping + Recipe Attribution
See `docs/next-prompt-M18.md` for full implementation guidance.

**All sub-milestones COMPLETE**: M18.1.0, M18.1.1, M18.1.2, M18.1.3, M18.1.4, M10.4.0

### FUI-1 — Dashboard, Navigation, Recipe UI
See `docs/next-prompt-FUI-1.md` for full implementation guidance.
**PRD**: `docs/prds/active/fui-1-dashboard-navigation-recipe-ui.md`

**Remaining**: FUI-1.7 (dashboard)

1. ~~**FUI-1.5** (Recipe computed properties)~~ — COMPLETE (861e86a)
2. ~~**FUI-1.4** (Recipe detail hero image + attribution)~~ — COMPLETE (e8f983e)
3. ~~**FUI-1.1** (Tab restructure 5→4)~~ — COMPLETE (5156954)
4. ~~**FUI-1.2** (Search relocation)~~ — COMPLETE
5. ~~**FUI-1.3** (Settings relocation)~~ — COMPLETE (built in FUI-1.1)
6. ~~**FUI-1.6** (Recipe grid/list toggle)~~ — COMPLETE (bdfedc3)
7. **FUI-1.7** (DashboardView) — needs FUI-1.2 + FUI-1.3, largest piece (~4-5h)

---

## Planned (Next Up)

### M9.28 — Remove Diagnostic Logging for Production

**PRD**: `docs/prds/active/m9.28-strip-diagnostic-logging.md`
**Estimated**: 1-2 hours

Gate DiagnosticLogger, DebugLogService behind `#if DEBUG`. Wrap ~106 caller-site `diag.*` and `DebugLogService.shared.log()` calls. Remove Settings > Diagnostics from Release. Keep CloudKitLogger OSLog calls.

**Conflict note**: Touches `SettingsView.swift` — run after M18.1.3 lands (also modifies SettingsView).

Key files:
- `Services/DiagnosticLogger.swift` — gate entire class
- `Services/DebugLogService.swift` — gate entire class
- `Services/Persistence/CloudKitLogger.swift` — gate DiagnosticLogger bridge only
- `Services/HouseholdService.swift` — 58 `diag.*` calls to wrap
- `Services/Import/RecipeImportService.swift` — 15 calls
- `forager/Views/Settings/SettingsView.swift` — gate `diagnosticLogSection`

---

### M7.7 — App Store Submission

**PRD**: `docs/prds/active/m7.7-app-store-submission.md` (audited April 1, 2026)
**Estimated**: 3-5h

Screenshots, metadata, landing page, README, App Store Connect, submission. Partly manual (screenshots, App Store Connect configuration). M7.7.1 (landing page) + M7.7.2 (README) can run in parallel. M7.7.3-4 need final build.

---

## Parallelism Reference

### Phase 1 — COMPLETE
All M18 sub-milestones + FUI-1.1, FUI-1.4, FUI-1.5, FUI-1.6 done.

### Phase 2 (now — parallel workers)
```
Worker A: FUI-1.2 (search relocation)     READY
Worker B: FUI-1.3 (settings relocation)   READY
```

### Phase 3 — FUI-1.7 (Dashboard, ~4-5h, needs FUI-1.2 + FUI-1.3)
### Phase 4 — Testing + M9.28 (strip logging, after testing)
### Phase 5 — PR + merge
### Phase 6 — M7.7 (App Store, last)

---

## Completed (Recent)

### M10.4.0 — Recipe Attribution Wiring
COMPLETE (April 1, 2026). imageURL + author persisted through both save paths (saveImport + replaceExistingRecipe), createRecipe, duplicateRecipe. 5 unit tests. Commit d5acc1f.

### M18.1.3 — Store Management UI
COMPLETE (April 1, 2026). ManageStoresView, AddStoreView, ForagerTheme+StoreColors, SettingsView integration, foragerApp StoreService wiring. Commit e9e5307.

### M18.1.0-M18.1.2 — Store Schema + Service + Snapshot Wiring
COMPLETE (April 1, 2026). Schema v11, StoreService (7 methods, 13 tests), store snapshot in 3 GroceryListItem creation paths.

### M16.9 — ML Model Retraining
COMPLETE (March 28, 2026). BiLSTM-CRF v2 deployed, parser fixes ported, 3 new test classes. PR #105 merged, build 91.

---

## Post-Launch Priorities

- M18.2: Multi-store + shopping trips (Phase 2)
- FUI-2: Meal planner calendar grid
- M10.4: Recipe import polish — history, telemetry (deferred)
- M6: Testing Foundation (12-18h)
- M9 Remaining (~120h)

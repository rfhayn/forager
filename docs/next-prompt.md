# Next Implementation Prompt

**Last Updated**: February 20, 2026
**For Milestone**: M15 ✅ COMPLETE → M7.5 → M9-prereqs → M8.4 → M7.7 → M6 → M9 → M10+
**Status**: M15 ✅ **ALL PHASES + BUG FIXES COMPLETE** | M7.5 📋 **NEXT** | M8.4 📋 **READY**
**Branch**: `feature/M15-ux-design-system` (local, not pushed — needs PR + squash merge)

---

## **STEP 0: MERGE M15 & PUSH TESTFLIGHT**

### **Merge M15 to Main**
```bash
git push -u origin feature/M15-ux-design-system
gh pr create --title "M15: UX Design System & Visual Refresh" --body "Complete visual refresh..."
gh pr merge --squash --delete-branch
git checkout main && git pull origin main
```

### **New TestFlight Build**
- Archive in Xcode (Product → Archive)
- Upload to App Store Connect
- Distribute to existing "Public Beta Testers" group
- Build number: 11, Version: 1.2 (bump from 1.1)

---

## **NEXT: M7.5 — Architecture Hardening (14-19h)**

**Status**: 📋 NEXT
**PRD**: `docs/prds/m7.5-architecture-hardening-ux-service-cleanup.md` (v2.0, refreshed Feb 20, 2026)
**Why first**: Cleans up service layer and navigation patterns, making everything after it cleaner

### **Phase 1: Service Ownership of Saves (8-10h)**
```
Branch: feature/M7.5-service-ownership
```
- Eliminate 35 production `context.save()` calls across 15 view files
- Create RecipeService, WeeklyListService; extend IngredientTemplateService
- Services accept `IngredientParsingService` via init (M8.4 forward-compat)
- Service unit tests (2.5h) + integration tests (1.5h) — 18-22 tests across 4 files

### **Phase 2: Navigation Cleanup (4-6h)**
```
Branch: feature/M7.5-navigation-cleanup
```
- Convert 3 highest-complexity views to enum routing (IngredientsView 8 booleans, CreateRecipeView 6, EditRecipeView 6)
- Descoped from 23 views — only 6+ boolean views warrant enum conversion

### **Phase 3: Tests & Polish (2-3h)**
```
Branch: feature/M7.5-invariant-tests
```
- 2 ad-hoc empty states → ContentUnavailableView
- 4-5 Core Data invariant tests with correct entity names

---

## **THEN: M9-prereqs → M8.4 ML-Powered Parsing (9h + 18-24h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md`

### **M9 Prerequisites (~9h, 3 sessions)**

#### M9.0 — Warning Resolution (2-3h)
```
Branch: feature/M9.0-warning-resolution
```
- Resolve all Xcode warnings — zero-warning baseline before adding CoreML

#### M9.1.2 — Centralize extractCleanIngredientName (2-3h)
```
Branch: feature/M9.1.2-centralize-extract-clean
```
- Exists in 3 files with diverging regex patterns → single utility function

#### M9.5-partial — Parser Dependency Injection (4h)
```
Branch: feature/M9.5-parser-di
```
- `IngredientParsingService` hardcodes `HybridIngredientParser()` → injectable via init
- Enables mock parsers in tests + ML parser A/B testing

### **M8.4 Phases (18-24h, 4 sessions)**

#### Phases 1+2 — Dataset Prep + Model Training (4h)
```
Branch: feature/M8.4-ml-parsing
```
- NYT (180k) + strangetom (81k) → unified BIO-tagged format → BiLSTM-CRF training

#### Phases 3+4 — CoreML Conversion + MLIngredientParser (3h)
- PyTorch → .mlpackage, implement `MLIngredientParser.swift`

#### Phases 5+6 — Integration + Test Suite (4h)
- Update `HybridIngredientParser` routing (regex → ML → NLP), 20+ test cases

#### Phases 7+8 — Continuous Learning + Documentation (3h)
- BIO export for retraining, integration testing, core doc updates

---

## **AFTER M8.4: M7.7 → M6 → M9 → M10+**

### **M7.7: App Store Submission (3-5h)**
```
Branch: feature/M7.7-app-store-submission
```
- Beta landing page, README update, App Store listing, submission
- Launches with ML parser in place for best first impression
- **PRD**: `docs/prds/active/m7.7-app-store-submission.md`

### **M6: Testing Foundation (20-30h)**
- 50%+ test coverage on critical services
- AI test reviewer on every PR
- CI/CD pipeline
- Protects quality before the big M9 refactor

### **M9 Remaining (~120h)**
- Phase 1 remaining: String utilities, performance, thread safety
- Phase 2: Service consistency, full DI, view decomposition (RecipeListView 1,204→400)
- Phase 3: Query optimization, batch ops, Category→Relationship migration
- Phase 4: Code standards, test coverage, logging
- **PRD**: `docs/prds/m9-technical-debt-codebase-optimization.md`

### **M10+: Analytics, Advanced Features**
- Usage statistics, recommendations, data export
- Recipe import, barcode scanning, store layouts, budgets

---

## **M15 Completion Summary**

All 8 phases + 7 bug fix commits delivered on `feature/M15-ux-design-system`:

| Phase | Description | Status |
|-------|-------------|--------|
| M15.1 | Design System Foundation & Liquid Glass TabView | ✅ COMPLETE |
| M15.2 | Color & Typography Migration | ✅ COMPLETE |
| M15.3 | Grocery Lists UX Overhaul | ✅ COMPLETE |
| M15.4 | Recipes UX Overhaul | ✅ COMPLETE |
| M15.5 | Meal Plans & Ingredients UX | ✅ COMPLETE |
| M15.5b | Settings, Categories & Household | ✅ COMPLETE |
| M15.6 | Liquid Glass Polish | ✅ COMPLETE |
| M15.7 | Dark Mode, Accessibility & Final QA | ✅ COMPLETE |
| Bug fixes | 7 commits: structured qty, redundant displays, strikethrough, dark mode, template sanitization, category refresh, code review, pluralization | ✅ COMPLETE |

---

**Version**: February 20, 2026 - M15 COMPLETE with bug fixes, M8.4 PRD ready
**Dependencies**: M15.1-M15.7 ✅, TestFlight live (build 10, v1.1), M8.4 PRD at docs/prds/active/m8.4-ml-powered-parsing.md

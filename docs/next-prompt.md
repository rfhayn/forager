# Next Implementation Prompt

**Last Updated**: February 21, 2026
**For Milestone**: M9.0 ✅ COMPLETE → M9.1.2 → M9.5-partial → M8.4 → M7.7 → M6 → M9 → M10+
**Status**: M9.0 ✅ **COMPLETE** | M9.1.2 📋 **NEXT** | M8.4 📋 **READY**
**Branch**: `main` (M9.0 merged via PR #41)

---

## **NEXT: M9-prereqs — Extract Clean, Parser DI (~8h remaining)**

**Status**: 📋 NEXT (M9.0 done, 2 of 3 prereqs remaining)
**Why first**: Centralized parsing utilities before adding CoreML model

### ~~**M9.0 — Warning Resolution**~~ ✅ COMPLETE (Feb 21, <1h)
- Zero-warning baseline achieved — 18 warnings resolved across 7 files
- PR #41 merged to main

### **M9.1.2 — Centralize extractCleanIngredientName (2-3h)**
```
Branch: feature/M9.1.2-centralize-extract-clean
```
- Exists in 3 files with diverging regex patterns → single utility function

### **M9.5-partial — Parser Dependency Injection (4h)**
```
Branch: feature/M9.5-parser-di
```
- `IngredientParsingService` hardcodes `HybridIngredientParser()` → injectable via init
- Enables mock parsers in tests + ML parser A/B testing

---

## **THEN: M8.4 ML-Powered Parsing (18-24h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md`

### **Phases 1+2 — Dataset Prep + Model Training (4h)**
```
Branch: feature/M8.4-ml-parsing
```
- NYT (180k) + strangetom (81k) → unified BIO-tagged format → BiLSTM-CRF training

### **Phases 3+4 — CoreML Conversion + MLIngredientParser (3h)**
- PyTorch → .mlpackage, implement `MLIngredientParser.swift`

### **Phases 5+6 — Integration + Test Suite (4h)**
- Update `HybridIngredientParser` routing (regex → ML → NLP), 20+ test cases

### **Phases 7+8 — Continuous Learning + Documentation (3h)**
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
- **PRD**: `docs/prds/active/m9-technical-debt-codebase-optimization.md`

### **M10+: Analytics, Advanced Features**
- Usage statistics, recommendations, data export
- Recipe import, barcode scanning, store layouts, budgets

---

## **M7.5 Completion Summary**

All 3 phases delivered on `feature/M7.5-service-ownership`:

| Phase | Description | Commits | Key Changes |
|-------|-------------|---------|-------------|
| Phase 1: Service Ownership | f1b96aa, a227b4c, 24595a8, cf81f65 | 4 | 3 new services + 24 unit tests + integration tests + 35 direct saves eliminated from 13 views |
| Phase 2: Navigation Cleanup | ea75dcf | 1 | 3 views converted to enum-based sheet/alert routing |
| Phase 3: Tests & Polish | b913fe3 | 1 | 2 empty states → ContentUnavailableView + 5 Core Data invariant tests |

Total commits on branch: 6

---

**Version**: February 21, 2026 - M9.0 COMPLETE, M9.1.2 next
**Dependencies**: M9.0 ✅ (zero warnings), M7.5 ✅, TestFlight live (build 10, v1.1), M8.4 PRD at docs/prds/active/m8.4-ml-powered-parsing.md

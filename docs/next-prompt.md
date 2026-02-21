# Next Implementation Prompt

**Last Updated**: February 21, 2026
**For Milestone**: M9.5-partial ✅ COMPLETE → M8.4 → M7.7 → M6 → M9 → M10+
**Status**: M9.5-partial ✅ **COMPLETE** | M8.4 📋 **NEXT** | All M8.4 prerequisites done
**Branch**: `main` (after M9.5 PR merges)

---

## ✅ **M9.5-partial — Parser Dependency Injection — COMPLETE**

**Status**: ✅ COMPLETE (February 21, 2026, ~3h)
**Branch**: `feature/M9.5-parser-di` (PR pending)

All M8.4 prerequisites are now complete. Parser construction is injectable with backward-compatible defaults.

### **M9 Prerequisites Summary**

| Prereq | Status | Actual |
|--------|--------|--------|
| M9.0: Warning Resolution | ✅ COMPLETE | <1h |
| M9.1.2: Centralize extractCleanIngredientName | ✅ COMPLETE | ~2h |
| M9.5-partial: Parser DI | ✅ COMPLETE | ~3h |

---

## **NEXT: M8.4 ML-Powered Parsing (18-24h)**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md`

### **Phases 1+2 — Dataset Prep + Model Training (4h)**
```
Branch: feature/M8.4-ml-parsing
```
- NYT (180k) + strangetom (81k) → unified BIO-tagged format → BiLSTM-CRF training

### **Phases 3+4 — CoreML Conversion + MLIngredientParser (3h)**
- PyTorch → .mlpackage, implement `MLIngredientParser.swift`

### **Phases 5+6 — Integration + Test Suite (4h)**
- Add `mlParser:` to HybridIngredientParser init (slot prepared by M9.5-partial)
- Update routing (regex → ML → NLP), 20+ test cases

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

**Version**: February 21, 2026 - M9.5-partial COMPLETE, M8.4 NEXT
**Dependencies**: M9.0 ✅, M9.1.2 ✅, M9.5-partial ✅, M7.5 ✅, TestFlight live (build 10, v1.1), M8.4 PRD at docs/prds/active/m8.4-ml-powered-parsing.md

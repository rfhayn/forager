# Next Implementation Prompt

**Last Updated**: February 21, 2026
**For Milestone**: M9.1.2 ✅ COMPLETE → M9.5-partial → M8.4 → M7.7 → M6 → M9 → M10+
**Status**: M9.1.2 ✅ **COMPLETE** | M9.5-partial 📋 **NEXT** | M8.4 📋 **READY**
**Branch**: `main` (after M9.1.2 PR merges)

---

## **NEXT: M9.5-partial — Parser Dependency Injection (~4h)**

**Status**: 📋 NEXT (M9.0 + M9.1.2 done, last prereq before M8.4)
**Why first**: Testable, swappable parsers before adding CoreML model
**PRD**: `docs/prds/active/m9-technical-debt-codebase-optimization.md` (M9.5-partial section)

```
Branch: feature/M9.5-parser-di
```

### **Phase A: HybridIngredientParser DI (45 min)**
- Add init parameters: `regexParser: IngredientParser`, `nlpParser: IngredientParser`, `regexConfidenceThreshold: Float`
- All with defaults (backward compatible, zero call site changes)
- Change `private static let regexConfidenceThreshold` → instance property from init

### **Phase B: IngredientParsingService DI (30 min)**
- Add `parser: IngredientParser` parameter to init with default `HybridIngredientParser()`
- Static `extractCleanIngredientName()` unchanged (keeps own sharedParser)

### **Phase C: MockIngredientParser + Routing Tests (1h)**
- Create `foragerTests/Mocks/MockIngredientParser.swift` — configurable results, call counting
- Create `foragerTests/Services/Parsing/HybridParserRoutingTests.swift` — 5+ routing tests
- Tests: high-confidence short-circuit, low-confidence fallback, threshold config, tie handling
- Must add both files to pbxproj (manual PBXGroup for test target)

### **Phase D: Update Existing Test Files (45 min)**
- Existing tests should compile unchanged (defaults). Verify all 146+ pass.
- Add mock-based test in RecipeServiceTests showing parser injection works

### **Phase E: QuantityMigrationService Update (15 min)**
- Accept `IngredientParsingService` via init (currently creates own)
- Update `foragerApp.swift` to pass shared instance

### **Phase F: Build Verification + Documentation (30 min)**
- Zero-warning build, all tests pass
- Update insights log, development journal, core docs
- Commit and PR

### **Key Cross-Reference: M8.4 Impact**
After M9.5-partial, M8.4 Phase 5 will:
- Add optional `mlParser: IngredientParser?` parameter to `HybridIngredientParser.init`
- Pass `regexConfidenceThreshold: 0.9` (raised from default 0.8)
- Update `parse()` routing: regex → ML → NLP (3-tier)
- Use `MockIngredientParser` from Phase C for router testing

### **M9 Prerequisites Summary**

| Prereq | Status | Actual |
|--------|--------|--------|
| M9.0: Warning Resolution | ✅ COMPLETE | <1h |
| M9.1.2: Centralize extractCleanIngredientName | ✅ COMPLETE | ~2h |
| **M9.5-partial: Parser DI** | **📋 NEXT** | **~4h est** |

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

**Version**: February 21, 2026 - M9.1.2 COMPLETE, M9.5-partial NEXT
**Dependencies**: M9.0 ✅, M9.1.2 ✅, M7.5 ✅, TestFlight live (build 10, v1.1), M8.4 PRD at docs/prds/active/m8.4-ml-powered-parsing.md

# Next Implementation Prompt

**Last Updated**: February 7, 2026
**For Milestone**: M8.2 - Telemetry Analysis & Strategy
**Status**: READY TO START
**Prerequisite**: Merge M8.1 PR to main first
**PRD**: `docs/prds/m8-ingredient-parsing-intelligence-meta-prd.md`

---

## **M8.2: TELEMETRY ANALYSIS & STRATEGY**

### **Goal**
Analyze real parsing telemetry data collected by M8.1's ParsingTelemetryService to identify the most impactful failure patterns and create a prioritized implementation strategy for M8.3.

### **Prerequisites**
- M8.1 merged to main ✅
- Telemetry data collected from real usage (ParsingTelemetryService)
- Some recipes created/used to generate parsing events

### **Phase 1: Dashboard View (1 hour)**

**M8.2.1: Telemetry Dashboard**
- Create a simple view accessible from Settings
- Display statistics from `ParsingTelemetryService.shared.getStatistics()`
  - Total parsing events
  - Low-confidence count and rate
  - Total user corrections
  - Most common failure patterns
- Display recent low-confidence events from `getLowConfidenceEvents()`
- Group failures by pattern type (no quantity, range, non-numeric phrase, etc.)

**Key files:**
- `Services/ParsingTelemetryService.swift` — already has `getStatistics()` and `getLowConfidenceEvents()` APIs
- New: `forager/TelemetryDashboardView.swift`

### **Phase 2: Pattern Analysis (30 min)**

**M8.2.2: Failure Pattern Categorization**
- Analyze telemetry data to identify top failure patterns
- Categorize by type:
  - Range patterns: "2-3 cloves"
  - Non-numeric quantities: "a pinch of", "a handful"
  - No quantity: "salt to taste", "pepper as needed"
  - Parenthetical: "1 can (14.5 oz)"
  - Qualifier phrases: "garlic, minced"
- Rank by frequency and user correction rate

### **Phase 3: Strategy Document (30 min)**

**M8.2.3: M8.3 Implementation Strategy**
- Create prioritized list of patterns for M8.3 Hybrid NLP Parser
- Calculate ROI: effort to implement vs frequency of occurrence
- Determine which patterns can be handled by improved regex vs NLP
- Document in `docs/prds/m8.3-implementation-strategy.md`

### **Exit Criteria**
- [ ] Dashboard view showing telemetry statistics
- [ ] Top 10 failure patterns identified and ranked
- [ ] Clear strategy for M8.3 (which patterns to tackle, regex vs NLP)
- [ ] ROI analysis documenting effort vs impact

### **Estimated Time**: 2 hours

---

## **KEY FILES FOR CONTEXT**

```
Services/ParsingTelemetryService.swift     # Has getStatistics(), getLowConfidenceEvents()
Services/IngredientParsingService.swift    # Logs events to telemetry
forager/RecipeListView.swift               # Yellow badges on low-confidence ingredients
forager/GroceryListDetailView.swift        # Yellow badges in grocery list
foragerTests/Services/ParsingTelemetryServiceTests.swift  # 20/20 tests
```

---

## **AFTER M8.2**

### **M8.3: Hybrid NLP Parser (8-10 hours)**
- Protocol-based parser abstraction
- RegexIngredientParser (extract existing logic)
- NLPIngredientParser using Apple NaturalLanguage
- Pattern-specific handlers based on M8.2 analysis
- Target: 95% → 98%+ accuracy

### **Pre-Launch Roadmap**

| Task | Status | Est. Hours |
|------|--------|------------|
| M8.1: Parsing Resilience & Telemetry | ✅ COMPLETE | ~3h |
| **M8.2: Telemetry Analysis** | 🚀 NEXT | 2h |
| M8.3: Hybrid NLP Parser | 📋 PLANNED | 8-10h |
| M7.6: External TestFlight | 📋 PLANNED | 2-3h |
| M7.7: App Store Submission | 📋 PLANNED | 2-3h |

---

**Version**: February 7, 2026 - M8.2 Ready
**Dependencies**: M8.1 complete, telemetry collecting data

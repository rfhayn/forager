# Next Implementation Prompt

**Last Updated**: February 5, 2026
**For Milestone**: M8.1 - Parsing Resilience & Telemetry
**Status**: READY TO START
**Prerequisites**: M7.4 merged to main ✅
**Branch**: `feature/M8.1-parsing-resilience-telemetry`
**PRD**: `docs/prds/m8-ingredient-parsing-intelligence-meta-prd.md` (M8.1 section)

---

## **M8.1: PARSING RESILIENCE & TELEMETRY**

**Goal**: Professional UX for parsing failures + telemetry to understand real user patterns.

**Estimated Time**: 3-4 hours

**Pre-Implementation Audit**: ✅ COMPLETE (see PRD for details)

### **Core Features**

1. **Yellow Badge for Low Confidence** (parseConfidence < 0.5)
   - Visual indicator on ingredient rows in RecipeDetailView
   - Existing partial implementation in GroceryListItemRow to update

2. **EditIngredientSheet**
   - Context menu → "Edit Ingredient"
   - Pre-filled with parsed values
   - User corrections feed telemetry

3. **ParsingTelemetryService**
   - Log parsing events to local JSON
   - Track: raw input, parsed result, confidence, user edits
   - Foundation for M8.2 analysis

### **Key Files to Modify**

| File | Location | Action |
|------|----------|--------|
| `RecipeListView.swift` | Lines 1132+ | Add yellow badge to ingredientRowView() |
| `GroceryListDetailView.swift` | Lines 657+ | Update existing indicator |
| NEW `EditIngredientSheet.swift` | - | Create sheet for editing |
| NEW `ParsingTelemetryService.swift` | Services/ | Telemetry logging |

### **Git Workflow**

```bash
git checkout main && git pull origin main
git checkout -b feature/M8.1-parsing-resilience-telemetry
git push -u origin feature/M8.1-parsing-resilience-telemetry
```

### **Exit Criteria**

- [ ] Yellow badge visible on low-confidence ingredients
- [ ] Context menu "Edit Ingredient" opens EditIngredientSheet
- [ ] User edits save correctly and update UI
- [ ] Telemetry logs parsing events to JSON file
- [ ] Zero regressions in existing parsing behavior

---

## **PRE-LAUNCH ROADMAP**

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.3.4: Error Handling | ✅ COMPLETE | - |
| M7.4: UI Polish & Pre-Launch Fixes | ✅ COMPLETE | ~4h |
| **M8.1: Parsing Resilience & Telemetry** | 🚀 NEXT | 3-4h |
| M8.2: Telemetry Analysis | 📋 PLANNED | 2h |
| M8.3: Hybrid NLP Parser | 📋 PLANNED | 8-10h |
| M7.6: External TestFlight | 📋 PLANNED | 2-3h |
| M7.7: App Store Submission | 📋 PLANNED | 2-3h |

---

## **KEY CONTEXT FOR M8.1**

### **Existing Infrastructure**

- `parseConfidence` field exists on both `Ingredient` and `GroceryListItem` entities
- `notes` field exists on `Ingredient` for storing original text
- `IngredientParsingService` handles all parsing
- GroceryListItemRow already has partial confidence indicator (lines 684-692)

### **Views That Need Yellow Badge**

1. **RecipeDetailView** (inside RecipeListView.swift:1132)
   - Primary target - ingredient rows need badge + context menu

2. **GroceryListItemRow** (GroceryListDetailView.swift:657)
   - Already has partial implementation - needs update

### **Views to SKIP**

- CreateRecipeView / EditRecipeView - use inline editing, badges don't apply

---

**Version**: February 5, 2026 - M8.1 Ready
**Dependencies**: M7.4 merged to main

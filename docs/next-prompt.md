# Next Implementation Prompt

**Last Updated**: February 7, 2026
**For Milestone**: M8.1 - Parsing Resilience & Telemetry
**Status**: USER TESTING PHASE
**Branch**: `feature/M8.1-parsing-resilience-telemetry`
**PRD**: `docs/prds/m8-ingredient-parsing-intelligence-meta-prd.md`

---

## **M8.1: CURRENT STATE**

### **Core Implementation: COMPLETE ✅**

All code is written and committed. Ready for user testing.

| Feature | Status | Location |
|---------|--------|----------|
| ParsingTelemetryService | ✅ COMPLETE | `Services/ParsingTelemetryService.swift` |
| Unit tests (20/20 passing) | ✅ COMPLETE | `foragerTests/Services/ParsingTelemetryServiceTests.swift` |
| Yellow badge (Recipes) | ✅ COMPLETE | `forager/RecipeListView.swift` |
| Yellow badge (Grocery) | ✅ COMPLETE | `forager/GroceryListDetailView.swift` |
| Context menu editing | ✅ COMPLETE | `forager/RecipeListView.swift` |
| EditIngredientSheet | ✅ COMPLETE | `forager/EditIngredientSheet.swift` |
| Telemetry integration | ✅ COMPLETE | `Services/IngredientParsingService.swift` |
| Sample test recipes | ✅ COMPLETE | 3 recipes with low-confidence ingredients |

### **Remaining Work**

1. **User Testing**
   - Run app on device
   - Create test recipes (Recipes → ⋯ → Create Test Recipes)
   - Verify yellow badges appear on recipes 12-14
   - Add low-confidence ingredients to grocery list
   - Verify badges appear in grocery list view
   - Test context menu → Edit Ingredient → EditIngredientSheet

2. **Final Steps After Testing**
   - Any UI tweaks based on feedback
   - Merge PR to main: `gh pr merge --squash --delete-branch`

---

## **HOW TO TEST LOW-CONFIDENCE BADGES**

### **Step 1: Create Test Recipes**
1. Run app on device
2. Go to **Recipes** tab
3. Tap menu (⋯) → **Create Test Recipes**
4. Creates 14 recipes (11 existing + 3 new with low-confidence)

### **Step 2: View Yellow Badges in Recipes**
Open these recipes to see yellow ⚠️ badges:
- **Recipe 12: Simple Seasoned Rice** - "salt to taste", "pepper as needed", etc.
- **Recipe 13: Rustic Garlic Bread** - "butter as desired", "2-3 cloves garlic", etc.
- **Recipe 14: Quick Avocado Toast** - "salt and pepper to taste", "a drizzle of olive oil", etc.

### **Step 3: View Yellow Badges in Grocery List**
1. Open a recipe with low-confidence ingredients
2. Add ingredients to a grocery list
3. Go to **Lists** tab → Open the list
4. Low-confidence items show yellow ⚠️ badge

### **Step 4: Test Edit Flow**
1. Long-press on an ingredient in a recipe
2. Tap "Edit Ingredient" from context menu
3. EditIngredientSheet opens with parsed values
4. Make changes and save
5. Badge should disappear (parseConfidence = 1.0 after manual edit)

---

## **LOW-CONFIDENCE EXAMPLES**

These patterns get `parseConfidence < 0.5`:

| Input | Confidence | Reason |
|-------|------------|--------|
| "salt to taste" | 0.0 | No numeric quantity |
| "pepper as needed" | 0.0 | No numeric quantity |
| "a pinch of saffron" | 0.3 | Non-numeric quantity phrase |
| "some butter" | 0.0 | No quantity |
| "2-3 cloves garlic" | 0.3 | Range not parseable to single number |
| "a handful of parsley" | 0.3 | Non-numeric quantity phrase |
| "fresh herbs to garnish" | 0.0 | No quantity |

---

## **COMMITS ON BRANCH**

```
731b212 M8.1: Add ParsingTelemetryService test plan
963bd78 M8.1: Add XCTest unit tests for ParsingTelemetryService
32498b2 M8.1: Add missing Info.plist files for test targets
7b797c8 M8.1: Add test isolation and fix async race conditions
759628a M8.1: Add EditIngredientSheet and yellow badge UI
0fb1c88 M8.1: Add yellow badge to grocery list and sample low-confidence recipes
```

---

## **AFTER M8.1 MERGES**

### **Next: M8.2 Telemetry Analysis (2h)**
- Dashboard view for viewing telemetry data
- Statistics display (total events, low-confidence rate, corrections)
- Export functionality for analysis

### **Pre-Launch Roadmap**

| Task | Status | Est. Hours |
|------|--------|------------|
| **M8.1: Parsing Resilience & Telemetry** | 🔄 USER TESTING | 3-4h |
| M8.2: Telemetry Analysis | 📋 PLANNED | 2h |
| M8.3: Hybrid NLP Parser | 📋 PLANNED | 8-10h |
| M7.6: External TestFlight | 📋 PLANNED | 2-3h |
| M7.7: App Store Submission | 📋 PLANNED | 2-3h |

---

## **KEY FILES FOR CONTEXT**

If picking up from previous session, these are the key M8.1 files:

```
Services/ParsingTelemetryService.swift     # Telemetry logging service
Services/IngredientParsingService.swift    # Modified - logs to telemetry
forager/EditIngredientSheet.swift          # NEW - structured edit form
forager/RecipeListView.swift               # Yellow badge + context menu
forager/GroceryListDetailView.swift        # Yellow badge in list view
foragerTests/Services/ParsingTelemetryServiceTests.swift  # 20/20 tests
```

---

**Version**: February 7, 2026 - M8.1 User Testing Phase
**Dependencies**: All code complete, awaiting user validation

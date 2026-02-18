# Next Implementation Prompt

**Last Updated**: February 17, 2026
**For Milestone**: M15 — UX Design System & Visual Refresh
**Status**: M15.1 ✅ | M15.2 ✅ | M15.3 ✅ | M15.4 ✅ | M15.5 ✅ | M15.5b ✅ | M15.6 🚀 **NEXT** | M7.7 📋 **QUEUED**
**Branch**: `feature/M15-ux-design-system` (local, not pushed)

---

## **M15.6: LIQUID GLASS POLISH & APP ICON**

### **Context**
- M15.1-M15.5b complete: ForagerTheme tokens, Liquid Glass TabView, color migration, grocery/recipe/meal plan/ingredients/settings/categories/household UX overhaul
- All shared components available: ForagerCard, FilterPill, ForagerSectionHeader, ForagerButtonStyles, ForagerProgressRing, etc.
- iOS 26 deployment target already set (M15.1)

### **Implementation Plan**
Read the detailed plan before starting: `docs/prds/active/plans/m15.6-implementation-plan.md`

### **All Reference Docs**
```
docs/prds/active/plans/m15.6-implementation-plan.md  # DETAILED PLAN — read this first
docs/prds/active/m15-ux-design-system.md               # Full PRD v1.2
docs/mockups/forager-design-system.html                 # 16 phone-frame mockups
```

### **M15.6 Scope (from PRD)**
- Glass card modifiers + shadow removal
- Per-screen glass application (grocery, recipe, meal plan, ingredients)
- Button glass styling evaluation
- Tab bar refinement
- Layered app icon via Icon Composer

### **Key Files (will be modified)**
```
forager/ForagerCard.swift             # Glass card modifier
forager/WeeklyListsView.swift        # Glass on grocery cards
forager/GroceryListDetailView.swift   # Glass on sticky bar
forager/RecipeListView.swift          # Glass on recipe cards
forager/MealPlanListView.swift        # Glass on meal plan cards
forager/MealPlanDetailView.swift      # Glass on day cards
forager/ForagerTheme.swift            # Glass-related tokens
```

### **Continues on Same Branch**
```
# Already on feature/M15-ux-design-system
git log --oneline  # Should show M15.1-M15.5b commits
```

---

## **QUEUED: M7.7 — App Store Submission & Public Presence**

**Status**: 📋 READY (after M15 + TestFlight push)
**PRD**: `docs/prds/active/m7.7-app-store-submission.md`
**Estimated**: 3-5 hours

After M15 implementation:
1. Build new archive with M15 visual refresh
2. Push to TestFlight for final validation
3. Execute M7.7 (landing page, README, App Store listing, submit)

---

**Version**: February 17, 2026 - M15.6 implementation ready
**Dependencies**: M15.1 ✅, M15.2 ✅, M15.3 ✅, M15.4 ✅, M15.5 ✅, M15.5b ✅, TestFlight live (build 10, v1.1)

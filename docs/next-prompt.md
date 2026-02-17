# Next Implementation Prompt

**Last Updated**: February 17, 2026
**For Milestone**: M15 — UX Design System & Visual Refresh
**Status**: M15.1 ✅ | M15.2 ✅ | M15.3 🚀 **NEXT** | M7.7 📋 **QUEUED**
**Branch**: `feature/M15-ux-design-system` (local, not pushed)

---

## **M15.3: GROCERY LISTS UX OVERHAUL**

### **Context**
- M15.1 complete: ForagerTheme tokens, Liquid Glass TabView, iOS 26 deployment target
- M15.2 complete: ~300+ color/radius/typography replacements across ~25 files
- 6 files explicitly deferred to M15.3-M15.5 (RecipeListView, WeeklyListsView, GroceryListDetailView, MealPlanDetailView, MealPlanListView, IngredientsView)
- All non-skipped `.foregroundColor()` calls eliminated from codebase

### **Implementation Plan**
Read the detailed plan before starting: `docs/prds/active/plans/m15.3-implementation-plan.md`

### **All Reference Docs**
```
docs/prds/active/plans/m15.3-implementation-plan.md  # DETAILED PLAN — read this first
docs/prds/active/m15-ux-design-system.md              # Full PRD v1.2
docs/mockups/forager-design-system.html                # 16 phone-frame mockups
```

### **M15.3 Scope (from PRD)**
- Shared components: ForagerCard, ProgressRing, SectionHeader, CategoryChipPills, FilterPill, ButtonStyles
- Card-based list overview with progress rings
- Sticky bottom progress bar + quick-add
- Collapsible category sections with auto-collapse
- Check-off haptics + animation
- 100% completion celebration

### **Key Files (will be rewritten)**
```
forager/WeeklyListsView.swift          # Card-based list overview
forager/GroceryListDetailView.swift    # Category sections, check-off, progress bar
```

### **Continues on Same Branch**
```
# Already on feature/M15-ux-design-system
git log --oneline  # Should show M15.1 + M15.2 commits
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

**Version**: February 17, 2026 - M15.3 implementation ready
**Dependencies**: M15.1 ✅, M15.2 ✅, TestFlight live (build 10, v1.1)

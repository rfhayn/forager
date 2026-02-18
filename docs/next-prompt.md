# Next Implementation Prompt

**Last Updated**: February 17, 2026
**For Milestone**: M15 — UX Design System & Visual Refresh
**Status**: M15.1 ✅ | M15.2 ✅ | M15.3 ✅ | M15.4 ✅ | M15.5 ✅ | M15.5b 🚀 **NEXT** | M7.7 📋 **QUEUED**
**Branch**: `feature/M15-ux-design-system` (local, not pushed)

---

## **M15.5b: SETTINGS, CATEGORIES & HOUSEHOLD VISUAL REDESIGN**

### **Context**
- M15.1-M15.5 complete: ForagerTheme tokens, Liquid Glass TabView, color migration, grocery/recipe/meal plan/ingredients UX overhaul
- Core Data v6 migration complete (quickOption on PlannedMeal)
- Shared components from M15.3 available: ForagerCard, FilterPill, ForagerSectionHeader, ForagerButtonStyles, etc.

### **Implementation Plan**
Read the detailed plan before starting: `docs/prds/active/plans/m15.5b-implementation-plan.md`

### **All Reference Docs**
```
docs/prds/active/plans/m15.5b-implementation-plan.md  # DETAILED PLAN — read this first
docs/prds/active/m15-ux-design-system.md               # Full PRD v1.2
docs/mockups/forager-design-system.html                 # 16 phone-frame mockups
```

### **M15.5b Scope (from PRD)**
- Extract HouseholdView from SettingsView with sync indicator + stats + Danger Zone
- SettingsView restructure with NavigationLink to HouseholdView + version footer
- ManageCategoriesView: nav bar "+", Uncategorized lock icon, footer text

### **Key Files (will be modified)**
```
forager/SettingsView.swift            # Restructure with NavigationLink to Household
forager/HouseholdMembersView.swift    # May be folded into HouseholdView
forager/ManageCategoriesView.swift    # Nav bar +, lock icon, footer
```

### **Continues on Same Branch**
```
# Already on feature/M15-ux-design-system
git log --oneline  # Should show M15.1-M15.5 commits
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

**Version**: February 17, 2026 - M15.5b implementation ready
**Dependencies**: M15.1 ✅, M15.2 ✅, M15.3 ✅, M15.4 ✅, M15.5 ✅, TestFlight live (build 10, v1.1)

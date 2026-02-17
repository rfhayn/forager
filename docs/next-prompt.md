# Next Implementation Prompt

**Last Updated**: February 17, 2026
**For Milestone**: M15 — UX Design System & Visual Refresh
**Status**: M15 🚀 **ACTIVE** | M7.7 📋 **QUEUED**
**Branch**: `main` (create feature branch for M15.1)

---

## **M15.1: DESIGN SYSTEM FOUNDATION & LIQUID GLASS TABVIEW**

### **Context**
- M7.6 complete: TestFlight live (build 10, v1.1), external testers active
- M15 planning complete: 8 detailed implementation plans, cross-validated against codebase, reviewed by Gemini + ChatGPT
- TestFlight link shared on LinkedIn (Feb 17, 2026)
- After M15: new TestFlight push → M7.7 App Store submission

### **Implementation Plan**
Read the detailed plan before starting: `docs/prds/active/plans/m15.1-implementation-plan.md`

### **All Reference Docs**
```
docs/prds/active/plans/m15.1-implementation-plan.md  # DETAILED PLAN — read this first
docs/prds/active/m15-ux-design-system.md              # Full PRD v1.2
docs/prds/active/m15-design-review-action-plan.md     # Completed 5-phase review
docs/mockups/forager-design-system.html                # 16 phone-frame mockups
docs/architecture/011-tab-architecture-reduction.md    # 6→5 tab reduction ADR
docs/learning-notes/32-m15-css-design-system-dark-mode.md
docs/learning-notes/33-m15-ux-design-decisions.md
```

### **M15.1 Sub-Phases (from implementation plan)**
- **A**: ForagerTheme.swift + raise deployment target to iOS 26 (~1.5-2h)
- **B**: NavigationTab enum migration to 5-tab structure (~0.5h)
- **C**: Replace CustomBottomNavigation with Liquid Glass TabView (~2-2.5h)
- **D**: Coach mark system update for 5-tab navigation (~1-1.5h)
- **E**: Settings — add Ingredients & Categories links (~1-1.5h)
- **F**: Cleanup, documentation & final verification (~1-1.5h)

### **Branch**
```
git checkout -b feature/M15.1-design-system-foundation
```

### **Key Files**
```
forager/CustomBottomNavigation.swift    # WILL BE DELETED in M15.1
forager/HamburgerMenuView.swift        # WILL BE DELETED in M15.1
forager/foragerApp.swift                # TabView + NavigationTab enum
forager/ForagerTheme.swift              # NEW — design token system
forager/Assets.xcassets/Colors/         # NEW — 38 adaptive color sets
forager/SettingsView.swift              # Remove NavigationView, add Data section
forager/UnifiedSearchView.swift         # Remove NavigationView wrapper
forager/OnboardingView.swift            # Update coach mark steps
```

### **Critical Risks (from plan)**
| Risk | Mitigation |
|------|------------|
| `Tab(role: .search)` API differs from assumption | Fallback to standard `Tab("Search", ...)` — do NOT use role API if it breaks selection binding |
| SettingsView double-nested NavigationStack | Remove inner `NavigationView` wrapper, test push navigation carefully |
| pbxproj manual edits corrupt project | Validate with `plutil` before building |

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

**Version**: February 17, 2026 - M15.1 implementation ready
**Dependencies**: M15 planning ✅ COMPLETE, TestFlight live (build 10, v1.1)

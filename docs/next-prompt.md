# Next Implementation Prompt

**Last Updated**: February 17, 2026
**For Milestone**: M15 — UX Design System & Visual Refresh
**Status**: M15.1 ✅ | M15.2 ✅ | M15.3 ✅ | M15.4 ✅ | M15.5 ✅ | M15.5b ✅ | M15.6 ✅ | M15.7 🚀 **NEXT** | M7.7 📋 **QUEUED**
**Branch**: `feature/M15-ux-design-system` (local, not pushed)

---

## **M15.7: DARK MODE, ACCESSIBILITY & FINAL QA**

### **Context**
- M15.1-M15.6 complete: ForagerTheme tokens, Liquid Glass TabView, color migration, all screen UX overhauls, glass effects on cards/floating elements, tab bar minimize behavior
- iOS 26 deployment target with full Liquid Glass adoption
- All screens rebuilt with card-based layouts and ForagerTheme semantic tokens

### **Implementation Plan**
Read the detailed plan before starting: `docs/prds/active/plans/m15.7-implementation-plan.md`

### **All Reference Docs**
```
docs/prds/active/plans/m15.7-implementation-plan.md  # DETAILED PLAN — read this first
docs/prds/active/m15-ux-design-system.md               # Full PRD v1.2
docs/mockups/forager-design-system.html                 # 16 phone-frame mockups
```

### **M15.7 Scope (from PRD)**
- Dark mode walkthrough (tonal elevation, category colors, glass+dark)
- Empty state replacement (ContentUnavailableView)
- VoiceOver audit, Dynamic Type audit, Reduce Motion audit
- Glass contrast WCAG verification
- Performance profiling (60fps target)
- Final testing matrix

### **Key Areas to Audit**
```
ForagerTheme.swift               # Verify all 38 color tokens in dark mode
All card views                   # Glass readability in dark mode
ForagerProgressRing.swift        # Contrast in both modes
ForagerSectionHeader.swift       # Contrast in both modes
Category colors                  # All 11 category colors in dark mode
```

### **Continues on Same Branch**
```
# Already on feature/M15-ux-design-system
git log --oneline  # Should show M15.1-M15.6 commits
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

**Version**: February 17, 2026 - M15.7 implementation ready
**Dependencies**: M15.1 ✅, M15.2 ✅, M15.3 ✅, M15.4 ✅, M15.5 ✅, M15.5b ✅, M15.6 ✅, TestFlight live (build 10, v1.1)

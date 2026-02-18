# Next Implementation Prompt

**Last Updated**: February 17, 2026
**For Milestone**: M15 — UX Design System & Visual Refresh
**Status**: M15.1 ✅ | M15.2 ✅ | M15.3 ✅ | M15.4 🚀 **NEXT** | M7.7 📋 **QUEUED**
**Branch**: `feature/M15-ux-design-system` (local, not pushed)

---

## **M15.4: RECIPES UX OVERHAUL**

### **Context**
- M15.1 complete: ForagerTheme tokens, Liquid Glass TabView, iOS 26 deployment target
- M15.2 complete: ~300+ color/radius/typography replacements across ~25 files
- M15.3 complete: 7 shared components, card-based grocery lists, progress rings, collapsible sections, haptics, celebration
- Shared components from M15.3 available for reuse: ForagerCard, ForagerProgressRing, FilterPill, ForagerButtonStyles, CategoryChipPills, FlowLayout

### **Implementation Plan**
Read the detailed plan before starting: `docs/prds/active/plans/m15.4-implementation-plan.md`

### **All Reference Docs**
```
docs/prds/active/plans/m15.4-implementation-plan.md  # DETAILED PLAN — read this first
docs/prds/active/m15-ux-design-system.md              # Full PRD v1.2
docs/mockups/forager-design-system.html                # 16 phone-frame mockups
```

### **M15.4 Scope (from PRD)**
- Card-based recipe list with timing pills and filter pills
- Hero detail header with simplified nav
- Inline scale pills (0.5×–3×) replacing modal scaling sheet
- Left-justified ingredients with monospaced digits
- Dynamic CTA and numbered instructions

### **Key Files (will be rewritten)**
```
forager/RecipeListView.swift           # Card-based recipe list
forager/RecipeDetailView.swift         # Hero header, inline scale pills
```

### **Shared Components Available (from M15.3)**
```
forager/ForagerCard.swift              # .foragerCard() ViewModifier
forager/ForagerProgressRing.swift      # Circular progress ring
forager/ForagerSectionHeader.swift     # Collapsible section header
forager/FilterPill.swift               # Shared filter pill (3 sizes)
forager/ForagerButtonStyles.swift      # Primary/Secondary/Tertiary styles
forager/CategoryChipPills.swift        # Category composition pills
forager/FlowLayout.swift               # Custom Layout for wrapping
```

### **Continues on Same Branch**
```
# Already on feature/M15-ux-design-system
git log --oneline  # Should show M15.1 + M15.2 + M15.3 commits
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

**Version**: February 17, 2026 - M15.4 implementation ready
**Dependencies**: M15.1 ✅, M15.2 ✅, M15.3 ✅, TestFlight live (build 10, v1.1)

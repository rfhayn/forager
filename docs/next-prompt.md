# Next Implementation Prompt

**Last Updated**: February 17, 2026
**For Milestone**: M15 — UX Design System & Visual Refresh
**Status**: M15 🚀 **ACTIVE** | M7.7 📋 **QUEUED**
**Branch**: `main` (create feature branch for M15.1)

---

## **M15: UX DESIGN SYSTEM & VISUAL REFRESH**

### **Context**
- M7.6 complete: TestFlight live (build 10, v1.1), external testers active
- M15 design phase complete: HTML mockups, PRD v1.1, 5-phase design review done
- TestFlight link being shared on LinkedIn and social media (Feb 17, 2026)
- After M15: new TestFlight push → M7.7 App Store submission
- M15 reduces future M7.5 Architecture Hardening scope (navigation cleanup)

### **Design Artifacts (ALREADY COMPLETE)**
```
docs/prds/active/m15-ux-design-system.md           # Full PRD v1.1 (7 phases)
docs/prds/active/m15-design-review-action-plan.md   # Completed 5-phase review
docs/mockups/forager-design-system.html              # 16 phone-frame mockups
docs/architecture/011-tab-architecture-reduction.md  # 6→5 tab reduction ADR
docs/learning-notes/32-m15-css-design-system-dark-mode.md
docs/learning-notes/33-m15-ux-design-decisions.md
```

### **Phases**

#### M15.1: Design System Foundation & Liquid Glass TabView (8-10 hours)
- Create `ForagerTheme.swift` with semantic color tokens
- Create 38 Asset Catalog adaptive color sets (backgrounds, surfaces, text, accent, semantic, borders, categories)
- Typography system constants (SF Pro Rounded UI, New York serif for recipes)
- Raise deployment target from iOS 18 to iOS 26
- **Replace `CustomBottomNavigation` with native Liquid Glass TabView (5 tabs: Lists, Recipes, Meals, Settings, Search)**
- **Remove `HamburgerMenuModifier`** — Settings/Categories become standard tabs
- Branch: `feature/M15.1-design-system-foundation`

#### M15.2: Color & Typography Migration (8-10 hours)
- Apply semantic color tokens across all views (replace hardcoded colors)
- Implement typography scale with dynamic type support
- Border and divider system migration
- Category color system (11 colors with light/dark variants)

#### M15.3: Grocery Lists UX Overhaul (8-10 hours)
- Smart sorting toggle (category/priority)
- Enhanced swipe actions with SF Symbols
- Progress bar redesign with semantic colors
- Quick-add field redesign

#### M15.4: Recipes UX Overhaul (6-8 hours)
- Card-based recipe list with hero images
- Structured recipe detail with tabbed sections
- Glass-effect floating action buttons
- Enhanced search with filter chips

#### M15.5: Meal Plans & Ingredients UX (6-8 hours)
- Horizontal day strip calendar
- Drag-and-drop meal reordering
- Ingredient library cards with usage indicators
- Category management visual refresh

#### M15.6: Liquid Glass Polish & App Icon (6-8 hours)
- `.glassEffect()` on toolbars, sheets, floating elements
- `.tabBarMinimizeBehavior(.onScrollDown)` for content-first scrolling
- `tabViewBottomAccessory` for contextual actions
- `Tab(role: .search)` for native search integration
- Layered app icon via Icon Composer (glass-over-sprout)

#### M15.7: Dark Mode, Accessibility & Final QA (6-10 hours)
- Dark mode audit of all 38 color tokens
- WCAG AA contrast verification (all pairings ≥ 4.5:1 text, ≥ 3:1 UI)
- Dynamic Type audit (all text scales correctly)
- VoiceOver audit and reduce-motion support
- Haptic feedback integration
- Cross-screen regression testing

### **Key Files to Understand Before Starting**

```
forager/CustomBottomNavigation.swift    # WILL BE REPLACED in M15.1
forager/HamburgerMenuModifier.swift     # WILL BE REMOVED in M15.1
forager/foragerApp.swift                # Tab structure changes here
forager/Assets.xcassets/                # Color sets added here
```

### **Risk Mitigation**

| Risk | Mitigation |
|------|------------|
| iOS 26 SDK availability | Verify Xcode version supports iOS 26 before starting M15.1 |
| Regression in existing features | Test all core workflows after each phase |
| Dark mode breakage | M15.7 dedicated to dark mode audit |
| Navigation state loss | M15.1 carefully maps existing nav state to new TabView |

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

**Version**: February 17, 2026 - M15 Active
**Dependencies**: M15 design phase ✅ COMPLETE, TestFlight live (build 10, v1.1)

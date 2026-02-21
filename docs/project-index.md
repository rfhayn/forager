# Forager - Project Index

**Last Updated**: February 20, 2026
**Purpose**: Central navigation hub for all project documentation
**Current Milestone**: M15 ✅ COMPLETE (bug fixes done) | M7.7 📋 **QUEUED** | M8.4 📋 **READY**
**Current Phase**: M15 ✅ **COMPLETE** (all 8 phases + 7 bug fix commits) | M7.7 📋 **QUEUED**
**Next Priority**: Merge M15 → M7.5 → M9-prereqs → M8.4 → M7.7 App Store
**Execution Order**: M7.5 (14-19h) → M9-prereqs (9h) → M8.4 (18-24h) → M7.7 (3-5h) → M6 (20-30h) → M9 remaining (~120h) → M10+

---

## 🚨 **START HERE: MANDATORY SESSION STARTUP**

### **For EVERY Development Session:**

**⚠️ CRITICAL - Complete these in order:**

1. **[Session Startup Checklist](session-startup-checklist.md)** ← **START HERE FIRST**
   - Mandatory 8-point checklist for every session (updated with git workflow!)
   - Ensures naming consistency and context loading
   - Prevents 7-16 hours of potential rework
   - **10-15 minutes that save hours**

2. **[Project Naming Standards](project-naming-standards.md)** ← **READ SECOND**
   - M#.#.# naming hierarchy (e.g., M7.1.3)
   - Status indicators (✅ 🔄 🚀 ⏳)
   - Quick reference card at top
   - **Zero tolerance for incorrect naming**

3. **[Current Story](current-story.md)** ← **READ THIRD**
   - Current milestone and active phases
   - What's 🚀 READY to start
   - Recently completed work ✅
   - Next steps with prompts

4. **[Next Prompt](next-prompt.md)** ← **READ FOURTH**
   - Ready-to-use implementation prompt
   - Current phase guidance
   - Technical requirements
   - Acceptance criteria

**Why this order matters:**
- Checklist → Ensures you follow the complete process
- Naming Standards → Establishes the language/convention
- Current Story → Provides specific project state
- Next Prompt → Gives implementation details

**Failure to follow this sequence breaks project continuity.**

---

## 🔥 **RECENT ACTIVITY**

### **February 20, 2026** - M15 Bug Fixes COMPLETE ✅, M8.4 PRD Written 📋
- **Completed**: 7 bug fix commits on M15 branch — structured qty loss, redundant displays, strikethrough, dark mode settings, template sanitization, category refresh, code review fixes, pluralization/product variant fixes
- **New PRD**: M8.4 ML-Powered Parsing — dataset-bootstrapped CoreML BiLSTM-CRF, moved to pre-launch
- **M9 prerequisites identified**: M9.0 (warnings), M9.1.2 (centralize extractCleanIngredientName), M9.5-partial (parser DI)
- **Execution order updated**: M8.4 moved ahead of M7.5/M6/M9

### **February 17, 2026** - M15.7 Dark Mode, Accessibility & Final QA COMPLETE ✅ — M15 FULLY COMPLETE
- **Completed**: M15.7 — Dark mode glass rim light, ContentUnavailableView migration, VoiceOver labels, Dynamic Type scaling, Reduce Motion guards
- **Key Deliverables**:
  - Dark mode rim light overlay on glass card modifiers
  - StandardEmptyStateView deleted, replaced with native ContentUnavailableView on 5 views
  - VoiceOver accessibility labels on all interactive elements (grocery items, recipe cards, filter pills, scale pills, meal plan cards, action buttons, ingredient rows)
  - @ScaledMetric on ForagerProgressRing (56pt) and day circles (22pt)
  - Reduce Motion guards across 10 view structs — all M15 animations guarded
- **Files**: 1 deleted, 10 modified
- **Builds**: 5 clean builds (one per sub-phase)
- **M15 Status**: ALL 8 PHASES COMPLETE — ready for PR + squash merge to main
- **Next**: Merge branch → TestFlight push → M7.7 App Store Submission

### **February 17, 2026** - M15.6 Liquid Glass Polish COMPLETE ✅
- **Completed**: M15.6 — iOS 26 Liquid Glass effects on cards, floating elements, tab bar
- **Key Deliverables**:
  - Glass card modifiers: `.foragerGlassCard()` + `.foragerProminentGlassCard()` in ForagerCard.swift
  - Glass on 4 card views (WeeklyLists, RecipeList, MealPlanList, MealPlanDetail)
  - Glass on 4 autocomplete dropdowns + shadows removed from 6 files
  - Tab bar: `.tabBarMinimizeBehavior(.onScrollDown)` for content immersion
  - Button glass evaluation: kept semantic styling (documented decision)
- **Files**: 12 modified, 0 new
- **Builds**: 4 clean builds
- **Next**: M15.7 Dark Mode, Accessibility & Final QA

### **February 17, 2026** - M15.5b Settings, Categories & Household COMPLETE ✅
- **Completed**: M15.5b — HouseholdView extraction, SettingsView restructure, ManageCategoriesView polish
- **Key Deliverables**:
  - HouseholdView: dedicated screen with async member loading, sharing stats, sync indicator, Danger Zone
  - SettingsView: 867 → 549 lines, NavigationLink to HouseholdView, version footer
  - ManageCategoriesView: nav bar `+`, Uncategorized lock icon, footer help text
- **Files**: 1 new (HouseholdView.swift), 3 modified
- **Builds**: 1 clean build
- **Next**: M15.6 Liquid Glass Polish

### **February 17, 2026** - M15.5 Meal Plans & Ingredients UX COMPLETE ✅
- **Completed**: M15.5 — Core Data v6 + meal plan cards + day strip + ingredients overhaul
- **Key Deliverables**:
  - Core Data v6 migration: `quickOption` on PlannedMeal with QuickOption enum
  - MealPlansListView: summary cards with day dots, Tonight snippet, Generate button
  - MealPlanDetailView: horizontal day strip, action buttons (Done/Swap/Remove), quick-select pills
  - IngredientsView: category filter pills, sort toolbar, category-colored left-border strips
  - IngredientReviewSheet: guided one-at-a-time triage with progress, reason badges, Save & Next / Skip
  - Review banner + staples summary header
- **Files**: 3 rewritten (MealPlanListView, MealPlanDetailView, IngredientsView), 4 modified
- **Builds**: 5 clean builds (one per sub-phase)
- **Next**: M15.5b Settings, Categories & Household Visual Redesign

### **February 17, 2026** - M15.4 Recipes UX Overhaul COMPLETE ✅
- **Completed**: M15.4 — Card-based recipe list + full detail view rewrite
- **Key Deliverables**:
  - Card-based recipe list with timing pills, filter pills (All/Favorites/Recent), sort menu
  - Hero detail header (28pt bold title, compact timing row, simplified nav)
  - Inline scale pills (6 presets + custom two-component picker) replacing modal scaling sheet
  - Flat ingredient layout with monospaced digits and confidence-colored bullets
  - Dynamic CTA with scaled servings count, numbered instructions with accent step numbers
  - Collapsible usage footer via DisclosureGroup
  - RecipeFilter/RecipeSortOrder enums, RecipeCardView, SearchMatchType ForagerTheme migration
- **Files**: 1 file rewritten (RecipeListView.swift — contains both list and detail views)
- **Builds**: 2 clean builds (one per commit)
- **Next**: M15.5 Meal Plans & Ingredients UX

### **February 17, 2026** - M15.3 Grocery Lists UX Overhaul COMPLETE ✅
- **Completed**: M15.3 — 7 shared components + full grocery list UX rewrite
- **Key Deliverables**:
  - 7 shared components: ForagerCard, ProgressRing, SectionHeader, CategoryChipPills, FlowLayout, FilterPill, ButtonStyles
  - Card-based grocery list overview with progress rings and category chip pills
  - 3-option creation dialog (From Staples / From Meal Plan / Empty List)
  - Sticky bottom progress bar + quick-add via .safeAreaInset(edge: .bottom)
  - Collapsible category sections with auto-collapse after 2s
  - Check-off haptics (medium/light impact) + spring animations
  - 100% completion celebration banner with success haptic
  - MealPlanService.generateGroceryList(from:) for meal plan → grocery list flow
- **Files**: 7 new, 5 modified (WeeklyListsView + GroceryListDetailView fully rewritten)
- **Builds**: 4 clean builds (one per sub-phase commit)
- **Next**: M15.4 Recipes UX Overhaul

### **February 17, 2026** - M15 Elevated to Pre-Launch 🚀
- **Decision**: M15 UX Design System elevated to pre-launch — polished UI before App Store debut
- **Rationale**: Better brand impression, design phase already complete (mockups, PRD v1.1, 5-phase review)
- **New sequence**: M15 → TestFlight push → M7.7 App Store submission
- **Architecture benefit**: M15 first reduces M7.5 scope (native TabView replaces custom navigation)
- **TestFlight**: Build 10 (v1.1) live, LinkedIn share imminent
- **Core docs**: All 5 updated to reflect new execution order

### **February 15, 2026** - M7.6 COMPLETE ✅ — TestFlight Live
- **Completed**: M7.6.7 TestFlight submission + M7.6.8 owner display name fix
- **Key Deliverables**:
  - CloudKit schema deployed to Production
  - Archive uploaded, Apple review approved, external testers active
  - Fixed owner display name: repurposed `ownerEmail` to store name on shared Household root record
  - Fixed empty `nameComponents` detection (iOS 16+ returns empty, not nil)
  - Cross-device name display verified via TestFlight on owner + joinee devices
- **PRs**: #32 (TestFlight beta bugs), #33 (owner display name fix)
- **PRD**: `docs/prds/complete/m7.6.8-owner-display-name-fix.md`
- **Insights**: 3 new entries logged (CloudKit sharing root record, field repurposing, CKShare nameComponents)
- **Build**: v1.1 build 10
- **Next**: M7.7 App Store Submission & Public Presence

### **February 12, 2026** - M7.6.3 Loading Screen + Learning Note 31 ✅
- **Completed**: Branded SwiftUI loading screen bridging storyboard → main app
- **Key Deliverables**:
  - Two-phase `PersistenceController` init: fast container creation deferred from slow `loadPersistentStores()`
  - `AppLoadingView` matching storyboard aesthetic (named color + icon assets, light/dark)
  - `@Published var isReady` with Combine `onReceive` bridge to `@State` in foragerApp
  - Animated crossfade transition from splash to main content
- **Key Learning**: `loadPersistentStores()` is the slow call (~0.5-2s) — splitting into two phases lets SwiftUI render the splash before stores finish loading
- **Learning Note 31**: Core Data Schema Evolution & CloudKit Constraints — promoted 7 insights from M7.6.4-M7.6.6 schema cleanup
- **Branch**: `feature/M7.6-pre-launch-testflight`
- **Next**: M7.6.7 TestFlight Submission (all prerequisites complete)

### **February 11, 2026** - M7.6.1 App Configuration COMPLETE ✅
- **Completed**: Display name, iOS 18.0 deployment target, branded launch screen with light/dark mode
- **Key Deliverables**:
  - Deployment target lowered from 18.5 → 18.0 (no API changes needed)
  - LaunchScreen.storyboard with centered sprout icon and branded background colors
  - Light mode: cream background (#F5F0E1) with light sprout
  - Dark mode: charcoal background (#121212) with dark sprout
  - Transparent sprout PNGs (Vision framework background removal) for seamless blending
  - Asset catalog appearance variants for automatic light/dark resolution
- **Key Learning**: UILaunchScreen plist dict does NOT resolve asset catalog dark mode variants — must use storyboard approach
- **Branch**: `feature/M7.6-pre-launch-testflight`
- **Next**: M7.6.2 Production Gating (#if DEBUG)

### **February 8, 2026** - M7.6/M7.7 Scoped & PRDs Written 📋
- **Completed**: Full scope definition and PRDs for M7.6 (8 phases) and M7.7 (4 phases)
- **Key Decisions**:
  - iOS 18 deployment target (deliberate — avoids ~104 API changes for no market)
  - Display name: `forager - Smart Meal Planner` (lowercase 'forager')
  - Core Data schema cleanup before CloudKit Production deployment (P0/P1/P2)
  - 4-page onboarding walkthrough (first-launch + Settings replay)
  - Developer tools gated behind `#if DEBUG`
  - LinkedIn post removed (handled via newsletter)
- **Schema audit findings**: 2 dead entities (Tag, LeaveRequest), wrong cardinality (Recipe.plannedMeals), misnamed field (ownerEmail), 5 code-schema mismatches, 6 unused fields
- **PRDs**: `docs/prds/active/m7.6-pre-launch-prep-testflight.md`, `docs/prds/active/m7.7-app-store-submission.md`
- **All 5 core docs updated**

### **February 8, 2026** - M8.3.1 Template Hygiene & M8.3.2 Auto-Merge COMPLETE ✅
- **Completed**: Template name hygiene, review badges, grocery auto-merge (~6 hours combined)
- **Key Deliverables**:
  - All template creation paths routed through findOrCreateTemplate (normalization + dedup)
  - `needsReview` heuristic + "Review" filter pill on Ingredients tab
  - Merge-on-rename deduplication, compound plural fix
  - GroceryMergeService with automatic quantity aggregation (19 tests)
  - 21 new validation/normalization tests
  - Badge threshold raised to < 0.7

### **February 8, 2026** - M8.3 Hybrid NLP Parser COMPLETE ✅
- **Completed**: Protocol-based hybrid parser architecture (~11 hours)
- **Key Deliverables**:
  - HybridIngredientParser with confidence-based routing (regex + NLP)
  - 7 regex pattern categories, NLP fallback with Apple NaturalLanguage
  - 58 new tests, zero public API changes
  - ADR 010, Learning Note 30

### **February 7, 2026** - M8.1 Parsing Resilience & Telemetry COMPLETE ✅
- **Completed**: ParsingTelemetryService, yellow badges, telemetry integration (~3 hours)
- **Key Deliverables**:
  - ParsingTelemetryService with local JSON logging (20/20 tests passing)
  - Yellow badge on low-confidence ingredients in recipe detail and grocery list views
  - Telemetry integration in IngredientParsingService
  - Sample low-confidence recipes for testing
- **Scope Reduction**: EditIngredientSheet removed (redundant with inline editing, M8.3 will improve parser)
- **Bug Fixes**: Removed phantom `normalizedName` from IngredientTemplate+CoreDataProperties.swift
- **Total Progress**: ~170 hours
- **Next**: M8.2 Telemetry Analysis & Strategy

### **February 6, 2026** - M7 Retrospective Documentation 📚
- **Created**: Learning Note 29 - Complete M7 CloudKit & Household Journey retrospective
- **Key Content**:
  - 800+ line comprehensive narrative covering all M7 pivots and lessons
  - External AI validation story (ChatGPT & Gemini catching production bugs)
  - iOS 18.x UICloudSharingController regression and public link workaround
  - Time estimates vs actuals (~60h actual vs 27-37h estimated)
  - Newsletter-ready source material for "Systems Over Vibes" series
- **ADR Updates**: ADR 008 & 009 verified and updated (not stale)
- **Documentation**: [29-m7-cloudkit-household-journey.md](learning-notes/29-m7-cloudkit-household-journey.md)

### **February 8, 2026** - M8.3 COMPLETE ✅
- **Hybrid NLP Parser**: Protocol-based architecture with 7 regex pattern categories + NLP fallback
- **New ADR**: [ADR 010 - Hybrid Parser Confidence Routing](architecture/010-hybrid-parser-confidence-routing.md)
- **Key decisions**: Confidence-driven routing (0.8 threshold), NLP confidence cap (0.75), pattern priority ordering
- **Zero call site changes** — all 6 consumers unchanged
- **Documentation**:
  - [30-m8.3-hybrid-parser-implementation.md](learning-notes/30-m8.3-hybrid-parser-implementation.md) - Implementation journey and learnings
  - [ADR 010](architecture/010-hybrid-parser-confidence-routing.md) - Architectural decision record

### **February 5, 2026** - M7.3.4 COMPLETE ✅ + Roadmap Updated
- **Completed**: Error handling improvements, ghost data fixes, CloudKit logging
- **Key Achievements**:
  - Ghost Data bug fix (loadCurrentHousehold no longer auto-clears left flag)
  - Check Again button replaces exit(0)
  - CloudKitErrorMapper and CloudKitLogger utilities
  - householdKey filtering across all autocomplete surfaces (16 files)
- **Roadmap Decisions**:
  - Original M7.4 (Sync Status UI) **SKIPPED** - dual-store architecture makes it unnecessary
  - M7.4 repurposed for **UI Polish & Pre-Launch Fixes**
  - **M8.1-M8.3 before launch** - Fix "3 avocados" parsing issue
  - M7.5, M6, M8.4 deferred post-launch
- **Total Progress**: ~158 hours
- **Next**: Merge M7.3.4 → Start M7.4 UI Polish

### **February 3, 2026** - M7.3.3 Remove Member & Delete Household COMPLETE ✅
- **Completed**: Owner can remove members, delete household, with proper data migration and cleanup
- **Key Fixes**:
  - CategoryDeduplicator now respects householdKey scope (prevents cross-scope deletion)
  - viewContext.reset() before destroyAndRecreateSharedStore() (prevents crash)
  - Household protection prevents multi-household state
  - Removed member detection with automatic cleanup
- **Files**: HouseholdService.swift, CategoryDeduplicator.swift, HouseholdMembersView.swift, SettingsView.swift
- **Total Progress**: ~155 hours
- **Next**: Merge branch → M7.3.4 Error Handling & Recovery

### **February 2, 2026** - M7.2.2 Leave Flow COMPLETE ✅
- **Completed**: Full member leave flow — leave with data migration, CKShare deletion, shared store cleanup, rejoin support
- **Achievement**: ~450 lines of dead code removed, purge helper extracted, PasteInvitationSheet API fixed
- **Commits**: 5 commits on `feature/M7.2.2-leave-flow-fixes`
- **Files**: HouseholdService.swift (major refactor), PersistenceController.swift (purge helper), KeychainHelper.swift (NEW), PasteInvitationSheet.swift (API fix), ShareSheet.swift (invitation message)
- **Documentation**: All 5 critical docs updated (current-story, next-prompt, roadmap, requirements, project-index)
- **Total Progress**: ~147 hours
- **Next**: Merge branch → M7.3.3 Remove Member & Delete Household

### **January 13, 2026** - Documentation Cleanup & M6 Planning 📚
- **Completed**: Comprehensive documentation sync and milestone planning review
- **Achievement**: All planning documents updated to reflect M7.2.2 and M7.2.3 completion
- **Documentation Updates**:
  - requirements.md: Updated to v4.7, added M6 deferred section, M7 status refresh
  - roadmap.md: Added M6 deferred section with strategic rationale, M7 progress update
  - project-index.md: Current phase updated (M7.3 next), execution order clarified
  - session-startup-checklist.md: Updated to v2.2 with ADR 008/009 and service-layer-pattern
  - claude-instructions.md: Created v5.0 with timeless content (removed M7.1 status)
  - CLAUDE.md: Created streamlined startup guide for /init command
  - M7.2.3 PRD: Updated to v2.4 FINAL (COMPLETE status, deferred phases documented)
  - M7.2 PRD: Updated to v2.0 COMPLETE (Jan 12, 2026 completion)
- **M6 Strategic Decision**: Deferred to execute after M7 (before M8)
  - Rationale: External beta proves stability → Testing foundation → Parsing improvements → Safe refactoring
  - Impact: Test coverage protects against regressions during M9's 135-173h refactoring
  - Execution order: M7 → M6 → M8 → M9 (not M1-M5 → M6 → M7 as originally planned)
- **Current Status**:
  - M7.0-M7.2: ✅ COMPLETE (~27h)
  - M7.2.3: ✅ COMPLETE (12.25h)
  - M7 Total: ~37h of ~52-60h estimated
  - Next: M7.3 - Household Management & Settings (6-8h)
- **Total Progress**: ~131 hours (includes M7.2.2 bug fixes ~11-12h from Jan 9-10)
- **Planning Accuracy**: 89% maintained
- **Key Decision**: Keep milestone numbers sequential (M1→M5→M7→M6→M8), document execution order instead of renumbering

### **January 4, 2026** - M7.2.3 COMPLETE ✅ (~12.25 hours total)
- **Completed**: All M7.2.3 phases complete - CloudKit hardening & shared data architecture operational
- **Achievement**: Production-ready CloudKit sync with attach-then-share migration validated
- **Total Time**: 12.25 hours (estimated 14-17h, 88% accuracy)
- **Phase Breakdown**:
  - Phase 0: Core Data Model v2 (2h)
  - Prep A: StoreIdentityLogger (0.5h)
  - Phase 1: Persistence Decomposition (5h)
  - Phase 2: Scope-Based Factory (3.75h)
  - Phase 3.8: CategoryDeduplicator (1h)
  - Phase 4: Attach-Then-Share Migration (3.5h)
- **Critical Success**: Fixed CloudKit sync bug (missing `context.save()` after share)
- **Migration Validated**: 61 items (11 recipes, 1 list, 1 meal plan, 41 templates, 7 categories)
- **CloudKit Dashboard**: Shared zone created, data visible, zone-wide sharing enabled
- **Console Logs**: Private → Shared transition confirmed
- **Total Progress**: ~119.5 hours
- **Next**: M7.2.2 - Member Invitation & Acceptance Testing (2-3h) - Requires 2 physical iPhones

### **January 2, 2026** - M7.2.3 Phase 2.5 Infrastructure Complete ✅ (~1.75 hours)
- **Completed**: Protocol activation & manual Core Data files (Phases 2.1-2.5 all done)
- **Achievement**: Build successful with complete household-scoped infrastructure activated
- **The Journey**:
  - Phase 2.1-2.4: Infrastructure created (DataScope, ScopeProvider, Factory, Environment)
  - Phase 2.5: Activated infrastructure → 162 build errors
  - Root cause: Core Data model v2 had householdKey, but Swift property files not updated
  - Solution: Created 12 manual Core Data files (6 entities × 2 files each)
  - Debugging: Systematic error reduction (162 → 4 → 3 → 1 → 0)
- **Files Created** (12 manual Core Data files):
  - Household+CoreDataClass.swift & +CoreDataProperties.swift
  - HouseholdMember+CoreDataClass.swift & +CoreDataProperties.swift
  - MealPlan+CoreDataClass.swift & +CoreDataProperties.swift
  - IngredientTemplate+CoreDataClass.swift & +CoreDataProperties.swift
  - PlannedMeal+CoreDataClass.swift & +CoreDataProperties.swift
  - UserPreferences+CoreDataClass.swift & +CoreDataProperties.swift
- **Files Modified**:
  - Services/Persistence/DataScope.swift (protocol conformances activated)
  - Services/Persistence/ManagedObjectFactory.swift (household logic activated)
  - WeeklyList+CoreDataProperties.swift, Recipe+CoreDataProperties.swift, Category+CoreDataProperties.swift
  - forager/MealPlanRowView.swift (Preview syntax fix)
- **Key Learnings**:
  - Manual/None codegen requires BOTH +CoreDataClass AND +CoreDataProperties files
  - Core Data model changes don't auto-update Swift files (must regenerate manually)
  - Cross-reference model XML to find missing properties
  - Systematic debugging: fix one error category at a time
- **Codegen Strategy**: Changed 6 entities from Class Definition → Manual/None (prevents conflicts)
- **Build Status**: ✅ SUCCESS (0 errors, down from 162)
- **Current Reality**:
  - ✅ Infrastructure complete and activated
  - ✅ Protocol conformances enforced by compiler
  - ❌ Factory exists but nothing uses it yet (no creation points updated)
  - ⚠️ Design challenge: How to use factory in background contexts?
- **Documentation**:
  - [learning-notes/29-m7-cloudkit-household-journey.md](learning-notes/29-m7-cloudkit-household-journey.md) - Complete M7 CloudKit journey retrospective
  - [current-story.md](current-story.md) - Phase 2.5 marked complete
  - [next-prompt.md](next-prompt.md) - Phase 2.6 ready with design options
- **Planning Accuracy**: 58% (1h estimated, 1.75h actual - underestimated codegen complexity)
- **Total Progress**: ~113 hours (M1-M7.1: ~102h + M7.2.1: 1.25h + CloudKit Debug: 4h + M7.2.3: 6.5h)
- **Next**: Phase 2.6 - Update creation points (2-3h) - Decide on background context pattern

### **January 1, 2026** - M7.2.3 External Validation ✅ COMPLETE (~1 day planning)
- **Completed**: PRD v2.2 FINAL ready with production-ready architecture validated by external AI experts
- **Achievement**: Prevented 4 critical bugs BEFORE implementation, received complete production-ready code
- **External Validation**:
  - **ChatGPT**: "Gold Standard for NSPersistentCloudKitContainer implementations"
  - **Gemini**: "Production-ready, no architectural changes required before coding"
- **Critical Bugs Caught**:
  1. ❌ Share creation API wrong → ✅ Fixed: `container.share([household], to: nil)`
  2. ❌ Delete rules too aggressive → ✅ Fixed: Cascade for owned, Nullify for value
  3. ❌ DataScope coupled to persistence → ✅ Fixed: ObjectID-based via ScopeProvider
  4. ❌ Type-switch maintenance hotspot → ✅ Fixed: HouseholdScoped protocol
- **Production-Ready Code Received**:
  - DataScope enum (ObjectID-based, prevents stale references)
  - HouseholdScoped protocol (compiler-enforced)
  - ScopeProvider (auto-resolves store from coordinator)
  - ManagedObjectFactory (prevents stale refs, auto-sets relationships)
  - Share API (validated `to: nil` pattern)
  - Cross-store validator (DEBUG-only, catches violations)
  - IngredientTemplateDeduplicator (complete, 328 lines from ChatGPT)
- **PRD v2.2 FINAL**:
  - All v2.1 content (1413 lines) + 6 polish items
  - 1597 lines total, battle-tested specifications
  - Complete integration of ChatGPT & Gemini feedback
- **Documentation**: requirements.md (+10 requirements, 210 total), roadmap.md, project-index.md
- **Next**: M7.2.3 Prep Phase - Store Logging + Migration Validation (1 hour)

### **December 31, 2025** - M7.2.3 Phase 3.8 CategoryDeduplicator ✅ COMPLETE (~1 hour)
- **Completed**: Duplicate category prevention using dedupe-after-creation pattern
- **Achievement**: Self-healing CloudKit sync that automatically removes duplicates
- **Architecture**:
  - DefaultSeeder (Simplified): Each device seeds independently
  - CategoryDeduplicator (182 lines): Groups by normalizedName, keeps oldest
  - CloudKitSyncMonitor: Runs dedupe automatically after every sync
- **Test Results**: Simultaneous launch convergence in ~60 seconds total
- **Files Created**: Services/Persistence/CategoryDeduplicator.swift (182 lines)
- **Planning Accuracy**: ~1 hour actual (including 4h of failed prevention attempts)
- **Total Progress**: ~108.25 hours
- **Next**: M7.2.2 - Member Invitation & Acceptance (2-3 hours)

_[Previous entries remain the same through December 23...]_

---

## 📊 **CURRENT STATE**

### **Project Metrics**
- **Total Development Time**: ~190 hours
- **Planning Accuracy**: 89% overall (consistently within estimates)
- **Build Success**: 100% (zero breaking changes)
- **Performance**: 100% (all operations <0.5s target maintained)
- **Data Integrity**: 100% (zero data loss across all migrations)
- **Technical Debt**: NONE ✅
- **Git Workflow**: Clean main branch history with feature branches + squash merges

### **Milestones Complete** ✅
- **M1**: Professional Grocery Management (32 hours)
- **M2**: Recipe Integration (16.5 hours)
- **M3**: Structured Quantity Management (10.5 hours)
- **M3.5**: Foundation Validation (8.5 hours)
- **M4**: Meal Planning & Enhanced Grocery (19.25 hours)
- **M5.0**: App Renaming & TestFlight (6 hours)
- **M7.0**: App Store Prerequisites (3 hours)
- **M7.1.1**: CloudKit Schema Validation (1.5 hours)
- **M7.1.2**: CloudKitSyncMonitor Service (2 hours)
- **M7.2.1**: Household Setup Foundation (1.25 hours)
- **M7.2.3 Phase 0**: Core Data Model v2 (2 hours)
- **M7.2.3 Phase 1**: Persistence Decomposition (5 hours)
- **M7.2.3 Phase 2.1-2.5**: Infrastructure Complete (3 hours)
- **M7.2.3**: CloudKit Hardening & Shared Data Architecture (12.25 hours)

### **Current Work** 🔄
- **M8**: ✅ COMPLETE (Feb 7-8, 2026) — All core phases delivered
  - **M8.1**: Parsing telemetry + yellow badges (~3h)
  - **M8.2**: Skipped (PRD analysis sufficient)
  - **M8.3**: Hybrid NLP parser with 7 pattern categories (~11h)
  - **M8.3.1**: Template hygiene, review badges, merge-on-rename (~3h)
  - **M8.3.2**: Auto-merge grocery quantities (~3h)
  - **M8.4**: ML-powered parsing — deferred post-launch
- **Total M8 tests**: 102 unit tests across 7 test files

### **Technology Stack**
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (iOS 18.0+)
- **Persistence**: Core Data → CloudKit (M7.1)
- **Cloud Backend**: CloudKit (NSPersistentCloudKitContainer)
- **Testing**: XCTest framework + TestFlight
- **Version Control**: Git + GitHub (feature branch workflow)

### **App Features** (Fully Operational)
- ✅ Professional grocery list management with store-layout optimization
- ✅ Recipe catalog with ingredient tracking and scaling
- ✅ Structured quantity management with intelligent consolidation (95%+ accuracy)
- ✅ Calendar-based meal planning with recipe integration
- ✅ Automated meal plan to grocery list conversion
- ✅ Settings infrastructure with user preferences
- ✅ Internal TestFlight deployment
- ✅ CloudKit infrastructure (schema validated, sync monitoring operational)
- ✅ Household setup foundation (M7.2.1)
- ✅ Core Data model v2 with household relationships (M7.2.3 Phase 0)
- ✅ Persistence layer decomposed (M7.2.3 Phase 1)
- ✅ Scope-based store assignment infrastructure (M7.2.3)
- ✅ Category deduplication (M7.2.3)
- ✅ Attach-then-share migration with UI (M7.2.3)
- ✅ CloudKit sync verified working (M7.2.3)

### **Key Achievements**
- Household-scoped data architecture complete (all infrastructure in place)
- 12 manual Core Data files created for proper codegen control
- Protocol-enforced household scoping (compiler-verified)
- Build successful with 0 errors (down from 162)
- Professional iOS app with App Store readiness
- Zero technical debt maintained throughout
- 89% planning accuracy across all milestones
- Clean git history with feature branch workflow
- Sub-millisecond performance for all operations

---

## 🎯 **WHAT'S NEXT**

### **Pre-Launch Roadmap** 🚀

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.6: Pre-Launch Prep & TestFlight | ✅ COMPLETE | ~12h |
| **M15: UX Design System & Visual Refresh** | 🚀 **ACTIVE** | 50-70h |
| TestFlight push (post-M15) | 📋 PLANNED | ~1h |
| **M7.7: App Store Submission & Public Presence** | 📋 QUEUED | 3-5h |
| **Pre-Launch Total** | | **~54-76h remaining** |

### **Post-Launch Roadmap**

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.5: Architecture Hardening | 📋 READY | 14-19h |
| M6: Testing Foundation | PLANNED | 12-18h |
| M8.4: ML-Powered Parsing | OPTIONAL | 15-20h |
| M9: Technical Debt | PLANNED | 135-165h |
| M10+: Future Features | FUTURE | 48-72h |

### **Key Decisions (February 17, 2026)**
14. **M15 elevated to pre-launch** — polished UI before App Store debut
15. **New launch sequence**: M15 → TestFlight push → M7.7 App Store submission
16. **M15 first reduces M7.5 scope** — native TabView replaces custom navigation

### **Key Decisions (February 8, 2026)**
1. Original M7.4 (Sync Status UI) **SKIPPED** - dual-store architecture makes it unnecessary
2. M7.4 repurposed for UI Polish & Pre-Launch Fixes ✅ COMPLETE
3. M8.1-M8.3.2 completed before launch - parsing accuracy 95% → 98%+, template hygiene, auto-merge
4. M8.2 **SKIPPED** - PRD analysis proved sufficient; telemetry for post-launch monitoring
5. M8.4 **DEFERRED** post-launch - M8.3 achieves professional-grade 98%+ accuracy
6. M7.5 deferred post-launch - developer-facing code quality
7. iOS 18 deployment target - deliberate decision, avoids ~104 mechanical API changes
8. Core Data schema cleanup (M7.6.4-M7.6.6) gates TestFlight - CloudKit Production is append-only
9. Display name: `forager - Smart Meal Planner` (lowercase 'forager')
10. LinkedIn showcase removed from M7.7 - handled via newsletter

---

## 🚨 **CRITICAL REMINDERS**

1. **Session Startup**: Complete [session-startup-checklist.md](session-startup-checklist.md) EVERY session (8 items!)
2. **Naming Standards**: Always use M#.#.# format (enforced in [project-naming-standards.md](project-naming-standards.md))
3. **Documentation Updates**: Update [current-story.md](current-story.md) after EVERY session
4. **Learning Notes**: Create comprehensive notes after phase completion
5. **Insights Log**: Log technical insights to [insights-log.md](insights-log.md) during every session
6. **Git Workflow**: Feature branches with frequent commits (15-30 min), squash merge to main
6. **Zero Technical Debt**: Maintain quality standards throughout
7. **Performance Targets**: <0.5s for operations, <5s for CloudKit sync
8. **Manual Core Data**: Requires BOTH +CoreDataClass AND +CoreDataProperties files

---

## 🗺️ **COMPLETE MILESTONE ROADMAP**

### **✅ Completed Milestones** (M1-M5.0, M7.0-M7.4, M8.1: ~170 hours)

**M1: Professional Grocery Management** (32 hours) - August 2025
- Store-layout optimized grocery lists
- Custom category management with drag-and-drop
- Staple item system
- Core Data architecture

**M2: Recipe Integration** (16.5 hours) - September-October 2025
- Complete recipe catalog with CRUD operations
- Unified IngredientTemplate system
- Recipe-to-grocery list integration
- Recipe ingredient autocomplete
- Multi-field search and analytics

**M3: Structured Quantity Management** (10.5 hours) - October 2025
- Structured quantity data model (numericValue, standardUnit, parseConfidence)
- Enhanced parsing with 95%+ accuracy
- Recipe scaling (0.25x-4x) with kitchen-friendly fractions
- Quantity consolidation with unit conversion
- Professional UX and help documentation

**M3.5: Foundation Validation & Testing** (8.5 hours) - October 2025
- Template system validation (16 templates)
- Core Data audit and documentation
- Automated validation test suite (6 suites, 100% pass rate)
- 75+ computed properties added

**M4: Meal Planning & Enhanced Grocery Integration** (19.25 hours) - November 2025
- M4.1: Settings Infrastructure (1.5h)
- M4.2: Calendar-Based Meal Planning (4h)
- M4.3.1: Recipe Source Tracking (3.5h)
- M4.3.2: Scaled Recipe to List (1.25h)
- M4.3.3: Bulk Add from Meal Plan (2.5h)
- M4.3.4: Meal Completion Tracking (1h)
- M4.3.5: Ingredient Normalization (5.5h)

**M5.0: App Renaming & TestFlight Deployment** (6 hours) - December 2025
- Complete app rename to "Forager"
- Professional app icon design
- Apple Developer Program enrollment
- App Store Connect configuration
- Internal TestFlight deployment
- Multi-tester beta program

**M7.0: App Store Prerequisites** (3 hours) - December 2025
- Privacy policy creation and hosting
- In-app privacy link implementation
- App Privacy questionnaire completion
- Display name disambiguation

**M7.1: CloudKit Sync Foundation** (6.5 hours) - December 2025
- CloudKit schema validation
- CloudKitSyncMonitor service
- Multi-device sync debugging (4h additional)
- Bi-directional sync < 5s latency

**M7.2.1: Household Setup Foundation** (1.25 hours) - December 2025
- Household Core Data entity
- CreateHouseholdSheet UI
- Active household management
- Professional onboarding flow

**M7.2.3: CloudKit Hardening & Shared Data Architecture** (12.25 hours) - December 2025-January 2026
- Phase 0: Core Data Model v2 (2h)
- Phase 1: Persistence Decomposition (5h)
- Phase 2: Scope-Based Infrastructure (3.75h)
- Phase 3.8: CategoryDeduplicator (1h)
- Phase 4: Attach-Then-Share Migration (3.5h)
- 8 entities household-scoped
- 61 items migrated to CloudKit shared zone

---

### **📋 Ready** (M7.7: 3-5 hours)

**M7.7: App Store Submission & Public Presence** (3-5 hours) - 📋 READY
- M7.7.1: Beta Landing Page (GitHub Pages)
- M7.7.2: GitHub README Update
- M7.7.3: App Store Listing
- M7.7.4: App Store Submission
- **PRD**: `docs/prds/active/m7.7-app-store-submission.md`

---

### **⏳ Planned Milestones** (M6-M14: ~335-465 hours)

**M7 Remaining: CloudKit Sync & External TestFlight** (8-15 hours remaining)
- M7.2.4: Household Management (1-2h)
- M7.3: Conflict Resolution & Error Handling (4-6h)
- M7.4: Sync UI & Polish (3-4h)
- M7.5: Architecture Hardening - UX/Service Cleanup (8-12h)
- M7.6: External TestFlight Deployment (2-3h)
- M7.7: Public Beta Program (2-3h)
- **PRD**: [milestone-7-cloudkit-sync-external-testflight.md](prds/milestone-7-cloudkit-sync-external-testflight.md)

**M6: Testing Foundation & AI Augmentation** (12-18 hours)
- Phase 1: Human Test Baseline (5-7h)
- Phase 2: AI Test Review Setup (3-4h)
- Phase 3: Testing Standards & Infrastructure (2-3h)
- Phase 4: Phase 3 Prep - Optional (2-4h)
- **Target**: 50%+ coverage, AI reviewer operational

**M8: Ingredient Parsing Intelligence** (13-16 hours core, +15-20h optional ML) 🧠
- **M8.1**: Parsing Resilience & Telemetry (~3h) - ✅ COMPLETE
  - Yellow badge for low confidence, ParsingTelemetryService, telemetry integration
  - EditIngredientSheet removed (scope reduction — redundant with inline editing)
  - **Source**: [M7.5 Parsing Resilience PRD](prds/parsing/M7.5-parsing-resilience-polish-prd.md)
- **M8.2**: Telemetry Analysis & Strategy (2h) - 🚀 NEXT
  - Analyze real telemetry, prioritize improvements, ROI analysis
  - **Source**: [M8.0 Parsing Improvements PRD](prds/parsing/M8.0-parsing-improvements-foundation-prd.md) (Phase 1)
- **M8.3**: Hybrid NLP Parser (8-10h) - Implementation
  - Protocol abstraction, Regex + NLP paths, pattern handlers
  - **Target**: 95% → 98%+ accuracy, 5% → 2% low-confidence rate
  - **Source**: [M8.0 Parsing Improvements PRD](prds/parsing/M8.0-parsing-improvements-foundation-prd.md) (Phases 2-4)
- **M8.4**: ML-Powered Parsing (15-20h) - OPTIONAL Excellence
  - CoreML model, on-device inference, continuous learning
  - **Target**: 98% → 99.5%+ accuracy (only if 100+ corrections available)
  - **Source**: [M9.5 ML-Powered Parsing PRD](prds/parsing/M9.5-ml-powered-parsing-prd.md)
- **PRD**: [m8-ingredient-parsing-intelligence-meta-prd.md](prds/m8-ingredient-parsing-intelligence-meta-prd.md)

**M9: Technical Debt & Codebase Optimization** (135-165 hours) 🏗️
- Phase 1: Quick Wins (20-25h) - String utilities, performance, thread safety
- Phase 2: Architecture & Structure (40-50h) - Service consistency, DI, view decomposition
- Phase 3: Performance & Data Model (60-70h) - Query optimization, batch operations, migrations
- Phase 4: Quality & Standards (15-20h) - Code standards, test coverage, logging
- **Impact**: ~2,000 lines removed, 50-80% performance improvement, RecipeListView 1,204→400 lines
- **PRD**: [m9-technical-debt-codebase-optimization.md](prds/m9-technical-debt-codebase-optimization.md)

**M10: Analytics & Insights** (8-12 hours)
- Phase 1: Analytics Infrastructure (2-3h)
- Phase 2: Insights Dashboard (3-4h)
- Phase 3: Recommendations (2-3h)
- Phase 4: Export & Sharing (1-2h)
- **Leverages**: M3 structured quantities, M4 meal planning data

**M11: Health & Nutrition Integration** (10-15 hours)
- Apple Health integration
- Nutritional database
- Dietary goal tracking
- Health-aware recommendations
- Allergen and dietary restriction support

**M12: Budget Intelligence** (10-15 hours)
- Price tracking and history
- Budget planning tools
- Cost optimization suggestions
- Store price comparison
- Deal and coupon integration

**M13: AI-Powered Shopping Assistant** (10-15 hours)
- Natural language meal planning
- Smart recipe discovery
- Automated list generation
- Contextual recommendations
- Learning user preferences

**M14: Advanced Collaboration** (10-15 hours)
- Real-time shopping mode
- Assignment and delegation
- Shopping history and analytics
- Family preference learning
- Advanced sharing controls

**M15: UX Design System & Visual Refresh** (50-70 hours) 🎨 — 🚀 ACTIVE
- ForagerTheme design system with semantic color tokens
- Warm color palette (forest green, bark, cream, canvas)
- Typography system (SF Pro Rounded + New York serif)
- iOS 26 deployment target with full Liquid Glass adoption
- Liquid Glass TabView replacing custom bottom navigation
- Screen-by-screen UX overhauls (grocery, recipes, meal plans, ingredients)
- Layered app icon via Icon Composer
- WCAG AA compliance, dark mode, Dynamic Type, haptics
- **Design phase complete**: HTML mockups, PRD v1.1, 5-phase design review
- **PRD**: `docs/prds/active/m15-ux-design-system.md`

---

### **Milestone Timeline Summary**

**Core Platform (M1-M10)**: ~220-270 hours estimated (core) or ~235-290 hours (with M8.4 ML)
- **Completed (M1-M8)**: ~190 hours ✅
- **Remaining (M6-M10)**: ~200-253 hours (core) or ~215-273 hours (with M8.4 ML)

**Advanced Intelligence Platform (M11-M14)**: 40-60 hours total
- Dependencies: M1-M10 complete

**UX Design System (M15)**: 50-70 hours total
- Dependencies: App Store launch, iOS 26 SDK
- 7 phases with full Liquid Glass adoption

**Total Project Estimate**: ~310-400 hours (core) or ~325-420 hours (with M8.4 ML + M15)

---

## 📚 **LEARNING RESOURCES**

### **Internal Knowledge**
- [insights-log.md](insights-log.md) - Technical insights triage inbox (promotes to LNs/ADRs)
- [learning-notes/](learning-notes/) - 37 implementation journey notes
- [architecture/](architecture/) - 12 architecture decision records
- [prds/](prds/) - 10+ product requirement documents
- [git-workflow-for-milestones.md](git-workflow-for-milestones.md) - Complete git workflow guide

### **External Resources**
- [NSPersistentCloudKitContainer Documentation](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect](https://appstoreconnect.apple.com)

---

**Version**: 9.4
**Last Updated**: February 17, 2026
**Maintained By**: Rich Hayn
**Project**: forager - Smart Meal Planning
**Repository**: https://github.com/rfhayn/forager.git

---

**Documentation Update**: January 4, 2026 - Milestone restructuring complete
- ✅ M8: Ingredient Parsing Intelligence (4 phases, was M7.5/M8.0/M9.5)
- ✅ M9: Technical Debt & Codebase Optimization (new comprehensive PRD)
- ✅ M10: Analytics & Insights (was M8)
- ✅ M11-M14: Advanced Intelligence Platform (was M9-M12)
- ✅ All PRDs, requirements.md, roadmap.md, and project-index.md updated

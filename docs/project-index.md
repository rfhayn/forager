# Forager - Project Index

**Last Updated**: March 21, 2026
**Purpose**: Central navigation hub for all project documentation
**Current Milestone**: M9.27 ✅ **COMPLETE** | M9.25.1 ✅ | M9.24 🔄 | M10.6 🔄 **ACTIVE** (M10.6.5 docs remaining)
**Current Phase**: Launch Prep — M9.24-M9.29 + M7.7
**Launch Path**: M9.24 → M9.15.3 → M9.26 → M10.6.5 → M9.28 → M9.29 → M7.7 (~10-18h to App Store)

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

### **March 21, 2026** - M9.27 ✅ COMPLETE — First Launch Walkthrough Redesign
- **New**: `WelcomeWalkthroughView` — 3-screen welcome carousel (Welcome → How It Works → Power Up)
- **Deleted**: `SampleDataSeeder.swift` (~700 lines of sample data removed)
- **Updated**: Coach marks simplified for replay-only use, onboarding references AI + household sharing
- **PRD**: `docs/prds/active/m9.27-first-launch-walkthrough-redesign.md`

### **March 21, 2026** - M9.25/M9.25.1 ✅ COMPLETE — Launch Prep UI Fixes
- Glass card styling unified across Settings, Household, HouseholdMembers, ManageCategories, Help
- Grocery list items styled as boxed cards matching recipe detail
- Meal plan day dots and calendar strip centered
- Quick-add bar background fixed

### **March 14, 2026** - M9.16 ✅ COMPLETE — Unified GroceryListItemService & Ingredient Selection
- **New**: `GroceryListItemService` — unified pipeline consolidating 6 independent GroceryListItem creation paths
- **New**: `MealPlanIngredientSelectionView` — recipe-by-recipe wizard for meal plan → grocery list flow
- **Migrated**: MealPlanDetailView.performBulkAdd (had zero categories) + MealPlanService.generateGroceryList (inline resolution)
- **Code review**: Fixed duplicate service instance, rollback hazard (skipSave), loading spinner rendering, sheet sequencing
- **Build**: 0 warnings, 359/360 tests pass
- **Branch**: `feature/M9.16-grocery-list-item-service`

### **March 11, 2026** - M9.13 ✅ COMPLETE — ManagedObjectFactory Enforcement & Hardening
- **Fixed**: TestFlight crash from `viewContext.assign()` after leaving household
- **Enforced**: Factory pattern across all 26 production creation sites (ADR 014)
- **Hardened**: Converted 11 `try?` sites to `do/catch` with DEBUG logging, removed dead code in RecipeImportService
- **Store correctness**: WeeklyListsView now uses `performScopedWrite`, CreateMealPlanSheet single-save
- **Encapsulation**: All `factory` properties now `private(set)` with `configure(factory:)` injection
- **Branch**: `feature/M9.13-factory-enforcement` (PR pending)

### **March 11, 2026** - M16.1-M16.2 ✅ COMPLETE — Knowledge MCP Server
- **Completed**: Python MCP server at `Tools/mcp-knowledge/` with 7 tools (search, read, list, project status, newsletter context/draft/export)
- **Stats**: 182 documents indexed, 2,472 searchable chunks, BM25 search <1ms
- **Newsletters**: 7 .docx files moved to `docs/newsletters/`, fully indexed
- **Deployed**: Operational in Claude Desktop via MCP configuration
- **Remaining**: M16.3 (polish, search tuning) — planned for later

### **March 3, 2026** - M10.6.10 ✅ COMPLETE — Ingredient Autocomplete + Three-State Match Icons
- **Completed**: Autocomplete dropdowns in RecipeDetailView + RecipeImportPreviewView ingredient editing
- **Three-state icons**: ready (green checkmark), needsCategory (amber dashed), needsTemplate (gray plus + NEW badge)
- **Also completed in prior sessions**: M10.6.7 (household API key), M10.6.8 (shared match service), M10.6.9 (category validation + persistence fixes)
- **Remaining**: M10.6.5 (documentation + final verification)

### **March 1, 2026** - M10.6 🔄 ACTIVE — Claude API Integration
- **Started**: Optional Claude API for import ingredient parsing (fills ~7-8% semantic gap)
- **Branch**: `feature/M10.6-claude-api-integration`
- **PRD**: `docs/prds/active/m10.6-claude-api-integration.md` (audited — accurate against codebase)
- **Scope**: 10 sub-phases (M10.6.1-M10.6.10), ~22h actual, 7+ new files, ~20 new tests
- **Also**: Renamed all 12 project skills to `forager-*` prefix, CLAUDE.md audit/cleanup

### **February 28, 2026** - M10.8 ✅ COMPLETE — Inline Ingredient, Instruction & Metadata Editing
- **Completed**: Two phases — Phase 1 (ingredient display/edit toggle), Phase 2 (fully inline RecipeDetailView)
- **Phase 1**: Tap-to-edit ingredients in EditRecipeView + CreateRecipeView, ported from RecipeImportPreviewView pattern
- **Phase 2**: Inline instruction editing (bordered card per step), inline metadata editing (title, timing, servings, favorite), Edit Recipe modal removed
- **Import preview**: Instruction editing added to RecipeImportPreviewView with mutual exclusion vs ingredient editing
- **Architecture**: Three `@FocusState` properties for mutual exclusion — SwiftUI enforces single-active-editor natively
- **Category picker**: `.presentationDetents([.medium, .large])` on both views
- **TestFlight**: Build 29 deployed, submitted for beta review
- **PRD**: `docs/prds/complete/m10.8-inline-ingredient-editing.md`
- **Next**: M10.3 merge → M10.4 → M10.6

### **February 24, 2026** - M8.4.1 ✅ COMPLETE — Normalization Qualifier Reclassification
- **Completed**: Fixed identity qualifier stripping bug — "ground beef" was being normalized to "beef"
- **Root cause**: `removeVariations()` conflated identity qualifiers (ground, fresh, frozen) with preparation qualifiers (diced, chopped, sliced)
- **Fix**: Data-driven reclassification using strangetom training data (68,846 samples, 3,032 compound ingredients)
- **Changes**: Reduced strip list from 30+ to 9 preparation-only qualifiers, added compound preferPlural check
- **Testing**: 15 new tests + 3 updated, 282 total tests passing
- **Documentation**: PRD at `docs/prds/complete/m8.4.1-normalization-qualifier-reclassification.md`
- **Next**: M10 Recipe Import

### **February 24, 2026** - M10 Implementation Blueprint Finalized
- **Update**: Full implementation plan reviewed and incorporated into PRD
- **Key decisions**: Separate `ImportDraftRecipe` model (not extending RecipeFormData), `imageURL`-only v1 (no schema change), import history in UserDefaults (not Core Data), extractors return `nil` pattern
- **Scope**: 27 sub-phases, ~16 new production files, ~11 views, ~119 new tests, ~4,500-5,000 new lines, zero Core Data schema changes
- **PRD**: `docs/prds/active/m10-recipe-import.md` (full implementation blueprint)
- **Status**: Ready for Codex review before implementation begins

### **February 24, 2026** - Documentation Update: M10 Recipe Import Prioritized
- **Change**: M10 redefined from "Analytics & Insights" (8-12h) to "Recipe Import" (70-95h)
- **Old Analytics scope**: Bumped to M11
- **New execution order**: M10 (Recipe Import) → M7.7 → M6 → M9 → M11+
- **Rationale**: Recipe import is the #1 competitive gap; completing before launch
- **PRD**: `docs/prds/active/m10-recipe-import.md` (spike-validated, 28 sites tested)

### **February 22, 2026** - M8.4 ✅ COMPLETE — ML-Powered Parsing (All 10 Phases)
- **Completed**: Full ML parsing pipeline — BiLSTM-CRF model, CoreML deployment, 3-tier hybrid routing, correction feedback loop
- **Key metrics**: 98.49% token accuracy, 95.40% sentence accuracy, 100% Viterbi parity, <5ms inference
- **Architecture**: 3-tier hybrid parser (regex ≥0.9 → ML ≥0.8 → NLP fallback) with shared tokenizer
- **Testing**: 259 total tests (83 added in M8.4), 0 failures, 8 end-to-end integration scenarios
- **Correction pipeline**: Schema v3 telemetry → correction export → fine-tuning script
- **Documentation**: Learning note 38, CLAUDE.md updated, all 7 core docs updated
- **Total effort**: ~25 hours across 10 phases, 15 sessions
- **Next**: M7.7 App Store Submission

### **February 21, 2026** - M8.4 Phase 2 COMPLETE ✅ — BiLSTM-CRF Model Training
- **Completed**: BiLSTM-CRF sequence labeler trained on 55,076 samples, all acceptance criteria exceeded
- **Results**: Token accuracy 98.49% (≥96%), sentence accuracy 95.40% (≥92%), all key F1 ≥0.90
- **Architecture**: Embedding 128, hidden 256, 2 BiLSTM layers, dropout 0.5, CRF layer — 1.35M params, 5.2 MB
- **Training**: 21 epochs (early stopped at 26), ~39 min on Apple Silicon MPS
- **Artifacts**: `ingredient_tagger.pt` (checkpoint), `transitions.json` (CRF params), `vocabulary.json`
- **Commit**: `ce98e43` on `feature/M8.4-ml-parsing`
- **Next**: Phase 3 — CoreML conversion (extract emission scorer → .mlpackage, Viterbi parity gate)

### **February 21, 2026** - M8.4 Phase 0+1 COMPLETE ✅ — Contract Lock + Dataset Preparation
- **Completed**: Architecture locked (word-only BiLSTM v1), tokenizer spec frozen (NFKD + 100 test vectors), single-parse refactor (`parseCore()`/`parseUnified()`), dataset prepared (68,846 unique samples in 80/10/10 JSONL splits from strangetom's 81,316 rows)
- **Key Deliverables**: `Tools/ml-training/` with `prepare_dataset.py`, `TOKENIZER_SPEC.md`, `MODEL_CARD.md`, `LICENSES.md`, `requirements.txt`
- **Single-Parse Refactor**: Eliminated redundant `parser.parse()` calls across 3 view files + IngredientParsingService — critical prep for ML inference in the pipeline
- **Dataset**: 12,470 duplicates removed (15%), 7 Forager labels mapped from 13 strangetom labels, fraction notation decoded, stratified by 5 sources
- **Commits**: `dd332c9` (Phase 0), `e39b098` (Phase 1) on `feature/M8.4-ml-parsing`
- **Previous**: M9.5-partial (parser DI), M9.1.2 (centralized extractCleanIngredientName), M9.0 (zero-warning baseline)
- **Insights**: 3 new — CloudKit deprecation, MainActor await, PRD staleness pattern
- **Next**: M9.1.2 (centralize extractCleanIngredientName)

### **February 20, 2026** - M7.5 Architecture Hardening COMPLETE ✅
- **Completed**: All 3 phases — service ownership, navigation cleanup, tests & polish
- **Key Deliverables**:
  - Created RecipeService, WeeklyListService; extended IngredientTemplateService
  - 24 unit tests + integration tests for parse → service → persist pipeline
  - 35 direct `context.save()` calls eliminated from 13 production views
  - 3 views converted to enum-based sheet/alert routing (IngredientsView, CreateRecipeView, EditRecipeView)
  - 2 empty states → ContentUnavailableView + 5 Core Data invariant tests
- **Commits**: 6 on `feature/M7.5-service-ownership`
- **Branch**: Ready for PR + squash merge
- **Next**: M9-prereqs (warning resolution, centralize extractCleanIngredientName, parser DI)

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
- **All 7 core docs updated**

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
- **Total Development Time**: ~227 hours
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
- **M9.0**: ✅ COMPLETE (Feb 21, 2026) — Zero-warning build baseline (18 warnings resolved)
- **M7.5**: ✅ COMPLETE (Feb 20, 2026) — Service layer ownership, enum navigation, invariant tests
- **M8**: ✅ COMPLETE (Feb 7-8, 2026) — All core phases delivered
  - **M8.1**: Parsing telemetry + yellow badges (~3h)
  - **M8.2**: Skipped (PRD analysis sufficient)
  - **M8.3**: Hybrid NLP parser with 7 pattern categories (~11h)
  - **M8.3.1**: Template hygiene, review badges, merge-on-rename (~3h)
  - **M8.3.2**: Auto-merge grocery quantities (~3h)
  - **M9.5-partial**: ✅ COMPLETE (Feb 21, 2026) — Parser DI, mock parser, 9 routing tests
- **M8.4**: ML-powered parsing — 📋 READY (all prerequisites complete)
- **Total tests**: 259 unit tests across 19 test files

### **Technology Stack**
- **Language**: Swift 6+
- **UI Framework**: SwiftUI (iOS 26+)
- **Persistence**: Core Data → CloudKit (NSPersistentCloudKitContainer)
- **Cloud Backend**: CloudKit (dual-store: private + shared)
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
| **M15: UX Design System & Visual Refresh** | ✅ **COMPLETE** | 50-70h |
| TestFlight push (post-M15) | 📋 PLANNED | ~1h |
| **M7.7: App Store Submission & Public Presence** | 📋 QUEUED | 3-5h |

### **Post-Launch Roadmap**

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.5: Architecture Hardening | ✅ COMPLETE | ~5h |
| M9-prereqs (M9.0, M9.1.2, M9.5-partial) | ✅ COMPLETE | ~6h |
| M8.4: ML-Powered Parsing | 📋 READY | 23-32h |
| M6: Testing Foundation | PLANNED | 20-30h |
| M9: Remaining Technical Debt | PLANNED | ~120h |
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

**M7.7: App Store Submission & Public Presence** (3-5 hours) — 📋 QUEUED after M8.4
- M7.7.1: Beta Landing Page (GitHub Pages)
- M7.7.2: GitHub README Update
- M7.7.3: App Store Listing
- M7.7.4: App Store Submission
- **PRD**: [m7.7-app-store-submission.md](prds/active/m7.7-app-store-submission.md)

**M6: Testing Foundation & AI Augmentation** (12-18 hours)
- Phase 1: Human Test Baseline (5-7h)
- Phase 2: AI Test Review Setup (3-4h)
- Phase 3: Testing Standards & Infrastructure (2-3h)
- Phase 4: Phase 3 Prep - Optional (2-4h)
- **Target**: 50%+ coverage, AI reviewer operational

**M8: Ingredient Parsing Intelligence** — ✅ M8.1–M8.3 COMPLETE, M8.4 QUEUED
- **M8.1**: Parsing Resilience & Telemetry — ✅ COMPLETE
- **M8.2**: Telemetry Analysis & Strategy — ✅ COMPLETE
- **M8.3**: Hybrid NLP Parser — ✅ COMPLETE (98%+ accuracy, 7 regex categories)
- **M8.4**: ML-Powered Parsing (23-32h) — QUEUED
  - CoreML BiLSTM-CRF model, on-device inference
  - **Target**: 98% → 99.5%+ accuracy
  - **Source**: [M9.5 ML-Powered Parsing PRD](prds/parsing/M9.5-ml-powered-parsing-prd.md)
- **PRD**: [m8-ingredient-parsing-intelligence-meta-prd.md](prds/m8-ingredient-parsing-intelligence-meta-prd.md)

**M9: Technical Debt & Codebase Optimization** (135-165 hours) 🏗️
- Phase 1: Quick Wins (20-25h) - String utilities, performance, thread safety
- Phase 2: Architecture & Structure (40-50h) - Service consistency, DI, view decomposition
- Phase 3: Performance & Data Model (60-70h) - Query optimization, batch operations, migrations
- Phase 4: Quality & Standards (15-20h) - Code standards, test coverage, logging
- **Impact**: ~2,000 lines removed, 50-80% performance improvement, RecipeListView 1,204→400 lines
- **PRD**: [m9-technical-debt-codebase-optimization.md](prds/active/m9-technical-debt-codebase-optimization.md)

**M10: Recipe Import** (70-95 hours) 🚀 **NEXT**
- Phase 1: URL Import — JSON-LD + WKWebView, Share extension (24-32h)
- Phase 2: Text Paste — Foundation Models + heuristic fallback (14-19h)
- Phase 3: Photo/Image — OCR + section classification (23-30h)
- Phase 4: Polish — History, telemetry, regression testing (11-16h)
- **PRD**: [m10-recipe-import.md](prds/active/m10-recipe-import.md)
- **Spike**: [docs/import-research/](import-research/) — 28 sites tested

**M11: Analytics & Insights** (8-12 hours)
- Phase 1: Analytics Infrastructure (2-3h)
- Phase 2: Insights Dashboard (3-4h)
- Phase 3: Recommendations (2-3h)
- Phase 4: Export & Sharing (1-2h)
- **Leverages**: M3 structured quantities, M4 meal planning data

**M12: Health & Nutrition Integration** (10-15 hours)
- Apple Health integration
- Nutritional database
- Dietary goal tracking
- Health-aware recommendations
- Allergen and dietary restriction support

**M13: Budget Intelligence** (10-15 hours)
- Price tracking and history
- Budget planning tools
- Cost optimization suggestions
- Store price comparison
- Deal and coupon integration

**M14: AI-Powered Shopping Assistant** (10-15 hours)
- Natural language meal planning
- Smart recipe discovery
- Automated list generation
- Contextual recommendations
- Learning user preferences

**M16: Advanced Collaboration** (10-15 hours)
- Real-time shopping mode
- Assignment and delegation
- Shopping history and analytics
- Family preference learning
- Advanced sharing controls

**M15: UX Design System & Visual Refresh** (~50 hours) 🎨 — ✅ COMPLETE
- ForagerTheme design system with semantic color tokens
- Warm color palette (forest green, bark, cream, canvas)
- Typography system (SF Pro Rounded for chrome, system default for body)
- iOS 26 deployment target with full Liquid Glass adoption
- Liquid Glass TabView replacing custom bottom navigation
- Screen-by-screen UX overhauls (grocery, recipes, meal plans, ingredients)
- Layered app icon via Icon Composer
- WCAG AA compliance, dark mode, Dynamic Type, haptics
- **PRD**: [m15-ux-design-system.md](prds/complete/m15-ux-design-system.md)

---

### **Milestone Timeline Summary**

**Core Platform (M1-M10)**:
- **Completed (M1-M9.5-partial, M15, M7.5)**: ~227 hours ✅
- **Remaining**: M8.4, M7.7, M6, M9 (remaining)

**Advanced Intelligence Platform (M11-M14)**: 40-60 hours total
- Dependencies: M1-M10 complete

**Total Project Estimate**: ~350-450 hours (core + M8.4 ML)

---

## 📚 **LEARNING RESOURCES**

### **Internal Knowledge**
- [insights-log.md](insights-log.md) - Technical insights triage inbox (promotes to LNs/ADRs)
- [development-journal.md](development-journal.md) - Narrative chronicle of building Forager (decisions, learning, AI tooling evolution)
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

**Version**: 9.5
**Last Updated**: February 21, 2026
**Maintained By**: Rich Hayn
**Project**: forager - Smart Meal Planning
**Repository**: https://github.com/rfhayn/forager.git

---

**Documentation Update**: February 21, 2026 - Post-M8.4 Phase 0+1
- ✅ M8.4 Phase 0+1 complete on `feature/M8.4-ml-parsing` (contract lock + dataset preparation)
- ✅ 68,846 training samples prepared in 80/10/10 JSONL splits
- ✅ Single-parse refactor eliminates redundant parser.parse() calls
- ✅ All core docs synchronized
- ✅ Next: M8.4 Phase 2 (model training) → Phases 3-9 → M7.7

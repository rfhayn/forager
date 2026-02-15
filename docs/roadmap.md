# Forager - Development Roadmap

**Last Updated**: February 13, 2026
**Current Phase**: **M7.6 Pre-Launch Prep 🔄 IN PROGRESS** (M7.6.1-M7.6.6 ✅, M7.6.7 code prep ✅, TestFlight submission pending)
**Status**: All M1-M5.0 milestones complete, M7 CloudKit sync operational, M8 parsing intelligence complete, M7.6 nearly complete
**Execution Order**: M7.6-M7.7 (App Store) → M7.5 → M6 → M8.4 → M9 → M10+

---

## 🎯 **PROJECT OVERVIEW**

**Vision**: Revolutionary iOS grocery and recipe management app with intelligent automation, family collaboration, and lifestyle optimization.

**Core Value Proposition**:
- Store-layout optimized grocery shopping
- Integrated recipe catalog with smart ingredient management
- Structured quantity system enabling scaling and consolidation
- Recipe ingredient autocomplete for efficient data entry
- Calendar-based meal planning
- CloudKit family collaboration
- Analytics-driven insights
- **Data-driven ingredient parsing improvements** (M8: 4 phases, 95% → 98%+ accuracy)

---
## 📊 **CURRENT STATE - February 2026**

### **Completed Milestones** ✅

**M1: Professional Grocery Management (32 hours) - August 2025** ✅
- Store-layout optimized grocery lists with custom categories
- Drag-and-drop category management
- Staple item system with auto-population
- Professional iOS UI with SwiftUI
- Core Data architecture with performance optimization

**M2: Recipe Integration (16.5 hours) - September-October 2025** ✅
- Complete recipe catalog with CRUD operations
- Unified IngredientTemplate system for normalization
- Recipe-to-grocery list integration with category preservation
- Enhanced search across name, ingredients, tags, instructions
- Usage analytics and favorite tracking
- Recipe ingredient autocomplete with parse-then-search ✅
- Fuzzy matching and intelligent template alignment
- Performance: < 0.1s queries, < 0.5s complex operations

**M3: Structured Quantity Management (10.5 hours) - October 2025** ✅
- **Phase 1-2** (3 hours): Core data model & enhanced parsing ✅
- **Phase 3** (1.5 hours): Data migration with 100% success ✅
- **Phase 4** (2.5 hours): Recipe scaling service with fractions ✅
- **Phase 5** (2.5 hours): Quantity consolidation with unit conversion ✅
- **Phase 6** (1 hour): UI polish & comprehensive documentation ✅

**M3 Completion**: All 33 requirements complete, production-ready quality achieved

**M3.5: Foundation Validation & Testing (8.5 hours) - October 2025** ✅
- **Phase 1** (8.5 hours): Comprehensive validation and test infrastructure ✅
  - Template system validation (16 templates verified)
  - Core Data audit and documentation
  - Edge case analysis and handling
  - 75+ computed properties added across Recipe/Ingredient entities
  - **Automated validation test suite built** (6 test suites, 100% pass rate)
  - Performance validation (all operations < 0.5s)

**M3.5 Completion**: Test automation pattern established, 100% validation success, production-ready

**M4.1: Settings Infrastructure Foundation (1.5 hours) - October 2025** ✅
- UserPreferences Core Data entity (single-record pattern)
- UserPreferencesService with singleton pattern and auto-save
- Meal Planning preferences UI in SettingsView
- Real-time validation and persistence
- Duration (3-14 days) and start day (Sun-Sat) configuration

**M4.1 Completion**: Settings infrastructure complete, M4.2 ready to use preferences

**M4.2: Calendar-Based Meal Planning Core (~4 hours) - November 2025** ✅
- MealPlan and PlannedMeal Core Data entities with relationships
- MealPlanService with singleton pattern
- Calendar grid view with tap-to-add recipe functionality (M4.2.1-3)
- RecipePickerSheet with search, servings adjustment, manual fetching
- Date range picker enhancement (replaced duration stepper)
- Recipe usage tracking (usageCount, lastUsed)
- Sheet pattern discovery and fix (`.sheet(item:)` vs `.sheet(isPresented:)`)

**M4.2 Completion**: Functional meal planning operational, M4.3 ready for grocery integration

**M4: Meal Planning & Enhanced Grocery Integration (19.25 hours) - November 2025** ✅
- **M4.1**: Settings Infrastructure Foundation (1.5h) ✅
- **M4.2**: Calendar-Based Meal Planning Core (~4h) ✅
- **M4.3.1**: Recipe Source Tracking Foundation (3.5h) ✅
- **M4.3.2**: Scaled Recipe to List Integration (1.25h) ✅
- **M4.3.3**: Bulk Add from Meal Plan (2.5h) ✅
- **M4.3.4**: Meal Completion Tracking (1.0h) ✅
- **M4.3.5**: Ingredient Normalization - All 4 Phases (5.5h) ✅
  - Phase 1: Case normalization (Butter → butter)
  - Phase 2: Singular/plural with 13-item preserve-plural list
  - Phase 3: Abbreviation expansion (tbsp → tablespoon)
  - Phase 4: Variation handling (diced tomato → tomato)
- Complete grocery-recipe workflow operational
- 30% reduction in ingredient template fragmentation
- Intelligent plural preservation ("peas", "chocolate chips")
- Revolutionary meal planning to grocery automation

**M4 Completion**: Core workflow complete (planning accuracy: 90%), ready for CloudKit or TestFlight

**M5.0: App Renaming & TestFlight Deployment (6 hours) - December 2025** ✅
- Complete app rename from "GroceryRecipeManager" to "Forager"
- Professional app icon design (green sprout, grocery-themed)
- Bundle identifier migration (com.richhayn.forager)
- Systematic file and folder renaming
- Apple Developer Program enrollment ($99/year)
- App Store Connect configuration
- CloudKit production entitlements
- Internal TestFlight deployment
- Multi-tester beta program (3+ testers)
- Real device validation on physical iPhones

**M5.0 Completion**: Forager brand established, TestFlight operational, ready for M7 CloudKit sync

---

## 🚀 **IMMEDIATE NEXT STEPS**

### **M5.0 COMPLETE - M7 Ready to Start** ✅

With M5.0 completion, Forager is now:
- **Branded**: Professional "Forager: Smart Meal Planner" identity established
- **Deployed**: Internal TestFlight operational with multi-tester beta program
- **Validated**: Running successfully on real devices
- **Ready**: CloudKit-enabled and prepared for family collaboration

**Next Milestone: M7 - CloudKit Sync & External TestFlight**
- **M7.0: App Store Prerequisites (MANDATORY)** - 2-3 hours
  - Privacy policy creation and hosting
  - In-app privacy link implementation
  - App Privacy questionnaire completion
  - Display name disambiguation
- **M7.1-7.4: CloudKit Implementation** - 25-30 hours
  - CloudKit schema and sync foundation
  - Multi-user collaboration with CKShare
  - Conflict resolution and sync UI
- **M7.5-7.6: External TestFlight & Public Beta** - 5-9 hours
  - App Review submission
  - Public beta landing page
  - LinkedIn showcase

**Timeline**: 27-37 hours base, 32-42 hours with buffer (3-4 weeks including Apple Review)

**⚠️ CRITICAL**: M7.0 App Store Prerequisites are MANDATORY before external TestFlight submission

### **M4 Component Summary:**

**✅ M4.1: Settings Infrastructure Foundation - COMPLETE**
- Completed: October 2025
- Actual Time: 1.5 hours
- UserPreferences entity and service
- Meal planning settings UI

**✅ M4.2: Calendar-Based Meal Planning Core - COMPLETE**
- Completed: November 2025
- Actual Time: ~4 hours
- Calendar grid with recipe assignment
- RecipePickerSheet with search
- Date range picker

**✅ M4.3.1: Recipe Source Tracking Foundation - COMPLETE**
- Completed: November 22, 2025
- Actual Time: 3.5 hours (est: 2-2.5h, +40%)
- Many-to-many GroceryListItem ↔ Recipe relationships
- Display Options in Settings with toggle
- Recipe source badges with navigation
- 11/11 tests passing, production-ready

**✅ M4.3.2: Scaled Recipe to List Integration - COMPLETE**
- Completed: November 22, 2025
- Actual Time: 1.25 hours (est: 1.5-2h, -17%)
- Servings adjustment UI with scale warnings
- Real-time quantity scaling with fractions
- RecipeScalingService integration
- All tests passing, professional UI

**✅ M4.3.3: Bulk Add from Meal Plan - COMPLETE**
- Completed: November 24, 2025
- Actual Time: 2.5 hours (est: 2h, +25%)
- Bulk add button with progress overlay
- Servings adjustment UI enhancement (collapsible recipes)
- Scale indicators (e.g., "↕ 2.0x scale")
- Perfect integration: M4.3.1 badges, M4.3.2 scaling, M3 consolidation
- 5 core tests passing (85% coverage)
- Mathematical accuracy: 100%
- Production-ready

**✅ M4.3.4: Meal Completion Tracking - COMPLETE**
- Completed: November 24, 2025
- Actual Time: 1.0 hour (est: 45 min, +33%)
- Checkbox toggle for meal completion
- Visual feedback: green checkmark, strikethrough, opacity
- Core Data persistence with isCompleted and completedDate
- SwiftUI reactivity fix with refreshID
- Production-ready

**✅ M4.3.5: Ingredient Normalization - COMPLETE**
- Completed: November 26, 2025
- Actual Time: 5.5 hours (est: 4-5h, +10%)
- Complete 4-phase normalization pipeline:
  - Phase 1: Case normalization (2.5h)
  - Phase 2: Singular/plural with preserve-plural list (1.5h)
  - Phase 3: Abbreviation expansion (0.5h)
  - Phase 4: Variation handling with compound word fix (1h)
- 30% reduction in template fragmentation (50+ → 35 templates)
- 13-item preserve-plural list (peas, beans, chocolate chips, etc.)
- Handles "frozen peas" → "peas" (qualifier stripping)
- Handles "largeegg" compound words → "egg"
- StandardEmptyStateView component created
- Production-ready

### **Strategic Integration Points:**
- **M3 Phase 4 → M4.3**: Recipe scaling service enables scaled-to-list feature ✅
- **M3 Phase 5 → M4.3**: Quantity consolidation enhances grocery automation ✅
- **M4.1 → M4.3.1**: Settings infrastructure ready for Display Options ✅
- **M4.2 → M4.3**: Meal planning data ready for bulk grocery list generation ✅
- **M4.3.1 → M4.3.2+**: Core Data relationships enable recipe source display ✅
- **M4 → M7**: Meal planning data architecture ready for CloudKit family collaboration
- **M5.0 → M7**: TestFlight infrastructure ready for external beta and CloudKit sync
- **M3 + M4 → M8**: Ingredient parsing improvements leverage structured quantities
- **M7 → M9**: External beta data informs technical debt priorities
- **M3 + M4 → M10**: Rich analytics data from structured quantities and meal patterns
- **M9 → M11-M14**: Clean architecture foundation enables advanced intelligence platform

### **Timeline Summary:**
- **Core Platform (M1-M10)**: ~220-270 hours estimated
- **M1 Complete**: 32 hours ✅
- **M2 Complete**: 16.5 hours ✅
- **M3 Complete**: 10.5 hours ✅
- **M3.5 Complete**: 8.5 hours ✅
- **M4 Complete**: 19.25 hours ✅
- **M5.0 Complete**: 6 hours ✅
- **Total Completed (M1-M5.0)**: ~92.5 hours ✅
- **M7 Planned**: 32-42 hours (with buffer)
- **M6 Planned**: 12-18 hours (testing & AI augmentation)
- **M8 Planned**: 13-16 hours core (+15-20h optional ML) (ingredient parsing intelligence)
- **M9 Planned**: 135-165 hours (technical debt & optimization)
- **M10 Planned**: 8-12 hours (analytics & insights)
- **Remaining (M6-M10)**: ~200-253 hours (core) or ~215-273 hours (with M8.4 ML)

---

## 📝 **CURRENT DEVELOPMENT STATE**

### **Technical Foundation Complete:**
- **Structured Quantity Model**: numericValue, standardUnit, displayText, isParseable, parseConfidence ✅
- **Enhanced Parsing**: Numeric conversion, unit standardization, fraction handling ✅
- **Data Migration**: Complete one-time migration with 100% success ✅
- **Recipe Scaling**: Mathematical scaling with kitchen-friendly fractions ✅
- **Quantity Consolidation**: Intelligent merging with unit conversion ✅
- **Recipe Ingredient Autocomplete**: Parse-then-search with fuzzy matching ✅
- **Settings Infrastructure**: Professional settings tab operational ✅
- **Meal Planning**: Calendar-based planning with recipe assignment ✅
- **Help Documentation**: Comprehensive in-app user guide (HelpView.swift) ✅
- **Performance Architecture**: All targets met or exceeded ✅
- **Automated Testing**: Comprehensive validation test suite for future milestones ✅

### **Recipe Features Complete:**
- **Complete Recipe Catalog**: Professional list view with Core Data integration ✅
- **Enhanced Recipe Details**: Comprehensive timing, analytics, and ingredient display ✅
- **Recipe Management**: Full CRUD operations (create/read/update/delete) ✅
- **Recipe Scaling**: Professional scaling UI with live preview and fraction conversion ✅
- **Recipe Ingredient Autocomplete**: Smart ingredient entry with template linking ✅
- **Search and Navigation**: Multi-field filtering with intelligent ranking ✅
- **Favorite Toggle**: @ObservedObject UI refresh with Core Data persistence ✅
- **Usage Analytics**: Functional mark-as-used with usage count and date tracking ✅
- **Template System**: Ingredient parsing, template creation, grocery integration ✅
- **Meal Planning Integration**: Recipe assignment to meal plans with servings ✅

### **UI Enhancements Complete:**
- **Visual Indicators**: Color coding for parseable vs unparseable quantities ✅
- **Consolidation Badge**: Shows merge opportunities in grocery list toolbar ✅
- **Help System**: Comprehensive in-app documentation accessible from settings ✅
- **Calendar View**: Professional date-range meal planning interface ✅
- **Recipe Picker**: Search-enabled recipe selection with servings adjustment ✅

### **Ready for M4.3.1:**
- ✅ Core Data schema ready for relationship changes
- ✅ Settings infrastructure exists for Display Options
- ✅ GroceryListItem entity ready for many-to-many recipe relationships
- ✅ Recipe entity ready for contributedToItems relationship
- ✅ Meal planning data ready for bulk grocery generation
- ✅ All M4.2 foundations production-ready

---

## 📋 **MILESTONE DETAILS**

### **✅ M3: Structured Quantity Management - COMPLETE**

**Status**: ✅ Complete  
**Total Time**: 10.5 hours (target: 8-12 hours) ✅  
**Completion Date**: October 20, 2025

#### **Phase Summary:**

**✅ Phase 1-2: Core Data Model & Enhanced Parsing (3 hours)**
- Replaced string quantities with structured data (numericValue, standardUnit, displayText, isParseable, parseConfidence)
- Enhanced IngredientParsingService with numeric conversion and unit standardization
- Updated 10 files across codebase with zero build errors
- Performance: Sub-0.1s response times

**✅ Phase 3: Data Migration (1.5 hours)**
- QuantityMigrationService with batch processing and async/await
- Professional UI: Preview → Migration → Results workflow
- Settings infrastructure created
- 100% success: 24 parsed (75%), 8 text-only (25%)

**✅ Phase 4: Recipe Scaling Service (2.5 hours)**
- RecipeScalingService with mathematical quantity scaling
- Kitchen-friendly fraction conversion (1.5 → "1 1/2")
- Professional scaling UI with slider and quick buttons (0.25x-4x)
- Graceful degradation for unparseable ingredients
- Performance: < 0.5s for 20+ ingredient recipes

**✅ Phase 5: Quantity Merge Service (2.5 hours)**
- QuantityMergeService with intelligent consolidation logic
- UnitConversionService for volume/weight conversions (cups ↔ tbsp ↔ tsp, lb ↔ oz)
- ConsolidationPreviewView with professional preview UI
- Source tracking for recipe provenance
- Performance: < 0.3s analysis for 50+ items, < 0.8s merge execution
- User value: Reduces list redundancy by 30-50%

**✅ Phase 6: UI Polish & Documentation (1 hour)**
- Recipe ingredient autocomplete validated with M3 features
- Consolidation button with opportunity badge
- Visual indicators for quantity types (green dot, yellow dot, no dot)
- Comprehensive in-app help documentation (HelpView.swift)
- Learning notes and documentation finalized

**Key Achievements:**
- 95%+ parsing accuracy for common quantity formats
- Zero data loss during migration
- All performance targets exceeded
- Professional UI with visual feedback
- Comprehensive user documentation
- Foundation for M4 scaled recipe features

---

### **✅ M3.5: Foundation Validation & Testing - COMPLETE**

**Status**: ✅ Complete  
**Total Time**: 8.5 hours (target: 7 hours)  
**Completion Date**: October 25, 2025

#### **Phase Summary:**

**✅ Phase 1: Comprehensive Validation (8.5 hours)**
- Template system validation (16 templates verified)
- Core Data audit and documentation
- Edge case analysis and handling
- 75+ computed properties added across Recipe/Ingredient entities
- Automated validation test suite built (6 test suites)
- Performance validation (all operations < 0.5s)
- 100% test pass rate

**Key Achievements:**
- Test automation pattern established
- Production-ready validation confirmed
- Zero technical debt
- Foundation for efficient future development

---

### **✅ M4.1: Settings Infrastructure Foundation - COMPLETE**

**Status**: ✅ Complete  
**Total Time**: 1.5 hours (target: 1.5 hours) ✅  
**Completion Date**: October 28, 2025

#### **Implementation Summary:**

**Core Data Entity:**
- UserPreferences entity with single-record pattern
- Properties: mealPlanDuration (3-14 days), mealPlanStartDay (0-6)
- Codegen: Class Definition for automatic code generation

**Service Layer:**
- UserPreferencesService singleton pattern
- Automatic record creation on first access
- Auto-save with 0.3s debouncing
- Thread-safe Core Data operations

**UI Implementation:**
- Settings tab with Meal Planning section
- Duration stepper (3-14 days) with validation
- Start day picker (Sunday-Saturday)
- Real-time updates with proper data binding

**Key Achievements:**
- Professional settings infrastructure operational
- Zero build errors
- Clean service architecture
- Ready for M4.2 calendar integration

---

### **✅ M4.2: Calendar-Based Meal Planning Core - COMPLETE**

**Status**: ✅ Complete  
**Total Time**: ~4 hours (target: 2.5-3 hours, extended for UX improvements)  
**Completion Date**: November 3, 2025

#### **Implementation Summary:**

**Core Data Entities:**
- MealPlan entity (id, name, startDate, duration, dates)
- PlannedMeal entity (id, date, servings)
- Relationships: MealPlan ↔ PlannedMeal ↔ Recipe
- Proper cascade rules and data integrity

**Service Layer:**
- MealPlanService singleton pattern
- addRecipeToMealPlan() with date, plan, servings
- Date validation and availability checking
- Active meal plan management
- Recipe usage tracking (usageCount, lastUsed)

**UI Implementation:**
- MealPlanDetailView with calendar grid
- **M4.2.1-3**: Tap-to-add functionality
  - Tap empty day → RecipePickerSheet opens
  - Tap occupied day → Replace confirmation
  - Remove recipe with confirmation
- RecipePickerSheet with recipe list
  - Manual recipe fetching (avoids @FetchRequest sheet issues)
  - Search functionality
  - Servings adjustment
  - Add to plan functionality
- CreateMealPlanSheet with date range picker
  - Start and end date pickers (replaced duration stepper)
  - Day-of-week display for clarity
  - Auto-generated names
  - Date validation

**Key Technical Achievements:**

1. **Blank Sheet Bug Fix** (Critical Discovery):
   - Problem: `.sheet(isPresented:)` caused blank sheets with Core Data
   - Solution: Used `.sheet(item:)` pattern with `RecipePickerPayload`
   - Pattern discovered in own learning notes (M1 StaplesView pattern)
   - Created data payload with `Identifiable` protocol
   - Prevents timing issues between selection and presentation

2. **Date Range Picker Enhancement**:
   - Replaced duration stepper with end date picker
   - Shows "Mon" for start, "Sun" for end (day-of-week only)
   - Auto-calculates duration from date range
   - Better UX: users think in dates, not duration

3. **Manual Core Data Fetching**:
   - Replaced `@FetchRequest` with manual `fetch()` in sheets
   - Avoids context issues in modal presentations
   - Pattern: Load on `.onAppear` into `@State` array
   - More reliable for complex sheet hierarchies

**Key Achievements:**
- Functional meal planning operational
- Professional calendar interface
- Recipe assignment with servings tracking
- Recipe usage analytics working
- Sheet pattern best practices established
- Zero data integrity issues
- Ready for M4.3 grocery integration

---

### **✅ M4.3: Enhanced Grocery Integration - COMPLETE**

**Status**: ✅ Complete
**Total Time**: ~14.25 hours (M4.3.1: 3.5h, M4.3.2: 1.25h, M4.3.3: 2.5h, M4.3.4: 1h, M4.3.5: 5.5h)
**Completed**: November 2025

#### **Component Breakdown:**

**🚀 M4.3.1: Recipe Source Tracking Foundation (2-2.5 hours) - READY**

**Phase 1: Core Data Schema Changes** (45-60 min)
- Remove `sourceRecipeId` UUID property from GroceryListItem
- Add many-to-many relationship: `contributingRecipes` (GroceryListItem → Recipe)
- Add inverse relationship: `contributedToItems` (Recipe → GroceryListItem)
- Set delete rule: Nullify (independent lifecycle)
- Add fetch indexes for query optimization
- Lightweight Core Data migration (automatic)

**Phase 2: Settings UI Enhancement** (30-45 min)
- Create "Display Options" section in SettingsView
- Add `showRecipeSourcesOnGroceryItems` toggle preference
- Update UserPreferences entity with new boolean property
- Add display preference to UserPreferencesService
- Test settings persistence and real-time updates

**Phase 3: Foundation Integration** (45-60 min)
- Update addToShoppingList() to establish relationships
- Update IngredientTemplateService for relationship preservation
- Add computed property: groceryListItemRecipeNames
- Test relationship creation with single recipe
- Verify database integrity and cascade behavior
- Update unit tests for relationship logic

**Acceptance Criteria:**
- ✅ Many-to-many relationship operational between GroceryListItem and Recipe
- ✅ Legacy sourceRecipeId removed from codebase
- ✅ Display Options section in Settings with toggle
- ✅ Settings preference persists correctly
- ✅ Single recipe-to-list still works correctly
- ✅ Database migration successful with no data loss
- ✅ Zero build errors or warnings
- ✅ Foundation ready for M4.3.2+ features

---

#### **✅ M4.3.1: Recipe Source Tracking Foundation - COMPLETE**

**Completed**: November 22, 2025  
**Actual Time**: 3.5 hours  
**Status**: Production-ready, all acceptance criteria met

**What Was Built:**
- Many-to-many relationships (GroceryListItem ↔ Recipe)
- Display Options section in Settings
- Recipe source badges with horizontal scrolling
- Tappable navigation to recipe details
- Removal of legacy sourceRecipeId
- Fetch indexes for query optimization

**Bugs Fixed:**
1. Empty displayText in recipe ingredients (30 min)
2. Duplicate source text display (15 min)
3. Redundant quantity tags in recipe view (15 min)

**Test Results:**
- 11/11 tests passing ✅
- 6 test recipes created for validation
- Perfect integration with existing features
- Zero regressions

---

#### **✅ M4.3.2: Scaled Recipe to List Integration - COMPLETE**

**Completed**: November 22, 2025  
**Actual Time**: 1.25 hours  
**Status**: Production-ready, under estimate (-17%)

**What Was Built:**
- Servings adjustment UI with +/- stepper
- "Recipe makes: X servings" display
- "Adding for: Y servings" adjustable (0.25x to 4x range)
- Orange warning: "Quantities will be scaled X.X×"
- Real-time quantity scaling preview
- Blue text for scaled quantities
- Gray italic for original quantities
- Fraction formatting (½, ¼, ¾, etc.)
- RecipeScalingService integration

**Test Results:**
- All tests passing ✅
- 0.5x, 1.5x, 2.0x scaling validated
- Fraction handling perfect
- Recipe badges working (M4.3.1 integration)
- Non-parseable items handled correctly

---

#### **✅ M4.3.3: Bulk Add from Meal Plan - COMPLETE**

**Completed**: November 24, 2025  
**Actual Time**: 2.5 hours (est: 2h, +25% for enhancement)  
**Status**: Production-ready, 85% test coverage

**What Was Built:**

*Core Functionality:*
- "Add All to Shopping List" button in meal plan detail
- SelectListSheet for list selection and recipe review
- Progress overlay with recipe names and percentage
- Success messaging with accurate counts
- Background processing (async/await)
- Recipe source tracking integration (M4.3.1)
- Quantity scaling integration (M4.3.2)

*Enhancement - Servings Adjustment UI:*
- Collapsible "Recipes to Add" section
- Individual servings adjusters per recipe (+/- buttons)
- Scale factor indicators (e.g., "↕ 2.0x scale" in orange)
- State tracking via UUID → Int16 dictionary
- Min/max bounds enforcement (1-99 servings)
- Visual feedback when servings differ from defaults

**Files Modified:**
- MealPlanDetailView.swift (~230 lines added)
- SelectListSheet.swift (~180 lines enhanced)

**Test Results - 5 Core Tests Passing:**
1. **Basic Bulk Add**: ✅ 21 items from 3 recipes
2. **Recipe Source Badges**: ✅ All items tagged correctly
3. **Scaled Quantities**: ✅ 100% accurate (0.5x, 1.5x, 2.0x)
4. **Servings Adjustment UI**: ✅ Professional
5. **Consolidation Integration**: ✅ Perfect (21 → 18 items, math 100% accurate)

**Integration Validation:**
- M4.3.1 (Recipe Source Tracking): ✅ Perfect integration
- M4.3.2 (Quantity Scaling): ✅ Perfect integration
- M3 Phase 5 (Consolidation): ✅ Perfect with scaled recipes
- M2 (IngredientTemplateService): ✅ Name-based soft links working

**Performance:**
- 3 recipes: < 1 second ✓
- UI responsive: 60fps ✓
- Build quality: 0 errors, 0 warnings ✓

**User Experience Wins:**
- One-tap bulk add
- Flexible servings adjustments
- Visual progress feedback
- Clear success confirmation
- Recipe traceability via badges
- Smart automatic consolidation

---

#### **✅ M4.3.4: Meal Completion Tracking - COMPLETE**

**Completed**: November 24, 2025
**Actual Time**: 1.0 hour

**Delivered:**
- isCompleted boolean property on PlannedMeal
- Checkbox/checkmark UI on meal rows
- Visual feedback (strikethrough, opacity)
- Core Data persistence
- Simple toggle behavior

---

#### **✅ M4.3.5: Ingredient Normalization - CANCELLED (Superseded by M8.3.1)**

**Original Estimate**: 4 hours
**Status**: CANCELLED — All 4 normalization phases (case, singular/plural, abbreviation, variation) were implemented as part of `IngredientTemplateService` and hardened in M8.3.1 (template hygiene, compound plural fix). No separate milestone needed.

**PRD**: docs/prds/M4.3.5-INGREDIENT-NORMALIZATION-PRD.md (historical reference)

---


---

### **⏸️ M6: Testing Foundation & AI Augmentation - DEFERRED** 🔜

**Status**: 🔜 Deferred (executing after M7)
**Estimated Time**: 20-30 hours
**Execution Plan**: M7 (CloudKit + External Beta) → M6 (Testing Foundation) → M8 (Parsing)
**PRD**: docs/prds/milestone-6-testing-foundation-ai-augmentation.md

**Why Deferred?**
Originally planned after M5, M6 was strategically deferred to execute after M7 completes:
- ✅ External beta proves app stable before investing in testing infrastructure
- ✅ Test coverage in place BEFORE M8 parsing improvements (13-16h) and M9 refactoring (135-173h)
- ✅ AI test reviewer learns patterns from M8 implementation
- ✅ CI/CD established before external users depend on stability

**Planned Phases:**
- **M6.1**: Human Test Baseline (50%+ coverage on services)
- **M6.2**: AI Test Review Setup (operational on every PR)
- **M6.3**: Testing Standards (documentation and CI/CD)

**Key Deliverables:**
- 50%+ test coverage on critical services
- AI test reviewer operational on every PR
- Testing standards documented
- CI/CD pipeline with automated test execution
- Foundation for autonomous testing evolution

**Impact**: Establishes testing foundation before major refactoring, protecting quality during M8-M9 development.

---

### **🔄 M7: CloudKit Sync, Household Sharing & External TestFlight - IN PROGRESS** 🚀

**Status**: 🔄 In Progress - M7.0-M7.4 Complete ✅, **M7.6 External TestFlight 🚀 Next**
**Estimated Time**: 52-60 hours total
**Actual Progress**: ~37 hours (M7.0: 3h, M7.1: 6.5h, M7.2: 15h, M7.2.3: 12.25h)
**Remaining**: 15-23 hours (M7.3, M7.5, M7.6, M7.7)
**Dependencies**: M5.0 complete ✅
**PRD**: docs/prds/milestone-7-cloudkit-sync-external-testflight.md (v2.2 - Shared Zone Architecture)

**⚠️ ARCHITECTURE PIVOT (Dec 21, 2025)**: Pivoted from CKShare (per-item sharing) to Shared Household Zone (all data shared automatically). See learning note 25 for rationale.

**M7.0: App Store Prerequisites (3 hours) - COMPLETE** ✅
- ✅ **M7.0.1**: Privacy Policy Creation & Hosting (1h)
- ✅ **M7.0.2**: Privacy Policy Integration (1h)
- ✅ **M7.0.3**: App Privacy Questionnaire (30min)
- ✅ **M7.0.4**: Display Name Disambiguation (30min)

**M7.1: CloudKit Sync Foundation (6.5 hours) - COMPLETE** ✅
- ✅ **M7.1.1**: CloudKit Schema Validation (1.5h)
- ✅ **M7.1.2**: CloudKitSyncMonitor Service (2h)
- ⏭️ **M7.1.3**: Multi-Device Testing (skipped - integrated into debugging)

**M7 CloudKit Multi-Device Sync Debugging (4 hours) - COMPLETE** ✅
- ✅ **Problem 1**: Production Schema Lock (45 min)
  - Fixed entitlements to force Development environment
  - Learning: Entitlements file takes precedence over code
- ✅ **Problem 2**: Duplicate Categories Race Condition (45 min)
  - Implemented CloudKit import observer pattern
  - Wait for NSPersistentCloudKitContainer.eventChangedNotification
- ✅ **Problem 3**: Observer/Timeout Race Condition (60 min)
  - Added serial queue synchronization (PersistenceController.setupQueue)
  - Serial queue guarantees atomic check-set-execute
- ✅ **Problem 4**: Sample Data Creating Fake Staples (30 min)
  - Removed sample data from production app launches
  - Users start with clean slate (7 categories only)
- ✅ **Testing**: Perfect bi-directional sync across 2 devices (<5s latency)
- ✅ **Documentation**: [27-m7-cloudkit-sync-debugging.md](archive/27-m7-cloudkit-sync-debugging.md)

**M7.2: Shared Household Zone (~40 hours) - COMPLETE** ✅
- ✅ **M7.2.1**: Household Setup & Shared Zone (1.25h) - COMPLETE
- ✅ **M7.2.2**: Member Invitation & Acceptance (11-12h) - COMPLETE (Jan 12, 2026)
- ✅ **M7.2.2 Leave Flow**: Leave Household, Rejoin Fix, Dead Code Cleanup (~12h) - COMPLETE (Feb 2, 2026)
- ✅ **M7.2.3**: CloudKit Hardening & Shared Data Architecture (12.25h) - COMPLETE (88% accuracy)
  - ✅ Phase 0: Core Data Model v2 (2h) - household relationships
  - ✅ Prep A: StoreIdentityLogger (0.5h) - DEBUG utility
  - ✅ Phase 1: Persistence Decomposition (5h) - PersistenceController, DefaultSeeder, MigrationRunner
  - ✅ Phase 2: Scope-Based Infrastructure (3.75h) - DataScope, ScopeProvider, Factory, manual files
  - ✅ Phase 3.8: CategoryDeduplicator (1h) - dedupe-after-creation
  - ✅ Phase 4: Attach-Then-Share Migration (3.5h) - Migration UI + CloudKit sync fix
    - Phase 4.1: Migration Prompt UI (1.5h)
    - Phase 4.2-4.4: Backend Testing & Fix (2h)
  - ✅ **Critical Bug Fixed**: Missing context.save() after container.share()
  - ✅ **Migration Validated**: 61 items to CloudKit shared zone
- ✅ **M7.3.1**: Rename Household - COMPLETE (Jan 13, 2026)
- ✅ **M7.3.3**: Remove Member & Delete Household - COMPLETE (Feb 3, 2026)

**Architecture Decision (Dec 23, 2025):**
- ✅ **ALL 8 entities household-scoped**: GroceryItem, Recipe, WeeklyList, MealPlan, Tag, Ingredient, GroceryListItem, IngredientTemplate
- ✅ **Security-first**: Explicit data ownership prevents leakage
- ✅ **Consistency**: Zero special cases, one pattern for all entities
- ✅ **Future-proof**: Clean extension path (PublicIngredientTemplate when needed)
- ✅ **Documentation**: ADR 008, Learning Note 26, M7.2 PRD updated

**Architecture Change:**
- ❌ **Abandoned**: CKShare per-item sharing (3.5h invested)
- ✅ **New Approach**: CloudKit Shared Zones (household database)
- ✅ **Better UX**: Invite once, share everything automatically
- ✅ **Documentation**: Complete technical framework and PRD

**M7.3: Household Management & Error Handling (4-6 hours)**
- ✅ **M7.3.1**: Rename Household - COMPLETE
- ✅ **M7.3.3**: Remove Member & Delete Household - COMPLETE (Feb 3, 2026)
- ✅ **M7.3.4**: Error Handling & Stability Improvements - COMPLETE (Feb 5, 2026)
  - P0: Ghost Data bug fix, replace exit(0) with "Check Again"
  - P1: CloudKitErrorMapper, OSLog integration
  - Bonus: householdKey filtering across all autocomplete surfaces

**M7.4: UI Polish & Pre-Launch Fixes (~4 hours) - ✅ COMPLETE**
- Apple Music-style bottom navigation with inline search
- Hamburger menu for Settings/Categories
- Keyboard search bar fix
- Filter pill sizing improvements
- **Note**: Original M7.4 (Sync Status UI) was SKIPPED - dual-store architecture makes it unnecessary
- PRD: `docs/prds/active/m7.4-ui-polish-pre-launch.md`

**M7.5: Architecture Hardening - UX/Service Cleanup (18.5-24.5 hours) - ⏸️ DEFERRED POST-LAUNCH**
- **Phase 1**: Service Ownership of Saves (4-6h)
  - Eliminate 39 scattered save() calls across 18 views
  - Create RecipeService, WeeklyListService
  - Intent-style service methods
- **Phase 2**: SwiftUI Navigation Cleanup (11.5-14.5h)
  - Replace 60+ boolean states with enum routing
  - Fix member count CloudKit refresh bug
- **Phase 3**: UX Polish & Invariant Tests (3-4h)
  - EmptyStateView standardization
  - 7 Core Data invariant tests

**Why Deferred?** M7.5 is developer-facing code quality. Users won't notice the difference. Prioritizing user-visible polish (M7.4) and parsing fixes (M8) before launch.

**PRD**: [docs/prds/m7.5-architecture-hardening-ux-service-cleanup.md](prds/m7.5-architecture-hardening-ux-service-cleanup.md)

**M7.6: Pre-Launch Prep & TestFlight Submission (~12 hours) — ✅ COMPLETE**
- **M7.6.1**: App Configuration (0.5h) — ✅ COMPLETE (iOS 18.0 target, branded launch screen with light/dark)
- **M7.6.2**: Production Gating (0.5h) — ✅ COMPLETE (`#if DEBUG` for developer tools)
- **M7.6.3**: Onboarding Flow (~4h) — ✅ COMPLETE (coach marks, sample data, first-launch loading screen)
- **M7.6.4**: Schema Cleanup P0 (~1h) — ✅ COMPLETE (removed Tag + LeaveRequest, fixed Recipe.plannedMeals)
- **M7.6.5**: Schema Cleanup P1 (~1.5h) — ✅ COMPLETE (renamed ownerEmail, fixed delete rules, code-schema mismatches)
- **M7.6.6**: Schema Cleanup P2 (~1.5h) — ✅ COMPLETE (removed unused fields, fixed sourceURL tags hack, naming)
- **M7.6.7**: TestFlight Submission (~2h) — ✅ COMPLETE (schema deployed to Production, archive uploaded, Apple approved, external testers active)
- **M7.6.8**: Owner Display Name Fix + Beta Bugs (~3h) — ✅ COMPLETE (PRs #32, #33 — repurposed ownerEmail for display name, fixed empty nameComponents detection, cross-device verified)
- **PRD**: `docs/prds/active/m7.6-pre-launch-prep-testflight.md`, `docs/prds/complete/m7.6.8-owner-display-name-fix.md`

**M7.7: App Store Submission & Public Presence (3-5 hours) — 📋 READY**
- **M7.7.1**: Beta Landing Page (1-2h) — GitHub Pages with TestFlight link, features, screenshots
- **M7.7.2**: GitHub README Update (0.5h) — Portfolio-quality README with badges
- **M7.7.3**: App Store Listing (1-2h) — Description, keywords, screenshots, category
- **M7.7.4**: App Store Submission (0.5h) — Submit for App Store review
- **PRD**: `docs/prds/active/m7.7-app-store-submission.md`

**Success Criteria:**
- [✅] Privacy policy published and accessible (M7.0)
- [✅] All 10 entities sync via CloudKit (M7.1)
- [✅] Multi-device sync < 5s latency (M7.1)
- [✅] CloudKit debugging complete (M7 Debug)
- [✅] Household setup working (M7.2.1)
- [✅] CloudKit hardening complete (M7.2.3 all phases)
- [✅] Attach-then-share migration validated (M7.2.3 Phase 4)
- [✅] 61 items migrated to CloudKit shared zone (M7.2.3 Phase 4)
- [ ] Household collaboration working (M7.2.2)
- [ ] Conflict resolution reliable (M7.3)
- [ ] Sync status UI informative (M7.4)
- [ ] Service layer cleanup complete (M7.5)
- [ ] Navigation patterns standardized (M7.5)
- [ ] Empty states consistent (M7.5)
- [ ] External TestFlight approved (M7.6)
- [ ] Public beta launched (M7.7)
- [ ] 10+ external beta testers active

**Requirements**: 39 total
- ✅ **Complete (27)**: 4 App Store prerequisites + 5 CloudKit sync + 4 debugging fixes + 2 household setup + 3 household management + 4 error handling + 5 UI polish
- ⏳ **Remaining (12)**: 5 external TestFlight (M7.6) + 3 public beta (M7.7) + 4 architecture hardening (M7.5 — deferred post-launch)

---

### **⏳ M6: Testing Foundation & AI Augmentation - PLANNED (Post-Launch)**

**Status**: ⏳ Planned (post-launch priority)
**Estimated Time**: 12-18 hours
**Dependencies**: M7.7 complete (app launched)

**Progress to Date**: M8 work established a solid test foundation with 102 unit tests across 7 test files (parsing, telemetry, merge, validation, normalization). However, significant gaps remain in service layer coverage and integration testing for code that has been in place since M1-M4. This milestone should be reviewed post-launch to identify additional tests needed for long-standing code paths.

**Phase 1: Human Test Baseline** (5-7 hours)
- **M6.1.1: Core Data & Model Tests** (2-3h)
  - Entity relationship validation
  - Data integrity tests
  - Migration and persistence tests
- **M6.1.2: Service Layer Tests** (2-3h)
  - IngredientParsingService tests
  - RecipeScalingService tests
  - QuantityMergeService tests
  - IngredientTemplateService tests
- **M6.1.3: Critical Workflow Tests** (1-2h)
  - Recipe-to-grocery flow
  - Meal plan to list generation
  - Category assignment workflows
- **Target**: 50%+ coverage on critical services

**Phase 2: AI Test Review Setup** (3-4 hours)
- **M6.2.1: CLI Refinement** (1-1.5h)
  - Enhance diff parsing for iOS project structure
  - Add context gathering (recent commits, PR description)
  - Improve prompt engineering for Given/When/Then format
- **M6.2.2: GitHub Actions Workflow** (1.5-2h)
  - Configure PR trigger workflow
  - Set up API key management via secrets
  - Add comment posting to PRs
  - Test on sample PRs
- **M6.2.3: Documentation & Integration** (0.5-1h)
  - Document usage and capabilities
  - Update development guidelines
  - Team onboarding materials
- **Target**: ≥90% PRs receive suggestions, ≥75% found useful

**Phase 3: Testing Standards & Infrastructure** (2-3 hours)
- **M6.3.1: Test Architecture Standards** (1-1.5h)
  - Document test organization patterns
  - XCTest best practices guide
  - Mock and fixture guidelines
- **M6.3.2: Coverage Monitoring** (0.5-1h)
  - Set up Xcode coverage reporting
  - Define coverage targets per layer
  - Create coverage dashboard
- **M6.3.3: CI/CD Test Foundation** (0.5-1h)
  - Configure automated test runs
  - Set up test result reporting
  - Define passing criteria

**Phase 4: Phase 3 Prep (Optional)** (2-4 hours)
- **M6.4.1: Domain Model Documentation** (1-1.5h)
  - Document business rules explicitly
  - Entity relationship diagrams with rules
  - Validation logic specifications
- **M6.4.2: Architecture Diagrams** (1-1.5h)
  - Service layer architecture
  - Data flow diagrams
  - Component interaction maps
- **M6.4.3: Gap Detection Experiments** (1-2h)
  - Prototype semantic gap detector
  - Test on historical PRs
  - Refine detection heuristics
- **Note**: Can be deferred to M6.5 or M7 if needed

**Success Criteria:**
- [ ] 50%+ service layer coverage achieved
- [ ] All Core Data entities have basic tests
- [ ] 5+ critical workflows validated
- [ ] AI reviewer operational (≥90% PR activation)
- [ ] ≥75% of AI suggestions found useful
- [ ] Testing standards documented
- [ ] CI/CD running tests on every commit
- [ ] Zero flaky tests, < 30s test suite
- [ ] Documentation through tests

---

### **✅ M8: Ingredient Parsing Intelligence - COMPLETE** 🧠

**Status**: ✅ Complete (February 7-8, 2026)
**Actual Time**: ~17 hours delivered (+15-20h optional ML deferred)
**PRD**: [M8 Meta-PRD](prds/m8-ingredient-parsing-intelligence-meta-prd.md)

**Overview**: Data-driven evolution of ingredient parsing from 95% baseline accuracy to 98%+ through resilience infrastructure, hybrid NLP architecture, template hygiene, and automatic grocery merging.

**Phase Breakdown:**

**M8.1: Parsing Resilience & Telemetry (~3 hours) - ✅ COMPLETE**
- Yellow badge for low-confidence ingredients on recipe detail and grocery list views
- ParsingTelemetryService logging to local JSON (20/20 tests passing)
- Telemetry integration in IngredientParsingService
- Sample low-confidence recipes for testing
- Scope reduction: EditIngredientSheet removed (redundant with inline editing)
- **Source**: [M7.5 Parsing Resilience PRD](prds/parsing/M7.5-parsing-resilience-polish-prd.md)

**M8.2: Telemetry Analysis & Strategy - SKIPPED**
- PRD analysis proved sufficient; telemetry infrastructure used for post-launch monitoring
- Pattern analysis was done during M8.3 planning via the Meta-PRD

**M8.3: Hybrid NLP Parser (~11 hours) - ✅ COMPLETE**
- HybridIngredientParser with protocol abstraction
- RegexIngredientParser (7 pattern categories, ~650 lines)
- NLPIngredientParser using Apple NaturalLanguage (~310 lines)
- Fast path (80% inputs < 0.05s) + Smart path (15% inputs < 0.2s)
- 58 new test cases across 3 test files
- **Result**: 95% → 98%+ accuracy, low-confidence rate: 5% → 2%
- **Source**: [M8.0 Parsing Improvements PRD](prds/parsing/M8.0-parsing-improvements-foundation-prd.md)

**M8.3.1: Template Name Hygiene & Badge Fix (~3 hours) - ✅ COMPLETE**
- Routed all 5 template creation paths through `findOrCreateTemplate` (normalization + dedup)
- `needsReview` heuristic on IngredientTemplate (parentheticals, digits, qualifier suffixes, unit prefixes)
- Yellow badges + "Review (N)" filter pill on Ingredients tab
- Merge-on-rename deduplication (renaming to existing name merges instead of blocking)
- Compound plural normalization fix ("black beans", "red pepper flakes" stay plural)
- Badge threshold raised to `< 0.7` (aligned with M8.3 confidence tiers)
- Scroll clearance fix for custom bottom navigation
- 21 new unit tests (validation heuristics + normalization)
- **Source**: [M8.3.1 PRD](prds/complete/m8.3.1-template-hygiene-badge-fix.md)

**M8.3.2: Auto-Merge Grocery Quantities (~3 hours) - ✅ COMPLETE**
- GroceryMergeService with testable merge logic (same unit, convertible, unparseable)
- Wired into AddIngredientsToListView (replaces string concatenation)
- Consolidation button removed from GroceryListDetailView
- Confidence tracking: `min(existing, incoming)` preserves yellow badges through merges
- 19 new unit tests covering all merge scenarios
- **Source**: [M8.3.2 PRD](prds/complete/m8.3.2-auto-merge-grocery-quantities.md)

**M8.4: ML-Powered Parsing (15-20 hours) - DEFERRED** 🎓
- Custom CoreML model trained on user corrections
- **Deferred to post-launch**: M8.3 achieves 98%+ accuracy (professional-grade)
- **Source**: [M9.5 ML-Powered Parsing PRD](prds/parsing/M9.5-ml-powered-parsing-prd.md)

**Success Criteria:**
- [x] Professional UX for parsing failures (M8.1)
- [x] Telemetry collecting real data (M8.1)
- [x] Parsing accuracy: 95% → 98%+ (M8.3)
- [x] Low-confidence rate: 5% → 2% (M8.3)
- [x] Zero regressions on existing patterns (M8.3)
- [x] Clean ingredient template names (M8.3.1)
- [x] Automatic quantity merging on grocery lists (M8.3.2)
- [ ] (Optional) ML accuracy: 98% → 99.5%+ (M8.4 — deferred)

---

### **⏳ M9: Technical Debt & Codebase Optimization - PLANNED** 🏗️

**Status**: ⏳ Planned
**Estimated Time**: 135-165 hours total
**Dependencies**: M7 complete (external beta launched)
**PRD**: [M9 Technical Debt PRD](prds/m9-technical-debt-codebase-optimization.md)

**Overview**: Comprehensive technical debt remediation and codebase optimization before scaling to advanced features. Reduces codebase by ~2,000 lines, improves performance 50-80%, and establishes architectural patterns for long-term maintainability.

**Strategic Impact:**
- **Code Reduction**: ~2,000 lines eliminated (RecipeListView 1,204→400 lines)
- **Performance**: 50-80% improvement in critical paths
- **Maintainability**: Consistent patterns across 400+ service methods
- **Quality**: Professional test coverage and error handling
- **Future-Proofing**: Clean foundation for M10-M14 features

**Phase Breakdown:**

**Phase 1: Quick Wins (20-25 hours)**
- M9.1: String Utilities & Code Deduplication (6-8h)
- M9.2: Performance Optimizations (7-9h)
- M9.3: Thread Safety & Context Management (7-8h)
- **Impact**: 30% performance improvement, safer Core Data operations

**Phase 2: Architecture & Structure (40-50 hours)**
- M9.4: Service Consistency & Error Handling (15-18h)
- M9.5: Dependency Injection Foundation (10-12h)
- M9.6: View Decomposition (15-20h)
- **Impact**: 50% reduction in RecipeListView, consistent service layer

**Phase 3: Performance & Data Model (60-70 hours)**
- M9.7: Query Optimization (20-25h)
- M9.8: Batch Operations (15-18h)
- M9.9: Data Model Cleanup (15-17h)
- M9.10: Migration Strategy (10-12h)
- **Impact**: 80% query performance improvement, clean schema

**Phase 4: Quality & Standards (15-20 hours)**
- M9.11: Code Standards & Linting (8-10h)
- M9.12: Test Coverage (4-6h)
- M9.13: Logging & Observability (3-4h)
- **Impact**: Professional quality gates, comprehensive monitoring

**Recommended Path**: Phase 1 → Evaluate → Phase 2 → Phase 4 (skip Phase 3 if performance acceptable)

**Success Criteria:**
- [ ] ~2,000 lines removed from codebase
- [ ] 50-80% performance improvement in critical paths
- [ ] RecipeListView: 1,204 → 400 lines
- [ ] Zero N+1 queries remaining
- [ ] Consistent error handling across all services
- [ ] Thread safety patterns established
- [ ] Professional test coverage (50%+ critical paths)

---

### **⏳ M10: Analytics & Insights - PLANNED**

**Status**: ⏳ Planned
**Estimated Time**: 8-12 hours
**Dependencies**: M4 complete (structured data from meal planning)

**Phase 1: Analytics Infrastructure** (2-3 hours)
- Analytics service architecture
- Data aggregation and caching
- Query optimization for trends

**Phase 2: Insights Dashboard** (3-4 hours)
- Usage statistics visualization
- Cost tracking and trends
- Recipe popularity metrics
- Ingredient frequency analysis

**Phase 3: Recommendations** (2-3 hours)
- Smart recipe suggestions
- Seasonal ingredient highlights
- Budget optimization tips
- Meal plan optimization

**Phase 4: Export & Sharing** (1-2 hours)
- Data export capabilities
- Report generation
- Share insights with family

**Success Criteria:**
- [ ] Dashboard loads < 1s
- [ ] Meaningful insights generated
- [ ] Trend analysis over time
- [ ] Actionable recommendations
- [ ] Export functionality working
- [ ] Leverages M3 structured quantities

---

### **⏳ M11-M14: Advanced Intelligence Platform - PLANNED**

**Status**: ⏳ Future Development
**Estimated Time**: 40-60 hours total
**Dependencies**: M1-M10 complete

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

---

## ⏱️ **TIME TRACKING & ESTIMATES**

### **Completed Work:**
- **M1**: 32 hours (estimated 30-35h) - ✅ 91% accuracy
- **M2**: 16.5 hours (estimated 15-18h) - ✅ 92% accuracy
- **M3**: 10.5 hours (estimated 8-12h) - ✅ 88% accuracy
- **M3.5**: 8.5 hours (estimated 7h) - ✅ 82% accuracy
- **M4**: 19.25 hours (all phases) - ✅ 90% accuracy
- **M5.0**: 6 hours (estimated 5-7h) - ✅ 86% accuracy
- **M7.0**: 3 hours (estimated 2-3h) - ✅ 100% accuracy
- **M7.1**: 6.5 hours (estimated 6-7h) - ✅ 93% accuracy
- **M7.2.1**: 1.25 hours (estimated 1-1.5h) - ✅ 100% accuracy
- **CloudKit Debug**: 4 hours (unplanned) - ✅ N/A
- **M7.2.3**: 12.25 hours (estimated 14-17h) - ✅ 88% accuracy
- **M7.2.2 Leave**: ~12 hours (leave flow, rejoin fix, dead code cleanup)
- **M7.3.1**: Rename Household (~1h)
- **M7.3.3**: Remove Member & Delete Household (~3h)
- **M7.3.4**: Error Handling & Stability (~2h)
- **M7.4**: UI Polish & Pre-Launch Fixes (~4h)
- **M8.1**: Parsing Resilience & Telemetry (~3h)
- **M8.3**: Hybrid NLP Parser (~11h)
- **M8.3.1**: Template Hygiene & Badge Fix (~3h)
- **M8.3.2**: Auto-Merge Grocery Quantities (~3h)
- **M7.6**: Pre-Launch Prep (M7.6.1-M7.6.6) (~9h)
- **M7.6.7**: Version bump & code prep (~0.5h)
- **Total Completed**: ~188 hours

### **Planned Core Platform:**
- **M7**: 27-37 hours base, 32-42 hours with buffer (CloudKit sync + external TestFlight)
  - M7.0: 2-3 hours (App Store prerequisites - MANDATORY) ✅
  - M7.1: 6-7 hours (CloudKit foundation) ✅
  - M7.2.1: 1-1.5 hours (Household setup) ✅
  - CloudKit Debug: 4 hours (Multi-device sync) ✅
  - M7.2.3: 14-17 hours (CloudKit hardening) ✅ (12.25h actual, 88% accuracy)
  - M7.2.2 Leave Flow: ~12 hours (leave, rejoin, cleanup) ✅
  - M7.3.1: Rename Household (~1h) ✅
  - M7.3.3-7.4: ~8 hours (Remove member, error handling, UI polish) ✅
  - M7.6: 10-12 hours (Pre-launch prep, schema cleanup, TestFlight) 🚀
  - M7.7: 3-5 hours (App Store submission, landing page) ⏳
- **M6**: 12-18 hours (comprehensive testing & AI augmentation)
- **M8**: 13-16 hours core (+15-20h optional ML) (ingredient parsing intelligence)
- **M9**: 135-165 hours (technical debt & codebase optimization)
- **M10**: 8-12 hours (analytics and insights)

**Total Core Platform (M1-M10)**: ~220-270 hours estimated (core) or ~235-290 hours (with M8.4 ML)

### **Planning Accuracy:**
- **Phase-level estimates**: Consistently accurate within ±15 minutes
- **Milestone estimates**: Excellent accuracy for M1-M4.1 (88-100%)
- **Risk mitigation**: Proactive problem identification preventing scope creep
- **Overall Average**: 88% accuracy across completed work

### **Quality Metrics:**
- **Build Success Rate**: 100% (zero breaking changes)
- **Performance Targets**: 100% met or exceeded
- **Data Integrity**: 100% (zero data loss)
- **Feature Completeness**: 100% (all acceptance criteria met)

### **Productivity Insights:**
- **Phase-based planning**: Highly effective for focus and progress tracking
- **Incremental validation**: Prevents compound errors and rework
- **Learning notes**: Valuable for pattern recognition and decision reference
- **Documentation-first**: Reduces ambiguity and improves execution speed
- **UX iterations**: M4.2 time extended for date picker enhancement - worthwhile investment

---

## 🎯 **SUCCESS CRITERIA BY MILESTONE**

### **M3: Structured Quantity Management** ✅
- ✅ Structured quantity data model operational
- ✅ 95%+ parsing accuracy for common quantity formats
- ✅ Recipe scaling from 0.25x to 4x
- ✅ Kitchen-friendly fraction display
- ✅ Intelligent shopping list consolidation
- ✅ Unit conversion support (volume and weight)
- ✅ Recipe ingredient autocomplete validated
- ✅ User-facing help documentation
- ✅ Sub-0.5s performance for all operations
- ✅ Comprehensive documentation complete

### **M4: Meal Planning & Enhanced Grocery Integration**
- [x] Settings infrastructure with meal planning preferences (M4.1) ✅
- [x] UserPreferences entity with duration and start day (M4.1) ✅
- [x] Calendar-based meal planning interface (M4.2) ✅
- [x] MealPlan and PlannedMeal Core Data entities (M4.2) ✅
- [x] Recipe assignment with tap-to-add workflow (M4.2) ✅
- [x] Recipe usage tracking (usageCount, lastUsed) (M4.2) ✅
- [ ] Many-to-many recipe source relationships (M4.3.1)
- [ ] Display Options settings section (M4.3.1)
- [ ] Recipe source tracking foundation (M4.3.1)
- [ ] "Add All to Shopping List" from meal plan (M4.3.2)
- [ ] Scaled recipe to list with servings (M4.3.3)
- [ ] Recipe source tags display (M4.3.4)
- [ ] Smart quantity consolidation for meal plans (M4.3)
- [ ] Sub-0.5s performance maintained

### **M5: Production Infrastructure & CloudKit**
- [ ] Apple Developer Account activated
- [ ] TestFlight build deployed successfully
- [ ] Real device testing complete on 3+ devices
- [ ] CloudKit schema operational
- [ ] Real-time multi-user sync working
- [ ] Conflict resolution tested and reliable
- [ ] Family sharing flows intuitive
- [ ] Performance: < 2s sync for typical changes

### **M6: Testing Foundation & AI Augmentation**
- [ ] 50%+ service layer coverage achieved
- [ ] All Core Data entities have basic tests
- [ ] 5+ critical workflows validated
- [ ] AI reviewer operational (≥90% PR activation)
- [ ] ≥75% of AI suggestions found useful
- [ ] Testing standards documented
- [ ] CI/CD running tests on every commit
- [ ] Zero flaky tests, < 30s test suite

### **M10: Analytics & Insights**
- [ ] Usage analytics tracking
- [ ] Insights dashboard with visualizations
- [ ] Trend analysis over time
- [ ] Smart recommendation engine
- [ ] Export capabilities
- [ ] Leverages structured quantity data
- [ ] Performance: < 1s for dashboard load

---

## 🔍 **RISK MANAGEMENT**

### **Current Risks: NONE**

All identified risks from M1-M3 have been successfully mitigated through:
- Phase-based incremental development
- Comprehensive validation at each step
- Performance monitoring throughout
- Transaction safety and rollback capabilities
- Professional architecture patterns

### **Future Considerations:**

**M4.3: Recipe Source Tracking**
- **Risk**: Core Data migration with many-to-many relationships
- **Mitigation**: Lightweight automatic migration, proper delete rules, comprehensive testing
- **Risk**: Performance with multiple recipe sources per item
- **Mitigation**: Fetch indexes, efficient queries, computed properties

**M7: CloudKit & External TestFlight**
- **Risk**: Sync conflicts and network issues
- **Mitigation**: Conflict resolution strategy, offline-first design, comprehensive error handling
- **Risk**: App Review rejection for external TestFlight
- **Mitigation**: M7.0 prerequisites (privacy policy, questionnaire, name disambiguation)

**M6: Testing**
- **Risk**: Time investment may exceed estimate
- **Mitigation**: Focus on critical paths first, expand coverage iteratively

### **Technical Debt: NONE**

Clean architecture maintained throughout M1-M4.3.4 with:
- Service layer separation
- Clear data models
- Performance optimization
- Comprehensive documentation
- Zero shortcuts or workarounds

---

## 📚 **RELATED DOCUMENTATION**

### **Current Milestone:**
- [M7 PRD](prds/milestone-7-cloudkit-sync-external-testflight.md) - CloudKit sync & external TestFlight
- [Current Story](current-story.md) - M5.0 complete, M7 in progress
- [Requirements Document](requirements.md) - All M1-M14 requirements documented
- [M8 Meta-PRD](prds/m8-ingredient-parsing-intelligence-meta-prd.md) - Ingredient parsing intelligence (4 phases)
- [M9 PRD](prds/m9-technical-debt-codebase-optimization.md) - Technical debt & codebase optimization

### **Completed Milestones:**
- [M1 Learning Notes](learning-notes/01-10-milestone-1-phases.md)
- [M2 Learning Notes](learning-notes/11-m2.1-recipe-architecture.md through 13)
- [M3 Phase 1-2 Learning Notes](learning-notes/12-m3-phase1-2-structured-quantities.md)
- [M3 Phase 3 Learning Notes](learning-notes/13-m3-phase3-data-migration.md)
- [M3 Phase 4 Learning Notes](learning-notes/14-m3-phase4-recipe-scaling.md)
- [M3 Phase 5 Learning Notes](learning-notes/15-m3-phase5-quantity-consolidation.md)
- [M3 Phase 6 Learning Notes](learning-notes/16-m3-phase6-ui-polish.md)
- [M3.5 Learning Notes](learning-notes/17-m3.5-foundation-validation.md)
- [M4.1 Learning Notes](learning-notes/18-m4.1-settings-infrastructure.md)
- [M4.2 Learning Notes](learning-notes/19-m4.2-calendar-meal-planning.md)
- [M4.3.1 Learning Notes](learning-notes/22-m4.3.1-recipe-source-tracking.md)
- M4.3.3-4 Learning Notes - To be created

### **Architecture & Requirements:**
- [Requirements Document](requirements.md)
- [Project Index](project-index.md)
- [Architecture Decision Records](architecture/)
- [Product Requirements Documents](prds/)

---

## 🎉 **ACHIEVEMENTS TO DATE**

### **M1 Highlights:**
- Professional store-layout optimized grocery lists
- Custom category management with drag-and-drop
- Staple item system with auto-population
- Zero-error Core Data implementation
- Sub-0.1s query performance

### **M2 Highlights:**
- Complete recipe CRUD operations
- Unified IngredientTemplate normalization system
- Recipe-to-grocery integration with category preservation
- Parse-then-autocomplete for efficient ingredient entry
- Fuzzy matching and smart template alignment
- Multi-field search with intelligent ranking
- Usage analytics and favorite tracking

### **M3 Highlights:**
- Structured quantity system with 95%+ parsing accuracy
- Recipe scaling with kitchen-friendly fractions (0.25x-4x)
- Intelligent shopping list consolidation (30-50% redundancy reduction)
- Professional unit conversion system (volume and weight)
- Source tracking across recipes
- Sub-0.3s consolidation analysis for 50+ items
- Transaction safety with zero data loss
- 100% migration success rate
- Visual indicators and consolidation badges
- Comprehensive in-app help documentation (HelpView.swift)
- All performance targets exceeded

### **M4 Highlights:**
- Professional settings infrastructure with UserPreferences ✅
- Calendar-based meal planning with date pickers ✅
- MealPlan and PlannedMeal entities operational ✅
- Recipe usage tracking (usageCount, lastUsed) ✅
- Recipe source tracking with many-to-many relationships ✅
- Scaled recipe to shopping list with servings adjustment ✅
- Bulk add from meal plan with progress overlay ✅
- Meal completion tracking with flexible UX ✅
- 4-phase ingredient normalization pipeline ✅
- 30% reduction in template fragmentation ✅

### **M5.0 Highlights:**
- Complete app rename from GroceryRecipeManager to Forager ✅
- Professional green sprout app icon ✅
- Bundle identifier migration (com.richhayn.forager) ✅
- Apple Developer Program enrollment ✅
- App Store Connect configuration ✅
- CloudKit production entitlements ✅
- Internal TestFlight deployment ✅
- Multi-tester beta program (3+ testers) ✅
- Real device validation on physical iPhones ✅
- Zero data loss through migration ✅

### **Platform Readiness:**
- Meal planning foundation complete ✅
- Recipe source tracking complete ✅
- Scaled recipe to list operational ✅
- Bulk add from meal plan operational ✅
- Meal completion tracking operational ✅
- Smart consolidation ready (M3 Phase 5) ✅
- Analytics-ready data structures ✅
- CloudKit-ready architecture ✅
- Comprehensive documentation ✅
- Professional UI throughout ✅
- Exceptional performance metrics ✅
- Production-ready quality ✅

---

**Next Action**: M7.6.7 TestFlight Submission (manual Apple portal steps)

**Status**: M1-M5.0 complete (~92.5h), M7.0-M7.4 complete (~69h), M8 complete (~17h), M7.6.1-M7.6.7 code prep complete (~9.5h). Total: ~188 hours. Ready for TestFlight submission.

---

## 🚀 **PRE-LAUNCH ROADMAP (February 2026)**

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.3.4: Error Handling | ✅ COMPLETE | - |
| M7.4: UI Polish & Pre-Launch Fixes | ✅ COMPLETE | ~4h |
| M8.1: Parsing Resilience & Telemetry | ✅ COMPLETE | ~3h |
| M8.3: Hybrid NLP Parser | ✅ COMPLETE | ~11h |
| M8.3.1: Template Hygiene & Badge Fix | ✅ COMPLETE | ~3h |
| M8.3.2: Auto-Merge Grocery Quantities | ✅ COMPLETE | ~3h |
| **M7.6: Pre-Launch Prep & TestFlight** | 🚀 NEXT | 10-12h |
| M7.7: App Store Submission & Public Presence | 📋 PLANNED | 3-5h |
| **Pre-Launch Total** | | **~37-41h** |

### **Post-Launch Roadmap**

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.5: Architecture Hardening | DEFERRED | 18.5-24.5h |
| M6: Testing Foundation | PLANNED | 12-18h |
| M8.4: ML-Powered Parsing | OPTIONAL | 15-20h |
| M9: Technical Debt | PLANNED | 135-165h |
| M10: Analytics & Insights | PLANNED | 8-12h |
| M11-M14: Advanced Features | FUTURE | 40-60h |

### **Key Decisions (February 5, 2026)**

1. **Original M7.4 (Sync Status UI) SKIPPED** - Dual-store architecture makes it unnecessary
2. **M7.4 repurposed** for UI Polish & Pre-Launch Fixes
3. **M8.1-M8.3 before launch** - Fix "3 avocados" parsing issue (95% → 98% accuracy)
4. **M7.5 deferred post-launch** - Developer-facing code quality, users won't notice
5. **M8.4 optional post-launch** - ML requires 100+ user corrections from M8.1 telemetry
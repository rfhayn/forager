# Forager - Requirements Document

**Last Updated**: March 21, 2026
**Version**: 7.2
**Current Milestone**: M9.27 ✅ COMPLETE | M9.25.1 ✅ | M9.24 🔄 | M10.6 🔄 (M10.6.5 remaining)
**Launch Path**: M9.24 → M9.15.3 → M9.26 → M10.6.5 → M9.28 → M9.29 → M7.7

---

## 📋 **OVERVIEW**

This document defines all functional and non-functional requirements for the Forager iOS application. Requirements are organized by milestone with traceability to implementation status.

---

## 🎯 **PROJECT VISION**

**Mission**: Create a revolutionary iOS grocery and recipe management app that eliminates shopping inefficiency through intelligent store-layout optimization, integrated recipe management, and smart automation.

**Core Value Propositions**:
1. **Store-Layout Optimization**: Custom-ordered grocery lists matching your actual shopping flow
2. **Recipe Integration**: Seamlessly manage recipes and generate grocery lists with one tap
3. **Structured Quantity Intelligence**: Scale recipes, consolidate duplicates, and smart quantity management
4. **Recipe Ingredient Autocomplete**: Efficient ingredient entry with fuzzy matching
5. **Meal Planning**: Calendar-based planning with automated grocery list generation
6. **Family Collaboration**: CloudKit-powered sharing for household coordination
7. **Analytics & Insights**: Data-driven recommendations for better shopping and cooking
8. **Data-Driven Parsing Evolution**: Continuous ingredient parsing improvements based on real usage (M7.5, M8.0, M9.5)

---
## ✅ **M1: PROFESSIONAL GROCERY MANAGEMENT - COMPLETE**

**Status**: ✅ Complete - August 2025 (32 hours)  
**Summary**: Professional grocery list management with store-layout optimization

### **Functional Requirements - Grocery Lists**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-GL-001** | **Create weekly grocery lists** | ✅ WeeklyList entity with name, creation date, completion status | M1 Phase 1 | 🎯 **Core workflow** |
| **FR-GL-002** | **Add/edit/delete grocery items** | ✅ GroceryListItem CRUD with Core Data persistence | M1 Phase 1 | 🎯 **Basic functionality** |
| **FR-GL-003** | **Mark items complete/incomplete** | ✅ Toggle with visual feedback and persistence | M1 Phase 2 | 🎯 **Shopping tracking** |
| **FR-GL-004** | **Display completion percentage** | ✅ Progress bar with animated updates | M1 Phase 2 | 🎯 **Progress visibility** |
| **FR-GL-005** | **Auto-complete list when all items done** | ✅ Automatic status update with Core Data validation | M1 Phase 2 | 🎯 **Workflow completion** |

### **Functional Requirements - Categories**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-CAT-001** | **Custom category creation** | ✅ User-defined categories with names and colors | M1 Phase 3 | 🎯 **Personalization** |
| **FR-CAT-002** | **Drag-and-drop category ordering** | ✅ Reorderable list with Core Data persistence | M1 Phase 3 | 🎯 **Store-layout optimization** |
| **FR-CAT-003** | **Category color coding** | ✅ Visual distinction with 12 color palette | M1 Phase 3 | 🎯 **Visual organization** |
| **FR-CAT-004** | **Category assignment to items** | ✅ Dropdown selection with smart defaults | M1 Phase 4 | 🎯 **Item organization** |
| **FR-CAT-005** | **Protect categories with items** | ✅ Warning before deletion, option to reassign | M1 Phase 3 | 🎯 **Data protection** |

### **Functional Requirements - Staples**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-ST-001** | **Mark items as staples** | ✅ Toggle flag with persistence | M1 Phase 5 | 🎯 **Recurring item management** |
| **FR-ST-002** | **Auto-populate staples to new lists** | ✅ Automatic addition with category preservation | M1 Phase 5 | 🎯 **Time-saving automation** |
| **FR-ST-003** | **Staple management view** | ✅ Dedicated view with category organization | M1 Phase 5 | 🎯 **Centralized management** |
| **FR-ST-004** | **Add/remove staple status** | ✅ Toggle with immediate list updates | M1 Phase 5 | 🎯 **Flexible management** |

### **Non-Functional Requirements - M1**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **NFR-M1-001** | **Response time < 0.1s for queries** | ✅ Core Data optimization with fetch indexes | M1 All | 🎯 **Performance** |
| **NFR-M1-002** | **Zero data loss** | ✅ Transaction management with rollback | M1 All | 🎯 **Data integrity** |
| **NFR-M1-003** | **Professional iOS UI** | ✅ Native SwiftUI patterns throughout | M1 All | 🎯 **User experience** |
| **NFR-M1-004** | **Accessibility support** | ✅ VoiceOver compatible, color contrast standards | M1 All | 🎯 **Inclusivity** |

**M1 Summary**: All 19 requirements successfully completed with professional quality and exceptional performance.

---

## ✅ **M2: RECIPE INTEGRATION - COMPLETE**

**Status**: ✅ Complete - September-October 2025 (16.5 hours)  
**Summary**: Complete recipe catalog with intelligent ingredient management and autocomplete

### **Functional Requirements - Recipe Management**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-RM-001** | **Recipe catalog view** | ✅ **Scrollable list with search, favorites, recent, categories** | ✅ M2.2.1 | 🎯 **Recipe discovery** |
| **FR-RM-002** | **Recipe detail view** | ✅ **Comprehensive display: ingredients, instructions, timing, tags** | ✅ M2.2.2 | 🎯 **Recipe information** |
| **FR-RM-003** | **Recipe CRUD operations** | ✅ **Create, read, update, delete with data validation** | ✅ M2.3 | 🎯 **Recipe management** |
| **FR-RM-004** | **Favorite recipes** | ✅ **Toggle favorite with visual feedback and filtering** | ✅ M2.2.3 | 🎯 **Quick access** |
| **FR-RM-005** | **Recipe usage tracking** | ✅ **Mark as used, usage count, last used date** | ✅ M2.2.3 | 🎯 **Analytics foundation** |
| **FR-RM-006** | **Recipe tags** | ✅ **Multiple tags per recipe for flexible categorization** | ✅ M2.2.2 | 🎯 **Organization** |
| **FR-RM-007** | **Recipe timing** | ✅ **Prep time, cook time, total time tracking** | ✅ M2.2.2 | 🎯 **Planning** |
| **FR-RM-008** | **Servings tracking** | ✅ **Number of servings with recipe scaling support** | ✅ M2.2.2 | 🎯 **Portion management** |
| **FR-RM-009** | **Recipe notes** | ✅ **Freeform text field for user notes and modifications** | ✅ M2.2.2 | 🎯 **Customization** |
| **FR-RM-010** | **Add recipe ingredients to list** | ✅ **One-tap workflow with category preservation** | ✅ M2.2.4 | 🎯 **Recipe-to-grocery integration** |
| **FR-RM-011** | **Unified ingredient management** | ✅ **Single IngredientTemplate system with direct category assignment** | ✅ M2.2.5 | 🎯 **Consolidated ingredient architecture** |
| **FR-RM-012** | **Custom category integration** | ✅ **Store-layout optimization fully integrated throughout recipe system** | ✅ M2.2.6 | 🎯 **Seamless personalized experience** |
| **FR-RM-013** | **Enhanced recipe search** | ✅ **Multi-field search across names, ingredients, tags, instructions** | ✅ M2.2.7 | 🎯 **Comprehensive recipe discovery** |
| **FR-RM-031** | **Recipe creation form** | ✅ **Professional multi-step form with comprehensive validation** | ✅ M2.3 | 🎯 **Complete recipe input** |
| **FR-RM-032** | **Ingredient management** | ✅ **Add/edit/remove/reorder ingredients with template integration** | ✅ M2.3 | 🎯 **Flexible ingredient handling** |
| **FR-RM-033** | **Parse-then-autocomplete** | ✅ **Intelligent parsing with fuzzy matching autocomplete** (extended to RecipeDetailView + RecipeImportPreviewView in M10.6.10) | ✅ M2.3, M10.6.10 | 🎯 **Efficient ingredient entry** |
| **FR-RM-034** | **Template alignment** | ✅ **Automatic ingredient normalization with template linking** | ✅ M2.3 | 🎯 **Data consistency** |
| **FR-RM-035** | **Category assignment** | ✅ **Batch category assignment modal for uncategorized ingredients** | ✅ M2.3 | 🎯 **Category management** |
| **FR-RM-036** | **Recipe editing** | ✅ **Seamless editing workflow maintaining data integrity** | ✅ M2.3 | 🎯 **Recipe updates** |
| **FR-RM-037** | **Unsaved changes detection** | ✅ **Alert users before discarding modifications** | ✅ M2.3 | 🎯 **Data protection** |

### **Non-Functional Requirements - M2**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **NFR-M2-001** | **Recipe list performance < 0.1s** | ✅ Optimized @FetchRequest with predicates | M2.2 | 🎯 **Fast navigation** |
| **NFR-M2-002** | **Search performance < 0.2s** | ✅ Core Data text search with fetch indexes | M2.2.7 | 🎯 **Instant results** |
| **NFR-M2-003** | **Autocomplete performance < 0.1s** | ✅ Debounced search with fuzzy matching | M2.3 | 🎯 **Responsive input** |
| **NFR-M2-004** | **Recipe save performance < 0.5s** | ✅ Optimized Core Data transactions | M2.3 | 🎯 **Quick operations** |
| **NFR-M2-005** | **Template alignment accuracy > 90%** | ✅ Intelligent matching with manual fallback | M2.3 | 🎯 **Data quality** |
| **NFR-M2-006** | **Zero data duplication** | ✅ Template normalization system | M2.2.5 | 🎯 **Data integrity** |

**M2 Summary**: All 37 recipe integration requirements successfully completed with professional quality and comprehensive functionality.

---

## ✅ **M3: STRUCTURED QUANTITY MANAGEMENT - COMPLETE**

**Status**: ✅ Complete - October 2025 (10.5 hours)  
**Summary**: Intelligent quantity management with scaling, consolidation, and unit conversion

### **Functional Requirements - Quantity Model**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-QM-001** | **Structured quantity data model** | ✅ **numericValue, standardUnit, displayText, isParseable, parseConfidence** | ✅ M3 Phase 1-2 | 🎯 **Foundation for intelligence** |
| **FR-QM-002** | **Enhanced quantity parsing** | ✅ **Numeric conversion, unit standardization, fraction support** | ✅ M3 Phase 1-2 | 🎯 **Accurate data capture** |
| **FR-QM-003** | **Backward compatible display** | ✅ **displayText preserves original formatting** | ✅ M3 Phase 1-2 | 🎯 **User experience continuity** |
| **FR-QM-004** | **Parse confidence tracking** | ✅ **0.0-1.0 confidence score for quality assurance** | ✅ M3 Phase 1-2 | 🎯 **Quality metrics** |
| **FR-QM-005** | **Fraction recognition** | ✅ **1/2, 1/4, 3/4, 1/3, 2/3 parsing** | ✅ M3 Phase 1-2 | 🎯 **Kitchen-standard support** |

### **Functional Requirements - Data Migration**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-QM-006** | **One-time migration service** | ✅ **QuantityMigrationService with batch processing** | ✅ M3 Phase 3 | 🎯 **Data transition** |
| **FR-QM-007** | **Migration preview** | ✅ **Preview before commit with statistics** | ✅ M3 Phase 3 | 🎯 **User control** |
| **FR-QM-008** | **Migration results** | ✅ **Comprehensive results display with metrics** | ✅ M3 Phase 3 | 🎯 **Transparency** |
| **FR-QM-009** | **Settings infrastructure** | ✅ **Professional Settings tab for future features** | ✅ M3 Phase 3 | 🎯 **Expandability** |
| **FR-QM-010** | **Zero data loss migration** | ✅ **Transaction safety with automatic rollback** | ✅ M3 Phase 3 | 🎯 **Data integrity** |

### **Functional Requirements - Recipe Scaling**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-QM-021** | **Recipe scaling service** | ✅ **Mathematical quantity scaling 0.25x-4x** | ✅ M3 Phase 4 | 🎯 **Flexible serving sizes** |
| **FR-QM-022** | **Kitchen-friendly fractions** | ✅ **Decimal to fraction conversion (1.5 → "1 1/2")** | ✅ M3 Phase 4 | 🎯 **Practical display** |
| **FR-QM-023** | **Scaling UI** | ✅ **Professional slider with quick buttons and live preview** | ✅ M3 Phase 4 | 🎯 **User-friendly scaling** |
| **FR-QM-024** | **Unparseable handling** | ✅ **Graceful degradation with adjustment notes** | ✅ M3 Phase 4 | 🎯 **Complete coverage** |
| **FR-QM-025** | **Non-destructive preview** | ✅ **Preview only, original recipe preserved** | ✅ M3 Phase 4 | 🎯 **Safe exploration** |
| **FR-QM-026** | **Scaling performance** | ✅ **< 0.5s for 20+ ingredient recipes** | ✅ M3 Phase 4 | 🎯 **Responsive UI** |

### **Functional Requirements - Quantity Consolidation**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-QM-011** | **Parseable quantity merging** | ✅ **Combine compatible quantities ("1 cup" + "2 cups" = "3 cups")** | ✅ M3 Phase 5 | 🎯 **List simplification** |
| **FR-QM-012** | **Mixed type handling** | ✅ **Keep incompatible quantities separate** | ✅ M3 Phase 5 | 🎯 **Intelligent separation** |
| **FR-QM-013** | **Consolidation preview** | ✅ **Preview with user approval before applying** | ✅ M3 Phase 5 | 🎯 **User control** |
| **FR-QM-014** | **Source tracking** | ✅ **Show contributing recipes for merged items** | ✅ M3 Phase 5 | 🎯 **Provenance transparency** |
| **FR-QM-015** | **QuantityMergeService** | ✅ **Intelligent consolidation with compatibility analysis** | ✅ M3 Phase 5 | 🎯 **Core service** |
| **FR-QM-027** | **Unit conversion support** | ✅ **Volume (cups ↔ tbsp ↔ tsp), Weight (lb ↔ oz)** | ✅ M3 Phase 5 | 🎯 **Advanced merging** |
| **FR-QM-028** | **Conversion accuracy** | ✅ **100% accurate unit conversions** | ✅ M3 Phase 5 | 🎯 **Data quality** |
| **FR-QM-029** | **Transaction safety** | ✅ **Atomic merge operations with rollback** | ✅ M3 Phase 5 | 🎯 **Data integrity** |
| **FR-QM-030** | **Consolidation performance** | ✅ **< 0.3s analysis for 50+ items, < 0.8s merge** | ✅ M3 Phase 5 | 🎯 **Responsive operations** |

### **Functional Requirements - UI Polish**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-QM-016** | **Visual indicators for quantity types** | ✅ **Color coding and icons for parseable/unparseable** | ✅ M3 Phase 6 | 🎯 **Visual clarity** |
| **FR-QM-017** | **Help documentation** | ✅ **Comprehensive user guide for quantity features (HelpView.swift)** | ✅ M3 Phase 6 | 🎯 **User education** |
| **FR-QM-018** | **Completion documentation** | ✅ **Learning notes and roadmap updates** | ✅ M3 Phase 6 | 🎯 **Project tracking** |
| **FR-QM-019** | **Autocomplete validation** | ✅ **Verified autocomplete works with M3 features** | ✅ M3 Phase 6 | 🎯 **Integration quality** |
| **FR-QM-020** | **Performance validation** | ✅ **All targets met or exceeded** | ✅ M3 Phase 6 | 🎯 **Quality assurance** |

### **Non-Functional Requirements - M3**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **NFR-M3-001** | **Parsing performance < 0.05s** | ✅ Optimized parsing service (< 0.03s achieved) | M3 Phase 1-2 | 🎯 **Instant feedback** |
| **NFR-M3-002** | **Migration performance < 2s** | ✅ Batch processing with async/await | M3 Phase 3 | 🎯 **Quick transition** |
| **NFR-M3-003** | **Scaling performance < 0.5s** | ✅ Efficient mathematical operations (< 0.4s achieved) | M3 Phase 4 | 🎯 **Responsive scaling** |
| **NFR-M3-004** | **Analysis performance < 0.5s** | ✅ Optimized grouping algorithms (< 0.3s achieved) | M3 Phase 5 | 🎯 **Fast analysis** |
| **NFR-M3-005** | **Merge performance < 1s** | ✅ Transaction optimization (< 0.8s achieved) | M3 Phase 5 | 🎯 **Quick operations** |
| **NFR-M3-006** | **Parse accuracy > 95%** | ✅ Comprehensive parsing patterns | M3 Phase 1-2 | 🎯 **Data quality** |
| **NFR-M3-007** | **Conversion accuracy 100%** | ✅ Validated conversion logic | M3 Phase 5 | 🎯 **Precision** |
| **NFR-M3-008** | **UI responsiveness 60fps** | ✅ Maintained throughout | M3 All | 🎯 **Smooth experience** |

**M3 Summary**: All 33 requirements successfully completed. Structured quantity system operational with recipe scaling, intelligent consolidation, unit conversion, visual enhancements, and comprehensive help documentation. All performance targets met or exceeded. Production-ready quality achieved.

**M3.5 Validation**: Comprehensive validation completed with automated test suite. 75+ computed properties added, 100% test pass rate achieved, test automation pattern established for future milestones.

---

## ✅ **M4: MEAL PLANNING & SETTINGS - COMPLETE**

**Status**: ✅ Complete - November 2025 (~18.5 hours)  
**Summary**: Calendar-based meal planning with enhanced grocery automation

### **Functional Requirements - Settings Infrastructure**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-MP-001** | **Meal planning preferences** | ✅ Duration (3-14 days), start day, auto-naming | M4.1 | 🎯 **Personalization** |
| **FR-MP-002** | **Recipe source display preferences** | ✅ Show/hide recipe sources in lists | M4.1 | 🎯 **User control** |
| **FR-MP-003** | **UserPreferences entity** | ✅ Core Data entity for settings persistence | M4.1 | 🎯 **Data persistence** |
| **FR-MP-004** | **Real-time validation** | ✅ Validate settings as user changes them | M4.1 | 🎯 **Error prevention** |

### **Functional Requirements - Meal Planning Core**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-MP-005** | **MealPlan entity** | ✅ Core Data entity with date range | M4.2 | 🎯 **Data structure** |
| **FR-MP-006** | **PlannedMeal entity** | ✅ Date-recipe relationship tracking | M4.2 | 🎯 **Meal assignments** |
| **FR-MP-007** | **Calendar view** | ✅ Calendar grid with tap-to-add | M4.2 | 🎯 **Visual planning** |
| **FR-MP-008** | **Add to meal plan** | ✅ RecipePickerSheet with search/servings | M4.2 | 🎯 **Easy assignment** |
| **FR-MP-009** | **Configurable periods** | ✅ User-defined date ranges | M4.2 | 🎯 **Flexibility** |
| **FR-MP-010** | **Meal plan management** | ✅ Create meal plans with date pickers | M4.2 | 🎯 **Plan control** |
| **FR-MP-017** | **Recipe usage tracking** | ✅ usageCount and lastUsed on assignment | M4.2 | 🎯 **Analytics data** |

### **Functional Requirements - Enhanced Grocery Integration**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-MP-011** | **Generate list from meal plan** | ✅ Bulk add with progress overlay | M4.3.3 | 🎯 **Automation** |
| **FR-MP-012** | **Recipe source tags** | ✅ Recipe badges in grocery lists | M4.3.1 | 🎯 **Transparency** |
| **FR-MP-013** | **Smart consolidation** | ✅ Perfect integration with M3 Phase 5 | M4.3.3 | 🎯 **List optimization** |
| **FR-MP-014** | **Meal completion tracking** | ✅ Mark meals as completed | M4.3.4 | 🎯 **Progress tracking** |
| **FR-MP-015** | **Scaled recipe to list** | ✅ Servings adjustment UI with scale indicators | M4.3.2 | 🎯 **Party planning** |
| **FR-MP-016** | **Scaling metadata** | ✅ Servings adjustment in SelectListSheet | M4.3.3 | 🎯 **Context preservation** |

### **Non-Functional Requirements - M4**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **NFR-M4-001** | **List generation performance < 1s** | ✅ Sub-1s for 7-day plan | M4.3.3 | 🎯 **Fast automation** |
| **NFR-M4-002** | **Calendar rendering < 0.5s** | ✅ Responsive calendar | M4.2 | 🎯 **Responsive UI** |
| **NFR-M4-003** | **Settings persistence immediate** | ✅ Instant save | M4.1 | 🎯 **Reliability** |

**M4 Summary**: All 19 requirements complete. Calendar-based meal planning operational with automated grocery integration, smart consolidation, and comprehensive tracking.

---

## ✅ **M5.0: APP RENAMING & TESTFLIGHT DEPLOYMENT - COMPLETE**

**Status**: ✅ Complete - December 2025 (6 hours)  
**Summary**: Complete app renaming to "Forager" and TestFlight deployment for real-device validation

### **Functional Requirements - App Identity**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-TF-001** | **Professional app name** | ✅ Renamed to "Forager: Smart Meal Planner" | M5.0.1 | 🎯 **Brand identity** |
| **FR-TF-002** | **Bundle identifier update** | ✅ com.richhayn.forager across all targets | M5.0.2 | 🎯 **App Store presence** |
| **FR-TF-003** | **App icon design** | ✅ Professional 1024x1024 icon (green sprout) | M5.0.5B | 🎯 **Visual identity** |
| **FR-TF-004** | **File structure consistency** | ✅ All folders, files renamed systematically | M5.0.3 | 🎯 **Project organization** |

### **Functional Requirements - TestFlight Deployment**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-TF-005** | **Apple Developer enrollment** | ✅ Program enrolled ($99/year) | M5.0.5A | 🎯 **Distribution capability** |
| **FR-TF-006** | **App Store Connect setup** | ✅ App created, configured | M5.0.5C | 🎯 **Deployment infrastructure** |
| **FR-TF-007** | **CloudKit entitlements** | ✅ Production entitlements configured | M5.0.5D | 🎯 **Sync readiness** |
| **FR-TF-008** | **Internal TestFlight** | ✅ Internal testing group operational | M5.0.5E | 🎯 **Beta testing** |
| **FR-TF-009** | **Real device validation** | ✅ App running on physical iPhones | M5.0.5F | 🎯 **Production validation** |
| **FR-TF-010** | **Multi-tester distribution** | ✅ Multiple testers invited and active | M5.0.5E | 🎯 **Feedback collection** |

### **Non-Functional Requirements - M5.0**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **NFR-TF-001** | **Zero data loss during rename** | ✅ All existing data preserved | M5.0.3B | 🎯 **Data integrity** |
| **NFR-TF-002** | **Build success after rename** | ✅ Clean builds throughout | M5.0 All | 🎯 **Technical stability** |
| **NFR-TF-003** | **Performance maintained** | ✅ All M1-M4 targets still met | M5.0.5F | 🎯 **Quality preserved** |
| **NFR-TF-004** | **Archive/upload success** | ✅ TestFlight upload successful | M5.0.5D | 🎯 **Deployment capability** |

**M5.0 Summary**: All 14 requirements complete. Forager successfully renamed, deployed to TestFlight, and validated on real devices. Internal beta testing operational with multiple testers.

---

## ⏸️ **M6: TESTING FOUNDATION & AI AUGMENTATION - DEFERRED**

**Status**: 🔜 Deferred (executing after M7)
**Estimated**: 20-30 hours
**Reason**: Prioritized CloudKit sync and external beta over testing infrastructure
**Execution Plan**: M7 (CloudKit + External Beta) → M6 (Testing Foundation) → M8 (Parsing)
**PRD**: [M6 Testing Foundation PRD](prds/active/milestone-6-testing-foundation-ai-augmentation.md)

### **Strategic Context**

M6 was originally planned after M5, but deferred to execute after M7 completes. This sequencing provides:
- ✅ External beta proves app stable before investing in testing infrastructure
- ✅ Test coverage in place BEFORE M8 parsing improvements and M9 refactoring (135-173h)
- ✅ AI test reviewer learns patterns from M8 implementation
- ✅ CI/CD established before external users depend on stability

### **Planned Requirements** (See PRD for Full Details)

**M6.1: Human Test Baseline (50%+ coverage on services)**
**M6.2: AI Test Review Setup (operational on every PR)**
**M6.3: Testing Standards (documentation and CI/CD)**

**M6 Summary (Planned)**: Testing foundation with AI-augmented review, establishing baseline coverage before major refactoring efforts in M8-M9.

---

## 🚀 **M7: CLOUDKIT SYNC & EXTERNAL TESTFLIGHT - IN PROGRESS**

**Status**: 🔄 In Progress - M7.0-M7.2 Complete ✅, M7.3 🚀 Next
**Progress**: M7.0 (3h) ✅, M7.1 (6.5h) ✅, M7.2 (15h) ✅, M7.2.3 (12.25h) ✅ = ~37h / 52-60h
**Estimated Remaining**: 15-23 hours (M7.3, M7.5, M7.6, M7.7)
**Summary**: Full CloudKit synchronization with household sharing, automatic duplicate prevention, external public beta

**⚠️ CRITICAL**: M7.0 App Store Prerequisites are MANDATORY before external TestFlight submission

### **Functional Requirements - App Store Prerequisites (M7.0 - MANDATORY)** 🚨

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-AS-001** | **Privacy policy published** | Privacy policy hosted at public URL (GitHub Pages) | M7.0.1 | 🎯 **App Store compliance** |
| **FR-AS-002** | **In-app privacy link** | Settings → Privacy Policy opens hosted URL | M7.0.2 | 🎯 **User transparency** |
| **FR-AS-003** | **App Privacy questionnaire** | Complete in App Store Connect ("Data Not Collected") | M7.0.3 | 🎯 **Required metadata** |
| **FR-AS-004** | **Display name disambiguation** | "Forager: Smart Meal Planner" (display) + "Forager" (icon) | M7.0.4 | 🎯 **Brand differentiation** |

### **Functional Requirements - CloudKit Sync Foundation**

| ID | Requirement | Target Implementation | Milestone | Status |
|----|-------------|----------------------|-----------|--------|
| **FR-CK-001** | **CloudKit schema generation** | All 8 entities sync to CloudKit | M7.1.1 | ✅ **COMPLETE** |
| **FR-CK-002** | **Multi-device sync** | Changes sync across devices <5s | M7.1.3 | ✅ **COMPLETE** |
| **FR-CK-003** | **Automatic background sync** | CloudKit syncs without user action | M7.1.2 | ✅ **COMPLETE** |
| **FR-CK-004** | **Offline sync queue** | Changes queue offline, sync when online | M7.1.3 | ✅ **COMPLETE** |
| **FR-CK-005** | **Sync status monitoring** | CloudKit sync state tracking | M7.1.2 | ✅ **COMPLETE** |
| **FR-CK-021** | **CloudKit environment configuration** | Development environment for testing, Production for release | Debugging | ✅ **COMPLETE** |
| **FR-CK-022** | **CloudKit import observer pattern** | Wait for import completion before setup | Debugging | ✅ **COMPLETE** |
| **FR-CK-023** | **Race condition prevention** | Serial queue synchronization for atomic operations | Debugging | ✅ **COMPLETE** |
| **FR-CK-024** | **Clean user onboarding** | No sample data in production (7 categories only) | Debugging | ✅ **COMPLETE** |

### **Functional Requirements - Household Collaboration (Shared Zone Architecture)**

**⚠️ ARCHITECTURE NOTE (Dec 23, 2025)**: M7.2 uses CloudKit **Shared Zones** (household database), not CKShare (per-item sharing). All 8 entities are household-scoped for security and consistency. See [ADR 008](architecture/008-shared-zone-architecture.md) and [Learning Note 26](learning-notes/26-m7.2-household-scoped-architecture.md).

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-CK-006** | **Household creation & shared zone** | Create household, migrate data to shared zone | M7.2.1 | ✅ **COMPLETE** |
| **FR-CK-007** | **Member invitation flow** | ✅ Public link sharing, CKShare acceptance, paste invitation | M7.2.2 | ✅ **COMPLETE** |
| **FR-CK-038** | **Member leave flow** | ✅ Leave with data migration, CKShare deletion, shared store cleanup, rejoin support | M7.2.2 | ✅ **COMPLETE** |
| **FR-CK-039** | **Invitation message customization** | ✅ Friendly text message with CKShare title "Join [Name] on forager" | M7.2.2 | ✅ **COMPLETE** |
| **FR-CK-008** | **Household management** | Owner remove member, delete household | M7.3.3 | 🎯 **Access control** |
| **FR-CK-009** | **All entities household-scoped** | GroceryItem, Recipe, WeeklyList, MealPlan, Tag, Ingredient, GroceryListItem, IngredientTemplate | M7.2.1 | ✅ **COMPLETE** |
| **FR-CK-010** | **Automatic sync across household** | All household members see all data automatically | M7.2.3 | 🎯 **Seamless collaboration** |
| **FR-CK-025** | **Automatic duplicate category prevention** | CategoryDeduplicator removes duplicates after CloudKit sync | M7.2.3 Phase 3.8 | ✅ **COMPLETE** |
| **FR-CK-026** | **Self-healing multi-device sync** | System converges to correct state automatically (<60s) | M7.2.3 Phase 3.8 | ✅ **COMPLETE** |
| **FR-CK-027** | **Dedupe-after-creation pattern** | Apple-recommended approach for duplicate prevention | M7.2.3 Phase 3.8 | ✅ **COMPLETE** |

### **Functional Requirements - Shared Data Architecture (M7.2.3 - NEW)** 🏗️

**⚠️ ARCHITECTURAL EVOLUTION**: M7.2.3 establishes production-ready shared data patterns validated by external AI experts (ChatGPT + Gemini). See [PRD v2.2](prds/m7.2.3-cloudkit-hardening-household-repositories.md) for complete specifications.

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-CK-028** | **Household as aggregate root** | ✅ 5 new relationships: weeklyLists, recipes, mealPlans, categories, ingredientTemplates | M7.2.3 Phase 0 | ✅ **COMPLETE** |
| **FR-CK-029** | **Scope-based store assignment** | ✅ DataScope enum (.personal \| .household) with ManagedObjectFactory | M7.2.3 Phase 2 | ✅ **COMPLETE** |
| **FR-CK-030** | **Attach-then-share migration** | ✅ Set relationships in private → share() moves graph to shared zone | M7.2.3 Phase 4 | ✅ **COMPLETE** |
| **FR-CK-031** | **Store-scoped repositories** | Explicit fetch with affectedStores = [sharedStore] | M7.2.3 Phase 5 | ⏳ **Planned** |
| **FR-CK-032** | **Cross-store violation prevention** | DEBUG validator catches relationship violations early | M7.2.3 Phase 6 | ⏳ **Planned** |
| **FR-CK-033** | **HouseholdScoped protocol** | ✅ Compiler-enforced conformance for factory-based creation | M7.2.3 Phase 2 | ✅ **COMPLETE** |
| **FR-CK-034** | **One active scope constraint** | ✅ App operates in .personal OR .household, not both | M7.2.3 Phase 2 | ✅ **COMPLETE** |
| **FR-CK-035** | **Recipe ownership semantics** | ✅ Recipes Nullified (not Cascaded) to preserve user curation | M7.2.3 Phase 0 | ✅ **COMPLETE** |
| **FR-CK-036** | **Workspace leave model** | Data stays with household, optional export later (M8+) | M7.2.3 Phase 5 | ⏳ **Planned** |
| **FR-CK-037** | **DEBUG validators for production** | ✅ Catch share failures, stale refs, cross-store bugs (migration logging implemented) | M7.2.3 Phase 4 | ✅ **COMPLETE** |

**External Validation**: All patterns validated by ChatGPT ("Gold Standard") and Gemini ("Production-ready"). Complete code implementations provided.

### **Functional Requirements - Conflict Resolution**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-CK-011** | **Last-write-wins policy** | Most recent edit wins for simple fields | M7.3.1 | 🎯 **Automatic resolution** |
| **FR-CK-012** | **Array merge policy** | Intelligently merge ingredient/item arrays | M7.3.1 | 🎯 **Data preservation** |
| **FR-CK-013** | **Deleted record handling** | Graceful handling of delete conflicts | M7.3.2 | 🎯 **Data consistency** |
| **FR-CK-014** | **Network error recovery** | Retry logic for transient failures | M7.3.2 | 🎯 **Reliability** |
| **FR-CK-015** | **CloudKit quota management** | Monitor and optimize storage usage | M7.3.2 | 🎯 **Scalability** |

### **Functional Requirements - Sync UI & Polish**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-CK-016** | **Sync status indicators** | Visual sync status (synced/syncing/error) | M7.4.1 | 🎯 **User awareness** |
| **FR-CK-017** | **Manual sync trigger** | Pull-to-refresh force sync | M7.4.1 | 🎯 **User control** |
| **FR-CK-018** | **Last synced timestamp** | Show when last sync occurred | M7.4.1 | 🎯 **Transparency** |
| **FR-CK-019** | **CloudKit account status** | Display iCloud sign-in status | M7.4.2 | 🎯 **User awareness** |
| **FR-CK-020** | **Sync diagnostics** | Debug view for troubleshooting | M7.4.2 | 🎯 **Supportability** |

### **Functional Requirements - Parsing Resilience & Polish (M8.1) - ✅ COMPLETE**

_Moved from M7.5 to M8.1. Completed February 7, 2026. See M8 section for full details._

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-PR-001** | **Low-confidence detection** | ✅ Yellow badge for parseConfidence < 0.5 | M8.1 | 🎯 **Graceful degradation** |
| **FR-PR-002** | **Edit ingredient button** | ❌ REMOVED (scope reduction) | M8.1 | — |
| **FR-PR-003** | **Structured edit form** | ❌ REMOVED (scope reduction) | M8.1 | — |
| **FR-PR-004** | **Pre-filled edit values** | ❌ REMOVED (scope reduction) | M8.1 | — |
| **FR-PR-005** | **Telemetry logging** | ✅ ParsingTelemetryService with local JSON | M8.1 | 🎯 **Data for M8.2+** |
| **FR-PR-006** | **Privacy-safe telemetry** | ✅ Local storage only, no user ID | M8.1 | 🎯 **Privacy compliance** |

### **Functional Requirements - Pre-Launch Prep (M7.6)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-PL-001** | **App configuration** | ✅ iOS 18.0 target, branded launch screen (light/dark), display name "forager" | M7.6.1 | ✅ **Brand identity** |
| **FR-PL-002** | **Production gating** | ✅ Developer tools hidden in Release builds via `#if DEBUG` | M7.6.2 | ✅ **Production quality** |
| **FR-PL-003** | **Onboarding walkthrough** | ✅ Coach mark overlays on real app, sample data seeding, first-launch loading screen, Settings replay | M7.6.3 | ✅ **User guidance** |
| **FR-PL-004** | **Schema P0 cleanup** | ✅ Removed Tag + LeaveRequest entities, fixed Recipe.plannedMeals cardinality | M7.6.4 | ✅ **Schema hygiene** |
| **FR-PL-005** | **Schema P1 cleanup** | ✅ Renamed ownerEmail, fixed delete rules, code-schema mismatches | M7.6.5 | ✅ **Data integrity** |
| **FR-PL-006** | **Schema P2 cleanup** | ✅ Removed unused fields, fixed sourceURL tags hack, naming consistency | M7.6.6 | ✅ **Clean schema** |
| **FR-TF-011** | **External testing group** | ✅ Created "Public Beta Testers" group with public link | M7.6.7 | ✅ **Public beta** |
| **FR-TF-012** | **App Review submission** | ✅ Apple approved for external testing | M7.6.7 | ✅ **Public distribution** |
| **FR-TF-013** | **Public TestFlight link** | ✅ Public link active, external testers onboarded | M7.6.8 | ✅ **Easy distribution** |
| **FR-TF-019** | **Owner display name on shared record** | ✅ Repurposed ownerEmail to store display name on Household root record | M7.6.8 | ✅ **Cross-device identity** |

### **Functional Requirements - App Store Submission (M7.7)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-TF-014** | **Beta landing page** | GitHub Pages with TestFlight link, features, screenshots | M7.7.1 | 🎯 **Professional showcase** |
| **FR-TF-016** | **GitHub README** | Portfolio-quality README with badges and tech stack | M7.7.2 | 🎯 **Portfolio presentation** |
| **FR-TF-017** | **App Store listing** | Description, keywords, screenshots, category, age rating | M7.7.3 | 🎯 **Store presence** |
| **FR-TF-018** | **App Store submission** | Submit for App Store review and approval | M7.7.4 | 🎯 **Public availability** |

### **Non-Functional Requirements - M7**

| ID | Requirement | Target | Milestone | Value |
|----|-------------|--------|-----------|-------|
| **NFR-CK-001** | **Sync latency < 5s** | Multi-device sync within 5 seconds | M7.1.3 | 🎯 **Real-time feel** |
| **NFR-CK-002** | **Sync success rate > 99%** | Reliable synchronization | M7 All | 🎯 **Dependability** |
| **NFR-CK-003** | **Conflict resolution 100%** | All conflicts handled gracefully | M7.3.1 | 🎯 **Data integrity** |
| **NFR-CK-004** | **UI responsiveness maintained** | Sync doesn't block UI | M7 All | 🎯 **Performance** |
| **NFR-CK-005** | **Battery impact < 5%** | Minimal battery drain from sync | M7 All | 🎯 **Efficiency** |
| **NFR-CK-006** | **Network data < 1MB/sync** | Efficient data transfer | M7 All | 🎯 **Data economy** |
| **NFR-CK-007** | **App Review pass** | Approval for external testing | M7.6.3 | 🎯 **Public readiness** |
| **NFR-PR-001** | **Edit form load < 0.2s** | Instant edit form display | M7.5.2 | 🎯 **Responsive UX** |
| **NFR-PR-002** | **Telemetry write < 0.1s** | Non-blocking telemetry logging | M7.5.3 | 🎯 **No UX impact** |

**M7 Summary**: 52 total requirements
- **Complete (41)**: App Store prerequisites (4), CloudKit sync foundation (9), Household foundation (3 from M7.2.1), Shared data architecture (6 from M7.2.3), Member invitation & leave flow (3 from M7.2.2), Household rename (1 from M7.3.1), Remove member & delete household (1 from M7.3.3), Error handling & stability (5 from M7.3.4), UI polish (2 from M7.4), Pre-launch prep (6 from M7.6.1-M7.6.6), TestFlight & beta (4 from M7.6.7-M7.6.8), Architecture hardening (3 from M7.5)
- **In Progress (11)**: Repository hardening (4 from M7.2.3 remaining), Conflict resolution (5), Sync UI polish (5), App Store submission (4 from M7.7) minus 7 completed in M7.5
- **Progress**: M7.0 ✅, M7.1 ✅, M7.2.1 ✅, CloudKit Debugging ✅, M7.2.3 ✅, M7.2.2 ✅, M7.3.1 ✅, M7.3.3 ✅, M7.3.4 ✅, M7.4 ✅, M7.5 ✅, M7.6 ✅
- **Achievement**: Full household collaboration operational — create, invite, join, leave, rejoin, remove member, delete household all working. TestFlight live with external testers. Service layer ownership enforced, navigation patterns standardized.
- **Next**: M7.7 App Store Submission & Public Presence

---

## ✅ **M8: INGREDIENT PARSING INTELLIGENCE - COMPLETE** 🧠

**Status**: ✅ Complete (February 7-8, 2026)
**Actual Effort**: ~17 hours (M8.1: 3h, M8.3: 11h, M8.3.1: 3h, M8.3.2: 3h)
**Summary**: Parsing accuracy 95% → 98%+, template hygiene, automatic grocery merging. M8.2 skipped (PRD analysis sufficient), M8.4 ML deferred post-launch.
**PRD**: [M8 Meta-PRD](prds/m8-ingredient-parsing-intelligence-meta-prd.md)

### **Functional Requirements - Resilience & Telemetry (M8.1) - ✅ COMPLETE**

_Note: These requirements were originally specified in M7.5. M8.1 completed Feb 7, 2026 (~3h). Scope reduced: EditIngredientSheet removed as redundant (users edit inline via recipe edit view, M8.3 will improve parser)._

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-PR-001** | **Low-confidence detection** | ✅ Yellow badge for parseConfidence < 0.7 on recipe detail and grocery list (threshold raised in M8.3.1) | M8.1 | 🎯 **Graceful degradation** |
| **FR-PR-002** | **Edit ingredient button** | ❌ REMOVED (scope reduction — inline editing via recipe edit view sufficient) | M8.1 | — |
| **FR-PR-003** | **Structured edit form** | ❌ REMOVED (scope reduction — M8.3 parser improvements will reduce need) | M8.1 | — |
| **FR-PR-004** | **Pre-filled edit values** | ❌ REMOVED (scope reduction — dependent on FR-PR-003) | M8.1 | — |
| **FR-PR-005** | **Telemetry logging** | ✅ ParsingTelemetryService with local JSON, 20/20 tests passing | M8.1 | 🎯 **Data for M8.2+** |
| **FR-PR-006** | **Privacy-safe telemetry** | ✅ No user identification, local storage only | M8.1 | 🎯 **Privacy compliance** |

### **Functional Requirements - Hybrid NLP Parser (M8.3) - ✅ COMPLETE**

_Completed February 8, 2026 (~11h). Protocol-based hybrid parser with 7 regex pattern categories + NLP fallback. 58 new tests._

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-PI-001** | **Hybrid parser architecture** | ✅ IngredientParser protocol + HybridIngredientParser router | M8.3 | 🎯 **Extensibility** |
| **FR-PI-002** | **Fast path optimization** | ✅ RegexIngredientParser for 80% of inputs (< 0.05s) | M8.3 | 🎯 **Performance** |
| **FR-PI-003** | **Smart path NLP** | ✅ NLPIngredientParser using Apple NaturalLanguage (~310 lines) | M8.3 | 🎯 **Accuracy** |
| **FR-PI-004** | **Range pattern support** | ✅ "2-3 cloves" → 2.5 cloves average | M8.3 | 🎯 **Common pattern** |
| **FR-PI-005** | **Parenthetical extraction** | ✅ "1 can (14.5 oz)" → 14.5 oz, can | M8.3 | 🎯 **Complex parsing** |
| **FR-PI-006** | **Qualifier separation** | ✅ "garlic, minced" → garlic (notes: minced) | M8.3 | 🎯 **Detail preservation** |
| **FR-PI-007** | **Confidence calibration** | ✅ 0.0-1.0 confidence tiers with routing at 0.8 threshold | M8.3 | 🎯 **Smart routing** |
| **FR-PI-008** | **Performance budgets** | ✅ < 0.1s per parse (all patterns) | M8.3 | 🎯 **Responsiveness** |
| **FR-PI-009** | **Telemetry enhancement** | ✅ parserUsed field added (schema v2) | M8.3 | 🎯 **Monitoring** |
| **FR-PI-010** | **Regression prevention** | ✅ 58 tests across 3 files (30 regex + 12 NLP + 16 hybrid) | M8.3 | 🎯 **Quality assurance** |

### **Functional Requirements - Template Hygiene & Badge Fix (M8.3.1) - ✅ COMPLETE**

_Completed February 8, 2026 (~3h). Fixed template name pollution and badge threshold. 21 new tests._

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-TH-001** | **Centralized template creation** | ✅ All 5 creation paths routed through findOrCreateTemplate | M8.3.1 | 🎯 **Data integrity** |
| **FR-TH-002** | **Template quality heuristic** | ✅ needsReview computed property (4 detection rules) | M8.3.1 | 🎯 **User guidance** |
| **FR-TH-003** | **Review filter on Ingredients tab** | ✅ Yellow badges + "Review (N)" filter pill | M8.3.1 | 🎯 **Discoverability** |
| **FR-TH-004** | **Merge-on-rename dedup** | ✅ Renaming to existing name merges templates | M8.3.1 | 🎯 **Clean library** |
| **FR-TH-005** | **Compound plural preservation** | ✅ "black beans", "red pepper flakes" stay plural | M8.3.1 | 🎯 **Correctness** |
| **FR-TH-006** | **Badge threshold calibration** | ✅ Raised from < 0.5 to < 0.7 (aligned with M8.3 tiers) | M8.3.1 | 🎯 **Visibility** |

### **Functional Requirements - Auto-Merge Grocery Quantities (M8.3.2) - ✅ COMPLETE**

_Completed February 8, 2026 (~3h). Automatic quantity aggregation when adding same ingredient from multiple recipes. 19 new tests._

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-GM-001** | **Automatic quantity merging** | ✅ GroceryMergeService with same-unit, convertible-unit, and incompatible-unit handling | M8.3.2 | 🎯 **Core value** |
| **FR-GM-002** | **Unit conversion during merge** | ✅ Converts via UnitConversionService (cups/tbsp/tsp, lbs/oz) | M8.3.2 | 🎯 **Smart merging** |
| **FR-GM-003** | **Source recipe tracking** | ✅ Both recipe sources associated with merged item | M8.3.2 | 🎯 **Traceability** |
| **FR-GM-004** | **Confidence preservation** | ✅ min(existing, incoming) — never hides uncertainty | M8.3.2 | 🎯 **Data integrity** |
| **FR-GM-005** | **Consolidation button removed** | ✅ Manual merge button removed from grocery list toolbar | M8.3.2 | 🎯 **Simplified UX** |

### **Functional Requirements - ML Enhancement (M8.4 - PRE-LAUNCH)** 🚀

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-ML-001** | **Dataset preparation** | ✅ strangetom (81k) → 68,846 unique samples, 13→7 label mapping, fraction decoding, JSONL format | M8.4 Phase 1 | ✅ **Quality data from day one** |
| **FR-ML-002** | **Data validation** | ✅ Token/label alignment, label validity, fraction decode verification, stratified 80/10/10 split, dedup verified | M8.4 Phase 1 | ✅ **Model accuracy** |
| **FR-ML-003** | **Model training** | ✅ BiLSTM-CRF: 98.49% token accuracy, 95.40% sentence accuracy, all F1 ≥0.90 | M8.4 Phase 2 | ✅ **Custom intelligence** |
| **FR-ML-004** | **CoreML conversion** | ✅ PyTorch → coremltools → .mlpackage, predictions match within 4.77e-06, Viterbi parity 100% | M8.4 Phase 3 | ✅ **On-device deployment** |
| **FR-ML-005** | **On-device inference** | ✅ MLIngredientParser with CoreML + ViterbiDecoder, < 5ms per parse | M8.4 Phase 4 | ✅ **Privacy + speed** |
| **FR-ML-006** | **Hybrid system integration** | ✅ MLIngredientParser as tier 2 in 3-tier HybridIngredientParser (regex ≥0.9 → ML ≥0.8 → NLP) | M8.4 Phase 5 | ✅ **Progressive enhancement** |
| **FR-ML-007** | **Test suite** | ✅ 83 tests across 7 test files (ML, Viterbi, routing, telemetry, integration) | M8.4 Phase 6-9 | ✅ **Quality assurance** |
| **FR-ML-008** | **Continuous learning pipeline** | ✅ exportCorrectionsAsTrainingData() + retrain_with_corrections.py, corpus gate ≥50 | M8.4 Phase 7-8 | ✅ **Self-improving** |

### **Functional Requirements - Normalization Qualifier Reclassification (M8.4.1) - ✅ COMPLETE**

_Completed February 24, 2026 (~2h). Fixed identity qualifier stripping in IngredientTemplateService.normalize(). 15 new tests + 3 updated._

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-NQ-001** | **Identity qualifier preservation** | ✅ ground, fresh, frozen, dried, dark, whole, unsalted, etc. preserved in normalize() | M8.4.1 | 🎯 **Correct dedup** |
| **FR-NQ-002** | **Preparation qualifier stripping** | ✅ 9 pure preparation qualifiers (diced, chopped, sliced, minced, crushed, grated, shredded, halved, quartered) still stripped | M8.4.1 | 🎯 **Template consolidation** |
| **FR-NQ-003** | **Compound preferPlural** | ✅ Last-word lookup for multi-word ingredients (e.g., "dried cranberries" stays plural) | M8.4.1 | 🎯 **Natural naming** |
| **FR-NQ-004** | **Separate templates for qualified ingredients** | ✅ "ground beef" and "beef" are distinct templates | M8.4.1 | 🎯 **Shopping accuracy** |

### **Non-Functional Requirements - M8**

| ID | Requirement | Target | Milestone | Value |
|----|-------------|--------|-----------|-------|
| **NFR-PI-001** | **Parsing accuracy (M8.3)** | ≥98% (up from 95% baseline) | M8.3 | 🎯 **Quality improvement** |
| **NFR-PI-002** | **Low-confidence rate (M8.3)** | ≤2% (down from 5% baseline) | M8.3 | 🎯 **Fewer manual edits** |
| **NFR-PI-003** | **Fast path performance** | 80% of inputs < 0.05s (regex unchanged) | M8.3 | 🎯 **Speed preserved** |
| **NFR-PI-004** | **Smart path performance** | 15% of inputs < 0.2s (NLP acceptable latency) | M8.3 | 🎯 **Responsive** |
| **NFR-PI-005** | **Hybrid routing overhead** | Decision cost < 0.01s (minimal) | M8.3 | 🎯 **Efficient** |
| **NFR-ML-001** | **ML token accuracy (M8.4)** | ✅ 98.49% (target: ≥96%) | M8.4 | ✅ **High accuracy** |
| **NFR-ML-002** | **ML inference latency** | ✅ < 5ms per parse on-device (0.84ms typical) | M8.4 | ✅ **Real-time** |
| **NFR-ML-003** | **Model size** | ✅ 5.15 MB CoreML model (target: ≤5MB, close enough) | M8.4 | ✅ **Download efficiency** |
| **NFR-ML-004** | **Privacy compliance** | ✅ 100% on-device, no cloud calls | M8.4 | ✅ **User trust** |
| **NFR-ML-005** | **Zero regressions** | Existing patterns maintain/improve accuracy | M8 All | 🎯 **Quality** |

**M8 Summary**: 43 requirements across 5 phases: resilience & telemetry (6 ✅), hybrid NLP parser (10 ✅), template hygiene (6 ✅), auto-merge grocery (5 ✅), ML enhancement (8/8 ✅), and non-functional requirements (10 ✅). All requirements complete. Professional-grade 98%+ accuracy achieved. M8.2 skipped (PRD analysis sufficient). **M8.4 ✅ COMPLETE** — 10 phases, ~25 hours, 259 unit tests.

---

## 🔮 **M9: TECHNICAL DEBT & CODEBASE OPTIMIZATION - PLANNED** 🛠️

**Status**: ⏳ Planned (M9.0 ✅, M9.1.2 ✅, M9.5-partial ✅ prerequisites complete)
**Estimated**: 135-173 hours (17-22 weeks part-time)
**Dependencies**: M7 complete, M8 complete
**Summary**: Systematic refactoring, architectural improvements, and performance optimizations to reduce code size ~25%, eliminate performance bottlenecks, and establish sustainable patterns
**PRD**: [M9 Technical Debt PRD](prds/active/m9-technical-debt-codebase-optimization.md)

### **M9 Prerequisites** ✅

| Prereq | Status | Description |
|--------|--------|-------------|
| M9.0: Warning Resolution | ✅ COMPLETE | Zero-warning build baseline (18 warnings resolved) |
| M9.1.2: Centralize extractCleanIngredientName | ✅ COMPLETE | Single static method, 12 unit tests |
| M9.5-partial: Parser DI | ✅ COMPLETE | Injectable HybridIngredientParser + IngredientParsingService, mock parser, 9 routing tests |

### **Summary of M9 Phases**

**Phase 1: Quick Wins & Critical Fixes** (20-25h)
- Utility consolidation (eliminate ~300 lines of duplication)
- Core Data performance (indexes, N+1 query fixes, caching)
- Thread safety fixes (ManageCategoriesView background operations)
- Error handling standardization (ServiceError framework)

**Phase 2: Architectural Improvements** (40-50h)
- Dependency injection (reduce PersistenceController.shared coupling)
- Service layer consistency (async/await migration)
- View decomposition (RecipeListView 1,204→400 lines, AddIngredientsToListView 901→500 lines)

**Phase 3: Performance & Data Model** (60-70h)
- Ingredient normalization optimization (caching)
- Core Data cascade delete rules
- Category string→relationship migration
- Batch fetching implementation

**Phase 4: Quality & Sustainability** (15-20h)
- Coding standards documentation
- PR review checklist
- Unit test framework (≥60% coverage target)
- Logging framework

_Note: Full requirements for M9 are detailed in the dedicated PRD. This milestone is structured to allow stopping after any phase if ROI diminishes._

---

## 🚀 **M10: RECIPE IMPORT - READY** 📥

**Status**: 🚀 Ready — Implementation blueprint complete, spike validated, wireframes designed
**Estimated**: 70-95 hours (4 phases, 27 sub-phases)
**Dependencies**: M8.4 ✅ (ML parsing), M15 ✅ (design system)
**PRD**: `docs/prds/active/m10-recipe-import.md` (full implementation blueprint)
**Core Data Impact**: NONE — no schema changes, no migration
**Summary**: URL, text paste, and photo/OCR recipe import with draft-first workflow using separate `ImportDraftRecipe` model, `RecipeExtractor` strategy pattern, and `ImportField<T>` confidence tracking

### **Architecture Decisions (Implementation Plan)**

| Decision | Resolution |
|----------|-----------|
| Draft model | Separate `ImportDraftRecipe` struct (NOT extending RecipeFormData) — needs author, imageURL, cuisine + confidence tracking |
| Save method | New atomic `RecipeService.importRecipe(from:ingredientTexts:sourceURL:)` — single `context.save()` |
| Extractor pattern | `RecipeExtractor` protocol returning `nil` (mirrors `MLIngredientParser.init?()`) |
| Image handling v1 | `imageURL` web URL only via AsyncImage — no Core Data schema change; local persistence deferred |
| Ingredient groups v1 | Flattened with label lines — structured `RecipeSection` is future milestone |
| Import history | UserDefaults JSON array (diagnostic/ephemeral, not Core Data) |

### **Functional Requirements - URL Import (M10.1)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-RI-001** | **JSON-LD extraction** | Server-rendered HTML via URLSession, 3-tier strategy (ld+json, inline scripts, __NEXT_DATA__) | M10.1.2 | 🎯 **Core import** |
| **FR-RI-002** | **WKWebView fallback** | JS-rendered page extraction for WordPress blogs, headless with 8s timeout | M10.1.5 | 🎯 **Coverage** |
| **FR-RI-003** | **Schema.org mapping** | ISO 8601 + yield parsing → `ImportDraftRecipe` with `ImportField<T>` confidence | M10.1.2 | 🎯 **Data quality** |
| **FR-RI-004** | **Import preview UI** | Confidence dots (green/amber/red), inline editing, warning banner for partial | M10.1.4 | 🎯 **User control** |
| **FR-RI-005** | **Share extension** | Safari Share Sheet → App Group UserDefaults → main app handoff | M10.1.7 | 🎯 **Convenience** |
| **FR-RI-006** | **Duplicate detection** | Exact URL match + Levenshtein distance < 3 fuzzy title match | M10.1.6 | 🎯 **Data integrity** |
| **FR-RI-007** | **Draft-first workflow** | `ImportDraftRecipe` in-memory staging, persist only on confirm, atomic save | M10.1.1 | 🎯 **Safety** |

### **Functional Requirements - Text Paste Import (M10.2)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-RI-008** | **Text input UI** | Large TextEditor, paste-from-clipboard, "Extract Recipe" button | M10.2.2 | 🎯 **Flexibility** |
| **FR-RI-009** | **Foundation Models extraction** | `@Generable ImportedRecipeGenerable` struct with `@Guide` annotations | M10.2.3 | 🎯 **AI quality** |
| **FR-RI-010** | **Heuristic fallback** | Line scoring with section-aware context boosting (ported from spike) | M10.2.4 | 🎯 **Universal** |
| **FR-RI-011** | **Section detection** | Color-coded highlights, tap-to-reclassify lines | M10.2.5 | 🎯 **Accuracy** |

### **Functional Requirements - Photo/Image Import (M10.3)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-RI-012** | **Document scanner** | `VNDocumentCameraViewController` via UIViewControllerRepresentable | M10.3.1 | 🎯 **Capture** |
| **FR-RI-013** | **OCR pipeline** | `VNRecognizeTextRequest` accurate mode, 4 languages, returns `OCRLine` | M10.3.2 | 🎯 **Text extraction** |
| **FR-RI-014** | **Section classification** | `OCRLineClassifier` with heuristic scoring + context boosting (ported from spike) | M10.3.3 | 🎯 **Structure** |
| **FR-RI-015** | **Semi-automated assignment** | Mela-style overlay with TITLE/META/INGREDIENTS/STEPS section tags | M10.3.4 | 🎯 **User review** |
| **FR-RI-016** | **AI-assisted extraction** | OCR text → `FoundationModelsExtractor` → structured recipe | M10.3.5 | 🎯 **Quality** |

### **Functional Requirements - Polish & Integration (M10.4)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-RI-017** | **Import history** | `ImportHistoryService` — UserDefaults, 100-entry retention, auto-pruned | M10.4.1 | 🎯 **Management** |
| **FR-RI-018** | **Household sharing** | Auto scope assignment via `factory.make(Recipe.self, in: scope) { ... }` — factory handles store placement and householdKey | M10.4.2 | 🎯 **Collaboration** |
| **FR-RI-019** | **Import telemetry** | `ImportTelemetryService` — success rate, latency, correction rate, failure reasons | M10.4.3 | 🎯 **Observability** |

### **Non-Functional Requirements - M10**

| ID | Requirement | Target | Milestone | Value |
|----|-------------|--------|-----------|-------|
| **NFR-RI-001** | **URL extraction latency** | < 3s URLSession, < 8s WKWebView | M10.1 | 🎯 **Speed** |
| **NFR-RI-002** | **Tier 1 extraction rate** | ≥ 80% (with WKWebView) | M10.1 | 🎯 **Coverage** |
| **NFR-RI-003** | **Graceful failure rate** | 100% (every failure shows user message) | M10.1 | 🎯 **UX quality** |
| **NFR-RI-004** | **OCR accuracy** | ≥ 95% clean printed, ≥ 80% neat handwriting | M10.3 | 🎯 **Accuracy** |
| **NFR-RI-005** | **Zero data pollution** | Cancel → zero persisted entities | M10 All | 🎯 **Safety** |
| **NFR-RI-006** | **Zero regressions** | All 282 existing tests continue passing | M10 All | 🎯 **Stability** |
| **NFR-RI-007** | **New test coverage** | ~119 new tests across 10 test files | M10 All | 🎯 **Quality** |

**M10 Summary (Ready)**: 26 requirements including URL import (7), text paste (4), photo/image (5), polish (3), and non-functional (7). Implementation blueprint with 27 sub-phases, ~16 new production files, ~11 view files, ~119 new tests, zero Core Data schema changes. Spike-validated against 28 sites. PRD addresses 5 Codex review findings with revised architecture decisions.

---

## ✅ **M10.8: INLINE INGREDIENT EDITING - COMPLETE**

**Status**: ✅ Complete — February 28, 2026 (~5 hours, 2 phases)
**Summary**: Tap-to-edit ingredients, instructions, and metadata across all recipe views. Edit Recipe modal eliminated.

### **Functional Requirements - Inline Editing (M10.8)**

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-IE-001** | **Ingredient display/edit toggle** | ✅ Formatted read-only display (qty+unit secondary, name accent), tap → inline TextField | M10.8 P1 | 🎯 **Consistent editing** |
| **FR-IE-002** | **Instruction display/edit toggle** | ✅ Bordered card per step, tap → vertical TextField, submit/blur → save | M10.8 P2 | 🎯 **Inline instructions** |
| **FR-IE-003** | **Metadata inline editing** | ✅ Tap title/timing/servings → inline TextField, save-on-blur | M10.8 P2 | 🎯 **No modal needed** |
| **FR-IE-004** | **Favorite toggle** | ✅ Always-visible heart icon, tap → `toggleFavorite()` | M10.8 P2 | 🎯 **Quick access** |
| **FR-IE-005** | **Add/delete steps** | ✅ "+ Add Step" button, long-press context menu delete | M10.8 P2 | 🎯 **Step management** |
| **FR-IE-006** | **Import instruction editing** | ✅ Same bordered card pattern in RecipeImportPreviewView, writes to draft buffer | M10.8 P2 | 🎯 **Import consistency** |
| **FR-IE-007** | **Edit Recipe modal removed** | ✅ `showingEditSheet` state, sheet, menu item all removed | M10.8 P2 | 🎯 **Simplified UX** |
| **FR-IE-008** | **Category picker height** | ✅ `.presentationDetents([.medium, .large])` on both views | M10.8 P2 | 🎯 **Accessibility** |

**M10.8 Summary**: 8 requirements complete. Zero model/service changes, 3 view files modified (RecipeListView, RecipeImportPreviewView, EditRecipeView + CreateRecipeView in Phase 1). Three `@FocusState` properties provide native mutual exclusion across ingredient, instruction, and metadata editing modes.

---

## 🔮 **M11: ANALYTICS & INSIGHTS - PLANNED** 📊

**Status**: ⏳ Planned
**Estimated**: 8-12 hours
**Dependencies**: M4 complete, M8 clean parsing, M9 optimized architecture
**Summary**: Usage analytics, insights dashboard, and data-driven recommendations

### **Functional Requirements - Analytics Infrastructure (M11.1)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-AN-001** | **Analytics service architecture** | Data aggregation and caching | M11.1 | 🎯 **Performance** |
| **FR-AN-002** | **Query optimization** | Efficient trend queries | M11.1 | 🎯 **Responsiveness** |

### **Functional Requirements - Insights Dashboard (M11.2)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-IN-001** | **Usage statistics** | Recipe popularity, ingredient frequency | M11.2 | 🎯 **User insights** |
| **FR-IN-002** | **Cost tracking** | Budget trends and analysis | M11.2 | 🎯 **Financial awareness** |
| **FR-IN-003** | **Visualizations** | Charts and graphs for trends | M11.2 | 🎯 **Data clarity** |

### **Functional Requirements - Recommendations (M11.3)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-RE-001** | **Recipe suggestions** | Smart recommendations based on history | M11.3 | 🎯 **Discovery** |
| **FR-RE-002** | **Seasonal highlights** | Ingredient seasonality awareness | M11.3 | 🎯 **Freshness** |
| **FR-RE-003** | **Budget optimization** | Cost-saving tips and recommendations | M11.3 | 🎯 **Value** |

### **Functional Requirements - Export & Sharing (M11.4)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-EX-001** | **Data export** | Export capabilities for analytics data | M11.4 | 🎯 **Data portability** |
| **FR-EX-002** | **Report generation** | Formatted reports for sharing | M11.4 | 🎯 **Sharing** |

### **Non-Functional Requirements - M11**

| ID | Requirement | Target | Milestone | Value |
|----|-------------|--------|-----------|-------|
| **NFR-AN-001** | **Dashboard load time** | < 1s for analytics display | M11.2 | 🎯 **User experience** |
| **NFR-AN-002** | **Query performance** | < 0.5s for data retrieval | M11.1 | 🎯 **Snappy** |
| **NFR-AN-003** | **Data accuracy** | 100% accurate based on Core Data | M11 All | 🎯 **Trust** |

**M11 Summary (Planned)**: 12 requirements including analytics infrastructure (2), insights dashboard (3), recommendations (3), export/sharing (2), and non-functional requirements (3). Leverages clean ingredient data from M8 and optimized architecture from M9 to provide data-driven insights.

---

## 🔮 **M12-M16: ADVANCED INTELLIGENCE PLATFORM - PLANNED**

### **M12: Health & Nutrition Integration** (10-15h core)

#### **Functional Requirements - Core Health Features**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-HN-001** | **Apple Health integration** | HealthKit connection | M12.1-12.4 | 🎯 **Health awareness** |
| **FR-HN-002** | **Nutritional database** | USDA nutrient data | M12.1-12.4 | 🎯 **Nutrition facts** |
| **FR-HN-003** | **Dietary goal tracking** | Custom nutrition targets | M12.1-12.4 | 🎯 **Goal management** |
| **FR-HN-004** | **Allergen support** | Dietary restriction filtering | M12.1-12.4 | 🎯 **Safety** |

_Note: ML-Powered Parsing previously listed as M9.5 has been moved to M8.4 (Optional ML Enhancement)_

**M12 Summary (Planned)**: 4 requirements for core health features. Leverages clean ingredient data from M8 parsing improvements for accurate nutritional analysis.

### **M13: Budget Intelligence** (10-15 hours)

| ID | Requirement | Milestone | Value |
|----|-------------|-----------|-------|
| **FR-BD-001** | **Price tracking** | M13 | 🎯 **Cost awareness** |
| **FR-BD-002** | **Budget planning** | M13 | 🎯 **Financial control** |
| **FR-BD-003** | **Cost optimization** | M13 | 🎯 **Savings** |
| **FR-BD-004** | **Store comparison** | M13 | 🎯 **Best value** |

### **M14: AI-Powered Shopping Assistant** (10-15 hours)

| ID | Requirement | Milestone | Value |
|----|-------------|-----------|-------|
| **FR-AI-001** | **Natural language meal planning** | M14 | 🎯 **Conversational UX** |
| **FR-AI-002** | **Smart recipe discovery** | M14 | 🎯 **Personalization** |
| **FR-AI-003** | **Automated list generation** | M14 | 🎯 **Convenience** |
| **FR-AI-004** | **Learning preferences** | M14 | 🎯 **Adaptive** |

### **M16: Advanced Collaboration** (10-15 hours)

| ID | Requirement | Milestone | Value |
|----|-------------|-----------|-------|
| **FR-AC-001** | **Real-time shopping mode** | M16 | 🎯 **Live coordination** |
| **FR-AC-002** | **Task delegation** | M16 | 🎯 **Family workflow** |
| **FR-AC-003** | **Shopping analytics** | M16 | 🎯 **Household insights** |

---

## 🎨 **M15: UX DESIGN SYSTEM & VISUAL REFRESH - ACTIVE**

**Status**: 🚀 Active (design complete, implementation starting)
**Estimated**: 50-70 hours (7 phases)
**Dependencies**: iOS 26 SDK
**Summary**: Comprehensive visual refresh with warm color palette, custom typography, Liquid Glass adoption, and iOS 26 deployment target
**PRD**: [M15 UX Design System PRD](prds/complete/m15-ux-design-system.md)

### **Functional Requirements - Design System Foundation (M15.1)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-UX-001** | **ForagerTheme design system** | Semantic color tokens, typography scale, spacing constants | M15.1 | 🎯 **Design consistency** |
| **FR-UX-002** | **Raise deployment target to iOS 26** | Remove iOS 18 target, adopt iOS 26 APIs without availability checks | M15.1 | 🎯 **Liquid Glass access** |
| **FR-UX-003** | **Liquid Glass TabView migration** | Replace CustomBottomNavigation + HamburgerMenuModifier with native TabView | M15.1 | 🎯 **Native experience** |
| **FR-UX-004** | **Asset Catalog color sets** | 38 adaptive color sets (backgrounds, surfaces, text, accent, semantic, borders, categories) | M15.1 | 🎯 **Theme infrastructure** |

### **Functional Requirements - Color & Typography (M15.2)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-UX-005** | **Warm color palette migration** | Forest green (#2D5016), bark (#2C2418), cream (#F5F0E8), canvas (#FDFBF7) | M15.2 | 🎯 **Brand identity** |
| **FR-UX-006** | **Typography system** | SF Pro Rounded for UI, New York serif for recipe content, monospaced digits | M15.2 | 🎯 **Visual hierarchy** |
| **FR-UX-007** | **Category color system** | 11 category colors with light/dark variants, all ≥ 3:1 contrast | M15.2 | 🎯 **Visual organization** |

### **Functional Requirements - Screen Overhauls (M15.3-M15.5)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-UX-008** | **Grocery list UX refresh** | Smart sorting, enhanced swipe actions, progress bar redesign | M15.3 | 🎯 **Shopping efficiency** |
| **FR-UX-009** | **Recipe UX refresh** | Card-based list, tabbed detail view, glass-effect FABs | M15.4 | 🎯 **Recipe experience** |
| **FR-UX-010** | **Meal plan UX refresh** | Horizontal day strip, drag-and-drop reordering | M15.5 | 🎯 **Planning experience** |
| **FR-UX-011** | **Ingredients UX refresh** | Library cards with usage indicators, category visual refresh | M15.5 | 🎯 **Ingredient management** |

### **Functional Requirements - Liquid Glass & Polish (M15.6)** ✅ COMPLETE

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-UX-012** | **Liquid Glass effects** | ✅ `.glassEffect(.regular)` on cards, autocomplete dropdowns, overlays (12 files) | M15.6 | 🎯 **iOS 26 native** |
| **FR-UX-013** | **Tab bar behaviors** | ✅ `.tabBarMinimizeBehavior(.onScrollDown)` on TabView | M15.6 | 🎯 **Content-first** |
| **FR-UX-014** | **Layered app icon** | ⏳ Deferred to manual Icon Composer session | M15.6 | 🎯 **Brand refresh** |

### **Functional Requirements - Accessibility & QA (M15.7)** ✅ COMPLETE

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-UX-015** | **Dark mode audit** | ✅ Glass rim light overlay, ForagerTheme tokens verified in dark mode | M15.7 | 🎯 **Dark mode quality** |
| **FR-UX-016** | **WCAG AA compliance** | ✅ VoiceOver labels on all interactive elements, accessibility values/hints | M15.7 | 🎯 **Accessibility** |
| **FR-UX-017** | **Dynamic Type support** | ✅ @ScaledMetric on fixed-size elements, lineLimit improvements | M15.7 | 🎯 **Inclusivity** |
| **FR-UX-018** | **Reduce Motion support** | ✅ All M15 animations guarded with accessibilityReduceMotion across 10 views | M15.7 | 🎯 **Motion sensitivity** |

### **Non-Functional Requirements - M15**

| ID | Requirement | Target | Milestone | Value |
|----|-------------|--------|-----------|-------|
| **NFR-UX-001** | **Zero regressions** | All existing features maintain functionality | M15 All | 🎯 **Quality** |
| **NFR-UX-002** | **60fps UI performance** | All animations smooth, no frame drops | M15 All | 🎯 **Smoothness** |
| **NFR-UX-003** | **Zero hard-coded colors** | All views use ForagerTheme semantic tokens | M15 All | 🎯 **Maintainability** |

**M15 Summary (COMPLETE)**: 21 requirements across 8 phases: design system foundation (4 ✅), color & typography (3 ✅), screen overhauls (4 ✅), Liquid Glass polish (2 ✅ + 1 deferred), accessibility & QA (4 ✅), and non-functional (3 ✅). Full iOS 26 Liquid Glass adoption with warm color palette, comprehensive accessibility, and dark mode polish. App icon deferred to manual Icon Composer session.

---

## ✅ **M9.13: MANAGEDOBJECTFACTORY ENFORCEMENT - COMPLETE**

**Status**: ✅ Complete - March 11, 2026 (~3 hours)
**Summary**: Bugfix milestone — fix TestFlight crash and enforce factory pattern for HouseholdScoped entity creation

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-FE-001** | **Factory enforcement for HouseholdScoped entities** | ✅ All 26 production creation sites route through ManagedObjectFactory (ADR 014) | M9.13 P1-P3 | 🎯 **Store correctness** |
| **FR-FE-002** | **Remove assign() band-aids** | ✅ All `viewContext.assign()` calls removed — factory handles store assignment | M9.13 P1 | 🎯 **Crash fix** |
| **FR-FE-003** | **Factory error visibility** | ✅ All 11 `try?` sites converted to `do/catch` with `#if DEBUG` logging | M9.13 P5 | 🎯 **Diagnosability** |
| **FR-FE-004** | **Store-correct background writes** | ✅ WeeklyListsView uses `performScopedWrite` instead of `performWrite` | M9.13 P5 | 🎯 **Store correctness** |
| **FR-FE-005** | **Factory encapsulation** | ✅ All `factory` properties `private(set)` with `configure(factory:)` injection | M9.13 P5 | 🎯 **Encapsulation** |

**M9.13 Summary (COMPLETE)**: 5 requirements across 5 phases. Fixed TestFlight crash from `viewContext.assign()`, enforced ManagedObjectFactory across all creation sites, hardened with DEBUG logging and encapsulation. Architecture audit skill prevents regression.

---

## ✅ **M9.16: UNIFIED GROCERYLISTITEMSERVICE - COMPLETE**

**Status**: ✅ Complete - March 14, 2026 (~4 hours)
**Summary**: Consolidate 6 independent GroceryListItem creation paths into unified service; add ingredient selection UI for meal plan → grocery list flow

| ID | Requirement | Implementation | Milestone | Value |
|----|-------------|----------------|-----------|-------|
| **FR-GIS-001** | **Unified GroceryListItem creation pipeline** | ✅ `GroceryListItemService` with `addItem()`, `addIngredients()`, `addStaples()` | M9.16 | 🎯 **Consistency** |
| **FR-GIS-002** | **Cross-store safe category resolution** | ✅ `resolveCategory()` compares `persistentStore`, falls back to name-based lookup | M9.16 | 🎯 **Store correctness** |
| **FR-GIS-003** | **Merge with existing list items** | ✅ Normalized name matching + `GroceryMergeService` integration in unified pipeline | M9.16 | 🎯 **Deduplication** |
| **FR-GIS-004** | **Meal plan ingredient selection wizard** | ✅ `MealPlanIngredientSelectionView` — recipe-by-recipe with checkboxes, servings stepper, "Add All Remaining" | M9.16 | 🎯 **User control** |
| **FR-GIS-005** | **MealPlanDetailView category fix** | ✅ `performBulkAdd` migrated from inline creation (zero categories) to `addIngredients()` | M9.16 | 🎯 **Bug fix** |
| **FR-GIS-006** | **MealPlanService category fix** | ✅ `generateGroceryList` migrated from 70-line inline resolution to `addIngredients(skipSave: true)` | M9.16 | 🎯 **Bug fix** |

**M9.16 Summary (COMPLETE)**: 6 requirements. Unified 6 creation paths (migrated 2 broken, 3 working left as-is, 1 background-context path incompatible). Built ingredient selection wizard. 0 build warnings.

---

## 📊 **REQUIREMENTS SUMMARY**

### **By Status**

| Status | M1 | M2 | M3 | M4 | M5.0 | M7 | M8 | M9 (Core) | M8.4 | M15 | Total |
|--------|----|----|----|----|------|----|----|-----------|------|-----|-------|
| ✅ Complete | 19 | 37 | 33 | 19 | 14 | 34 | 27 | 0 | 2 | 20 | **205** |
| 🔄 In Progress | 0 | 0 | 0 | 0 | 0 | 18 | 0 | 0 | 0 | 0 | **18** |
| ⏳ Planned | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 4 | 6 | 1 | **11** |
| **Total** | **19** | **37** | **33** | **19** | **14** | **52** | **27** | **4** | **8** | **21** | **234** |

### **By Category**

| Category | Requirements | Status |
|----------|--------------|--------|
| Grocery Lists | 5 | ✅ Complete |
| Categories | 5 | ✅ Complete |
| Staples | 4 | ✅ Complete |
| Recipes | 19 | ✅ Complete |
| Quantities | 33 | ✅ Complete |
| Meal Planning | 19 | ✅ Complete |
| TestFlight & Identity | 14 | ✅ Complete |
| App Store Compliance | 4 | ✅ Complete (M7.0) |
| CloudKit Sync Foundation | 9 | ✅ Complete (M7.1 + Debugging) |
| Household Foundation | 3 | ✅ Complete (M7.2.1) |
| Shared Data Architecture | 6 | ✅ Complete (M7.2.3 Phases 0, 2, 4) |
| CloudKit Collaboration | 17 | 🔄 In Progress (M7.2.2-M7.2.4, M7.3-M7.4) |
| **Parsing Resilience (M8.1)** | **3 delivered + 3 removed** | ✅ **Complete** |
| **Hybrid NLP Parser (M8.3)** | **10** | ✅ **Complete** |
| **Template Hygiene (M8.3.1)** | **6** | ✅ **Complete** |
| **Auto-Merge Grocery (M8.3.2)** | **5** | ✅ **Complete** |
| **ML Parsing (M8.4)** | **8** | ✅ **Complete** |
| **Normalization Fix (M8.4.1)** | **4** | ✅ **Complete** |
| Pre-Launch Prep (M7.6) | 9 | 🔄 In Progress (M7.6.1-M7.6.6 ✅, M7.6.7-M7.6.8 pending) |
| Recipe Import | 24 | 🚀 Ready (M10) |
| Analytics & Insights | 12 | ⏳ Planned (M11) |
| Health & Nutrition | 4 | ⏳ Planned (M12) |
| Budget Intelligence | 4 | ⏳ Planned (M13) |
| AI Assistant | 4 | ⏳ Planned (M14) |
| Advanced Collaboration | 3 | ⏳ Planned (M16) |
| **UX Design System (M15)** | **20 delivered + 1 deferred** | ✅ **Complete** |
| **Complete** | **205** | **88% (205/234)** |
| **In Progress** | **18** | **8% (18/234)** |
| **Planned (Mandatory)** | **5** | **2% (5/234)** |
| **Planned (Optional)** | **6** | **3% (6/234)** |

### **Performance Requirements Status**

| Requirement | Target | Actual | Status |
|-------------|--------|--------|--------|
| Query performance | < 0.1s | < 0.1s | ✅ Met |
| Search performance | < 0.2s | < 0.15s | ✅ Exceeded |
| Autocomplete | < 0.1s | < 0.08s | ✅ Exceeded |
| **Parsing (M3 baseline)** | **< 0.05s** | **< 0.03s** | ✅ **Exceeded** |
| **Parsing accuracy (M3)** | **> 95%** | **~95%** | ✅ **Met** |
| **Parsing accuracy (M8.3 target)** | **≥ 98%** | **98%+** | ✅ **Achieved** |
| **Parsing accuracy (M8.4 target)** | **≥ 99.5%** | **TBD** | ⏳ **Optional (deferred)** |
| Scaling | < 0.5s | < 0.4s | ✅ Exceeded |
| Consolidation analysis | < 0.5s | < 0.3s | ✅ Exceeded |
| Merge execution | < 1s | < 0.8s | ✅ Exceeded |
| UI responsiveness | 60fps | 60fps | ✅ Met |

**All current performance targets met or exceeded** ✅  
**New parsing targets set for M8.0 (98%) and M9.5 (99.5% optional)** ⏳

---

## 🎯 **CURRENT REQUIREMENTS FOCUS**

### **Completed: M5.0 App Renaming & TestFlight** ✅
**Total Time**: 6 hours  
**Status**: All 14 requirements complete

### **Completed: M7 CloudKit Sync & Shared Data Architecture** ✅
**Total Time**: 27 hours (M7.0: 3h + M7.1: 6.5h + M7.2.1: 1.25h + Debugging: 4h + M7.2.3: 12.25h)  
**Status**: 22 requirements complete
- ✅ App Store prerequisites (privacy policy, compliance)
- ✅ CloudKit schema generation (all 10 entities)
- ✅ Multi-device sync (<5s latency)
- ✅ Automatic background sync
- ✅ Offline sync queue
- ✅ Sync status monitoring
- ✅ Environment configuration (Development)
- ✅ CloudKit import observer pattern
- ✅ Race condition prevention (serial queue)
- ✅ Clean user onboarding (no sample data)
- ✅ Household creation & shared zone (M7.2.1)
- ✅ All 10 entities household-scoped (M7.2.1)
- ✅ Automatic duplicate category prevention (M7.2.3)
- ✅ Self-healing multi-device sync (<60s convergence)
- ✅ Dedupe-after-creation pattern (Apple-recommended)
- ✅ Household as aggregate root (M7.2.3 Phase 0)
- ✅ Scope-based store assignment (M7.2.3 Phase 2)
- ✅ Attach-then-share migration (M7.2.3 Phase 4)
- ✅ HouseholdScoped protocol (M7.2.3 Phase 2)
- ✅ Recipe ownership semantics (M7.2.3 Phase 0)
- ✅ DEBUG validators (M7.2.3 Phase 4)

**Achievement**: Production-ready CloudKit sync with complete shared data architecture! 61 items successfully migrated to shared zone.

### **In Progress: M7 Multi-User Collaboration & External TestFlight** 🔄
**Remaining Time**: 8-19 hours  
**Requirements In Progress**: 30 (member invitation, repository hardening, conflict resolution, sync UI, parsing, TestFlight)

**Recent Achievement**:
- ✅ M7.2.3 COMPLETE - All 6 phases done (12.25 hours, 88% accuracy)
- ✅ Shared data architecture operational (Phases 0-2)
- ✅ Attach-then-share migration validated (Phase 4)
- ✅ 61 items migrated to CloudKit shared zone
- ✅ Critical bug fixed: Missing context.save() after container.share()

**Strategic Additions:**
- **M7.2.3: COMPLETE** ✅ (6 requirements complete, 4 remaining for phases 5-6)
- **M7.2.2: Next** 🚀 (Member invitation testing, 2-3h)
- **M7.5: Parsing Resilience** (6 requirements, 3-4h) - Graceful degradation before external beta
- External TestFlight and public beta (9 requirements, 6-9h)

**Current Focus**: M7.2.2 - Member Invitation & Acceptance Testing (2-3 hours)

### **Future Parsing Evolution** 💡

**M8.0: Data-Driven Improvements** (10 requirements, 8-12h)
- Analyze M7 telemetry to identify real failure patterns
- Hybrid NLP system for 98%+ accuracy
- Build on actual user data, not speculation

**M9.5: ML Excellence - OPTIONAL** (8 requirements, 15-20h)
- Custom CoreML model for 99.5%+ accuracy
- Self-improving system with continuous learning
- **Decision point**: Only pursue if M8.0 shows room for improvement

---

**Strategic Validation**: Core platform (M1-M5.0) complete with 122 requirements. M7 CloudKit sync and collaboration (52 requirements: 34 complete, 18 in progress). M8 parsing intelligence complete (27 + 8 + 4 = 39 requirements delivered across M8.1-M8.4.1). M15 UX Design System complete (20 requirements delivered, 1 deferred). Complete platform: 238 total requirements (217 complete, 18 in progress, 3 planned).

**Last Updated**: February 24, 2026
**Version**: 7.0
**Next Update**: After M7.7 App Store Submission
**Current Focus**: M15 ✅ COMPLETE — Merge branch, TestFlight push, then M7.7
# Forager - Requirements Document

**Last Updated**: January 4, 2026  
**Version**: 4.6  
**Current Milestone**: M5.0 Complete ✅ | M7.1 Complete ✅ | M7.2.1 Complete ✅ | **M7.2.3 COMPLETE ✅** | M7.2.2 🚀 Ready

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
| **FR-RM-033** | **Parse-then-autocomplete** | ✅ **Intelligent parsing with fuzzy matching autocomplete** | ✅ M2.3 | 🎯 **Efficient ingredient entry** |
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


## 🚀 **M7: CLOUDKIT SYNC & EXTERNAL TESTFLIGHT - IN PROGRESS**

**Status**: 🔄 In Progress - M7.2.3 Complete ✅, M7.2.2 Testing Ready 🚀  
**Progress**: M7.0 (3h) ✅, M7.1 (6.5h) ✅, M7.2.1 (1.25h) ✅, CloudKit Debug (4h) ✅, M7.2.3 (12.25h) ✅ = 27h / 35-46h  
**Estimated Remaining**: 8-19 hours  
**Summary**: Full CloudKit synchronization with automatic duplicate prevention, multi-user collaboration, parsing resilience, and external public beta

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
| **FR-CK-007** | **Member invitation flow** | Invite household members via email, iCloud integration | M7.2.2 | 🎯 **Easy sharing** |
| **FR-CK-008** | **Household management** | View members, remove/leave household, dissolve | M7.2.4 | 🎯 **Access control** |
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

### **Functional Requirements - Parsing Resilience & Polish (M7.5 - NEW)** 💡

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-PR-001** | **Low-confidence detection** | Yellow badge for parseConfidence < 0.5 | M7.5.1 | 🎯 **Graceful degradation** |
| **FR-PR-002** | **Edit ingredient button** | "Review" button on low-confidence items | M7.5.1 | 🎯 **User correction flow** |
| **FR-PR-003** | **Structured edit form** | EditIngredientSheet with quantity/unit/name fields | M7.5.2 | 🎯 **Professional UX** |
| **FR-PR-004** | **Pre-filled edit values** | Parse results pre-populate edit form | M7.5.2 | 🎯 **Efficient editing** |
| **FR-PR-005** | **Telemetry logging** | ParsingTelemetryService logs failures to local JSON | M7.5.3 | 🎯 **Data for M8.0** |
| **FR-PR-006** | **Privacy-safe telemetry** | No user identification, local storage only | M7.5.3 | 🎯 **Privacy compliance** |

### **Functional Requirements - External TestFlight**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-TF-011** | **External testing group** | Create public external testing group | M7.6.1 | 🎯 **Public beta** |
| **FR-TF-012** | **App Review submission** | Pass Apple's external testing review | M7.6.2 | 🎯 **Public distribution** |
| **FR-TF-013** | **Public TestFlight link** | Generate shareable public link | M7.6.4 | 🎯 **Easy distribution** |
| **FR-TF-014** | **Beta landing page** | Professional web page for beta | M7.7.1 | 🎯 **Professional showcase** |
| **FR-TF-015** | **LinkedIn showcase** | Public post with beta link | M7.7.2 | 🎯 **Professional visibility** |

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
- **Complete (22)**: App Store prerequisites (4), CloudKit sync foundation (9), Household foundation (3 from M7.2.1), Shared data architecture (6 from M7.2.3)
- **In Progress (30)**: Multi-user collaboration (1 from M7.2.2), Repository hardening (4 from M7.2.3 remaining), Conflict resolution (5), Sync UI polish (5), Parsing resilience (6), External TestFlight (5), Non-functional (4 remaining)
- **Progress**: M7.0 ✅, M7.1 ✅, M7.2.1 ✅, CloudKit Debugging ✅, M7.2.3 ✅ (all 6 phases complete)
- **Achievement**: Production-ready CloudKit sync with attach-then-share migration validated. 61 items migrated successfully to shared zone.
- **Next**: M7.2.2 - Member Invitation & Acceptance Testing (2-3 hours)

---

## 🔮 **M8: INGREDIENT PARSING INTELLIGENCE - PLANNED** 🧠

**Status**: ⏳ Planned
**Estimated**: 13-16 hours core (+15-20h optional ML)
**Dependencies**: M7 complete with external beta telemetry
**Summary**: Data-driven parsing evolution from 95% → 98% → 99.5% accuracy through hybrid NLP and optional ML
**PRD**: [M8 Meta-PRD](prds/m8-ingredient-parsing-intelligence-meta-prd.md)

### **Functional Requirements - Resilience & Telemetry (M8.1)**

_Note: These 6 requirements were originally specified in M7.5 and are included here for completeness_

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-PR-001** | **Low-confidence detection** | Yellow badge for parseConfidence < 0.5 | M8.1 | 🎯 **Graceful degradation** |
| **FR-PR-002** | **Edit ingredient button** | "Review" button on low-confidence items | M8.1 | 🎯 **User correction flow** |
| **FR-PR-003** | **Structured edit form** | EditIngredientSheet with quantity/unit/name fields | M8.1 | 🎯 **Professional UX** |
| **FR-PR-004** | **Pre-filled edit values** | Parse results pre-populate edit form | M8.1 | 🎯 **Efficient editing** |
| **FR-PR-005** | **Telemetry logging** | ParsingTelemetryService logs failures to local JSON | M8.1 | 🎯 **Data for M8.2+** |
| **FR-PR-006** | **Privacy-safe telemetry** | No user identification, local storage only | M8.1 | 🎯 **Privacy compliance** |

### **Functional Requirements - Hybrid NLP Parser (M8.3)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-PI-001** | **Hybrid parser architecture** | Protocol-based abstraction (regex + NLP + future ML) | M8.3 | 🎯 **Extensibility** |
| **FR-PI-002** | **Fast path optimization** | RegexIngredientParser for 80% of inputs (< 0.05s) | M8.3 | 🎯 **Performance** |
| **FR-PI-003** | **Smart path NLP** | NLPIngredientParser using Apple NaturalLanguage | M8.3 | 🎯 **Accuracy** |
| **FR-PI-004** | **Range pattern support** | "2-3 cloves" → 2.5 cloves average | M8.3 | 🎯 **Common pattern** |
| **FR-PI-005** | **Parenthetical extraction** | "1 can (14.5 oz)" → 14.5 oz, can | M8.3 | 🎯 **Complex parsing** |
| **FR-PI-006** | **Qualifier separation** | "garlic, minced" → garlic (notes: minced) | M8.3 | 🎯 **Detail preservation** |
| **FR-PI-007** | **Confidence calibration** | Accurate confidence scores (0.0-1.0) for routing | M8.3 | 🎯 **Smart routing** |
| **FR-PI-008** | **Performance budgets** | p50 < 0.05s, p95 < 0.3s, p99 < 0.5s | M8.3 | 🎯 **Responsiveness** |
| **FR-PI-009** | **Telemetry enhancement** | Track parser used, durations, confidence scores | M8.3 | 🎯 **Monitoring** |
| **FR-PI-010** | **Regression prevention** | Comprehensive test suite (existing + new patterns) | M8.3 | 🎯 **Quality assurance** |

### **Functional Requirements - ML Enhancement (M8.4 - OPTIONAL)** 💡

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-ML-001** | **Training dataset creation** | Extract 100+ labeled examples from M7-M8 telemetry | M8.4 | 🎯 **Quality data** |
| **FR-ML-002** | **Data validation** | Validate and clean training data (spot-check 20%) | M8.4 | 🎯 **Model accuracy** |
| **FR-ML-003** | **Create ML training** | Train custom text classifier (99%+ test accuracy) | M8.4 | 🎯 **Custom intelligence** |
| **FR-ML-004** | **Hyperparameter tuning** | Optimize model iterations, algorithm selection | M8.4 | 🎯 **Best accuracy** |
| **FR-ML-005** | **On-device inference** | CoreML integration for local prediction (< 0.2s) | M8.4 | 🎯 **Privacy + speed** |
| **FR-ML-006** | **Hybrid system integration** | MLIngredientParser as third tier after regex/NLP | M8.4 | 🎯 **Progressive enhancement** |
| **FR-ML-007** | **Continuous learning pipeline** | Retraining workflow from ongoing telemetry | M8.4 | 🎯 **Self-improving** |
| **FR-ML-008** | **Retraining triggers** | Retrain at 50+ corrections or 30 days | M8.4 | 🎯 **Fresh model** |

### **Non-Functional Requirements - M8**

| ID | Requirement | Target | Milestone | Value |
|----|-------------|--------|-----------|-------|
| **NFR-PI-001** | **Parsing accuracy (M8.3)** | ≥98% (up from 95% baseline) | M8.3 | 🎯 **Quality improvement** |
| **NFR-PI-002** | **Low-confidence rate (M8.3)** | ≤2% (down from 5% baseline) | M8.3 | 🎯 **Fewer manual edits** |
| **NFR-PI-003** | **Fast path performance** | 80% of inputs < 0.05s (regex unchanged) | M8.3 | 🎯 **Speed preserved** |
| **NFR-PI-004** | **Smart path performance** | 15% of inputs < 0.2s (NLP acceptable latency) | M8.3 | 🎯 **Responsive** |
| **NFR-PI-005** | **Hybrid routing overhead** | Decision cost < 0.01s (minimal) | M8.3 | 🎯 **Efficient** |
| **NFR-ML-001** | **ML parsing accuracy (M8.4)** | ≥99.5% (up from 98% baseline) | M8.4 | 🎯 **Industry-leading** |
| **NFR-ML-002** | **ML inference latency** | < 0.2s on-device CoreML | M8.4 | 🎯 **Real-time** |
| **NFR-ML-003** | **Model size** | ≤5MB CoreML model file | M8.4 | 🎯 **Download efficiency** |
| **NFR-ML-004** | **Privacy compliance** | 100% on-device, no cloud calls | M8.4 | 🎯 **User trust** |
| **NFR-ML-005** | **Zero regressions** | Existing patterns maintain/improve accuracy | M8 All | 🎯 **Quality** |

**M8 Summary (Planned)**: 32 requirements across 4 phases: resilience & telemetry (6), hybrid NLP parser (10), ML enhancement (8 optional), and non-functional requirements (10). Achieves professional-grade 98%+ accuracy (M8.3) with optional industry-leading 99.5%+ ML enhancement (M8.4). Exit points after each phase allow flexible ROI optimization.

---

## 🔮 **M9: TECHNICAL DEBT & CODEBASE OPTIMIZATION - PLANNED** 🛠️

**Status**: ⏳ Planned
**Estimated**: 135-173 hours (17-22 weeks part-time)
**Dependencies**: M7 complete, M8 complete
**Summary**: Systematic refactoring, architectural improvements, and performance optimizations to reduce code size ~25%, eliminate performance bottlenecks, and establish sustainable patterns
**PRD**: [M9 Technical Debt PRD](prds/m9-technical-debt-codebase-optimization.md)

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

## 🔮 **M10: ANALYTICS & INSIGHTS - PLANNED** 📊

**Status**: ⏳ Planned
**Estimated**: 16-24 hours
**Dependencies**: M7 complete (structured data from meal planning), M9 complete (clean architecture)
**Summary**: Usage analytics, insights dashboard, and data-driven recommendations

### **Functional Requirements - Analytics Infrastructure (M10.1)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-AN-001** | **Analytics service architecture** | Data aggregation and caching | M10.1 | 🎯 **Performance** |
| **FR-AN-002** | **Query optimization** | Efficient trend queries | M10.1 | 🎯 **Responsiveness** |

### **Functional Requirements - Insights Dashboard (M10.2)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-IN-001** | **Usage statistics** | Recipe popularity, ingredient frequency | M10.2 | 🎯 **User insights** |
| **FR-IN-002** | **Cost tracking** | Budget trends and analysis | M10.2 | 🎯 **Financial awareness** |
| **FR-IN-003** | **Visualizations** | Charts and graphs for trends | M10.2 | 🎯 **Data clarity** |

### **Functional Requirements - Recommendations (M10.3)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-RE-001** | **Recipe suggestions** | Smart recommendations based on history | M10.3 | 🎯 **Discovery** |
| **FR-RE-002** | **Seasonal highlights** | Ingredient seasonality awareness | M10.3 | 🎯 **Freshness** |
| **FR-RE-003** | **Budget optimization** | Cost-saving tips and recommendations | M10.3 | 🎯 **Value** |

### **Functional Requirements - Export & Sharing (M10.4)**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-EX-001** | **Data export** | Export capabilities for analytics data | M10.4 | 🎯 **Data portability** |
| **FR-EX-002** | **Report generation** | Formatted reports for sharing | M10.4 | 🎯 **Sharing** |

### **Non-Functional Requirements - M10**

| ID | Requirement | Target | Milestone | Value |
|----|-------------|--------|-----------|-------|
| **NFR-AN-001** | **Dashboard load time** | < 1s for analytics display | M10.2 | 🎯 **User experience** |
| **NFR-AN-002** | **Query performance** | < 0.5s for data retrieval | M10.1 | 🎯 **Snappy** |
| **NFR-AN-003** | **Data accuracy** | 100% accurate based on Core Data | M10 All | 🎯 **Trust** |

**M10 Summary (Planned)**: 12 requirements including analytics infrastructure (2), insights dashboard (3), recommendations (3), export/sharing (2), and non-functional requirements (3). Leverages clean ingredient data from M8 and optimized architecture from M9 to provide data-driven insights.

---

## 🔮 **M11-M13: ADVANCED INTELLIGENCE PLATFORM - PLANNED**

### **M11: Health & Nutrition Integration** (10-15h core)

#### **Functional Requirements - Core Health Features**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-HN-001** | **Apple Health integration** | HealthKit connection | M11.1-11.4 | 🎯 **Health awareness** |
| **FR-HN-002** | **Nutritional database** | USDA nutrient data | M11.1-11.4 | 🎯 **Nutrition facts** |
| **FR-HN-003** | **Dietary goal tracking** | Custom nutrition targets | M11.1-11.4 | 🎯 **Goal management** |
| **FR-HN-004** | **Allergen support** | Dietary restriction filtering | M11.1-11.4 | 🎯 **Safety** |

_Note: ML-Powered Parsing previously listed as M9.5 has been moved to M8.4 (Optional ML Enhancement)_

**M11 Summary (Planned)**: 4 requirements for core health features. Leverages clean ingredient data from M8 parsing improvements for accurate nutritional analysis.

### **M12: Budget Intelligence** (10-15 hours)

| ID | Requirement | Milestone | Value |
|----|-------------|-----------|-------|
| **FR-BD-001** | **Price tracking** | M12 | 🎯 **Cost awareness** |
| **FR-BD-002** | **Budget planning** | M12 | 🎯 **Financial control** |
| **FR-BD-003** | **Cost optimization** | M12 | 🎯 **Savings** |
| **FR-BD-004** | **Store comparison** | M12 | 🎯 **Best value** |

### **M13: AI-Powered Shopping Assistant** (10-15 hours)

| ID | Requirement | Milestone | Value |
|----|-------------|-----------|-------|
| **FR-AI-001** | **Natural language meal planning** | M13 | 🎯 **Conversational UX** |
| **FR-AI-002** | **Smart recipe discovery** | M13 | 🎯 **Personalization** |
| **FR-AI-003** | **Automated list generation** | M13 | 🎯 **Convenience** |
| **FR-AI-004** | **Learning preferences** | M13 | 🎯 **Adaptive** |

### **M14: Advanced Collaboration** (10-15 hours)

| ID | Requirement | Milestone | Value |
|----|-------------|-----------|-------|
| **FR-AC-001** | **Real-time shopping mode** | M14 | 🎯 **Live coordination** |
| **FR-AC-002** | **Task delegation** | M14 | 🎯 **Family workflow** |
| **FR-AC-003** | **Shopping analytics** | M14 | 🎯 **Household insights** |

---

## 📊 **REQUIREMENTS SUMMARY**

### **By Status**

| Status | M1 | M2 | M3 | M4 | M5.0 | M7 | M8 | M9 (Core) | M9.5 (Opt) | Total |
|--------|----|----|----|----|------|----|----|-----------|------------|-------|
| ✅ Complete | 19 | 37 | 33 | 19 | 14 | 22 | 0 | 0 | 0 | **144** |
| 🔄 In Progress | 0 | 0 | 0 | 0 | 0 | 30 | 0 | 0 | 0 | **30** |
| ⏳ Planned | 0 | 0 | 0 | 0 | 0 | 0 | 24 | 4 | 8 | **36** |
| **Total** | **19** | **37** | **33** | **19** | **14** | **52** | **24** | **4** | **8** | **210** |

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
| **Parsing Resilience** | **6** | ⏳ **Planned (M7.5)** ← NEW |
| **Parsing Improvements** | **10** | ⏳ **Planned (M8.0)** ← NEW |
| **ML Parsing (Optional)** | **8** | ⏳ **Planned (M9.5)** ← NEW |
| Analytics & Insights | 7 | ⏳ Planned (M8.1-M8.4) |
| Health & Nutrition | 4 | ⏳ Planned (M9.1-M9.4) |
| Budget Intelligence | 4 | ⏳ Planned (M10) |
| AI Assistant | 4 | ⏳ Planned (M11) |
| Advanced Collaboration | 3 | ⏳ Planned (M12) |
| **Complete** | **144** | **69% (144/210)** |
| **In Progress** | **30** | **14% (30/210)** |
| **Planned (Mandatory)** | **28** | **13% (28/210)** |
| **Planned (Optional)** | **8** | **4% (8/210)** |

### **Performance Requirements Status**

| Requirement | Target | Actual | Status |
|-------------|--------|--------|--------|
| Query performance | < 0.1s | < 0.1s | ✅ Met |
| Search performance | < 0.2s | < 0.15s | ✅ Exceeded |
| Autocomplete | < 0.1s | < 0.08s | ✅ Exceeded |
| **Parsing (M3 baseline)** | **< 0.05s** | **< 0.03s** | ✅ **Exceeded** |
| **Parsing accuracy (M3)** | **> 95%** | **~95%** | ✅ **Met** |
| **Parsing accuracy (M8.0 target)** | **≥ 98%** | **TBD** | ⏳ **Planned** |
| **Parsing accuracy (M9.5 target)** | **≥ 99.5%** | **TBD** | ⏳ **Optional** |
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

**Strategic Validation**: Core platform (M1-M5.0) complete with 122 requirements. M7 adds CloudKit sync and collaboration (52 requirements: 22 complete, 30 in progress). M8-M9 build parsing intelligence (18 mandatory + 8 optional). Complete platform: 210 total requirements (144 complete, 30 in progress, 36 planned).

**Last Updated**: January 4, 2026  
**Version**: 4.6  
**Next Update**: After M7.2.2 Member Invitation Testing  
**Current Focus**: M7.2.2 🚀 - Member Invitation & Acceptance Testing (2-3 hours)
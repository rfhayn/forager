# Forager - Project Index

**Last Updated**: January 4, 2026  
**Purpose**: Central navigation hub for all project documentation  
**Current Milestone**: M7 - CloudKit Sync, Household Sharing & External TestFlight  
**Current Phase**: M7.2.3 ✅ COMPLETE, M7.2.2 🚀 READY  
**Next Priority**: M7.2.2 - Member Invitation & Acceptance Testing (2-3 hours)

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
  - [learning-notes/29-m7.2.3-phase-2.5-manual-core-data-files.md](learning-notes/29-m7.2.3-phase-2.5-manual-core-data-files.md) - Complete debugging journey
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
- **Total Development Time**: ~113 hours (M1-M7.1: ~102h + M7.2.1: 1.25h + CloudKit: 4h + M7.2.3: 6.5h)
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
- **M7.2.2**: Member Invitation & Acceptance Testing (2-3 hours) 🚀 READY
  - Code implemented from previous session (branch: `feature/M7.2.2-member-invitation`)
  - Requires 2 physical iPhones with DIFFERENT iCloud accounts
  - Test household invitation flow end-to-end (send/receive/accept)
  - Validate bi-directional sync between household members
  - Verify members list shows both users correctly
  - See next-prompt.md for detailed testing guide

### **Technology Stack**
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (iOS 18.5+)
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

### **Immediate Priority** (M7.2.2 - 2-3 hours) 🚀 READY
Member Invitation & Acceptance Testing:
1. **Prerequisites**: 2 physical iPhones with different iCloud accounts
2. **Test Invitation**: Send invite from Device A to Device B
3. **Test Acceptance**: Accept invite on Device B
4. **Verify Sharing**: Confirm both devices see shared household data
5. **Test Members View**: Verify household members list shows both users

**Required Equipment**:
- iPhone A: Owner's device (already has household)
- iPhone B: Member's device (different iCloud account)
- Both devices on same iOS version (18.5+)
- Both devices signed into iCloud

### **After M7.2.2**
- **M7.2.3 Remaining Work**: Phases 5-6 if needed (repository hardening, multi-device validation)
- **M7.3**: Conflict Resolution (4-6h)
- **M7.4**: Sync UI & Polish (3-4h)
- **M7.5**: External TestFlight (2-3h)

### **M7 Remaining Milestones**
- **M7.2.2**: Multi-User Collaboration (2-3h) - 🚀 ACTIVE (testing phase)
- **M7.3**: Conflict Resolution (4-6h)
- **M7.4**: Sync UI & Polish (3-4h)
- **M7.5**: External TestFlight (2-3h)

---

## 🚨 **CRITICAL REMINDERS**

1. **Session Startup**: Complete [session-startup-checklist.md](session-startup-checklist.md) EVERY session (8 items!)
2. **Naming Standards**: Always use M#.#.# format (enforced in [project-naming-standards.md](project-naming-standards.md))
3. **Documentation Updates**: Update [current-story.md](current-story.md) after EVERY session
4. **Learning Notes**: Create comprehensive notes after phase completion
5. **Git Workflow**: Feature branches with frequent commits (15-30 min), squash merge to main
6. **Zero Technical Debt**: Maintain quality standards throughout
7. **Performance Targets**: <0.5s for operations, <5s for CloudKit sync
8. **Manual Core Data**: Requires BOTH +CoreDataClass AND +CoreDataProperties files

---

## 🗺️ **COMPLETE MILESTONE ROADMAP**

### **✅ Completed Milestones** (M1-M5.0, M7.0-M7.2.3: ~119.5 hours)

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

### **🚀 In Progress** (M7.2.2: 2-3 hours)

**M7.2.2: Member Invitation & Acceptance** (2-3 hours) - 🚀 READY
- Code complete, awaiting 2 physical iPhones for testing
- Household invitation flow
- CKShare acceptance
- Bi-directional sync validation
- Members list verification

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
- **M8.1**: Parsing Resilience & Telemetry (3-4h) - Foundation
  - Yellow badge for low confidence, EditIngredientSheet, telemetry logging
  - **Source**: [M7.5 Parsing Resilience PRD](prds/parsing/M7.5-parsing-resilience-polish-prd.md)
- **M8.2**: Telemetry Analysis & Strategy (2h) - Insights
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

---

### **Milestone Timeline Summary**

**Core Platform (M1-M10)**: ~220-270 hours estimated (core) or ~235-290 hours (with M8.4 ML)
- **Completed (M1-M7 partial)**: ~119.5 hours ✅
- **Remaining (M6-M10)**: ~200-253 hours (core) or ~215-273 hours (with M8.4 ML)

**Advanced Intelligence Platform (M11-M14)**: 40-60 hours total
- Dependencies: M1-M10 complete

**Total Project Estimate**: ~260-330 hours (core) or ~275-350 hours (with M8.4 ML)

---

## 📚 **LEARNING RESOURCES**

### **Internal Knowledge**
- [learning-notes/](learning-notes/) - 29+ implementation journey notes
- [architecture/](architecture/) - 8+ architecture decision records
- [prds/](prds/) - 10+ product requirement documents
- [git-workflow-for-milestones.md](git-workflow-for-milestones.md) - Complete git workflow guide

### **External Resources**
- [NSPersistentCloudKitContainer Documentation](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect](https://appstoreconnect.apple.com)

---

**Version**: 8.1
**Last Updated**: January 4, 2026
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

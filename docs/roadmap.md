# Forager - Development Roadmap

**Last Updated**: December 24, 2025  
**Current Phase**: M5.0 COMPLETE ✅ | M7.1 COMPLETE ✅ | M7 CloudKit Debugging COMPLETE ✅ | Strategic Decision Point  
**Status**: All M1-M5.0 milestones complete, M7.1 CloudKit foundation operational, M7 multi-device sync working perfectly, deciding next steps (M7.2.2 vs M6 vs M8)

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
- **Data-driven ingredient parsing improvements** (M7.5, M8.0, M9.5)

---

_[Continue with all existing content through the completed milestones section - this remains unchanged]_

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
- **M7.5: Parsing Resilience & Polish (NEW)** - 3-4 hours
  - Low-confidence detection UI
  - "Edit Ingredient" structured form
  - Telemetry logging for future improvements
  - Graceful degradation before external beta
- **M7.6-7.7: External TestFlight & Public Beta** - 5-9 hours
  - App Review submission
  - Public beta landing page
  - LinkedIn showcase

**Timeline**: 30-41 hours base, 35-46 hours with buffer (3-4 weeks including Apple Review)

**⚠️ CRITICAL**: M7.0 App Store Prerequisites are MANDATORY before external TestFlight submission

_[Continue with existing roadmap structure but skip to the detailed M7 section]_

---

### **🔄 M7: CloudKit Sync, Household Sharing & External TestFlight - IN PROGRESS** 🚀

**Status**: 🔄 In Progress - M7.1 Complete ✅, Multi-Device Sync Working ✅  
**Estimated Time**: 30-41 hours base, 35-46 hours with buffer  
**Actual Progress**: 13.5 hours (M7.0: 3h, M7.1: 6.5h, CloudKit Debugging: 4h)  
**Dependencies**: M5.0 complete ✅  
**PRD**: docs/prds/milestone-7-cloudkit-sync-external-testflight.md (v2.0 - Shared Zone Architecture)

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
- ✅ **Documentation**: [27-m7-cloudkit-sync-debugging.md](m7-docs/27-m7-cloudkit-sync-debugging.md)

**M7.2: Shared Household Zone (8-10 hours) - PAUSED** ⏸️
- ✅ **M7.2.1**: Household Setup & Shared Zone (1.25h) - COMPLETE (100% accuracy)
- ⏳ **M7.2.2**: Member Invitation & Acceptance (2-3h) - READY (or defer)
- ⏳ **M7.2.3**: Sync Validation & Testing (1-2h) - MOSTLY DONE (multi-device validated)
- ⏳ **M7.2.4**: Household Management (1-2h) - READY

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

**M7.3: Conflict Resolution & Error Handling (4-6 hours)**
- **M7.3.1**: Conflict Resolution Policies (2-3h)
- **M7.3.2**: Error Handling & Recovery (2-3h)

**M7.4: Sync UI & Polish (3-4 hours)**
- **M7.4.1**: Sync Status Indicators (2-3h)
- **M7.4.2**: CloudKit Settings & Diagnostics (1h)

**M7.5: Parsing Resilience & Polish (3-4 hours) - 💡 NEW**
- **M7.5.1**: Low-Confidence UI Detection (1.5h)
  - Yellow indicator badge for confidence < 0.5
  - "Edit Ingredient" button integration
- **M7.5.2**: Structured Edit Form (1.5h)
  - Professional edit sheet UI
  - Pre-filled with parsed values
  - Manual correction workflow
- **M7.5.3**: Telemetry Logging (1h)
  - ParsingTelemetryService implementation
  - Log failures for M8.0 analysis
  - Privacy-safe local storage

**Why M7.5?** Adds graceful degradation for ingredient parsing edge cases before external beta launch. Prevents embarrassing failures like "2-3 cloves garlic, minced" and starts collecting real-world failure data for M8.0 improvements.

**PRD**: [docs/prds/parsing/M7.5-parsing-resilience-polish-prd.md](prds/parsing/M7.5-parsing-resilience-polish-prd.md)

**M7.6: External TestFlight Deployment (2-3 hours)** ← Renumbered from M7.5
- **M7.6.1**: External Testing Group Setup (30min)
- **M7.6.2**: App Review Submission (1-2h)
- **M7.6.3**: App Review Preparation (1h)
- **M7.6.4**: Public Link Generation (30min)

**M7.7: Public Beta Program (2-3 hours)** ← Renumbered from M7.6
- **M7.7.1**: Beta Landing Page (1-2h)
- **M7.7.2**: LinkedIn Showcase (1h)

**Success Criteria:**
- [ ] Privacy policy published and accessible (M7.0)
- [ ] All 8 entities sync via CloudKit (M7.1)
- [ ] Multi-device sync < 5s latency (M7.1.3)
- [ ] CKShare working for lists/recipes/meal plans (M7.2)
- [ ] Conflict resolution 100% reliable (M7.3)
- [ ] Sync status UI clear and informative (M7.4)
- [ ] **Low-confidence ingredients show review indicator (M7.5)** ← NEW
- [ ] **Edit ingredient flow operational (M7.5)** ← NEW
- [ ] **Parsing failures logged to telemetry (M7.5)** ← NEW
- [ ] External TestFlight approved by Apple (M7.6)
- [ ] Public beta link generated and working (M7.6)
- [ ] Beta landing page published (M7.7)
- [ ] 10+ external beta testers providing feedback

**Requirements**: 39 total
- ✅ **Complete (9)**: 4 App Store prerequisites + 5 CloudKit sync foundation + 4 debugging fixes
- ⏳ **Remaining (30)**: 5 household collaboration + 5 conflict resolution + 5 sync UI + 6 parsing resilience + 5 external TestFlight + 4 non-functional

---

### **⏳ M6: Testing Foundation & AI Augmentation - PLANNED**

**Status**: ⏳ Planned  
**Estimated Time**: 12-18 hours  
**Dependencies**: M5 complete (TestFlight validated, CloudKit tested)

**Phase 1: Human Test Baseline** (5-7 hours)
- **M6.1.1: Core Data & Model Tests** (2-3h)
- **M6.1.2: Service Layer Tests** (2-3h)
- **M6.1.3: Critical Workflow Tests** (1-2h)
- **Target**: 50%+ coverage on critical services

**Phase 2: AI Test Review Setup** (3-4 hours)
- **M6.2.1: CLI Refinement** (1-1.5h)
- **M6.2.2**: GitHub Actions Workflow (1.5-2h)
- **M6.2.3**: Documentation & Integration (0.5-1h)
- **Target**: ≥90% PRs receive suggestions, ≥75% found useful

**Phase 3: Testing Standards & Infrastructure** (2-3 hours)
- **M6.3.1**: Test Architecture Standards (1-1.5h)
- **M6.3.2**: Coverage Monitoring (0.5-1h)
- **M6.3.3**: CI/CD Test Foundation (0.5-1h)

**Phase 4: Phase 3 Prep (Optional)** (2-4 hours)
- **M6.4.1**: Domain Model Documentation (1-1.5h)
- **M6.4.2**: Architecture Diagrams (1-1.5h)
- **M6.4.3**: Gap Detection Experiments (1-2h)
- **Note**: Can be deferred to M6.5 or later if needed

**Success Criteria:**
- [ ] 50%+ service layer coverage achieved
- [ ] All Core Data entities have basic tests
- [ ] 5+ critical workflows validated
- [ ] AI reviewer operational (≥90% PR activation)
- [ ] ≥75% of AI suggestions found useful
- [ ] Testing standards documented
- [ ] CI/CD running tests on every commit
- [ ] Zero flaky tests, < 30s test suite

---

### **⏳ M8: Analytics, Insights & Parsing Improvements - PLANNED**

**Status**: ⏳ Planned  
**Estimated Time**: 16-24 hours (+8-12h for M8.0)  
**Dependencies**: M7 complete (telemetry data from external beta)

**M8.0: Parsing Improvements Foundation (8-12 hours) - 💡 NEW**
- **M8.0.1**: Telemetry Analysis (1h)
  - Parse M7 telemetry file
  - Identify top 10 failure patterns
  - Create analysis report
- **M8.0.2**: Pattern Prioritization (1h)
  - Decide which patterns to target
  - ROI analysis per pattern
- **M8.0.3**: Parser Architecture Refactor (1.5h)
  - Create hybrid parser abstraction
  - Fast path (regex) + Smart path (NLP)
- **M8.0.4**: Apple NLP Integration (2-3h)
  - Integrate Natural Language framework
  - Handle complex patterns
- **M8.0.5**: Pattern-Specific Handlers (1-1.5h)
  - Range patterns: "2-3 cloves" → 2.5 cloves
  - Parenthetical units: "1 can (14.5 oz)"
  - Qualifier extraction: "garlic, minced"
- **M8.0.6**: Smart Pre-fill Enhancement (1h)
  - Use NLP for better edit sheet defaults
- **M8.0.7**: Telemetry Enhancement (1h)
  - Track which parser used
  - Performance metrics
- **M8.0.8-10**: Integration Testing (2-4h)
  - Regression testing
  - Improvement validation
  - Performance benchmarking

**Why M8.0?** Data-driven approach using real M7 telemetry to prioritize parsing improvements. Achieves 98%+ accuracy (from 95%) by targeting actual user pain points, not speculation.

**PRD**: [docs/prds/parsing/M8.0-parsing-improvements-foundation-prd.md](prds/parsing/M8.0-parsing-improvements-foundation-prd.md)

**M8.1: Analytics Infrastructure** (2-3 hours)
- Analytics service architecture
- Data aggregation and caching
- Query optimization for trends

**M8.2: Insights Dashboard** (3-4 hours)
- Usage statistics visualization
- Cost tracking and trends
- Recipe popularity metrics
- Ingredient frequency analysis

**M8.3: Recommendations** (2-3 hours)
- Smart recipe suggestions
- Seasonal ingredient highlights
- Budget optimization tips
- Meal plan optimization

**M8.4: Export & Sharing** (1-2 hours)
- Data export capabilities
- Report generation
- Share insights with family

**Success Criteria:**
- [ ] **Parsing accuracy ≥ 98% (from 95%)** ← NEW
- [ ] **Low-confidence rate ≤ 2% (from 5%)** ← NEW
- [ ] **Hybrid NLP system operational** ← NEW
- [ ] **Top 5 failure patterns handled** ← NEW
- [ ] Dashboard loads < 1s
- [ ] Meaningful insights generated
- [ ] Trend analysis over time
- [ ] Actionable recommendations
- [ ] Export functionality working
- [ ] Leverages M3 structured quantities

---

### **⏳ M9-M12: Advanced Intelligence Platform - PLANNED**

**Status**: ⏳ Future Development  
**Estimated Time**: 40-60 hours total (+ 15-20h optional for M9.5)  
**Dependencies**: M1-M8 complete

**M9: Health & Nutrition Integration** (10-15 hours core)
- **M9.1-9.4**: Core Health Features (10-15h)
  - Apple Health integration
  - Nutritional database
  - Dietary goal tracking
  - Health-aware recommendations
  - Allergen and dietary restriction support

**M9.5: ML-Powered Parsing (15-20 hours) - 💡 NEW, OPTIONAL**
- **M9.5.1-4**: Training Dataset Creation (4-5h)
  - Collect 100+ user corrections from M7-M8
  - Label and validate training data
  - Split into train/validate/test sets
  - Create ML format conversion
- **M9.5.5-8**: Model Training (6-8h)
  - Create ML project setup
  - Train custom text classifier
  - Hyperparameter tuning
  - Model export and validation
- **M9.5.9-10**: On-Device Inference (3-4h)
  - MLIngredientParser implementation
  - Hybrid system integration
- **M9.5.11-12**: Continuous Learning (2-3h)
  - Ongoing telemetry collection
  - Model retraining pipeline

**Why M9.5?** Optional enhancement to achieve industry-leading 99.5%+ accuracy using custom CoreML model trained on YOUR users' actual corrections. Only pursue if M8.0 shows room for improvement and you want best-in-class parsing.

**Decision Point**: Evaluate after M8.0 complete. If M8.0 achieves 98.5%+ accuracy, M9.5 may not be worth the 15-20h investment (diminishing returns).

**PRD**: [docs/prds/parsing/M9.5-ml-powered-parsing-prd.md](prds/parsing/M9.5-ml-powered-parsing-prd.md)

**M10: Budget Intelligence** (10-15 hours)
- Price tracking and history
- Budget planning tools
- Cost optimization suggestions
- Store price comparison
- Deal and coupon integration

**M11: AI-Powered Shopping Assistant** (10-15 hours)
- Natural language meal planning
- Smart recipe discovery
- Automated list generation
- Contextual recommendations
- Learning user preferences

**M12: Advanced Collaboration** (10-15 hours)
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
- **M7.1**: 6.5 hours (estimated 6-8h) - ✅ 93% accuracy
- **M7.2.1**: 1.25 hours (estimated 1.25h) - ✅ 100% accuracy
- **M7 CloudKit Debugging**: 4 hours (unplanned but essential) - ✅ Perfect sync achieved
- **Total Completed**: ~107.25 hours

### **Planned Core Platform:**
- **M7**: 30-41 hours base, 35-46 hours with buffer (+3-4h for M7.5)
  - M7.0: 2-3 hours (App Store prerequisites - MANDATORY)
  - M7.1-7.4: 21-28 hours (CloudKit sync & polish)
  - M7.5: 3-4 hours (Parsing resilience - NEW)
  - M7.6-7.7: 4-6 hours (External beta)
- **M6**: 12-18 hours (comprehensive testing & AI augmentation)
- **M8**: 16-24 hours (+8-12h for M8.0 parsing improvements)

**Total Core Platform (M1-M8)**: ~156-181 hours estimated (+11-16h from original 145-165h)

**If Including M9.5 ML (Optional)**:
- **M9**: 25-35 hours (10-15h core + 15-20h ML optional)

### **Planning Accuracy:**
- **Phase-level estimates**: Consistently accurate within ±15 minutes
- **Milestone estimates**: Excellent accuracy for M1-M5.0 (88-100%)
- **Risk mitigation**: Proactive problem identification preventing scope creep
- **Overall Average**: 89% accuracy across completed work (excluding unplanned debugging sessions)

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
- **Data-driven improvements**: M7.5→M8.0→M9.5 evolution based on real telemetry

---

## 🎯 **SUCCESS CRITERIA BY MILESTONE**

_[All previous success criteria remain unchanged - these are already in the file]_

### **M7: CloudKit Sync & External TestFlight**
- [✅] Privacy policy published (M7.0)
- [✅] All 8 entities sync via CloudKit (M7.1)
- [✅] Multi-device sync < 5s latency (M7 Debugging)
- [✅] CloudKit environment configured (Development)
- [✅] CloudKit import observer prevents race conditions
- [✅] Serial queue synchronization working
- [✅] Clean user onboarding (no sample data)
- [ ] CKShare working for collaboration (M7.2) - OPTIONAL
- [ ] Conflict resolution reliable (M7.3)
- [ ] Sync status UI informative (M7.4)
- [ ] **Low-confidence parsing UI operational (M7.5)** ← NEW
- [ ] **Telemetry collection functional (M7.5)** ← NEW
- [ ] External TestFlight approved (M7.6)
- [ ] Public beta launched (M7.7)

### **M8: Analytics, Insights & Parsing**
- [ ] **Parsing accuracy ≥ 98%** ← NEW
- [ ] **Low-confidence rate ≤ 2%** ← NEW
- [ ] **Hybrid NLP parser operational** ← NEW
- [ ] Dashboard loads < 1s
- [ ] Meaningful insights generated
- [ ] Trend analysis functional
- [ ] Recommendations actionable
- [ ] Export capabilities working

---

## 🔍 **RISK MANAGEMENT**

_[Existing risks remain, adding new ones]_

### **M7.5: Parsing Resilience**
- **Risk**: Time overrun beyond 4 hours
- **Mitigation**: Simple UI, pre-built telemetry patterns
- **Risk**: Users ignore "Review" indicators
- **Mitigation**: Non-blocking design, telemetry shows usage

### **M8.0: Parsing Improvements**
- **Risk**: Apple NLP not accurate enough for complex patterns
- **Mitigation**: Pattern-specific handlers as fallback
- **Risk**: Performance degradation from NLP
- **Mitigation**: Fast path (regex) for 80% of inputs unchanged
- **Risk**: Insufficient telemetry data from M7
- **Mitigation**: Requires 2+ weeks of M7 external beta data before starting

### **M9.5: ML-Powered Parsing (Optional)**
- **Risk**: Insufficient training data (<100 corrections)
- **Mitigation**: Don't pursue until data threshold met
- **Risk**: Diminishing returns (98% → 99.5%)
- **Mitigation**: Make this phase truly optional, evaluate ROI after M8.0

---

## 📚 **RELATED DOCUMENTATION**

### **Current Milestone:**
- [M7 PRD](prds/milestone-7-cloudkit-sync-external-testflight.md) - CloudKit sync & external TestFlight
- **[M7.5 PRD](prds/parsing/M7.5-parsing-resilience-polish-prd.md)** - Parsing resilience ← NEW
- [Current Story](current-story.md) - M5.0 complete, M7 ready to start
- [Requirements Document](requirements.md) - 151+ total requirements

### **Parsing Enhancement PRDs:**
- **[M7.5: Parsing Resilience & Polish](prds/parsing/M7.5-parsing-resilience-polish-prd.md)** ← NEW
- **[M8.0: Parsing Improvements Foundation](prds/parsing/M8.0-parsing-improvements-foundation-prd.md)** ← NEW
- **[M9.5: ML-Powered Parsing (Optional)](prds/parsing/M9.5-ml-powered-parsing-prd.md)** ← NEW

### **Completed Milestones:**
- [M1 Learning Notes](learning-notes/01-10-milestone-1-phases.md)
- [M2 Learning Notes](learning-notes/11-m2.1-recipe-architecture.md through 13)
- [M3-M4 Learning Notes](learning-notes/) - Various phases
- [M5.0 Learning Notes](learning-notes/21-m5.0-forager-renaming-testflight.md)

### **Architecture & Requirements:**
- [Requirements Document](requirements.md)
- [Project Index](project-index.md)
- [Architecture Decision Records](architecture/)
- [Product Requirements Documents](prds/)

---

## 🎉 **ACHIEVEMENTS TO DATE**

_[All existing achievements remain - content already in file]_

### **Strategic Evolution:**
- **Parsing Foundation (M3)**: 95%+ accuracy with regex-based parser ✅
- **Graceful Degradation (M7.5)**: User correction UI + telemetry ⏳ PLANNED
- **Data-Driven Improvement (M8.0)**: Hybrid NLP system based on real failures ⏳ PLANNED
- **ML Excellence (M9.5)**: Custom CoreML model (optional) ⏳ PLANNED

---

**Next Action**: Strategic Decision - Continue M7.2.2 (Household Sharing) vs M6 (Testing) vs M8 (Analytics)

**Status**: M1-M5.0 complete with ~92.75 hours. M7.0 + M7.1 + CloudKit Debugging complete (13.5h). **Multi-device CloudKit sync working perfectly!** ✅ Perfect bi-directional sync across 2 physical devices with <5s latency, zero duplicates, zero data loss. Now deciding next milestone: finish household sharing (M7.2.2, 4-7h) OR pivot to testing (M6, 12-15h) OR analytics (M8, 16-24h).

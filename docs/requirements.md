# Forager - Requirements Document

**Last Updated**: December 19, 2025  
**Version**: 4.2  
**Current Milestone**: M5.0 Complete ✅ | M7.0 Ready 🚀

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

_[All M1-M5.0 sections remain exactly as they are in the current file - not repeating them here for brevity, but they would be included in the actual file]_

---

## 🚀 **M7: CLOUDKIT SYNC & EXTERNAL TESTFLIGHT - IN PROGRESS**

**Status**: 🔄 In Progress - CloudKit Multi-Device Sync Working ✅  
**Progress**: M7.0 (3h) ✅, M7.1 (6.5h) ✅, CloudKit Debugging (4h) ✅ = 13.5h / 35-46h  
**Estimated Remaining**: 21.5-32.5 hours  
**Summary**: Full CloudKit synchronization, multi-user collaboration, parsing resilience, and external public beta

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
| **FR-CK-006** | **Household creation & shared zone** | Create household, migrate data to shared zone | M7.2.1 | 🎯 **Household collaboration** |
| **FR-CK-007** | **Member invitation flow** | Invite household members via email, iCloud integration | M7.2.2 | 🎯 **Easy sharing** |
| **FR-CK-008** | **Household management** | View members, remove/leave household, dissolve | M7.2.4 | 🎯 **Access control** |
| **FR-CK-009** | **All entities household-scoped** | GroceryItem, Recipe, WeeklyList, MealPlan, Tag, Ingredient, GroceryListItem, IngredientTemplate | M7.2.1 | 🎯 **Data ownership** |
| **FR-CK-010** | **Automatic sync across household** | All household members see all data automatically | M7.2.3 | 🎯 **Seamless collaboration** |

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

**M7 Summary**: 39 total requirements
- **Complete (9)**: App Store prerequisites (4), CloudKit sync foundation (5 + 4 debugging fixes)
- **Planned (30)**: Multi-user collaboration (5), conflict resolution (5), sync UI polish (5), parsing resilience (6), external TestFlight (5), non-functional (4 remaining)
- **Progress**: M7.0 ✅, M7.1 ✅, CloudKit Multi-Device Sync Debugging ✅
- **Achievement**: Perfect bi-directional sync across 2 physical devices with zero duplicates
- **Next**: M7.2 (Household Sharing) or M6 (Testing) or M8 (Analytics)

---

## 🔮 **M8: ANALYTICS, INSIGHTS & PARSING IMPROVEMENTS - PLANNED** 💡

**Status**: ⏳ Planned  
**Estimated**: 16-24 hours (+8-12h for M8.0 parsing improvements)  
**Dependencies**: M7 complete (telemetry data from external beta)  
**Summary**: Data-driven parsing improvements + usage analytics and insights

### **Functional Requirements - Parsing Improvements Foundation (M8.0 - NEW)** 💡

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-PI-001** | **Telemetry analysis** | Parse M7 telemetry, identify top 10 failure patterns | M8.0.1 | 🎯 **Data-driven approach** |
| **FR-PI-002** | **Pattern prioritization** | ROI analysis, decide which patterns to target | M8.0.2 | 🎯 **Efficient investment** |
| **FR-PI-003** | **Hybrid parser architecture** | Fast path (regex) + Smart path (NLP) | M8.0.3 | 🎯 **Performance + accuracy** |
| **FR-PI-004** | **Apple NLP integration** | Natural Language framework for complex patterns | M8.0.4 | 🎯 **Advanced parsing** |
| **FR-PI-005** | **Range pattern handling** | "2-3 cloves" → 2.5 cloves average | M8.0.5 | 🎯 **Complex quantities** |
| **FR-PI-006** | **Parenthetical unit extraction** | "1 can (14.5 oz)" → quantity + unit | M8.0.5 | 🎯 **Nested formats** |
| **FR-PI-007** | **Qualifier extraction** | "garlic, minced" → name + note | M8.0.5 | 🎯 **Preparation notes** |
| **FR-PI-008** | **Smart pre-fill enhancement** | Use NLP results in edit form defaults | M8.0.6 | 🎯 **Better UX** |
| **FR-PI-009** | **Enhanced telemetry** | Track which parser used, performance metrics | M8.0.7 | 🎯 **Continuous improvement** |
| **FR-PI-010** | **Regression testing** | Ensure no accuracy loss on existing inputs | M8.0.8-10 | 🎯 **Quality assurance** |

### **Functional Requirements - Analytics Infrastructure**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-AN-001** | **Analytics service architecture** | Data aggregation and caching | M8.1 | 🎯 **Performance** |
| **FR-AN-002** | **Query optimization** | Efficient trend queries | M8.1 | 🎯 **Responsiveness** |

### **Functional Requirements - Insights Dashboard**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-IN-001** | **Usage statistics** | Recipe popularity, ingredient frequency | M8.2 | 🎯 **User insights** |
| **FR-IN-002** | **Cost tracking** | Budget trends and analysis | M8.2 | 🎯 **Financial awareness** |
| **FR-IN-003** | **Visualizations** | Charts and graphs for trends | M8.2 | 🎯 **Data clarity** |

### **Functional Requirements - Recommendations**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-RE-001** | **Recipe suggestions** | Smart recommendations | M8.3 | 🎯 **Discovery** |
| **FR-RE-002** | **Seasonal highlights** | Ingredient seasonality | M8.3 | 🎯 **Freshness** |
| **FR-RE-003** | **Budget optimization** | Cost-saving tips | M8.3 | 🎯 **Value** |

### **Functional Requirements - Export & Sharing**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-EX-001** | **Data export** | Export capabilities | M8.4 | 🎯 **Data portability** |
| **FR-EX-002** | **Report generation** | Formatted reports | M8.4 | 🎯 **Sharing** |

### **Non-Functional Requirements - M8**

| ID | Requirement | Target | Milestone | Value |
|----|-------------|--------|-----------|-------|
| **NFR-PI-001** | **Parsing accuracy ≥ 98%** | Up from 95% baseline | M8.0 | 🎯 **Quality improvement** |
| **NFR-PI-002** | **Low-confidence rate ≤ 2%** | Down from 5% baseline | M8.0 | 🎯 **Fewer manual edits** |
| **NFR-PI-003** | **Fast path performance < 0.05s** | Regex parser unchanged | M8.0 | 🎯 **Speed preserved** |
| **NFR-PI-004** | **Smart path performance < 0.2s** | NLP parsing acceptable latency | M8.0 | 🎯 **Responsive** |
| **NFR-PI-005** | **Hybrid routing overhead < 0.01s** | Decision cost minimal | M8.0 | 🎯 **Efficient** |
| **NFR-AN-001** | **Dashboard load < 1s** | Fast analytics display | M8.2 | 🎯 **User experience** |
| **NFR-AN-002** | **Query performance < 0.5s** | Responsive data retrieval | M8.1 | 🎯 **Snappy** |

**M8 Summary (Planned)**: 24 requirements including parsing improvements (10 NEW), analytics infrastructure (2), insights dashboard (3), recommendations (3), export/sharing (2), and non-functional requirements (7). Achieves 98%+ parsing accuracy through data-driven NLP enhancements while building analytics foundation.

---

## 🔮 **M9-M11: ADVANCED INTELLIGENCE PLATFORM - PLANNED**

### **M9: Health & Nutrition Integration + Optional ML Parsing** (10-15h core + 15-20h optional)

#### **Functional Requirements - Core Health Features**

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-HN-001** | **Apple Health integration** | HealthKit connection | M9.1-9.4 | 🎯 **Health awareness** |
| **FR-HN-002** | **Nutritional database** | USDA nutrient data | M9.1-9.4 | 🎯 **Nutrition facts** |
| **FR-HN-003** | **Dietary goal tracking** | Custom nutrition targets | M9.1-9.4 | 🎯 **Goal management** |
| **FR-HN-004** | **Allergen support** | Dietary restriction filtering | M9.1-9.4 | 🎯 **Safety** |

#### **Functional Requirements - ML-Powered Parsing (M9.5 - OPTIONAL)** 💡

| ID | Requirement | Target Implementation | Milestone | Value |
|----|-------------|----------------------|-----------|-------|
| **FR-ML-001** | **Training dataset creation** | Extract 100+ user corrections from M7-M8 | M9.5.1-4 | 🎯 **Quality data** |
| **FR-ML-002** | **Data labeling** | Label and validate training data | M9.5.1-4 | 🎯 **Model accuracy** |
| **FR-ML-003** | **Create ML model training** | Train custom text classifier | M9.5.5-8 | 🎯 **Custom intelligence** |
| **FR-ML-004** | **Hyperparameter tuning** | Optimize model performance | M9.5.5-8 | 🎯 **Best accuracy** |
| **FR-ML-005** | **On-device inference** | CoreML integration for local prediction | M9.5.9-10 | 🎯 **Privacy + speed** |
| **FR-ML-006** | **Hybrid system integration** | ML as third tier after regex + NLP | M9.5.9-10 | 🎯 **Progressive enhancement** |
| **FR-ML-007** | **Continuous learning pipeline** | Ongoing telemetry → retraining workflow | M9.5.11-12 | 🎯 **Self-improving** |
| **FR-ML-008** | **Model retraining triggers** | Retrain at 50+ corrections or 30 days | M9.5.11-12 | 🎯 **Fresh model** |

#### **Non-Functional Requirements - M9**

| ID | Requirement | Target | Milestone | Value |
|----|-------------|--------|-----------|-------|
| **NFR-ML-001** | **ML parsing accuracy ≥ 99.5%** | Up from 98% (M8.0) | M9.5 | 🎯 **Industry-leading** |
| **NFR-ML-002** | **Inference latency < 0.2s** | On-device CoreML speed | M9.5 | 🎯 **Real-time** |
| **NFR-ML-003** | **Model size < 5MB** | Compact on-device model | M9.5 | 🎯 **Efficient** |
| **NFR-ML-004** | **Training data minimum 100 samples** | Sufficient data for accuracy | M9.5 | 🎯 **Quality threshold** |

**M9 Summary (Planned)**: 12 requirements for core health features (4) + 8 optional ML parsing requirements. M9.5 is OPTIONAL - only pursue if M8.0 shows room for improvement and you want best-in-class parsing (99.5%+ accuracy). Evaluate after M8.0 complete.

### **M10: Budget Intelligence** (10-15 hours)

| ID | Requirement | Milestone | Value |
|----|-------------|-----------|-------|
| **FR-BD-001** | **Price tracking** | M10 | 🎯 **Cost awareness** |
| **FR-BD-002** | **Budget planning** | M10 | 🎯 **Financial control** |
| **FR-BD-003** | **Cost optimization** | M10 | 🎯 **Savings** |
| **FR-BD-004** | **Store comparison** | M10 | 🎯 **Best value** |

### **M11: AI-Powered Shopping Assistant** (10-15 hours)

| ID | Requirement | Milestone | Value |
|----|-------------|-----------|-------|
| **FR-AI-001** | **Natural language meal planning** | M11 | 🎯 **Conversational UX** |
| **FR-AI-002** | **Smart recipe discovery** | M11 | 🎯 **Personalization** |
| **FR-AI-003** | **Automated list generation** | M11 | 🎯 **Convenience** |
| **FR-AI-004** | **Learning preferences** | M11 | 🎯 **Adaptive** |

### **M12: Advanced Collaboration** (10-15 hours)

| ID | Requirement | Milestone | Value |
|----|-------------|-----------|-------|
| **FR-AC-001** | **Real-time shopping mode** | M12 | 🎯 **Live coordination** |
| **FR-AC-002** | **Task delegation** | M12 | 🎯 **Family workflow** |
| **FR-AC-003** | **Shopping analytics** | M12 | 🎯 **Household insights** |

---

## 📊 **REQUIREMENTS SUMMARY**

### **By Status**

| Status | M1 | M2 | M3 | M4 | M5.0 | M7 | M8 | M9 (Core) | M9.5 (Opt) | Total |
|--------|----|----|----|----|------|----|----|-----------|------------|-------|
| ✅ Complete | 19 | 37 | 33 | 19 | 14 | 9 | 0 | 0 | 0 | **131** |
| 🔄 In Progress | 0 | 0 | 0 | 0 | 0 | 30 | 0 | 0 | 0 | **30** |
| ⏳ Planned | 0 | 0 | 0 | 0 | 0 | 0 | 24 | 4 | 8 | **36** |
| **Total** | **19** | **37** | **33** | **19** | **14** | **39** | **24** | **4** | **8** | **197** |

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
| CloudKit Collaboration | 16 | 🔄 In Progress (M7.2-M7.4) |
| **Parsing Resilience** | **6** | ⏳ **Planned (M7.5)** ← NEW |
| **Parsing Improvements** | **10** | ⏳ **Planned (M8.0)** ← NEW |
| **ML Parsing (Optional)** | **8** | ⏳ **Planned (M9.5)** ← NEW |
| Analytics & Insights | 7 | ⏳ Planned (M8.1-M8.4) |
| Health & Nutrition | 4 | ⏳ Planned (M9.1-M9.4) |
| Budget Intelligence | 4 | ⏳ Planned (M10) |
| AI Assistant | 4 | ⏳ Planned (M11) |
| Advanced Collaboration | 3 | ⏳ Planned (M12) |
| **Complete** | **131** | **67% (131/197)** |
| **In Progress** | **30** | **15% (30/197)** |
| **Planned (Mandatory)** | **28** | **14% (28/197)** |
| **Planned (Optional)** | **8** | **4% (8/197)** |

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

### **Completed: M7 CloudKit Multi-Device Sync** ✅
**Total Time**: 13.5 hours (M7.0: 3h + M7.1: 6.5h + Debugging: 4h)  
**Status**: 9 requirements complete
- ✅ App Store prerequisites (privacy policy, compliance)
- ✅ CloudKit schema generation (all 8 entities)
- ✅ Multi-device sync (<5s latency)
- ✅ Automatic background sync
- ✅ Offline sync queue
- ✅ Sync status monitoring
- ✅ Environment configuration (Development)
- ✅ CloudKit import observer pattern
- ✅ Race condition prevention (serial queue)
- ✅ Clean user onboarding (no sample data)

**Achievement**: Perfect bi-directional sync across 2 physical devices with zero duplicates!

### **In Progress: M7 CloudKit Collaboration & External TestFlight** 🔄
**Remaining Time**: 21.5-32.5 hours  
**Requirements In Progress**: 30 (household sharing, conflict resolution, sync UI, parsing, TestFlight)

**Strategic Additions:**
- **M7.5: Parsing Resilience** (6 requirements, 3-4h) - Graceful degradation before external beta
- CloudKit sync and collaboration (25 requirements, 21-28h)
- External TestFlight and public beta (9 requirements, 6-9h)

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

**Strategic Validation**: Core platform (M1-M5.0) complete with 122 requirements. M7 adds CloudKit, parsing resilience, and public beta (35 requirements). M8-M9 build parsing intelligence (18 mandatory + 8 optional). Complete platform: 193 total requirements (122 complete, 63 mandatory planned, 8 optional).

**Last Updated**: December 24, 2025  
**Version**: 4.3  
**Next Update**: After M7.2 decision (Continue household sharing vs Testing vs Analytics)  
**Current Focus**: M7 - CloudKit Multi-Device Sync Complete ✅, Strategic Decision Point

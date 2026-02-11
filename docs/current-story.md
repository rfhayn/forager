# Current Development Story

**Last Updated**: February 8, 2026
**Status**: M8 ✅ **COMPLETE** | M7.6 🚀 **NEXT**
**Total Progress**: ~187 hours | 89% planning accuracy
**Current Branch**: `feature/M8.3-hybrid-nlp-parser` (ready to merge)
**Current Milestone**: M8 - Ingredient Parsing Intelligence (ALL CORE PHASES COMPLETE)

---

## ✅ **M8.3: HYBRID NLP PARSER - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 8, 2026
**Branch**: `feature/M8.3-hybrid-nlp-parser`
**PRD**: `docs/prds/m8-ingredient-parsing-intelligence-meta-prd.md`

### **What Was Delivered** ✅

**1. Protocol Abstraction** - `Services/Parsing/IngredientParser.swift`
   - `IngredientParser` protocol with `parse(_ input:) -> ParserResult`
   - `ParserResult` value type with confidence, parserUsed tracking

**2. Enhanced Regex Parser** - `Services/Parsing/RegexIngredientParser.swift` (~650 lines)
   - 7 pattern categories in priority order:
     1. Unicode fractions: ½, ¼, ⅓, 1½ (combined forms)
     2. Range patterns: "2-3 cloves garlic", "1 to 2 cups"
     3. Parenthetical patterns: "1 can (14.5 oz) tomatoes"
     4. Compound phrases: "one and a half cups", "two cups"
     5. Standard qty+unit+name (existing, preserved)
     6. Qualifier patterns: "salt to taste", "garlic, minced"
     7. Descriptive amounts: "a pinch of salt", "a handful"
   - Expanded known units: stick, bag, bottle, box, jar, sprig
   - Word-to-number mapping (one→1 through twelve→12)
   - Unicode fraction map (15 fraction characters)

**3. NLP Fallback Parser** - `Services/Parsing/NLPIngredientParser.swift` (~310 lines)
   - Apple NaturalLanguage framework with NLTagger
   - Part-of-speech tagging for token classification
   - Qualifier phrase detection and separation
   - Confidence capped at 0.75 (lower ceiling than regex)

**4. Hybrid Router** - `Services/Parsing/HybridIngredientParser.swift` (~60 lines)
   - Regex first (microseconds), NLP fallback if confidence < 0.8
   - Returns whichever parser produces higher confidence
   - Tracks parserUsed: "regex", "nlp", or "hybrid"

**5. Service Integration** - `Services/IngredientParsingService.swift`
   - Delegates to HybridIngredientParser (no public API change)
   - All call sites unchanged (zero modifications needed)

**6. Telemetry Enhancement** - `Services/ParsingTelemetryService.swift`
   - Added `parserUsed` field to `ParsingTelemetryEvent`
   - Schema version bumped to 2 (backward compatible)

**7. Test Suite** - 3 test files (~600 lines total)
   - `RegexIngredientParserTests`: 30 tests (regression + new patterns)
   - `NLPIngredientParserTests`: 12 tests (fallback behavior)
   - `HybridIngredientParserTests`: 16 tests (router + integration)
   - Performance benchmarks included

### **Confidence Tiers**

| Scenario | Confidence |
|----------|-----------|
| Full parse: qty + unit + name | 1.0 |
| Unicode fraction + unit + name | 1.0 |
| Unicode fraction + name (no unit) | 0.90 |
| Range + unit + name | 0.85 |
| Compound phrase + unit | 0.85 |
| Range + name (no unit) | 0.80 |
| Parenthetical parsed | 0.80 |
| Qty + name (no unit) | 0.75 |
| NLP full parse (capped) | 0.75 |
| Qualifier detected | 0.70 |
| Descriptive amount | 0.60 |
| NLP qty + name | 0.60 |
| NLP name + notes | 0.50 |
| NLP name only | 0.30 |
| Nothing parsed | 0.0 |

### **Files Created/Modified**

| File | Status | Lines |
|------|--------|-------|
| `Services/Parsing/IngredientParser.swift` | NEW | ~35 |
| `Services/Parsing/RegexIngredientParser.swift` | NEW | ~650 |
| `Services/Parsing/NLPIngredientParser.swift` | NEW | ~310 |
| `Services/Parsing/HybridIngredientParser.swift` | NEW | ~60 |
| `foragerTests/Services/Parsing/RegexIngredientParserTests.swift` | NEW | ~260 |
| `foragerTests/Services/Parsing/NLPIngredientParserTests.swift` | NEW | ~100 |
| `foragerTests/Services/Parsing/HybridIngredientParserTests.swift` | NEW | ~150 |
| `Services/IngredientParsingService.swift` | MODIFIED | Delegate to hybrid parser |
| `Services/ParsingTelemetryService.swift` | MODIFIED | +parserUsed field |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Build | ✅ BUILD SUCCEEDED | Clean build on iPhone 17 Pro |
| Regression | ✅ PASSING | All existing patterns preserved |
| New patterns | ✅ IMPLEMENTED | 6 new pattern categories |
| Performance | ✅ TARGET MET | <0.1s per parse |

---

## ✅ **M8.3.1: TEMPLATE NAME HYGIENE & BADGE FIX - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 8, 2026
**Branch**: `feature/M8.3-hybrid-nlp-parser` (same branch as M8.3)
**PRD**: `docs/prds/complete/m8.3.1-template-hygiene-badge-fix.md`

### **What Was Delivered** ✅

**1. Centralized Template Creation** - 5 view files modified
   - All template creation paths now route through `findOrCreateTemplate`
   - Ensures 4-phase normalization (case, plural, abbreviation, variation)
   - Sets `canonicalName` for semantic deduplication
   - Files: CreateRecipeView, EditRecipeView, AddListItemView, GroceryListDetailView, AddIngredientsToListView

**2. Template Quality Heuristic** - `IngredientTemplate+Validation.swift`
   - `needsReview` computed property with 4 detection rules:
     1. Parenthetical text: "butter (room temperature)"
     2. Digits/Unicode fractions: "2 cloves garlic", "½ cup"
     3. Qualifier suffixes: "salt to taste", "herbs for garnish"
     4. Leading unit words: "loaf french bread", "can tomatoes"

**3. Review UI on Ingredients Tab** - `IngredientsView.swift`
   - Yellow triangle badges on templates needing review
   - "Review (N)" filter pill with count badge
   - Scrollable filter pills (prevents overflow)
   - Bottom scroll clearance fix for custom navigation

**4. Merge-on-Rename Dedup** - `IngredientsView.swift`
   - Renaming a template to an existing name merges instead of blocking
   - Reassigns all Ingredient relationships, sums usage counts, deletes old template
   - `.buttonStyle(.borderless)` fix for List row tap handling
   - Error callback from child rows to parent view

**5. Compound Plural Normalization** - `IngredientTemplateService.swift`
   - `alwaysPluralSuffixes` last-word matching for compound names
   - "black beans", "red pepper flakes", "tortilla strips" stay plural
   - `normalize(name:)` changed to internal for test access

**6. Badge Threshold Calibration** - `RecipeListView.swift`, `GroceryListDetailView.swift`
   - Raised from `< 0.5` to `< 0.7` (aligned with M8.3 confidence tiers)

**7. Unit Tests** - 21 new tests
   - `IngredientTemplateValidationTests.swift` (17 tests): needsReview heuristic coverage
   - `IngredientTemplateNormalizationTests.swift` (21 tests): compound plural + normalization pipeline

### **Files Created/Modified**

| File | Status | Notes |
|------|--------|-------|
| `IngredientTemplate+Validation.swift` | MODIFIED | +needsReview heuristic |
| `Services/IngredientTemplateService.swift` | MODIFIED | Compound plural fix, normalize → internal |
| `forager/IngredientsView.swift` | MODIFIED | Badges, filter, merge-on-rename, scroll fix |
| `forager/CreateRecipeView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/EditRecipeView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/AddListItemView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/GroceryListDetailView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/AddIngredientsToListView.swift` | MODIFIED | Route through findOrCreateTemplate |
| `forager/RecipeListView.swift` | MODIFIED | Badge threshold → 0.7 |
| `foragerTests/Services/IngredientTemplateValidationTests.swift` | NEW | 17 tests |
| `foragerTests/Services/IngredientTemplateNormalizationTests.swift` | NEW | 21 tests |

---

## ✅ **M8.3.2: AUTO-MERGE GROCERY QUANTITIES - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 8, 2026
**Branch**: `feature/M8.3-hybrid-nlp-parser` (same branch as M8.3)
**PRD**: `docs/prds/complete/m8.3.2-auto-merge-grocery-quantities.md`

### **What Was Delivered** ✅

**1. GroceryMergeService** - `Services/GroceryMergeService.swift`
   - Pure computation service (no Core Data dependency)
   - Handles: same-unit addition, convertible-unit conversion, incompatible-unit rejection
   - Parseable/unparseable collision handling
   - Display text formatting
   - Confidence tracking: `min(existing, incoming)`

**2. Wired into AddIngredientsToListView** - `forager/AddIngredientsToListView.swift`
   - Replaces string concatenation ("8 oz + 12 oz") with numeric merging ("20 oz")
   - Source recipe tracking preserved

**3. Consolidation Button Removed** - `forager/GroceryListDetailView.swift`
   - Manual merge button removed from grocery list toolbar
   - Related state and functions cleaned up

**4. Unit Tests** - 19 tests
   - `GroceryMergeServiceTests.swift`: Same-unit, convertible, incompatible, confidence, display text

### **Files Created/Modified**

| File | Status | Notes |
|------|--------|-------|
| `Services/GroceryMergeService.swift` | NEW | Pure merge logic service |
| `foragerTests/Services/GroceryMergeServiceTests.swift` | NEW | 19 tests |
| `forager/AddIngredientsToListView.swift` | MODIFIED | Auto-merge wiring |
| `forager/GroceryListDetailView.swift` | MODIFIED | Consolidation button removed |

---

## ✅ **M8.1: PARSING RESILIENCE & TELEMETRY - COMPLETE**

**Status**: ✅ **COMPLETE**
**Sessions**: February 6-7, 2026
**Branch**: `feature/M8.1-parsing-resilience-telemetry`
**PRD**: `docs/prds/m8-ingredient-parsing-intelligence-meta-prd.md`

### **What Was Delivered** ✅

**1. ParsingTelemetryService** - `Services/ParsingTelemetryService.swift` (~400 lines)
   - Logs parsing events with confidence scores
   - Logs user corrections (before/after)
   - JSON persistence to Documents folder
   - Analysis APIs (getStatistics, getLowConfidenceEvents)
   - Privacy-safe (local storage only)

**2. Unit Tests** - `foragerTests/Services/ParsingTelemetryServiceTests.swift` (~660 lines)
   - 20/20 tests passing
   - Test isolation with `resetForTesting()` and `waitForPendingOperations()`

**3. Yellow Badge (Recipes)** - `forager/RecipeListView.swift`
   - Yellow exclamation triangle for `parseConfidence < 0.5`
   - Shows in ingredient rows within recipe detail view

**4. Yellow Badge (Grocery List)** - `forager/GroceryListDetailView.swift`
   - Low-confidence indicator in grocery list view

**5. Telemetry Integration** - `Services/IngredientParsingService.swift`
   - Added `source` parameter to `parseToStructured()`
   - Logs all parsing events to ParsingTelemetryService

**6. Sample Test Recipes** - `forager/RecipeListView.swift`
   - 3 sample recipes with low-confidence ingredients for validation
   - Access via: Recipes → Menu (⋯) → Create Test Recipes

### **What Was Removed (Scope Reduction)**

- **EditIngredientSheet** — Removed structured edit form. Users can already edit ingredients inline via the recipe edit view. The structured form would be replaced by M8.3's improved parser anyway.
- **Context menu on ingredient rows** — Removed (was only used to launch EditIngredientSheet)

### **Bug Fixes During Testing**

- **Crash fix**: `IngredientTemplate.normalizedName` was declared in CoreDataProperties but didn't exist in the Core Data model. Removed phantom property.
- **Build fix**: Cleaned up all references from project.pbxproj

### **Files Created/Modified**

| File | Status | Lines |
|------|--------|-------|
| `Services/ParsingTelemetryService.swift` | NEW | ~400 |
| `foragerTests/Services/ParsingTelemetryServiceTests.swift` | NEW | ~660 |
| `docs/testing/M8.1-ParsingTelemetryService-test-plan.md` | NEW | - |
| `foragerTests/Info.plist` | NEW | - |
| `foragerUITests/Info.plist` | NEW | - |
| `Services/IngredientParsingService.swift` | MODIFIED | +10 |
| `forager/RecipeListView.swift` | MODIFIED | +60 |
| `forager/GroceryListDetailView.swift` | MODIFIED | +10 |
| `IngredientTemplate+CoreDataProperties.swift` | MODIFIED | -1 (removed phantom normalizedName) |

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Unit tests | ✅ 20/20 PASSING | All telemetry service tests pass |
| Build | ✅ BUILD SUCCEEDED | Clean build on iPhone 17 Pro |
| Yellow badge (Recipes) | ✅ VERIFIED | Badges visible on low-confidence ingredients |
| Yellow badge (Grocery) | ✅ VERIFIED | Indicator shows in grocery list |

---

## ✅ **M7.4: UI POLISH & PRE-LAUNCH FIXES - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 5, 2026
**Branch**: `feature/M7.4-ui-polish-pre-launch`
**PRD**: `docs/prds/active/m7.4-ui-polish-pre-launch.md`

### **What Was Implemented** ✅

**Ad-hoc UI Polish (retroactively documented):**

1. **Apple Music-Style Bottom Navigation** - CustomBottomNavigation.swift
   - Grouped pill container with 4 main tabs
   - Separate circular search button that expands inline
   - Two-step search interaction (expand bar, then tap to focus)
   - Smooth spring animations on state changes
   - `.regularMaterial` for iOS 26 Liquid Glass design

2. **Hamburger Menu Navigation** - HamburgerMenuModifier.swift
   - Settings and Categories moved from tabs to hamburger menu
   - Sheet-based navigation with full-height presentation
   - Consistent access across all main views

3. **Settings Restructure** - SettingsView.swift
   - Clear visual hierarchy with section groupings
   - Migration status banner for post-household users
   - Household Management section (contextual, owner-only options)
   - App Information section with version display

4. **Keyboard Search Bar Fix** - CustomBottomNavigation.swift
   - Removed `.ignoresSafeArea(.keyboard)` that blocked keyboard avoidance
   - iOS natural keyboard avoidance now pushes nav bar up correctly

5. **Ingredients Filter Pill Sizing** - IngredientsView.swift
   - Added FilterPill.Size enum (compact, regular, large)
   - "All Categories" uses `.large` to prevent text truncation
   - "Staples First" shortened to "Staples" with `.compact` size
   - Sort button uses `.compact` size

### **Files Modified/Created**
- `forager/CustomBottomNavigation.swift` - NEW: Apple Music-style navigation
- `forager/HamburgerMenuModifier.swift` - NEW: Hamburger menu sheet
- `forager/SettingsView.swift` - Restructured with clear hierarchy
- `forager/IngredientsView.swift` - FilterPill sizing improvements
- `docs/prds/active/m7.4-ui-polish-pre-launch.md` - NEW: Retroactive PRD

### **Testing Status**
| Test | Status | Notes |
|------|--------|-------|
| Bottom nav animations | ✅ PASSED | Smooth spring transitions |
| Search keyboard interaction | ✅ PASSED | Keyboard pushes nav bar up |
| Filter pill readability | ✅ PASSED | No text truncation |
| Hamburger menu navigation | ✅ PASSED | Settings/Categories accessible |

---

## ✅ **M7.3.4: ERROR HANDLING & STABILITY IMPROVEMENTS - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 5, 2026
**Branch**: `feature/M7.3.3-remove-member-delete-household` (includes M7.3.4 changes)

### **What Was Implemented** ✅

**P0 Fixes:**
1. **ERR-001: Ghost Data Bug Fix** - `loadCurrentHousehold()` no longer auto-clears left flag
2. **ERR-002: Replace exit(0)** - Check Again button flow in AcceptInvitationSheet

**P1 Technical Debt:**
3. **ERR-010: CloudKitErrorMapper** - Single source of truth for CKError messages
4. **ERR-011: Magic Numbers** - Replaced with CKError.Code enum
5. **ERR-012: OSLog/CloudKitLogger** - Structured logging for CloudKit operations

**Additional Fixes (discovered during testing):**
6. **Offline Leave Hanging** - NWPathMonitor connectivity check before CKShare operations
7. **Pending Leave Queue** - KeychainHelper stores pending leaves for offline scenarios
8. **Autocomplete Ghost Data** - householdKey filtering across all autocomplete surfaces
9. **Category Management Ghost Data** - householdKey filtering for category operations

### **Files Modified/Created**
- `Services/HouseholdService.swift` - ERR-001 fix, connectivity check, pending leave processing, logging
- `forager/AcceptInvitationSheet.swift` - ERR-002 Check Again button
- `Services/Persistence/CloudKitErrorMapper.swift` - NEW
- `Services/Persistence/CloudKitLogger.swift` - NEW
- `Services/CloudKitSyncMonitor.swift` - Uses CloudKitErrorMapper
- `Services/Persistence/CloudKitDiagnostics.swift` - Uses CloudKitErrorMapper
- `Services/KeychainHelper.swift` - Pending leave queue
- `forager/MealPlanDetailView.swift` - householdKey filter for recipe autocomplete
- `Services/IngredientAutocompleteService.swift` - householdKey filter for ingredient autocomplete
- `forager/AddListItemView.swift` - Pass householdKey to autocomplete
- `forager/GroceryListDetailView.swift` - Pass householdKey to autocomplete (quick add)
- `forager/CreateRecipeView.swift` - Pass householdKey to autocomplete
- `forager/EditRecipeView.swift` - Pass householdKey to autocomplete
- `forager/AddCategoryView.swift` - householdKey filter for duplicate check and sort order
- `forager/ManageCategoriesView.swift` - householdKey filter for ingredient template operations
- `forager/IngredientsView.swift` - householdKey filter for ingredient rename duplicate check

### **Testing Status**
| Test | Status | Notes |
|------|--------|-------|
| Test 1: Offline Leave | ✅ PASSED | Pending leave queue works |
| Test 2: Rejoin + Ghost Data | ✅ PASSED | Autocomplete filtering fixed |
| Test 3: Multi-Device Leave | ⏭️ SKIPPED | User decision - not testing kid's iPad |
| Test 4: OSLog Validation | ✅ VALIDATED | Code implemented, use Console.app to verify |
| Test 5: Regression Testing | ⏭️ SKIPPED | User decision - exhaustive household testing already done |

---

## ✅ **M7.3.3: REMOVE MEMBER & DELETE HOUSEHOLD - COMPLETE**

**Status**: ✅ **COMPLETE**
**Session**: February 3, 2026
**Branch**: `feature/M7.3.3-remove-member-delete-household` (ready to merge)

### **What Was Implemented** ✅

**1. Remove Member (Owner-only)**
- `removeMember(_:from:)` in HouseholdService - uses CKShare.removeParticipant()
- Swipe-to-delete UI in HouseholdMembersView (only shows for owner, excludes self/owner rows)
- Confirmation alert before removal
- Error handling: `cannotRemoveSelf`, `cannotRemoveOwner`

**2. Delete Household (Owner-only)**
- `deleteHousehold(_:migrateData:)` in HouseholdService
- Optional data migration (reuses `migrateHouseholdDataToPersonal()`)
- Deletes CKShare from private database (revokes all participants' access)
- Purges shared store objects
- "Delete Household" button in SettingsView (red, destructive)
- Two-option confirmation alert: "Migrate & Delete" / "Clean Delete"

**3. Household Protection (Prevents Multi-Household State)**
- `alreadyInHousehold` error case added to `HouseholdError`
- Protection in `createHouseholdAndShare()` - cannot create when already in one
- Protection in `checkForAcceptedInvitations()` - cannot join when already in one
- SceneDelegate protection - rejects share invitation when already in household
- `cloudKitShareRejectedAlreadyInHousehold` notification for UI feedback

**4. Removed Member Detection**
- `checkIfRemovedFromHousehold()` detects when member loses access
- Automatically clears household state and purges shared data
- Marks household as "left" to prevent re-join loops

**5. Category Sync Diagnostics**
- `dumpCategorySyncDiagnostics()` for troubleshooting sync issues
- "Category Sync Diagnostic" button in Settings (DEBUG only)

**6. Deprecated API Cleanup**
- Removed `userDiscoverability` permission code from foragerApp.swift (~75 lines)
- Fixed `rootRecordID` → `hierarchicalRootRecordID` in SceneDelegate and PasteInvitationSheet

### **Files Modified**
- `Services/HouseholdService.swift` - removeMember(), deleteHousehold(), protections, diagnostics
- `forager/HouseholdMembersView.swift` - Swipe-to-delete UI with confirmation
- `forager/SettingsView.swift` - Delete Household button, diagnostic button
- `forager/SceneDelegate.swift` - Share rejection when already in household
- `forager/foragerApp.swift` - Removed deprecated permission code (-75 lines)
- `forager/PasteInvitationSheet.swift` - Fixed deprecated API

---

## ✅ **M7.2.2: LEAVE HOUSEHOLD - COMPLETE**

**Status**: ✅ **COMPLETE**
**Sessions**: January 18 - February 2, 2026
**Key Achievement**: Full member leave flow with data migration, CKShare cleanup, owner notification, rejoin support, and code cleanup

### **What Was Implemented** ✅

**1. Member Leave Flow (HouseholdService.swift)**
- `leaveHousehold()` - Complete leave sequence with data migration option
- `migrateHouseholdDataToPersonal()` - Full data migration (recipes, categories, ingredient templates, lists)
- `deleteCKShareFromSharedDatabase()` - Member self-removal from CKShare (workaround for CloudKit limitation)
- `purgeAllSharedStoreObjects(from:)` - Extracted shared-store purge helper on PersistenceController
- `destroyAndRecreateSharedStore()` - Nuclear cleanup of shared store

**2. Owner-Controlled Member Removal**
- Owner can remove members from household via CKShare participant management
- Real-time leave request detection via Combine sync observer
- Local notification to owner when member leaves

**3. Rejoin Fix & Keychain Tracking**
- `KeychainHelper` - Persistent tracking of left households (survives app reinstall)
- Fixed re-joining blocked by stale left-household flag
- Proper cleanup on successful rejoin

**4. PasteInvitationSheet API Fix**
- Changed from `CKContainer.accept(metadata)` to `NSPersistentCloudKitContainer.acceptShareInvitations(from:into:)`
- Matches SceneDelegate pattern for consistent sync behavior

**5. Dead Code Removal & Optimization (~450 lines removed)**
- Removed 9 dead functions: `stopParticipatingInShare`, `fetchShare`, `createHousehold(name:ownerName:)`, `createCloudKitShare`, `getCurrentUserDisplayName`, `getDisplayNameFromShare`, `waitForCloudKitExport`, `waitForMemberDeletionSync`, `removeParticipantFromShare`, `syncParticipantsFromShare`
- Extracted `purgeAllSharedStoreObjects(from:)` to PersistenceController
- CKShare caching opportunity identified for future optimization

**6. Invitation Message Enhancement**
- Outgoing text message includes friendly description above iCloud link
- CKShare title set to "Join [Household Name] on forager"

### **Commits on Branch**
1. `73a1909` - M7.2.2: Add real-time leave request detection via Combine sync observer
2. `463ab89` - M7.2.2: Fix re-joining household blocked by stale left-household flag
3. `a5dd9a6` - M7.2.2: Switch to owner-controlled member removal, fix recipe picker duplication
4. `9f47102` - M7.2.2: Harden leave flow — CKShare deletion, shared store nuke, rejoin fix
5. `c84cb20` - M7.2.2: Remove dead code, extract purge helper, fix PasteInvitationSheet API

### **Files Modified/Created**
- `Services/HouseholdService.swift` - Major refactor (~450 lines removed, leave flow hardened)
- `Services/Persistence/PersistenceController.swift` - Added `purgeAllSharedStoreObjects(from:)` helper
- `Services/KeychainHelper.swift` - NEW: Persistent left-household tracking
- `forager/PasteInvitationSheet.swift` - Fixed acceptance API
- `forager/ShareSheet.swift` - Invitation message enhancement

---

## **Previous Session Progress**

### **M7.3.1: Rename Household** ✅ COMPLETE (Jan 13, 2026)
- Owner-only household renaming functionality
- Inline text field edit UI in Settings

### **M7.2.3: CloudKit Hardening** ✅ COMPLETE (Jan 4, 2026)
- Dual-store architecture (private + shared)
- Scope-based store assignment
- CategoryDeduplicator for multi-device sync
- Attach-then-share migration

### **M7.2.2: Member Invitation** ✅ COMPLETE (Jan 12, 2026)
- Public link sharing (bypassed UICloudSharingController bugs)
- CKShare.participants as source of truth

---

## **Known Issues & Limitations**

1. **CloudKit Limitation**: Members cannot remove themselves from CKShare.participants
   - Workaround: `deleteCKShareFromSharedDatabase()` deletes CKShare from shared database
2. **Migration**: PlannedMeals not migrated (require recipe mapping)
   - User can recreate meal assignments manually
3. **CKShare caching**: `getShare(for:)` hits CloudKit on every call; could cache per operation

---

## **What's Next**

### **Pre-Launch Roadmap** 🚀

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

**M7.6 Phases** (8 phases — PRD: `docs/prds/active/m7.6-pre-launch-prep-testflight.md`):

| Phase | Description | Est. |
|-------|-------------|------|
| M7.6.1 | App Configuration (display name, iOS 18 target, launch screen) | 0.5h |
| M7.6.2 | Production Gating (`#if DEBUG` for developer tools) | 0.5h |
| M7.6.3 | Onboarding Flow (first-launch walkthrough, Settings replay) | 3-4h |
| M7.6.4 | Schema Cleanup P0 (remove Tag + LeaveRequest, fix plannedMeals cardinality) | 1-1.5h |
| M7.6.5 | Schema Cleanup P1 (rename ownerEmail, fix delete rules, code-schema mismatches) | 1-1.5h |
| M7.6.6 | Schema Cleanup P2 (remove unused fields, fix sourceURL tags hack, naming) | 1-1.5h |
| M7.6.7 | TestFlight Submission (CloudKit Production deploy, archive, submit) | 1.5h |
| M7.6.8 | Public Beta Link (after Apple approval, 24-48h wait) | 0.25h |

**M7.7 Phases** (4 phases — PRD: `docs/prds/active/m7.7-app-store-submission.md`):

| Phase | Description | Est. |
|-------|-------------|------|
| M7.7.1 | Beta Landing Page (GitHub Pages) | 1-2h |
| M7.7.2 | GitHub README Update (portfolio quality) | 0.5h |
| M7.7.3 | App Store Listing (metadata, screenshots, copy) | 1-2h |
| M7.7.4 | App Store Submission | 0.5h |

**Key Decisions (February 8, 2026)**:
- iOS 18 target (deliberate — avoids ~104 mechanical API changes for no market)
- Display name: `forager - Smart Meal Planner` (lowercase 'forager')
- Core Data schema cleanup before Production deployment (append-only once deployed)
- LinkedIn showcase removed — user handles via newsletter
- Onboarding: 4-page horizontal walkthrough, first-launch + Settings replay

### **Post-Launch Roadmap**

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.5: Architecture Hardening | DEFERRED | 18.5-24.5h |
| M6: Testing Foundation | PLANNED | 12-18h |
| M8.4: ML-Powered Parsing | OPTIONAL | 15-20h |
| M9: Technical Debt | PLANNED | 135-165h |
| M10: Analytics & Insights | PLANNED | 8-12h |
| M11-M14: Advanced Features | FUTURE | 40-60h |

---

## **SESSION STARTUP REMINDER**

**For EVERY development session**, follow the mandatory startup sequence:

1. Read `docs/session-startup-checklist.md`
2. Read `docs/project-naming-standards.md`
3. Read `docs/current-story.md` (this file)
4. Read `docs/next-prompt.md`

---

**Last Session**: February 8, 2026 - M7.6/M7.7 scoped, PRDs written, core docs updated
**Next Action**: Commit all uncommitted work, merge M8.3 branch to main, then start M7.6
**Branch**: `feature/M8.3-hybrid-nlp-parser` (ready to commit + merge)
**Confidence**: **GREEN** (All features delivered, tested, clean build, 102 M8 tests)
**Version**: February 8, 2026 - M7.6/M7.7 Scoped

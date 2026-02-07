# Current Development Story

**Last Updated**: February 7, 2026
**Status**: M8.1 🔄 **IN PROGRESS** - Core implementation complete, testing phase
**Total Progress**: ~168 hours | 89% planning accuracy
**Current Branch**: `feature/M8.1-parsing-resilience-telemetry`
**Current Milestone**: M8 - Ingredient Parsing Intelligence

---

## 🔄 **M8.1: PARSING RESILIENCE & TELEMETRY - IN PROGRESS**

**Status**: 🔄 **IN PROGRESS** (Core implementation complete, user testing phase)
**Sessions**: February 6-7, 2026
**Branch**: `feature/M8.1-parsing-resilience-telemetry`
**PRD**: `docs/prds/m8-ingredient-parsing-intelligence-meta-prd.md`

### **What's Been Implemented** ✅

**Phase 1: Telemetry Service (COMPLETE)**

1. **ParsingTelemetryService** - `Services/ParsingTelemetryService.swift` (~400 lines)
   - Logs parsing events with confidence scores
   - Logs user corrections (before/after)
   - JSON persistence to Documents folder
   - Analysis APIs (getStatistics, getLowConfidenceEvents)
   - Privacy-safe (local storage only)
   - Synchronous counter updates for test reliability

2. **Unit Tests** - `foragerTests/Services/ParsingTelemetryServiceTests.swift` (~660 lines)
   - **20/20 tests passing**
   - Test isolation with `resetForTesting()` and `waitForPendingOperations()`
   - Covers event logging, correction logging, statistics, edge cases
   - Fixed async race conditions with Thread.isMainThread check

3. **Test Plan** - `docs/testing/M8.1-ParsingTelemetryService-test-plan.md`
   - 26 test cases documented across 6 categories

**Phase 2: Low-Confidence UI (COMPLETE)**

4. **Yellow Badge in RecipeListView** - `forager/RecipeListView.swift`
   - Yellow exclamation triangle (⚠️) for `parseConfidence < 0.5`
   - Shows in ingredient rows within recipe detail view
   - `.help()` modifier provides accessibility hint

5. **Yellow Badge in GroceryListDetailView** - `forager/GroceryListDetailView.swift`
   - Updated existing indicator to use `parseConfidence < 0.5`
   - Visible when user is browsing grocery list (most useful location)

6. **Context Menu for Editing** - `forager/RecipeListView.swift`
   - "Edit Ingredient" context menu on ingredient rows
   - Opens EditIngredientSheet

**Phase 3: Structured Edit Form (COMPLETE)**

7. **EditIngredientSheet** - `forager/EditIngredientSheet.swift` (~330 lines)
   - Structured form with quantity, unit, name, notes fields
   - Handles both `Ingredient` and `GroceryListItem` entities
   - Original text section for low-confidence items
   - Validation with user-friendly error messages
   - Sets `parseConfidence = 1.0` after manual edit (max confidence)
   - Logs corrections to ParsingTelemetryService

**Phase 4: Telemetry Integration (COMPLETE)**

8. **IngredientParsingService Integration** - `Services/IngredientParsingService.swift`
   - Added `source` parameter to `parseToStructured()`
   - Logs all parsing events to ParsingTelemetryService
   - Tracks `.recipeIngredient` and `.groceryListItem` sources

**Phase 5: Test Data (COMPLETE)**

9. **Sample Low-Confidence Recipes** - `forager/RecipeListView.swift`
   - Added 3 sample recipes (12-14) with low-confidence ingredients
   - Ingredients like "salt to taste", "pepper as needed", "a pinch of"
   - Access via: Recipes → Menu (⋯) → Create Test Recipes

### **Files Created/Modified**

| File | Status | Lines |
|------|--------|-------|
| `Services/ParsingTelemetryService.swift` | NEW | ~400 |
| `foragerTests/Services/ParsingTelemetryServiceTests.swift` | NEW | ~660 |
| `forager/EditIngredientSheet.swift` | NEW | ~330 |
| `docs/testing/M8.1-ParsingTelemetryService-test-plan.md` | NEW | - |
| `foragerTests/Info.plist` | NEW | - |
| `foragerUITests/Info.plist` | NEW | - |
| `Services/IngredientParsingService.swift` | MODIFIED | +10 |
| `forager/RecipeListView.swift` | MODIFIED | +80 |
| `forager/GroceryListDetailView.swift` | MODIFIED | +10 |
| `forager.xcodeproj/project.pbxproj` | MODIFIED | +4 entries |

### **Commits on Branch**

1. `731b212` - M8.1: Add ParsingTelemetryService test plan
2. `963bd78` - M8.1: Add XCTest unit tests for ParsingTelemetryService
3. `32498b2` - M8.1: Add missing Info.plist files for test targets
4. `7b797c8` - M8.1: Add test isolation and fix async race conditions
5. `759628a` - M8.1: Add EditIngredientSheet and yellow badge UI
6. `0fb1c88` - M8.1: Add yellow badge to grocery list and sample low-confidence recipes

### **Remaining Work** 📋

- [ ] User testing with sample recipes (create test recipes, verify badge visibility)
- [ ] Any UI tweaks based on feedback
- [ ] Merge PR to main

### **Testing Status**

| Test | Status | Notes |
|------|--------|-------|
| Unit tests | ✅ 20/20 PASSING | All telemetry service tests pass |
| Build | ✅ BUILD SUCCEEDED | Clean build on iPhone 17 Pro |
| Yellow badge (Recipes) | ⏳ USER TESTING | Sample recipes created |
| Yellow badge (Grocery) | ⏳ USER TESTING | Indicator added |
| Edit sheet | ⏳ USER TESTING | Context menu wired |

### **How to Test Low-Confidence Badge**

1. Run the app on device
2. Go to **Recipes** tab
3. Tap menu (⋯) → **Create Test Recipes**
4. Creates 14 recipes including 3 with low-confidence ingredients:
   - Recipe 12: "Simple Seasoned Rice"
   - Recipe 13: "Rustic Garlic Bread"
   - Recipe 14: "Quick Avocado Toast"
5. Open any of these recipes to see yellow badges
6. Add ingredients to a grocery list
7. Open grocery list to see badges there too

### **Low-Confidence Examples**

These ingredient patterns get `parseConfidence < 0.5`:
- "salt to taste" → confidence 0.0
- "pepper as needed" → confidence 0.0
- "a pinch of saffron" → confidence 0.3
- "some butter" → confidence 0.0
- "2-3 cloves garlic" → confidence 0.3 (range not numeric)
- "a handful of parsley" → confidence 0.3
- "butter as desired" → confidence 0.0

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

### **Before App Store Launch**

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.3.4: Error Handling | ✅ COMPLETE | - |
| M7.4: UI Polish & Pre-Launch Fixes | ✅ COMPLETE | ~4h |
| **M8.1: Parsing Resilience & Telemetry** | 🔄 IN PROGRESS | 3-4h |
| M8.2: Telemetry Analysis | 📋 PLANNED | 2h |
| M8.3: Hybrid NLP Parser | 📋 PLANNED | 8-10h |
| M7.6: External TestFlight | 📋 PLANNED | 2-3h |
| M7.7: App Store Submission | 📋 PLANNED | 2-3h |

**Note**: Original M7.4 (Sync Status UI) was **SKIPPED** - dual-store architecture makes it unnecessary. M7.4 repurposed for UI polish.

### **After App Store Launch**

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

**Last Session**: February 7, 2026 - M8.1 Core Implementation Complete
**Next Action**: User testing with sample recipes, then merge PR to main
**Branch**: `feature/M8.1-parsing-resilience-telemetry`
**Confidence**: **GREEN** (All core features implemented, testing in progress)
**Version**: February 7, 2026 - M8.1 Core Complete

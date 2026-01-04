# Next Implementation Prompt

**Last Updated**: January 4, 2026  
**For Milestone**: M7.2.3 - CloudKit Hardening & Shared Data Architecture  
**Status**: 🧪 **PHASE 4.2 READY - Backend Migration Testing**  
**Estimated Duration**: 1.5-2 hours (Testing Phase)

---

## 🧪 **M7.2.3 PHASE 4.2 - BACKEND MIGRATION TESTING**

**Current State:**
- ✅ PRD v2.2 FINAL ready (externally validated)
- ✅ Phase 4.1 COMPLETE - Migration UI implemented
- ✅ Build successful - Zero errors, zero warnings
- ✅ Attach-then-share pattern implemented (Gemini-validated API)

**What's Next**: Phase 4.2 Testing (1.5-2 hours)  
**Purpose**: Validate migration flow works end-to-end

---

## 📋 **PHASE 4.2 TESTING GUIDE**

### **Step 1: Create Test Data** (15 minutes)

**Goal**: Add personal data to test migration

**Actions**:
1. **Add 5-10 Recipes**:
   - Open Recipes tab
   - Tap "+" to create recipes
   - Examples: "Chicken Stir Fry", "Spaghetti Carbonara", "Greek Salad"
   - Verify: All recipes have `household == nil` (personal data)

2. **Create 2 Weekly Lists**:
   - Open Grocery tab
   - Tap "+" to create weekly list
   - Add some items to each list
   - Verify: Lists are personal (not in household)

3. **Add 3-5 Meal Plans**:
   - Open Meal Plans tab
   - Tap "+" to create meal plans
   - Link to recipes you created
   - Verify: Meal plans are personal

**Verification**: You should have at least 10 total items across recipes/lists/meal plans

---

### **Step 2: Test Migration Flow** (30 minutes)

**Goal**: Test complete household creation + migration flow

**Actions**:
1. **Navigate to Settings**:
   - Tap Settings tab
   - Scroll to "Household" section
   - Tap "Create Household"

2. **Fill in Details**:
   - Household Name: "Test Household"
   - Your Name: [Your actual name]
   - Tap "Create"

3. **Expected: Migration Sheet Appears** ✅
   - Should see: "Move Existing Data to Household?"
   - Should display counts:
     - "X recipes"
     - "X grocery lists"
     - "X meal plans"
   - Icons should be colored (blue/green/orange)

4. **Choose "Move to Household"**:
   - Tap primary button "Move to Household"
   - Wait for creation (should see loading indicator)

5. **Expected: Success** ✅
   - Sheet dismisses
   - Settings shows household name
   - No error alerts

---

### **Step 3: Verify Migration in Console** (30 minutes)

**Goal**: Confirm DEBUG logs show correct migration flow

**Actions**:
1. **Open Xcode Console**:
   - Run app from Xcode (if not already running)
   - Open Debug Console (View → Debug Area → Activate Console)
   - Filter for "M7.2.3" to see relevant logs

2. **Expected Console Output**:

```
📊 Personal data counts:
   Recipes: 10
   Weekly Lists: 2
   Meal Plans: 5

🏗️ M7.2.3 Phase 4: Creating household and share
   Household: Test Household
   Owner: [Your email/recordID]
   Move existing data: true

🔄 Migrating personal data to household...
✅ Migrated 17 items:
   10 recipes
   2 weekly lists
   5 meal plans

🔒 Household [x-coredata://UUID] → Private Store

✅ CKShare created: [share-record-name]
👥 Household [x-coredata://UUID] → Shared Store

✅ Household created: Test Household
✅ Owner: [Your email]
✅ CloudKit shared zone activated
✅ Personal data migrated to household
```

3. **Key Indicators** ✅:
   - Data counts match what you created
   - "Private Store" logged before share
   - "Shared Store" logged after share
   - Migration counts logged
   - No error messages

**If you see errors**: Note the error message and stop testing

---

### **Step 4: Verify in CloudKit Dashboard** (15 minutes)

**Goal**: Confirm household in Shared Zone

**Actions**:
1. **Open CloudKit Dashboard**:
   - Visit: https://icloud.developer.apple.com/dashboard
   - Sign in with Apple ID
   - Select "iCloud.com.richhayn.forager" container
   - Select "Development" environment

2. **Check Private Database**:
   - Navigate to "Data" tab
   - Should see: Categories, IngredientTemplates (always private)
   - Should NOT see: Household (moved to shared)

3. **Check Shared Database** (NEW!):
   - Look for "Shared Records" or "Shared" database section
   - Should see: CD_Household record type
   - Click on it
   - Verify:
     - `name` = "Test Household"
     - `ownerEmail` = your email
     - Relationships to recipes/lists/meals (may show as references)

**Expected**: Household in Shared, personal entities still in Private but with household reference

---

### **Step 5: Test "Keep Personal" Path** (15 minutes)

**Goal**: Verify empty household creation works

**Actions**:
1. **Delete Test Household**:
   - In Settings → Household
   - (If delete UI exists, use it)
   - (Or: Delete from Core Data manually)

2. **Create Another Household**:
   - Settings → Create Household
   - Name: "Empty Household"
   - Your Name: [Your name]
   - Tap "Create"

3. **Expected: Migration Sheet Appears Again** ✅
   - Shows same data counts (data still exists)

4. **Choose "Keep Personal"**:
   - Tap "Keep Personal" button
   - Wait for creation

5. **Expected: Empty Household Created** ✅
   - Household created successfully
   - Recipes/lists/meals NOT migrated (still personal)
   - Check console: Should see `Move existing data: false`

---

### **Step 6: Test No-Data Path** (15 minutes)

**Goal**: Verify direct creation when no data exists

**Actions**:
1. **Delete All Data**:
   - Delete test household
   - Delete all recipes
   - Delete all weekly lists
   - Delete all meal plans
   - Verify: App is empty

2. **Create Household**:
   - Settings → Create Household
   - Name: "Clean Household"
   - Your Name: [Your name]
   - Tap "Create"

3. **Expected: NO Migration Sheet** ✅
   - Should NOT see migration prompt
   - Household created directly
   - Check console: Should see `Personal data counts: Recipes: 0, Weekly Lists: 0, Meal Plans: 0`

---

## ✅ **PHASE 4.2 ACCEPTANCE CRITERIA**

**All must pass**:
- ✅ Migration sheet appears when data exists
- ✅ Data counts accurate (recipes, lists, meal plans)
- ✅ "Move to Household" migrates all data
- ✅ "Keep Personal" creates empty household
- ✅ No migration sheet when no data exists
- ✅ StoreIdentityLogger shows Private → Shared transition
- ✅ CloudKit Dashboard shows household in Shared Zone
- ✅ Console logs show correct migration flow
- ✅ Zero crashes, zero errors
- ✅ Zero data loss (can still see all recipes/lists/plans)

---

## 🐛 **IF THINGS GO WRONG**

### **Migration Sheet Doesn't Appear**
- Check: Do you have any recipes/lists/meal plans?
- Check Console: Does `countPersonalData()` show counts > 0?
- Fix: Add test data and try again

### **Household Creation Fails**
- Check Console: What error message?
- Common causes:
  - No iCloud account signed in
  - CloudKit not available
  - Network issues
- Fix: Check Settings → iCloud, ensure signed in

### **Data Not Migrated**
- Check Console: Did `migratePersonalDataToHousehold()` run?
- Check: Did you choose "Move to Household" (not "Keep Personal")?
- Verify: Open a recipe, check if it has household relationship

### **Store Doesn't Change from Private to Shared**
- Check Console: Did `container.share()` call succeed?
- Check: Is CKShare created?
- This might indicate CloudKit API issue - report in console output

---

## 📊 **AFTER TESTING COMPLETE**

### **If All Tests Pass** ✅:

```bash
# Commit the successful work
git add forager/PreHouseholdDataMigrationSheet.swift
git add Services/HouseholdService.swift
git add forager/SettingsView.swift

git commit -m "M7.2.3 Phase 4.1-4.2: Migration UI + Testing COMPLETE

✅ Phase 4.1 Implementation:
- PreHouseholdDataMigrationSheet UI (165 lines)
- HouseholdService migration methods (3 new methods)
- CreateHouseholdSheet integration

✅ Phase 4.2 Testing:
- All 6 test scenarios passed
- Migration sheet works correctly
- Data counts accurate
- Both migration paths tested (move/keep)
- No-data path tested
- StoreIdentityLogger verified Private → Shared
- CloudKit Dashboard shows household in Shared Zone
- Zero crashes, zero data loss

📊 Metrics:
- Estimated: 3-4h (both phases)
- Actual: ~3h (Phase 4.1: 1.5h, Phase 4.2: 1.5h)
- Accuracy: 100% ✅"

git push
```

### **Update Documentation**:
1. Mark Phase 4 ✅ COMPLETE in `current-story.md`
2. Update `next-prompt.md` for Phase 5
3. Add actual hours to progress tracking
4. Create learning note with test results

### **Ready for Phase 5**:
- Phase 5: Repository Hardening (2-3h)
- Phase 6: Multi-Device Validation (1-2h)

---

## 🎯 **TESTING TIPS**

**Best Practices**:
- Test in Simulator first (easier to reset data)
- Keep Xcode Console open during all tests
- Take screenshots of migration sheet for documentation
- Note any unexpected behavior (even if minor)
- Test both iPhone and iPad if available

**Time Management**:
- Each test scenario: 15-30 minutes
- Don't rush - thorough testing prevents bugs
- If something doesn't work, investigate before moving on
- Document any workarounds needed

---

**Version**: January 4, 2026 - M7.2.3 Phase 4.2 Testing Ready  
**Status**: 🧪 Phase 4.1 complete, ready for backend testing  
**PRD**: PRD v2.2 FINAL (lines 662-820)

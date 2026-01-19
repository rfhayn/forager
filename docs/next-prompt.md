# Next Implementation Prompt

**Last Updated**: January 18, 2026
**For Milestone**: M7.2.2 - Leave Household Testing & Completion
**Status**: 🧪 **NEEDS TESTING**
**Estimated Duration**: 30-60 minutes testing
**Prerequisites**: Code complete, build from Xcode

---

## 🎯 **M7.2.2 - TEST LEAVE HOUSEHOLD FLOW**

**Goal**: Verify the member leave flow works end-to-end with automatic owner notification.

**Current State**:
- ✅ Code complete - LeaveRequest entity, leave flow, owner processing
- ✅ Migration fixed - categories & ingredient templates now included
- 🧪 Needs physical device testing
- 📍 Branch: `main` (all work committed)

**What Was Built**:
1. LeaveRequest Core Data entity (syncs via CloudKit)
2. Member creates LeaveRequest when leaving
3. Owner's app processes LeaveRequest on launch
4. Owner removes member from CKShare automatically
5. Owner receives local notification
6. Migration includes categories & ingredient templates

---

## 📋 **TESTING CHECKLIST**

### **Step 1: Build from Xcode** (5 min)

Open Xcode and build the app:
1. Open `forager.xcodeproj`
2. Select your physical device (iPhone)
3. Cmd+B to build
4. Fix any build errors if they occur

**Note**: Command-line build failed due to simulator naming. Build directly from Xcode.

---

### **Step 2: Setup Test Environment** (5 min)

**Device A (Owner - your phone)**:
1. Ensure household exists with data (recipes, categories)
2. Note the household name and member count

**Device B (Member - Tessa's iPad)**:
1. Should be a member of the household
2. Should see shared data (recipes, categories)

---

### **Step 3: Test Migrate and Leave** (15 min)

**On Device B (Member)**:
1. Go to Settings → Household
2. Tap "Leave Household"
3. Choose "Migrate and Leave"
4. Wait for leave to complete

**Verify on Device B**:
- [ ] App no longer shows household
- [ ] Recipes still visible (migrated to personal)
- [ ] **Categories still visible** (this was the bug we fixed)
- [ ] Ingredient templates preserved
- [ ] Can create new household or wait for invite

---

### **Step 4: Verify Owner Notification** (10 min)

**On Device A (Owner)**:
1. Close app completely (swipe up)
2. Reopen app
3. Check for local notification: "Member Left - [Name] has left [Household]"

**Verify on Device A**:
- [ ] Notification received (may appear in Notification Center)
- [ ] Member no longer appears in household members list
- [ ] Household still functional for owner

**Check Logs** (if available):
```
📋 M7.2.2: Processing leave request from [Name]
✅ M7.2.2: Removed [Name] from household
📬 M7.2.2: Sent member left notification
```

---

### **Step 5: Verify CloudKit State** (Optional)

If issues occur, check CloudKit Dashboard:
1. Go to CloudKit Dashboard
2. Check shared zone for LeaveRequest records
3. Verify CKShare.participants updated

---

## ✅ **SUCCESS CRITERIA**

**Member Side**:
- [ ] "Migrate and Leave" completes without crash
- [ ] Recipes persist after leaving (personal copies)
- [ ] **Categories persist after leaving** (this was the fix)
- [ ] Ingredient templates persist
- [ ] No re-joining on app restart

**Owner Side**:
- [ ] LeaveRequest processed automatically on app launch
- [ ] Member removed from CKShare.participants
- [ ] Local notification sent
- [ ] Household continues to function

---

## 🐛 **TROUBLESHOOTING**

**Build Errors**:
- Build from Xcode, not command line
- Check that LeaveRequest files are added to project

**Categories Not Persisting**:
- Check logs for: "M7.2.2: Migrated household data to personal"
- Should show category count > 0
- Verify `migrateHouseholdDataToPersonal` includes categorySet

**Member Still Shows After Leaving**:
- Owner needs to reopen app to process LeaveRequest
- Check CloudKit sync delay (may take 30-60 seconds)
- LeaveRequest should sync to owner's device first

**Notification Not Appearing**:
- Check notification permissions for app
- Check Notification Center (not just banner)
- Verify `sendMemberLeftNotification` was called in logs

**Re-Joining Automatically**:
- Check UserDefaults for left household tracking
- Log should show: "Marked household [ID] as left"
- On next launch: "Skipping re-join (household ID in left list)"

---

## 📊 **AFTER TESTING PASSES**

### **If All Tests Pass**:

1. Update documentation to mark M7.2.2 complete
2. Move to M7.3.3: Remove Member & Delete Household

### **If Issues Found**:

1. Document specific failure in logs
2. Save device logs to `/Users/rich/Desktop/forager/cc-ss/`
3. Next session will debug based on logs

---

## 🚀 **NEXT: M7.3.3 - REMOVE MEMBER & DELETE HOUSEHOLD**

**After M7.2.2 testing passes**:

**M7.3.3: Remove Member & Delete Household** (2-3 hours)
- Owners can remove members from household
- Owners can delete households entirely
- Data migration from shared → private zone on delete
- Confirmation alerts for destructive actions

---

## 📝 **GIT STATUS**

Current state:
- Branch: `main`
- Latest commit: `f263730 Mid 7.2.3 Troubleshooting...`
- Working tree: clean
- All changes committed

If testing reveals issues requiring code changes:
```bash
# Make fixes, then:
git add -A
git commit -m "M7.2.2: Fix [issue description]"
git push origin main
```

---

**Version**: January 18, 2026 - Testing Phase
**Status**: 🧪 Code complete, needs device testing
**Branch**: `main`
**Estimated Time**: 30-60 minutes testing
**Confidence**: 🟡 MEDIUM (Code looks good, needs verification)

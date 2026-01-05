# Next Implementation Prompt

**Last Updated**: January 4, 2026  
**For Milestone**: M7.2.2 - Member Invitation & Acceptance Testing  
**Status**: 🧪 **M7.2.2 READY - Multi-User Household Testing**  
**Estimated Duration**: 2-3 hours (Physical Device Testing)

---

## 🧪 **M7.2.2 - MEMBER INVITATION & ACCEPTANCE TESTING**

**Current State:**
- ✅ M7.2.3 COMPLETE - CloudKit sync verified working
- ✅ Shared zone validated with 61 migrated items
- ✅ M7.2.2 code already implemented (from previous session)
- ✅ Branch exists: `feature/M7.2.2-member-invitation`
- ⏸️ Testing paused - waiting for physical device availability

**What's Next**: Physical device testing with 2 iPhones (2-3 hours)  
**Purpose**: Validate household invitation and multi-user collaboration end-to-end

---

## 📋 **PREREQUISITES**

### **Required Equipment**

**Device A - Owner's iPhone:**
- Physical iPhone (not simulator)
- iOS 18.5+ installed
- iCloud account signed in (Account A)
- Forager app installed
- Has existing household from M7.2.3 testing OR ready to create new one

**Device B - Member's iPhone:**
- Physical iPhone (not simulator) - **DIFFERENT device**
- iOS 18.5+ installed  
- iCloud account signed in (Account B) - **DIFFERENT account than Device A**
- Forager app installed (fresh or can have data)

**Network:**
- Both devices have internet access (WiFi or cellular)
- CloudKit reachable from both devices

### **Code Verification**

Before testing, verify M7.2.2 code exists:

```bash
# Check if feature branch exists
git branch -a | grep M7.2.2

# If branch exists, review implementation
git checkout feature/M7.2.2-member-invitation
git log --oneline -10

# Verify these files exist with M7.2.2 changes:
# - Services/HouseholdService.swift (invite methods)
# - forager/ShareHouseholdSheet.swift (invitation UI)
# - forager/AcceptInvitationSheet.swift (acceptance UI)  
# - forager/HouseholdMembersView.swift (members list)

# If branch doesn't exist, you'll need to re-implement M7.2.2
# See M7.2.2 PRD for implementation details
```

---

## 🧪 **TESTING GUIDE**

### **Phase 1: Device Setup** (15 minutes)

**Goal**: Prepare both devices for testing

**Device A (Owner) Setup:**
1. Open Forager app
2. Navigate to Settings → Household
3. **If household exists** (from M7.2.3 testing):
   - Note household name
   - Verify data is present (recipes, lists, etc.)
   - Proceed to Phase 2
4. **If no household**:
   - Tap "Create Household"
   - Name: "Test Household"  
   - Owner: [Your name]
   - Choose "Move to Household" if data exists
   - Wait for creation to complete

**Device B (Member) Setup:**
1. Install Forager app (if not already installed)
2. Launch app
3. Navigate to Settings → Household
4. **Verify NO household exists** (should show "Create Household" button)
5. **Important**: Note the iCloud account email for Device B
   - Settings → [Your Name] at top → iCloud → Account email
   - You'll need this email for invitation on Device A

**Verification** ✅:
- Device A: Has household with data
- Device B: No household, shows create option
- Both devices signed into different iCloud accounts

---

### **Phase 2: Send Invitation** (30 minutes)

**Goal**: Send household invitation from Device A to Device B

**On Device A (Owner):**

1. **Navigate to Household Settings**:
   - Open Forager app
   - Tap Settings tab
   - Scroll to "Household" section
   - Tap to open household details

2. **Find Invite Button**:
   - Look for "Invite Member" or "Share Household" button
   - (Exact UI may vary based on implementation)

3. **Initiate Invitation**:
   - Tap "Invite Member" button
   - ShareHouseholdSheet should appear

4. **Expected UI Elements**:
   - Household name displayed
   - "Share with..." or similar text
   - System share sheet OR email input field
   - (Implementation may use UIActivityViewController or custom UI)

5. **Send Invitation**:
   - **If system share sheet**: Choose Messages or Mail
   - **If custom input**: Enter Device B's email address
   - Tap "Send" or "Invite"
   - Wait for confirmation

6. **Expected Confirmation** ✅:
   - Success message: "Invitation sent to [email]"
   - No error alerts
   - ShareSheet dismisses
   - (May see pending invitations list)

**On Device B (Member):**

1. **Check for Invitation**:
   - Open Messages app (if sent via Messages)
   - OR open Mail app (if sent via Email)
   - OR check Notifications (CloudKit share notifications)

2. **Locate Invitation**:
   - Look for message from Device A's iCloud account
   - Subject may include "Household Invitation" or similar
   - Message may contain link or button

3. **Note Invitation Details**:
   - What channel received it (Messages/Mail/Notification)?
   - What does the invitation look like?
   - Is there a clear "Accept" or "Open" button?

**Debugging - If No Invitation Received**:
- Check Device B's email/phone number is correct
- Verify both devices have internet
- Check CloudKit Dashboard for share records
- Look in Settings → Messages → Unknown Senders (might be filtered)
- Try alternative delivery method (Mail vs Messages)

---

### **Phase 3: Accept Invitation** (30 minutes)

**Goal**: Accept household invitation on Device B

**On Device B (Member):**

1. **Open Invitation**:
   - Tap the invitation link/button from Phase 2
   - **Expected**: Forager app launches automatically
   - **Expected**: AcceptInvitationSheet appears

2. **Review Invitation Details**:
   - Household name should be displayed
   - Owner name should be shown
   - (May show household data preview)

3. **Accept Invitation**:
   - Tap "Accept" or "Join Household" button
   - Wait for processing (may show loading indicator)

4. **Expected Results** ✅:
   - Success message: "Joined [Household Name]"
   - AcceptInvitationSheet dismisses
   - Settings → Household now shows household details
   - Household name displayed
   - Members list shows both users (Owner + Member)

**Verification on Device B**:
- Navigate through app tabs (Recipes, Grocery, Meal Plans)
- **Expected**: All household data from Device A is visible
- Recipes created on Device A should appear
- Weekly lists from Device A should appear
- Meal plans from Device A should appear
- Categories should be synced

**On Device A (Owner):**

1. **Verify Member Added**:
   - Open Settings → Household
   - Look at Members list
   - **Expected**: Both users shown
   - Owner has "Owner" badge
   - Member has "Member" role

---

### **Phase 4: Bi-Directional Sync Validation** (45 minutes)

**Goal**: Verify changes sync between both devices

**Test 1: Device A Creates Recipe → Device B Sees It**

1. **On Device A**:
   - Go to Recipes tab
   - Tap "+" to create new recipe
   - Name: "Sync Test Recipe A"
   - Add 2-3 ingredients
   - Save recipe
   - Note the time

2. **On Device B**:
   - Go to Recipes tab
   - Pull-to-refresh (or wait ~5 seconds)
   - **Expected**: "Sync Test Recipe A" appears
   - Tap on recipe
   - **Expected**: All details match (ingredients, etc.)
   - **Latency**: Should sync within <5 seconds

**Test 2: Device B Edits Recipe → Device A Sees Changes**

1. **On Device B**:
   - Open "Sync Test Recipe A"
   - Tap Edit
   - Change name to "Sync Test Recipe A - Modified"
   - Add one more ingredient
   - Save changes
   - Note the time

2. **On Device A**:
   - Navigate to "Sync Test Recipe A"
   - Pull-to-refresh (or wait ~5 seconds)
   - **Expected**: Name updated to "...Modified"
   - **Expected**: New ingredient appears
   - **Latency**: Should sync within <5 seconds

**Test 3: Device A Creates Grocery List → Device B Adds Items**

1. **On Device A**:
   - Go to Grocery tab
   - Create new weekly list: "Sync Test List"
   - Add 2-3 items
   - Note the time

2. **On Device B**:
   - Go to Grocery tab
   - Pull-to-refresh
   - **Expected**: "Sync Test List" appears
   - Open list
   - Add 2-3 more items
   - Save

3. **On Device A**:
   - Open "Sync Test List"
   - Pull-to-refresh
   - **Expected**: Device B's items appear
   - **Expected**: Total 4-6 items in list

**Test 4: Concurrent Edits (Optional Conflict Test)**

1. **Turn OFF WiFi on BOTH devices** (airplane mode)
2. **On Device A**: Edit a recipe (change prep time)
3. **On Device B**: Edit SAME recipe (change cook time)
4. **Turn ON WiFi on BOTH devices**
5. **Expected**: Both changes merge successfully
   - Device A's prep time kept
   - Device B's cook time kept
   - No data loss
   - (This tests CloudKit's automatic conflict resolution)

**Acceptance Criteria** ✅:
- All 4 test scenarios pass
- Sync latency < 5 seconds for all changes
- No data loss or duplication
- No crashes during sync
- Both devices show identical data after sync

---

### **Phase 5: Members View Validation** (15 minutes)

**Goal**: Verify household members list works correctly

**On Both Devices:**

1. **Navigate to Members**:
   - Settings → Household → Members (or similar)
   - **Expected**: HouseholdMembersView displays

2. **Verify Display**:
   - Both users listed (Owner + Member)
   - Owner has badge: "Owner" or crown icon
   - Member has badge: "Member"
   - Names displayed correctly (from iCloud accounts)

3. **Test Member Actions** (if implemented):
   - Try removing member (Owner only)
   - Try leaving household (Member only)
   - Verify permissions (Member can't invite others, etc.)

**Console Verification**:
- Check for CloudKit sync events
- Look for "HouseholdMember" entity updates
- Verify no errors in logs

---

## ✅ **M7.2.2 ACCEPTANCE CRITERIA**

**All must pass**:

**Invitation Flow**:
- ✅ Invitation sent successfully from Device A
- ✅ Invitation received on Device B (Messages/Mail/Notification)
- ✅ Invitation contains household details

**Acceptance Flow**:
- ✅ AcceptInvitationSheet launches correctly
- ✅ Acceptance completes without errors
- ✅ Device B joins household successfully
- ✅ Members list shows both users correctly

**Data Sync**:
- ✅ All existing household data visible on Device B
- ✅ New data from Device A syncs to Device B (<5s)
- ✅ New data from Device B syncs to Device A (<5s)
- ✅ Edits sync bi-directionally
- ✅ No data loss or duplication

**Performance**:
- ✅ Sync latency < 5 seconds
- ✅ No UI blocking during sync
- ✅ No crashes or freezes

**Members Management**:
- ✅ Members list accurate on both devices
- ✅ Roles displayed correctly (Owner vs Member)
- ✅ Permissions enforced (if implemented)

---

## 🐛 **TROUBLESHOOTING**

### **Invitation Not Received**

**Check**:
- Device B's email/phone number correct?
- Both devices have internet?
- Check spam/junk folder
- Check Messages → Unknown Senders
- Check CloudKit Dashboard for CKShare record

**Solutions**:
- Try alternative delivery (Mail vs Messages)
- Manually copy share URL and open in Safari
- Check iCloud sign-in status on both devices

### **Acceptance Fails**

**Check Console Logs For**:
- CloudKit errors (CKError)
- Network errors
- Permission errors

**Common Issues**:
- Not signed into iCloud on Device B
- CloudKit entitlements missing
- Network connectivity issues
- Already accepted (trying to accept twice)

**Solutions**:
- Sign out and back into iCloud
- Reinstall app
- Check CloudKit Dashboard for share status

### **Data Not Syncing**

**Check**:
- Both devices on same iCloud account? (Should be DIFFERENT!)
- Internet connectivity on both devices?
- CloudKit sync enabled? (Check Settings)
- Background refresh enabled?

**Console Checks**:
- Look for "CloudKit sync event" logs
- Check for NSPersistentCloudKitContainer errors
- Verify store scope (Shared vs Private)

**Solutions**:
- Force refresh (pull-to-refresh)
- Close and reopen app
- Check CloudKit Dashboard for recent changes
- Verify both devices show same CloudKit environment (Development)

### **Performance Issues**

**If Sync > 5 seconds**:
- Check network speed (both devices)
- Check data size (large recipes with many ingredients?)
- Monitor CloudKit Dashboard for bottlenecks
- Review CloudKitSyncMonitor logs

---

## 📊 **AFTER TESTING COMPLETE**

### **If All Tests Pass** ✅:

**Document Results**:
1. Create learning note: `32-m7.2.2-member-invitation-testing.md`
2. Include:
   - Test results for all 5 phases
   - Sync latency measurements
   - Screenshots of key flows
   - Any edge cases discovered
   - CloudKit Dashboard observations

**Update Documentation**:
1. Mark M7.2.2 ✅ COMPLETE in `current-story.md`
2. Update `next-prompt.md` for M7.3 (Conflict Resolution)
3. Add actual hours to progress tracking (estimate: 2-3h)
4. Update `project-index.md` recent activity

**Git Workflow**:
```bash
# If on feature branch
git checkout main
git pull origin main

# Merge M7.2.2 branch (if you made any test fixes)
git merge feature/M7.2.2-member-invitation --squash
git commit -m "M7.2.2: Member Invitation & Acceptance - Testing COMPLETE

✅ Acceptance Criteria:
- Invitation sent and received successfully
- AcceptInvitationSheet worked perfectly
- Both users appear in Members list
- Bi-directional sync < 5s latency
- All 4 sync tests passed
- Zero data loss or duplication

📊 Metrics:
- Estimated: 2-3 hours
- Actual: X.X hours (XX% accuracy)

🧪 Test Environment:
- Device A: [iPhone model, iOS version]
- Device B: [iPhone model, iOS version]
- Network: [WiFi/Cellular]
- Average sync latency: X.X seconds"

git push
```

### **Ready for M7.3**:
- **M7.3**: Conflict Resolution & Error Handling (4-6h)
  - M7.3.1: Conflict Resolution Policies (2-3h)
  - M7.3.2: Error Handling & Recovery (2-3h)

---

### **If Tests Fail** ❌:

**Document Failures**:
1. Note which phase failed
2. Capture error messages from console
3. Screenshot error states
4. Note CloudKit Dashboard state

**Debug Process**:
1. Review M7.2.2 implementation code
2. Check CloudKit entitlements
3. Verify Core Data relationships
4. Test in CloudKit Development environment first

**Get Help**:
- Review Apple's CKShare documentation
- Check CloudKit Console for detailed errors
- Test with simpler household (fewer data items)
- Verify M7.2.3 migration was successful

---

## 🎯 **TESTING TIPS**

**Efficiency**:
- Keep both devices side-by-side during testing
- Use stopwatch to measure sync latency
- Keep Xcode console open for Device A (primary development device)
- Take screenshots at key steps for documentation

**Data Management**:
- Create test data that's easy to identify (prefix with "Test")
- Use distinctive names for sync testing ("Sync Test Recipe A")
- Delete test data after testing (or keep for M7.3)

**Time Management**:
- Phase 1-2: 45 minutes (setup + invitation)
- Phase 3: 30 minutes (acceptance)
- Phase 4: 45 minutes (sync validation - the meaty part)
- Phase 5: 15 minutes (members view)
- **Total**: ~2.5 hours if everything works smoothly

**Safety**:
- Test in CloudKit Development environment
- Don't test with production data
- Keep backups of important recipes/lists
- Can always delete household and start over

---

**Version**: January 4, 2026 - M7.2.2 Testing Ready  
**Status**: 🧪 M7.2.3 complete, M7.2.2 code ready, awaiting physical device testing  
**Branch**: `feature/M7.2.2-member-invitation` (verify exists before starting)  
**Requirements**: 2 physical iPhones with different iCloud accounts

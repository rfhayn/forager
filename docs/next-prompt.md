# Next Implementation Prompt

**Last Updated**: February 3, 2026
**For Milestone**: M7.3.3 - Remove Member & Delete Household
**Status**: ✅ **COMPLETE** - All features implemented and tested
**Prerequisites**: M7.2.2 merged to main ✅
**Branch**: `feature/M7.3.3-remove-member-delete-household` (ready to merge)

---

## **M7.3.3 - REMOVE MEMBER & DELETE HOUSEHOLD**

**Goal**: Owner can remove members and delete the entire household with proper data handling.

**What Already Exists (from M7.2.2)**:
- `deleteCKShareFromSharedDatabase()` - CKShare deletion pattern
- `purgeAllSharedStoreObjects(from:)` - Shared store cleanup helper
- `destroyAndRecreateSharedStore()` - Nuclear shared store cleanup
- `migrateHouseholdDataToPersonal()` - Full data migration with dedup
- `HouseholdMembersView` - Displays participants from CKShare
- Leave confirmation alert pattern in SettingsView (reusable for delete)

---

## **COMPLETED** ✅

**Household Protection** (prevents multi-household state):
- `alreadyInHousehold` error case in HouseholdError
- Protection in `createHouseholdAndShare()` and `checkForAcceptedInvitations()`
- SceneDelegate rejects share invitation when already in household
- `cloudKitShareRejectedAlreadyInHousehold` notification

**Diagnostics**:
- `dumpCategorySyncDiagnostics()` for troubleshooting sync issues
- "Category Sync Diagnostic" button in Settings (DEBUG only)

**Deprecated API Cleanup**:
- Removed `userDiscoverability` permission code (~75 lines)
- Fixed `rootRecordID` → `hierarchicalRootRecordID`

---

## **IMPLEMENTATION PLAN** (Remaining)

### **Feature 1: Owner Removes Member** (Low Complexity)

**Service**: `removeMember()` in HouseholdService
- Fetch CKShare for household via `getShare(for:)`
- Call `share.removeParticipant(participant)` (owner HAS permission)
- Save the share via `CKModifyRecordsOperation`
- Delete the corresponding HouseholdMember entity
- Save context

**UI**: Button or swipe-to-delete in HouseholdMembersView
- Only visible for owner
- Confirmation alert before removal
- Cannot remove self (owner)

### **Feature 2: Owner Deletes Household** (Medium Complexity)

**Service**: `deleteHousehold()` in HouseholdService
1. Migrate owner's data to personal (reuse `migrateHouseholdDataToPersonal()`)
2. Delete the CKShare (removes all participants' access)
3. Purge shared store objects (reuse `purgeAllSharedStoreObjects(from:)`)
4. Destroy and recreate shared store
5. Clear `currentHousehold`

**UI**: "Delete Household" button in Settings (Household section)
- Red destructive button
- Two-step confirmation: "This will remove all members and delete shared data"
- Option to migrate data first
- Loading indicator during deletion

### **Feature 3: Removed Member Detection** (Low Complexity)

**Behavior**: When a member is removed by the owner, their next sync should detect the change.
- `loadCurrentHousehold()` already handles missing/invalid household state
- On next app launch, if CKShare no longer includes user, household clears automatically
- No additional code likely needed (verify during testing)

---

## **ACCEPTANCE CRITERIA**

**Owner Removes Member**:
- [ ] Owner sees "Remove" option for each non-owner member
- [ ] Confirmation alert before removal
- [ ] Member removed from CKShare.participants
- [ ] HouseholdMember entity deleted
- [ ] Member's next sync shows them as household-less

**Owner Deletes Household**:
- [ ] "Delete Household" button visible only for owner
- [ ] Two-step confirmation dialog
- [ ] Owner's data migrated to personal before deletion
- [ ] CKShare deleted (all members lose access)
- [ ] Shared store purged and recreated
- [ ] Owner returns to "no household" state
- [ ] Members detect household deletion on next sync

**General**:
- [ ] Clean build
- [ ] No regressions to existing leave flow
- [ ] Confirmation alerts for all destructive actions

---

## **GIT WORKFLOW**

```bash
git checkout main && git pull origin main
git checkout -b feature/M7.3.3-remove-member-delete-household
git push -u origin feature/M7.3.3-remove-member-delete-household
```

---

**Version**: February 3, 2026 - M7.3.3 Complete
**Status**: ✅ All features implemented
**Estimated Complexity**: Low-Medium (completed as planned)

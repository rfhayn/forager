# Next Implementation Prompt

**Last Updated**: January 13, 2026
**For Milestone**: M7.3.2 - Leave Household
**Status**: 🚀 **READY TO IMPLEMENT**
**Estimated Duration**: 1-2 hours
**Prerequisites**: M7.3.1 Complete ✅

---

## 🎯 **M7.3.2 - LEAVE HOUSEHOLD**

**Goal**: Allow household members to leave a household with optional data export and graceful local data preservation.

**Current State**:
- ✅ M7.3.1 COMPLETE - Rename household working
- 🚀 M7.3.2 READY - Leave household with data export
- 📍 Branch: Create `feature/M7.3.2-leave-household`

**What to Build**:
- Service method: `leaveHousehold(_:exportData:)`
- UI: Leave button in Settings with confirmation alert
- Optional: Export household data to JSON before leaving
- Local data: Preserve read-only copies after leaving

**Why This Next**: Second simplest M7.3 phase (1-2h), establishes member exit pattern before more complex features (remove member, delete household).

---

## 📋 **IMPLEMENTATION CHECKLIST**

### **Step 1: Git Branch** (2 min)

```bash
# Create feature branch
git checkout main
git pull origin main
git checkout -b feature/M7.3.2-leave-household

# Verify clean state
git status
```

---

### **Step 2: Service Method** (30-45 min)

**File**: `Services/HouseholdService.swift`

**Add Method**:
```swift
/// M7.3.2: Allows a member to leave a household
/// - Parameters:
///   - household: The household to leave
///   - exportData: Whether to export household data before leaving
/// - Returns: Optional JSON data if exportData is true
/// - Throws: HouseholdError if user is owner or not a member
func leaveHousehold(_ household: Household, exportData: Bool) async throws -> Data? {
    // Get current user's email/identifier
    let currentEmail = try await getCurrentUserEmail()

    // Find current user's member record
    guard let currentMember = household.memberArray.first(where: { $0.email == currentEmail }) else {
        throw HouseholdError.notMember
    }

    // Prevent owner from leaving (must delete household instead)
    guard !currentMember.isOwner else {
        throw HouseholdError.ownerCannotLeave
    }

    // Optional: Export data before leaving
    var exportedData: Data?
    if exportData {
        exportedData = try await exportHouseholdData(household)
    }

    // Remove member from household
    viewContext.delete(currentMember)

    // Note: Household data remains in shared store as read-only
    // CloudKit will automatically stop syncing updates after member is removed

    // Save changes
    try viewContext.save()

    // Clear current household
    currentHousehold = nil

    print("✅ M7.3.2: Left household: \(household.name ?? "Unknown")")
    print("   Data exported: \(exportData)")

    return exportedData
}

/// M7.3.2: Exports household data to JSON
/// - Parameter household: The household to export
/// - Returns: JSON data containing all household recipes, lists, and meal plans
private func exportHouseholdData(_ household: Household) async throws -> Data {
    // Create export dictionary
    var exportDict: [String: Any] = [:]

    // Add household metadata
    exportDict["householdName"] = household.name ?? "Unnamed Household"
    exportDict["exportDate"] = ISO8601DateFormatter().string(from: Date())

    // Export recipes
    let recipes = household.recipeArray.map { recipe in
        [
            "name": recipe.name ?? "",
            "servings": recipe.servings,
            "instructions": recipe.instructions ?? "",
            "ingredients": recipe.ingredientArray.map { ingredient in
                [
                    "name": ingredient.name ?? "",
                    "quantity": ingredient.quantity ?? ""
                ]
            }
        ]
    }
    exportDict["recipes"] = recipes

    // Export weekly lists
    let lists = household.weeklyListArray.map { list in
        [
            "name": list.name ?? "",
            "createdDate": ISO8601DateFormatter().string(from: list.createdDate ?? Date())
        ]
    }
    exportDict["weeklyLists"] = lists

    // Export meal plans
    let mealPlans = household.mealPlanArray.map { plan in
        [
            "name": plan.name ?? "",
            "startDate": ISO8601DateFormatter().string(from: plan.startDate ?? Date())
        ]
    }
    exportDict["mealPlans"] = mealPlans

    // Convert to JSON
    let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)

    print("✅ Exported \(recipes.count) recipes, \(lists.count) lists, \(mealPlans.count) meal plans")

    return jsonData
}
```

**Add Error Cases** (to existing `HouseholdError` enum):
```swift
enum HouseholdError: LocalizedError {
    // ... existing cases ...
    case notMember
    case ownerCannotLeave

    var errorDescription: String? {
        switch self {
        case .notMember:
            return "You are not a member of this household"
        case .ownerCannotLeave:
            return "Owners cannot leave. Delete the household instead."
        // ... other cases ...
        }
    }
}
```

---

### **Step 3: UI Implementation** (30-45 min)

**File**: `Views/Settings/SettingsView.swift`

**Add State Variables**:
```swift
// M7.3.2: Leave household state
@State private var showLeaveConfirmation = false
@State private var showExportOption = false
@State private var shouldExportData = false
@State private var exportedDataURL: URL?
@State private var showShareSheet = false
```

**Add Leave Button** (in household section, after Invite Member button):
```swift
// M7.3.2: Leave Household button (non-owners only)
if !isCurrentUserOwner {
    Button(action: {
        showLeaveConfirmation = true
    }) {
        HStack {
            Image(systemName: "rectangle.portrait.and.arrow.right")
            Text("Leave Household")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red.opacity(0.1))
        .foregroundColor(.red)
        .cornerRadius(10)
    }
    .padding(.top, 8)
}
```

**Add Confirmation Alert**:
```swift
.alert("Leave Household?", isPresented: $showLeaveConfirmation) {
    Button("Export & Leave", role: .destructive) {
        shouldExportData = true
        leaveHousehold(household)
    }
    Button("Leave Without Export", role: .destructive) {
        shouldExportData = false
        leaveHousehold(household)
    }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("You will lose access to shared data. Local copies will remain read-only. Optionally export data first.")
}
```

**Add Leave Method** (in Helper Methods):
```swift
// M7.3.2: Leaves household with optional data export
private func leaveHousehold(_ household: Household) {
    Task {
        do {
            let exportedData = try await householdService.leaveHousehold(
                household,
                exportData: shouldExportData
            )

            // If data was exported, save to temporary file and show share sheet
            if let data = exportedData {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("household-export-\(Date().timeIntervalSince1970).json")
                try data.write(to: tempURL)
                exportedDataURL = tempURL
                showShareSheet = true
            }

            // Refresh household to trigger UI update
            await householdService.loadCurrentHousehold()

        } catch {
            // Show error alert
            print("❌ Error leaving household: \(error)")
        }
    }
}
```

**Add Share Sheet** (in body):
```swift
.sheet(isPresented: $showShareSheet) {
    if let url = exportedDataURL {
        ActivityViewController(activityItems: [url])
    }
}
```

**Add ActivityViewController** (at bottom of file):
```swift
// M7.3.2: UIActivityViewController wrapper for sharing exported data
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
```

---

### **Step 4: Testing** (15-30 min)

**Build and Run**:
```bash
# Build app
Cmd+B

# Run on simulator or device
Cmd+R
```

**Manual Test**:
1. Navigate to Settings → Household
2. As non-owner member: Verify "Leave Household" button appears (red)
3. Tap "Leave Household"
4. Test "Export & Leave":
   - Should show share sheet with JSON file
   - Share to Files app or Mail
   - Verify JSON contains recipes, lists, meal plans
5. Test "Leave Without Export":
   - Should leave immediately without export
6. Verify:
   - Current household cleared
   - Settings shows "Create Household" button again
   - Shared data still visible but read-only (can't edit)

**Multi-Device Test** (if 2 devices available):
1. Device B (Member): Leave household
2. Wait 5 seconds
3. Device A (Owner): Navigate to Settings → Household → Members
4. Verify member no longer listed

---

## ✅ **ACCEPTANCE CRITERIA**

**Functionality**:
- ✅ Non-owner members can leave household
- ✅ Leave confirmation alert with two options
- ✅ "Export & Leave" exports JSON and shows share sheet
- ✅ "Leave Without Export" leaves immediately
- ✅ Owner cannot leave (button hidden or disabled)
- ✅ Current household cleared after leaving

**Data Export**:
- ✅ JSON includes recipes, lists, meal plans
- ✅ Share sheet allows saving to Files, Mail, etc.
- ✅ Exported filename includes timestamp

**Data Preservation**:
- ✅ Local copies of shared data remain read-only
- ✅ No data loss from leaving
- ✅ Can rejoin later if invited again

**Error Handling**:
- ✅ Owner attempting to leave shows clear error
- ✅ Network errors handled gracefully
- ✅ Export failures don't prevent leaving

**UX**:
- ✅ Red "Leave Household" button clearly destructive
- ✅ Confirmation alert prevents accidental leaving
- ✅ Clear messaging about data preservation
- ✅ No crashes or UI glitches

---

## 🐛 **TROUBLESHOOTING**

**Error: "Owners cannot leave"**
- Check: User is actually a member, not owner
- Fix: Owners must delete household instead (M7.3.3)

**Export Not Working**
- Check: Data actually exists in household
- Verify: JSON serialization succeeds
- Check logs: "Exported X recipes, Y lists, Z meal plans"

**Share Sheet Not Showing**
- Verify: exportedDataURL is set
- Check: File written to temp directory successfully
- Try: Re-run with fresh data export

**UI Not Updating After Leaving**
- Call `await householdService.loadCurrentHousehold()`
- Verify: currentHousehold set to nil
- Check: View observing householdService changes

---

## 📊 **AFTER COMPLETION**

### **Git Commit**:

```bash
# Stage changes
git add Services/HouseholdService.swift
git add forager/SettingsView.swift

# Commit with message
git commit -m "M7.3.2: Add leave household functionality

- HouseholdService.leaveHousehold(_:exportData:) method
- exportHouseholdData() for JSON export
- Leave button in Settings (non-owners only)
- Export & Leave vs Leave Without Export options
- ActivityViewController for share sheet integration
- Local data preserved as read-only after leaving

Acceptance criteria met:
✅ Non-owner members can leave household
✅ Optional JSON data export with share sheet
✅ Owner cannot leave (must delete instead)
✅ Current household cleared after leaving
✅ Local data preserved read-only

Tested on:
- Simulator (validation, export)
- Device A (Owner): Member removed from list
- Device B (Member): Leave successful, data exported

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Push to GitHub
git push -u origin feature/M7.3.2-leave-household

# Merge to main (after testing)
git checkout main
git merge --squash feature/M7.3.2-leave-household
git commit -m "M7.3.2: Leave household with data export complete"
git push origin main
git branch -d feature/M7.3.2-leave-household
git push origin --delete feature/M7.3.2-leave-household
```

### **Update Documentation**:

1. **current-story.md**:
   - Mark M7.3.2 ✅ COMPLETE
   - Update to M7.3.3 (Remove Member & Delete Household) as next
   - Add actual time (1-2h estimated)

2. **next-prompt.md**:
   - Replace with M7.3.3 content
   - Remove member and delete household features (2-3h)

3. **project-index.md** (optional):
   - Add M7.3.2 to recent activity if significant

---

## 🚀 **NEXT: M7.3.3 - REMOVE MEMBER & DELETE HOUSEHOLD**

**After M7.3.2 complete, next is**:

**M7.3.3: Remove Member & Delete Household** (2-3 hours)
- Owners can remove members from household
- Owners can delete households entirely
- Data migration from shared → private zone on delete
- Confirmation alerts for destructive actions

**Time Estimate**: 2-3 hours (most complex M7.3 phase)

---

**Version**: January 13, 2026 - M7.3.2 Ready to Implement
**Status**: 🚀 Ready to start
**Branch**: Create `feature/M7.3.2-leave-household` before starting
**Estimated Time**: 1-2 hours
**Confidence**: 🟢 HIGH (Well-defined scope, similar to M7.3.1 patterns)

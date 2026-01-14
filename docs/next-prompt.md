# Next Implementation Prompt

**Last Updated**: January 13, 2026
**For Milestone**: M7.3.1 - Rename Household
**Status**: 🚀 **READY TO IMPLEMENT**
**Estimated Duration**: 30 minutes
**Prerequisites**: M7.2.2 Complete ✅, M7.2.3 Complete ✅

---

## 🎯 **M7.3.1 - RENAME HOUSEHOLD**

**Goal**: Allow household owners to rename their household with automatic CloudKit sync to all members.

**Current State**:
- ✅ M7.2.2 COMPLETE - Member invitation working
- ✅ M7.2.3 COMPLETE - Dual-store architecture operational
- 🚀 M7.3.1 READY - Simple 30-minute feature
- 📍 Branch: Create `feature/M7.3.1-rename-household`

**What to Build**:
- Service method: `renameHousehold(_:to:)`
- UI: Inline text field edit in Settings → Household section
- Validation: 1-50 characters, non-empty, owner-only

**Why This First**: Simplest M7.3 phase (30 min), validates household management pattern before more complex features (leave, remove, delete).

---

## 📋 **IMPLEMENTATION CHECKLIST**

### **Step 1: Git Branch** (2 min)

```bash
# Create feature branch
git checkout main
git pull origin main
git checkout -b feature/M7.3.1-rename-household

# Verify clean state
git status
```

---

### **Step 2: Service Method** (10 min)

**File**: `Services/HouseholdService.swift`

**Add Method**:
```swift
/// Renames a household (owner-only operation)
/// - Parameters:
///   - household: The household to rename
///   - newName: The new household name (1-50 characters)
/// - Throws: HouseholdError if not owner or invalid name
func renameHousehold(_ household: Household, to newName: String) throws {
    // Verify owner
    guard household.isOwner else {
        throw HouseholdError.notOwner
    }

    // Validate name
    let trimmedName = newName.trimmingCharacters(in: .whitespaces)
    guard !trimmedName.isEmpty else {
        throw HouseholdError.emptyName
    }

    guard trimmedName.count <= 50 else {
        throw HouseholdError.nameTooLong
    }

    // Update name
    household.name = trimmedName
    try viewContext.save()

    // CloudKit syncs automatically via NSPersistentCloudKitContainer
    print("✅ Household renamed to: \(trimmedName)")
}
```

**Add Error Cases** (to existing `HouseholdError` enum):
```swift
enum HouseholdError: LocalizedError {
    // ... existing cases ...
    case notOwner
    case emptyName
    case nameTooLong

    var errorDescription: String? {
        switch self {
        case .notOwner:
            return "Only the household owner can rename the household"
        case .emptyName:
            return "Household name cannot be empty"
        case .nameTooLong:
            return "Household name must be 50 characters or less"
        // ... other cases ...
        }
    }
}
```

---

### **Step 3: UI Implementation** (15 min)

**File**: `Views/Settings/HouseholdSettingsView.swift`

**Add State Variables**:
```swift
@State private var isEditingName = false
@State private var editedName = ""
@State private var renameError: String?
```

**Update Household Name Section**:
```swift
// Replace static household name with editable version
Section {
    if let household = viewModel.currentHousehold {
        HStack {
            if isEditingName {
                // Edit mode - text field
                TextField("Household Name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        saveHouseholdName(household)
                    }

                Button("Cancel") {
                    isEditingName = false
                    renameError = nil
                }
                .foregroundColor(.gray)
            } else {
                // Display mode - tappable text
                VStack(alignment: .leading) {
                    Text(household.name ?? "Unnamed Household")
                        .font(.headline)

                    if household.isOwner {
                        Text("Tap to rename")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                if household.isOwner {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if household.isOwner && !isEditingName {
                editedName = household.name ?? ""
                isEditingName = true
            }
        }

        if let error = renameError {
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
        }
    }
} header: {
    Text("Household")
}
```

**Add Save Method**:
```swift
private func saveHouseholdName(_ household: Household) {
    do {
        try HouseholdService.shared.renameHousehold(household, to: editedName)
        isEditingName = false
        renameError = nil

        // Trigger view refresh
        viewModel.refreshHousehold()
    } catch {
        renameError = error.localizedDescription
    }
}
```

---

### **Step 3: Testing** (5 min)

**Build and Run**:
```bash
# Build app
Cmd+B

# Run on simulator or device
Cmd+R
```

**Manual Test**:
1. Navigate to Settings → Household
2. Tap household name (should enter edit mode)
3. Change name to "Test Family"
4. Tap return/done
5. Verify name updated
6. Test validation:
   - Try empty name (should show error)
   - Try 51+ character name (should show error)
7. Test non-owner (if have test member):
   - Pencil icon should not appear
   - Tap should not enter edit mode

**Multi-Device Test** (if 2 devices available):
1. Device A (Owner): Rename to "Test Household"
2. Wait 5 seconds
3. Device B (Member): Navigate to Settings → Household
4. Verify name shows "Test Household"

---

## ✅ **ACCEPTANCE CRITERIA**

**Functionality**:
- ✅ Owner can tap household name to edit
- ✅ Text field shows current name pre-filled
- ✅ Save on keyboard return
- ✅ Validation prevents empty names
- ✅ Validation prevents names > 50 characters
- ✅ Non-owners cannot edit (no pencil icon)

**CloudKit Sync**:
- ✅ Renamed household syncs to all members
- ✅ Members see new name within 5 seconds
- ✅ Sync works across multiple devices

**Error Handling**:
- ✅ Empty name shows clear error message
- ✅ Non-owner attempt prevented at UI level
- ✅ Network errors handled gracefully

**UX**:
- ✅ Edit mode visually clear
- ✅ Cancel button works correctly
- ✅ Error messages displayed inline
- ✅ No crashes or UI glitches

---

## 🐛 **TROUBLESHOOTING**

**Error: "Only the household owner can rename"**
- Check: `household.isOwner` property
- Verify: Current user is actually the owner
- Check CloudKit Dashboard: CKShare participants

**Sync Not Working**
- Verify: Both devices signed into different iCloud accounts
- Check: Internet connectivity on both devices
- Wait: Full 30 seconds for CloudKit propagation
- Check logs: Look for "Household renamed to: [name]"

**UI Not Updating**
- Call `viewModel.refreshHousehold()` after save
- Verify: View is observing household changes
- Check: Core Data context saved successfully

---

## 📊 **AFTER COMPLETION**

### **Git Commit**:

```bash
# Stage changes
git add Services/HouseholdService.swift
git add Views/Settings/HouseholdSettingsView.swift

# Commit with message
git commit -m "M7.3.1: Add rename household functionality

- HouseholdService.renameHousehold(_:to:) method
- Inline text field edit in Settings
- Validation: 1-50 characters, non-empty
- Owner-only operation with permission check
- CloudKit auto-sync to all members

Acceptance criteria met:
✅ Owner can rename household
✅ Syncs to members < 5s
✅ Validation prevents invalid names
✅ Non-owners cannot rename

Tested on:
- Simulator (validation)
- Device A (Owner): Rename success
- Device B (Member): Name synced correctly"

# Push to GitHub
git push -u origin feature/M7.3.1-rename-household

# Merge to main (after testing)
git checkout main
git merge feature/M7.3.1-rename-household
git push origin main
```

### **Update Documentation**:

1. **current-story.md**:
   - Mark M7.3.1 ✅ COMPLETE
   - Update to M7.3.2 (Leave Household) as next
   - Add actual time (should be ~30 min)

2. **next-prompt.md**:
   - Replace with M7.3.2 content
   - Leave household feature (1-2h)

3. **project-index.md** (optional):
   - Add M7.3.1 to recent activity if significant

---

## 🚀 **NEXT: M7.3.2 - LEAVE HOUSEHOLD**

**After M7.3.1 complete, next is**:

**M7.3.2: Leave Household** (1-2 hours)
- Member can leave households
- Optional data export to JSON
- Share sheet integration
- Graceful exit with local data preservation

**Time Estimate**: 1-2 hours (more complex than rename)

---

**Version**: January 13, 2026 - M7.3.1 Ready to Implement
**Status**: 🚀 Ready to start
**Branch**: Create `feature/M7.3.1-rename-household` before starting
**Estimated Time**: 30 minutes
**Confidence**: 🟢 HIGH (Simple, well-defined scope)

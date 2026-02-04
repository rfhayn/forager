# Next Implementation Prompt

**Last Updated**: February 3, 2026
**For Milestone**: M7.3.4 - Error Handling & Stability Improvements (RESCOPED)
**Status**: READY TO START
**Prerequisites**: M7.3.3 merged to main ✅
**Branch**: `feature/M7.3.4-error-handling-stability`
**PRD**: `docs/prds/active/m7.3.4-error-handling-stability.md`

---

## **M7.3.4 - ERROR HANDLING & STABILITY IMPROVEMENTS (RESCOPED)**

**Goal**: Fix architecture risks and improve debuggability for TestFlight beta.

**Why Rescoped**: External review (ChatGPT + Gemini) identified that original M7.3.4 scope (storage display, sync toggle, NWPathMonitor, exponential backoff) was unnecessary—CloudKit already handles most of it. They identified **actual architecture risks** that need fixing.

---

## **IMPLEMENTATION PLAN**

### **Phase 1: P0 Fixes (50 minutes)**

#### **ERR-001: Ghost Data Bug Fix (30 min)**

**Location**: `Services/HouseholdService.swift`, `loadCurrentHousehold()` method (~line 202)

**Problem**: If server-side leave fails but local cleanup succeeds, user can be auto-rejoined to household they tried to leave.

**Current (Buggy)**:
```swift
if hasLeftHousehold(householdID) {
    let isParticipant = await isCurrentUserParticipant(in: household)
    if isParticipant {
        // WRONG: Assumes re-join, clears flag
        clearLeftHouseholdFlag(householdID)
    }
}
```

**Fixed**:
```swift
if hasLeftHousehold(householdID) {
    let isParticipant = await isCurrentUserParticipant(in: household)
    if isParticipant {
        // M7.3.4: Don't auto-clear flag. User must explicitly re-join via new invitation.
        print("⚠️ M7.3.4: User marked as left but still participant - ignoring household")
        print("   (User must accept new invitation to rejoin)")
        continue  // Skip this household
    }
}
```

#### **ERR-002: Replace exit(0) with Check Again (20 min)**

**Location**: `forager/AcceptInvitationSheet.swift` (~line 117-126)

**Problem**: `exit(0)` is discouraged by Apple and provides poor UX on slow networks.

**Changes**:
1. Rename `showRestartAlert` → `showRetryAlert`
2. Replace "Restart Required" alert with "Still Syncing" alert
3. Add `retryCheck()` async method
4. Add `isChecking` state for loading indicator

---

### **Phase 2: P1 Technical Debt (1 hour 35 minutes)**

#### **ERR-010: CloudKitErrorMapper (30 min)**

**New File**: `Services/Persistence/CloudKitErrorMapper.swift`

Create single source of truth for CKError → user message mapping with:
- `ErrorType` enum: transient, userAction, permanent
- `MappedError` struct: userMessage, type, suggestedAction
- `map(_ error: CKError) -> MappedError`

Then update:
- `CloudKitSyncMonitor.swift` - Use CloudKitErrorMapper
- `CloudKitDiagnostics.swift` - Use CloudKitErrorMapper

#### **ERR-011: Replace Magic Numbers (20 min)**

Search codebase for raw CKError codes (3, 4, 9, 25, etc.) and replace with `CKError.Code.xxx.rawValue` or refactor to pass CKError objects directly.

#### **ERR-012: OSLog Integration (45 min)**

**New File**: `Services/Persistence/CloudKitLogger.swift`

Create structured logging using `Logger` (OSLog) for:
- Household operations (create, leave, delete, invite, remove, join)
- Share operations (create, accept, fail)
- Sync events (start, complete, fail)
- Debug/warning helpers

Then replace `print()` calls in HouseholdService with CloudKitLogger calls.

---

## **ACCEPTANCE CRITERIA**

**P0 - Must Fix**:
- [ ] Ghost data bug fixed - users can't be auto-rejoined to households they left
- [ ] No `exit(0)` anywhere in codebase
- [ ] "Check Again" button works on AcceptInvitationSheet timeout

**P1 - Should Fix**:
- [ ] Single `CloudKitErrorMapper` utility exists
- [ ] No magic numbers for CKError codes (use CKError.Code enum)
- [ ] All CloudKit operations logged via OSLog
- [ ] Logs retrievable from TestFlight devices via Console.app

---

## **FILES TO MODIFY/CREATE**

| File | Action |
|------|--------|
| `Services/HouseholdService.swift` | ERR-001 fix, logging integration |
| `forager/AcceptInvitationSheet.swift` | ERR-002 Check Again button |
| `Services/Persistence/CloudKitErrorMapper.swift` | **NEW** - ERR-010 |
| `Services/Persistence/CloudKitLogger.swift` | **NEW** - ERR-012 |
| `Services/CloudKitSyncMonitor.swift` | Use CloudKitErrorMapper |
| `Services/Persistence/CloudKitDiagnostics.swift` | Use CloudKitErrorMapper |

---

## **GIT WORKFLOW**

```bash
git checkout main && git pull origin main
git checkout -b feature/M7.3.4-error-handling-stability
git push -u origin feature/M7.3.4-error-handling-stability
```

---

## **TESTING CHECKLIST**

**Ghost Data Prevention**:
- [ ] Leave household, simulate server failure, verify user stays out on restart
- [ ] Accept new invitation after leaving, verify flag is cleared properly

**Check Again Flow**:
- [ ] Accept invitation, wait for timeout, tap "Check Again"
- [ ] Verify no exit(0) behavior anywhere

**Error Messages**:
- [ ] Verify consistent wording across all error surfaces
- [ ] No magic numbers in logs

**Logs**:
- [ ] Verify CloudKitLogger output in Console.app
- [ ] Test log retrieval from TestFlight device

---

## **EXPLICITLY DEFERRED**

These were evaluated and intentionally skipped:
- NWPathMonitor (CloudKit handles offline)
- Exponential backoff retry (risk of double operations)
- CloudKit storage display (complex, low value)
- iCloud sync toggle (breaks households)
- Event-driven share acceptance (too complex)
- CKAccountChangedNotification (low priority edge case)

---

**Version**: February 3, 2026 - M7.3.4 Rescoped
**Estimated Complexity**: Low-Medium (2.5-3 hours for P0+P1)
**Dependencies**: M7.3.3 complete ✅

# Next Implementation Prompt

**Last Updated**: February 3, 2026
**For Milestone**: M7.3.4 - Error Handling & Recovery
**Status**: 🚀 **READY TO START**
**Prerequisites**: M7.3.3 merged to main
**Branch**: `feature/M7.3.4-error-handling-recovery`

---

## **M7.3.4 - ERROR HANDLING & RECOVERY**

**Goal**: Graceful error handling for CloudKit failures with retry logic and user feedback.

**What Already Exists**:
- `HouseholdError` enum with various error cases
- `errorMessage` published property on HouseholdService
- `isLoading` state management
- CloudKitSyncMonitor for sync state tracking
- Basic error handling in existing service methods

---

## **IMPLEMENTATION PLAN**

### **Feature 1: CloudKit Error Classification** (Low Complexity)

**Service**: Add error classification helper to HouseholdService
- Classify CKError types: transient (retry) vs permanent (show error)
- Transient: `.networkUnavailable`, `.networkFailure`, `.serviceUnavailable`, `.requestRateLimited`
- Permanent: `.notAuthenticated`, `.quotaExceeded`, `.incompatibleVersion`
- User-friendly error messages for each category

```swift
private func classifyError(_ error: Error) -> (isRetryable: Bool, userMessage: String)
```

### **Feature 2: Retry Logic** (Medium Complexity)

**Service**: Add retry wrapper for CloudKit operations
- Exponential backoff: 1s, 2s, 4s (max 3 retries)
- Only retry transient errors
- Log retry attempts for debugging
- Cancel retries if user navigates away

```swift
private func withRetry<T>(
    maxAttempts: Int = 3,
    operation: () async throws -> T
) async throws -> T
```

### **Feature 3: Offline Detection** (Low Complexity)

**Service**: Network reachability monitoring
- Use `NWPathMonitor` to track connectivity
- Expose `isOffline` published property
- Queue operations when offline (optional - can defer)
- Show "Offline" indicator in UI

### **Feature 4: User-Facing Error UI** (Low Complexity)

**UI**: Error presentation in HouseholdService consumers
- Alert for permanent errors with actionable message
- Toast/banner for transient errors with "Retrying..." message
- "No internet connection" banner when offline
- Retry button for failed operations

---

## **ACCEPTANCE CRITERIA**

**Error Classification**:
- [ ] CKError types correctly classified as transient or permanent
- [ ] User-friendly messages for common error scenarios
- [ ] Error messages logged for debugging

**Retry Logic**:
- [ ] Transient errors trigger automatic retry
- [ ] Exponential backoff between retries
- [ ] Max 3 retry attempts
- [ ] Permanent errors fail immediately (no retry)

**Offline Handling**:
- [ ] Network status monitored via NWPathMonitor
- [ ] `isOffline` property exposed to UI
- [ ] Offline indicator displayed when appropriate

**User Experience**:
- [ ] Clear error messages (no technical jargon)
- [ ] "Retrying..." feedback during retry attempts
- [ ] Actionable guidance ("Check internet connection")
- [ ] No silent failures

---

## **FILES TO MODIFY**

1. `Services/HouseholdService.swift` - Error classification, retry logic
2. `Services/CloudKitSyncMonitor.swift` - Network monitoring (optional)
3. `forager/SettingsView.swift` - Error/offline UI indicators
4. `forager/HouseholdMembersView.swift` - Error handling for member operations

---

## **GIT WORKFLOW**

```bash
git checkout main && git pull origin main
git checkout -b feature/M7.3.4-error-handling-recovery
git push -u origin feature/M7.3.4-error-handling-recovery
```

---

## **REFERENCE: CKError Types**

**Transient (Retry)**:
- `.networkUnavailable` - No network
- `.networkFailure` - Network request failed
- `.serviceUnavailable` - CloudKit temporarily down
- `.requestRateLimited` - Too many requests
- `.zoneBusy` - Zone temporarily locked

**Permanent (Show Error)**:
- `.notAuthenticated` - Not signed into iCloud
- `.quotaExceeded` - iCloud storage full
- `.incompatibleVersion` - App version mismatch
- `.permissionFailure` - No permission
- `.unknownItem` - Record doesn't exist

---

**Version**: February 3, 2026 - M7.3.4 Ready
**Estimated Complexity**: Low-Medium (2-3 hours)
**Dependencies**: M7.3.3 complete ✅

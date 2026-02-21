# Learning Note 34: CloudKit Sharing & Sync Gotchas

**Milestone**: M7.6 — Pre-Launch Prep & TestFlight
**Date**: February 20, 2026
**Scope**: CKShare behavior, schema management, sync timing, multi-device gotchas

---

## Context

During M7.6 (TestFlight submission) and M7.6.8 (household sharing hardening), seven non-obvious CloudKit behaviors surfaced that aren't well-documented by Apple. These all relate to the `NSPersistentCloudKitContainer` + CKShare sharing model and would bite any developer building multi-user Core Data sync.

---

## 1. Schema Push Is Lazy, Not Eager

`NSPersistentCloudKitContainer` does NOT push schema for all entities on first launch. It pushes lazily — only when records of that type are first created.

**Consequence**: Entities with no instances (e.g., `Household` on a fresh device) won't appear in the CloudKit Console. If you deploy to Production before creating at least one record of every type, your Production schema will be incomplete.

**Fix**: Call `initializeCloudKitSchema(options: [])` once during development to force a full schema push, then remove it.

**Verification**: Run on device, check CloudKit Console — all record types should appear.

---

## 2. `cloudkit.share` Record Type Requires Manual Creation

The `cloudkit.share` record type — required for any CKShare-based sharing — is only created when `container.share()` is first called. It doesn't exist by default.

**Consequence**: If you deploy schema to Production before ever creating a share in Development, Production will be missing this type. `NSPersistentCloudKitContainer`'s mirroring delegate fails with: *"Cannot create new type cloudkit.share in production schema"*.

**Fix**: Create at least one share in the Development environment before deploying to Production.

---

## 3. `container.share()` Needs Retry Logic

`container.share()` can fail with `partialFailure` / "Failed to modify some records" on fresh installs. The reason: `NSPersistentCloudKitContainer` exports records asynchronously after `context.save()`. The record may not exist on the CloudKit server yet when `share()` runs.

**Fix**: Retry with exponential backoff (2s, 4s). The record typically syncs within 1-3 seconds.

```swift
// Simplified pattern
func shareWithRetry(objects: [NSManagedObject], maxAttempts: Int = 3) async throws {
    for attempt in 1...maxAttempts {
        do {
            try await container.share(objects, to: nil)
            return
        } catch {
            if attempt < maxAttempts {
                try await Task.sleep(for: .seconds(pow(2.0, Double(attempt))))
            } else {
                throw error
            }
        }
    }
}
```

---

## 4. Sharing Only Migrates the Root Record

`container.share([household])` only migrates the root record (`Household`) to the shared store. Child records (`HouseholdMember`) stay in the owner's private store, invisible to other participants.

**Consequence**: If you store essential cross-device data (like the owner's display name) only on child entities, other household members will never see it.

**Fix**: Store essential shared data directly on the root shared record. In Forager's case, `ownerDisplayName` was moved to the `Household` entity itself.

---

## 5. CKShare Strips Owner's Name Components

iOS 16+ strips `nameComponents` from the CKShare for the current user (owner). `share.currentUserParticipant?.userIdentity.nameComponents` returns `nil` on the owner's device.

Other participants' names may also be `nil` unless they've granted discoverability.

**Fix**: Never rely on `CKShare.participants` for display names. Store display names as explicit attributes on your data model entities.

---

## 6. Repurposing Deprecated Fields Avoids Schema Changes

CloudKit cannot delete or rename fields. But unused fields are free real estate.

In Forager, `ownerEmail` was originally stored on Household but never actually useful. Rather than adding a new `ownerDisplayName` field (which would require a schema change), we repurposed `ownerEmail` to store the display name with a computed alias:

```swift
// ownerEmail field repurposed — no CloudKit schema change
var ownerDisplayName: String? {
    get { ownerEmail }
    set { ownerEmail = newValue }
}
```

This only works when the old field's type matches and no existing data needs to be preserved.

---

## 7. CloudKit Environment Defaults to Production

`NSPersistentStoreCloudKitEnvironment` defaults to Production when not explicitly set. Debug builds typically set it to "Development," but Release builds omit it — pushing schema straight to Production.

**Consequence**: An accidental Release build on a device can push unfinished schema to Production, where it's permanent.

**Fix**: Explicitly set the environment in store description configuration. Use `#if DEBUG` to ensure Development environment in debug builds. Verify in CloudKit Console which environment you're targeting before any device run.

---

## Summary

| Gotcha | Severity | When It Bites |
|--------|----------|---------------|
| Lazy schema push | High | First Production deploy with missing record types |
| Missing `cloudkit.share` | Critical | First share attempt in Production fails permanently |
| Share timing race | Medium | Fresh installs where share() runs before sync completes |
| Root-only migration | High | Child data invisible to shared participants |
| Owner name stripped | Medium | UI shows "Unknown" for the household creator |
| Field repurposing | Low | Opportunity — saves a schema change |
| Production default | High | Accidental Release build pushes unfinished schema |

---

**Promoted from**: Insights Log entries — CloudKit/Schema (Feb 12, Feb 15), CloudKit/Timing (Feb 15), CloudKit/Sharing (Feb 15), CloudKit/Environment (Feb 12), iOS/CKShare (Feb 15)

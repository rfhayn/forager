# ADR 009: Public Link Sharing for Household Invitations

**Status**: ACTIVE - Production Solution
**Created**: January 13, 2026
**Context**: M7.2.2 Household Member Invitation
**Related**: ADR 008 (Shared Zone Architecture)

---

## Decision

Implement household member invitations using **public link sharing** (`publicPermission = .readWrite`) with UIActivityViewController, instead of private participant lists with UICloudSharingController.

---

## Context

### The Requirement

Enable household owners to invite members to shared households (ADR 008). Invited members should be able to:
1. Receive an invitation via Messages/Mail/AirDrop
2. Tap a link to open Forager
3. Accept the invitation
4. Immediately see all household data synced

### The Original Plan

Use UICloudSharingController for native contact picker and participant management:
- Select contacts from device address book
- CloudKit manages participant list
- Private sharing (`publicPermission = .none`)
- Apple's recommended approach for NSPersistentCloudKitContainer

---

## Problem

### iOS 18.x UICloudSharingController Regression

UICloudSharingController is fundamentally broken on iOS 18.x with NSPersistentCloudKitContainer:

**Symptoms:**
- Blank screen when tapping "Invite People"
- Shows "(Owner)" placeholder instead of share UI
- LaunchServices Error -54: "process may not map database"
- XPC connection failures
- Sandbox restriction errors

**Root Cause:**
- OS-level LaunchServices/XPC service communication failure
- Not fixable via entitlements or app code
- Multiple reports of UICloudSharingController flakiness with Core Data sharing
- Gemini's preparationHandler pattern was architecturally correct but didn't fix OS bug

**Impact:**
- Cannot present contact picker
- Cannot add participants to CKShare
- Blocks household invitation feature entirely

---

## Approaches Considered

### Approach 1: UICloudSharingController with PreparationHandler ❌

**Source**: Gemini AI recommendation
**Implementation**: Fetch CKShare on-demand within UICloudSharingController's security context

```swift
let controller = UICloudSharingController { _, preparationCompletionHandler in
    Task {
        let share = try await service.getShareForInvitation(household: household)
        let container = CKContainer(identifier: "iCloud.com.richhayn.forager")
        preparationCompletionHandler(share, container, nil)
    }
}
```

**Result**: FAILED with same LaunchServices Error -54
**Time Invested**: 4 hours
**Conclusion**: Correct pattern, but doesn't fix OS-level bug

---

### Approach 2: One-Time Participant URLs ❌

**Source**: ChatGPT recommendation
**Implementation**: Use CloudKit's one-time URL participant feature

```swift
let oneTimeParticipant = CKShare.Participant.oneTimeURLParticipant()
share.participants.append(oneTimeParticipant)  // ❌ participants is read-only
let url = oneTimeParticipant.invitationURL     // ❌ property doesn't exist
```

**Result**: FAILED - Build errors
- `CKShare.participants` is read-only (cannot append)
- `CKShare.Participant` has no `invitationURL` property
- ChatGPT's API doesn't exist in current iOS SDK

**Time Invested**: 2 hours
**Conclusion**: One-time participants require UICloudSharingController (unavailable)

---

### Approach 3: Public Link Sharing ✅

**Source**: Pragmatic pivot based on failed attempts
**Implementation**: Enable public sharing with UIActivityViewController

```swift
func createOneTimeInvitationURL(household: Household) async throws -> URL {
    let share = try await getShare(for: household)

    // Enable public link sharing (like Google Docs)
    if share.publicPermission == .none {
        share.publicPermission = .readWrite

        let persistentStore = persistenceController.container
            .persistentStoreCoordinator.persistentStores.first!
        try await persistenceController.container
            .persistUpdatedShare(share, in: persistentStore)
    }

    return share.url!  // URL now works for anyone
}
```

**Result**: ✅ SUCCESS
**Time Invested**: 1 hour implementation + 8 hours total troubleshooting
**Testing**: Device A successfully sent invitation via Messages, Device B joined successfully

---

## Trade-offs

### What We Lost

❌ **Native contact picker** - UICloudSharingController's nicest feature
❌ **Private participant list** - Cannot pre-approve specific email addresses
❌ **Granular permissions** - Cannot mix read-only and read-write participants
❌ **Participant management UI** - No native "Remove Person" interface

### What We Gained

✅ **Reliability** - Works consistently (no LaunchServices errors)
✅ **Native share sheet** - Messages/Mail/AirDrop/etc built-in
✅ **Simplicity** - Less code, fewer failure modes
✅ **User control** - User chooses how to share (Messages vs Mail vs AirDrop)
✅ **Maintainability** - Simple UIActivityViewController vs complex UICloudSharingController

---

## Security Model

### Public Link Sharing

**How it works:**
- Anyone with the URL can join the household
- User controls link distribution (only share with trusted people)
- Similar to: Google Docs "Anyone with link", Dropbox sharing, Notion pages

**Security boundaries:**
- ✅ Link required (not discoverable)
- ✅ iCloud authentication required (not truly "public")
- ✅ User responsibility: only share with household members
- ❌ No pre-approved participant list
- ❌ No email-based access control

### Comparison to Alternatives

**Private Sharing (unavailable due to iOS 18.x):**
- Pre-approve specific email addresses
- Granular per-person permissions
- Requires UICloudSharingController

**Family Sharing (not used):**
- Requires Apple Family Sharing setup
- All or nothing (can't exclude family members)
- Separate from household concept

---

## Implementation Details

### Key Changes

**1. HouseholdService.swift**
```swift
func createOneTimeInvitationURL(household: Household) async throws -> URL {
    let share = try await getShare(for: household)

    if share.publicPermission == .none {
        share.publicPermission = .readWrite
        let store = persistenceController.container
            .persistentStoreCoordinator.persistentStores.first!
        try await persistenceController.container
            .persistUpdatedShare(share, in: store)
    }

    return share.url!
}
```

**2. ShareSheet.swift**
```swift
struct ShareSheet: UIViewControllerRepresentable {
    let invitationURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [invitationURL],
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                print("✅ Invitation shared successfully")
            }
        }
        return controller
    }
}
```

**3. Info.plist**
```xml
<key>CKSharingSupported</key>
<true/>
```

### CloudKit Behavior

**Private Permission (original):**
- `publicPermission = .none`
- URL requires pre-approved participant
- UICloudSharingController needed to add participants
- **Unavailable on iOS 18.x**

**Public Permission (current):**
- `publicPermission = .readWrite`
- URL grants access to anyone
- Works with simple UIActivityViewController
- **Production-ready**

---

## Testing Results

### Device A (Owner): ✅ SUCCESS
- Generated invitation URL
- Shared via Messages
- UIActivityViewController worked flawlessly
- No LaunchServices errors

**Logs:**
```
✅ Fetched live CKShare from CloudKit: cloudkit.zoneshare
✅ Enabled public link sharing (readWrite)
✅ Share updated with public permissions
✅ One-time invitation URL created: https://www.icloud.com/share/0862riOyH7fY0wjkLgTjXUpHA
✅ Invitation shared successfully via com.apple.UIKit.activity.Message
```

### Device B (Member): ✅ SUCCESS
- Received invitation link via Messages
- Tapped link → Forager opened
- Accepted invitation
- All 60 household items synced (<5 seconds)
- Bi-directional sync working

---

## Future Considerations

### UICloudSharingController Retry

**When**: After iOS 18.x updates or on iOS 19+
**Why**: Best UX with contact picker and granular permissions
**How**: Test preparationHandler approach again on newer iOS
**Fallback**: Keep current public link implementation as backup

### Link Revocation

**Feature**: "Revoke Invitation Link" button
**Implementation**: Set `publicPermission = .none` on share
**UI**: Show in Settings → Household → Manage Sharing
**Priority**: Low (households are family/close friends)

> **WARNING (April 2026)**: Setting `publicPermission = .none` REMOVES all non-owner
> participants who joined via the public link. Their access depends on the public
> permission — it is not a one-time gate. Any revocation UI must check for existing
> members and warn the owner. See Known Constraints below.

### Known Constraints (Added April 2026)

1. **`publicPermission` must remain `.readWrite` while non-owner members exist.**
   Participants who joined via the public URL are "public participants" — their
   ongoing access is governed by `publicPermission`. Setting it to `.none` instantly
   revokes their access and removes them from `CKShare.participants`. This cannot
   be worked around without `UICloudSharingController` (broken on iOS 18.x) to
   promote them to private participants.

2. **Automatic invitation expiry must not revert `publicPermission`.**
   M9.30's `revertPublicPermissionIfNeeded()` was updated (April 2026) to check for
   non-owner participants before reverting. If any exist, the revert is skipped.

3. **The invitation URL remains technically valid** as long as `publicPermission = .readWrite`.
   This is acceptable because: (a) URLs are not guessable, (b) iCloud authentication
   is required, (c) the 10-member cap applies, (d) the owner can see all participants.

### Manual Email Entry

**Feature**: Type email instead of using link
**Implementation**: CKFetchShareParticipantsOperation
**Trade-off**: More complex, doesn't solve iOS 18.x issue
**Priority**: Low (current solution works well)

---

## Alternatives Rejected

### Wait for iOS 18.x Fix

**Rejected because:**
- Blocks M7 completion indefinitely
- No timeline for Apple fix
- May never be fixed (could be intentional deprecation)
- Users need feature now

### Use Separate CloudKit API

**Rejected because:**
- NSPersistentCloudKitContainer provides automatic sync
- Manual CloudKit API requires reimplementing all sync logic
- Massive complexity increase (weeks of work)
- Loses Core Data integration benefits

### Downgrade to iOS 17

**Rejected because:**
- Cannot ask users to downgrade
- Latest iOS features required for other parts of app
- Not a scalable solution

---

## Key Learnings

### Technical Learnings

1. **UICloudSharingController is fragile** - Has known issues with NSPersistentCloudKitContainer
2. **AI recommendations need verification** - APIs suggested by ChatGPT may not exist
3. **Public sharing is valid pattern** - Used by Google Docs, Dropbox, Notion, Airtable
4. **NSPersistentCloudKitContainer has limits** - Great for sync, limited for participant management
5. **Pragmatic pivots > perfect solutions** - 8h troubleshooting validated the simple approach

### Process Learnings

1. **Test on real devices** - Simulator hides LaunchServices errors
2. **Have fallback plans** - Always consider alternative approaches
3. **Sometimes "hacky" is right** - Simple solution beat complex perfect solution
4. **External validation helps** - Gemini/ChatGPT helped rule out approaches quickly

---

## Related Documentation

- **[ADR 008: Shared Zone Architecture](008-shared-zone-architecture.md)** - Foundation for household sharing
- **[M7.2.2 Implementation](../learning-notes/26-m7.2.2-public-link-sharing.md)** - Complete implementation journey
- **[M7.2.2 Completion](../learning-notes/27-m7.2.2-member-invitation-completion.md)** - Testing results
- **[M7 Complete Journey](../learning-notes/29-m7-cloudkit-household-journey.md)** - Full retrospective

---

## Decision Rationale

**Why public link sharing is the correct decision:**

1. **Works reliably** - 100% success rate in testing vs 0% with UICloudSharingController
2. **Matches use case** - Households are family/close friends (trust-based)
3. **Industry precedent** - Google Docs, Dropbox, Notion use same pattern
4. **Simple implementation** - 50 lines of code vs 200+ lines for UICloudSharingController
5. **User control** - User chooses sharing method (Messages vs Mail vs AirDrop)
6. **Maintainable** - No complex delegate callbacks or state management
7. **Future-proof** - If UICloudSharingController fixed, can add as alternative UI

**When to reconsider:**
- UICloudSharingController becomes reliable on iOS 19+
- Users request private participant lists
- Security model requires pre-approved email addresses
- Regulatory requirements demand granular access control

**Current assessment**: Public link sharing is production-ready and appropriate for household use case.

---

**Status**: ACTIVE - Production solution
**Version**: 1.0
**Last Updated**: January 13, 2026
**Next Review**: After iOS 19 release or if UICloudSharingController issues resolved

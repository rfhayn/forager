# Learning Note: CloudKit Foundation & Debugging

**Date**: December 4, 2025 (Foundation) + December 24, 2025 (Debugging)
**Milestone**: M7.1.1 + M7.1.3 Multi-Device Testing
**Duration**: 1.5h (foundation) + 4h (debugging) = 5.5h total
**Status**: ✅ COMPLETE - Production-ready CloudKit sync

---

## 🎯 Purpose

This learning note documents the **practical implementation patterns** for CloudKit + Core Data sync, including:
1. Initial CloudKit setup with NSPersistentCloudKitContainer
2. Development vs Production environment configuration
3. Multi-device sync debugging techniques
4. Race condition prevention patterns
5. CloudKit Dashboard usage

---

## 🔧 CloudKit Foundation Setup

### NSPersistentCloudKitContainer Configuration

**Change: Replace NSPersistentContainer**

```swift
import CoreData
import CloudKit  // ADDED for NSPersistentCloudKitContainer

struct PersistenceController {
    static let shared = PersistenceController()

    // M7.1.1: Changed to NSPersistentCloudKitContainer for CloudKit sync
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "forager")

        if let description = container.persistentStoreDescriptions.first {
            // M7.1.1: Enable CloudKit sync only in Release builds
            // Debug builds use local-only Core Data for fast iteration
            #if !DEBUG
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.richhayn.forager"
            )
            print("☁️ CloudKit sync enabled (Release build)")
            #else
            print("💻 Local-only Core Data (Debug build - fast iteration)")
            #endif

            // M7.1.1: Enable history tracking (required for CloudKit sync)
            description.setOption(true as NSNumber,
                                forKey: NSPersistentHistoryTrackingKey)

            // M7.1.1: Enable remote change notifications (observes CloudKit updates)
            description.setOption(true as NSNumber,
                                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
                print("🧪 In-memory store for testing")
            }
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("✅ Core Data stack loaded successfully")
        })

        // M7.1.1: Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        if !inMemory {
            performOneTimeSetup()
        }
    }
}
```

### Key Configuration Points

**1. History Tracking (Required)**
```swift
description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
```
- **Purpose**: Enables Core Data to track changes over time
- **Why needed**: CloudKit uses this to determine what needs syncing
- **Without this**: CloudKit sync won't work - changes won't be detected

**2. Remote Change Notifications (Required)**
```swift
description.setOption(true as NSNumber,
                    forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
```
- **Purpose**: Posts notifications when CloudKit receives updates from other devices
- **Why needed**: App needs to respond to changes from other devices
- **Without this**: App won't update until restart

**3. Automatic Merging (Critical)**
```swift
container.viewContext.automaticallyMergesChangesFromParent = true
container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
```
- **Purpose**: Auto-merge CloudKit updates into view context
- **Why needed**: UI updates automatically when data syncs
- **Merge policy**: Last-write-wins (simplest, works for most use cases)

---

## 🔀 Development vs Production Environments

### The #if !DEBUG Pattern (ESSENTIAL)

**Problem**: CloudKit has separate Development and Production environments
- Debug builds → Development environment
- Release builds → Production environment
- Data doesn't sync between environments
- Production schema **locks after first deployment** (immutable forever!)

**Solution**: Disable CloudKit in Debug builds for fast local development

```swift
#if !DEBUG
description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.richhayn.forager"
)
print("☁️ CloudKit sync enabled (Release build)")
#else
print("💻 Local-only Core Data (Debug build - fast iteration)")
#endif
```

**Benefits**:
- ✅ Debug builds: Instant app launch, no iCloud account needed
- ✅ Release builds: CloudKit sync enabled for testing
- ✅ No Development environment pollution with test data
- ✅ Can develop offline without issues

### Forcing Development Mode (Testing)

For Release builds during testing, force Development environment:

```swift
#if DEBUG
description.setOption("Development" as NSObject,
                    forKey: "NSPersistentStoreCloudKitEnvironment")
print("☁️ CloudKit sync enabled (DEVELOPMENT environment FORCED)")
#else
print("☁️ CloudKit sync enabled (Production environment)")
#endif
```

### Entitlements Configuration (CRITICAL)

**Critical Discovery**: Entitlements file takes precedence over code settings!

**File**: `forager/forager.entitlements`

```xml
<!-- ✅ CORRECT for Development/Testing -->
<key>aps-environment</key>
<string>development</string>

<key>com.apple.developer.icloud-container-environment</key>
<string>Development</string>

<!-- ❌ WRONG - Locks to Production, prevents schema changes -->
<key>com.apple.developer.icloud-container-environment</key>
<string>Production</string>
```

**Lesson**: Always verify entitlements match intended environment!

---

## 🐛 CloudKit Debugging Techniques

### Problem 1: Production Schema Lock

**Error:**
```
<CKError: "Invalid Arguments" (12/2006);
server message = "Cannot create new type CD_GroceryItem in production schema">
```

**Root Cause**: Entitlements file hardcoded Production environment

**Solution**:
1. Update entitlements to Development
2. Reset CloudKit Development environment in Dashboard
3. Verify code-level environment settings

**Key Learning**: Production schema is **immutable** - plan schema changes carefully before production deployment!

---

### Problem 2: CloudKit Import Race Condition

**Symptom**: App crashes with duplicate categories on second device

**Root Cause - The Race Condition**:
```
Timeline:
T=0s:   Device B starts, checks categories → 0 found
T=0.5s: Device B creates 7 default categories locally
T=1.0s: CloudKit import event fires (importing from Device A)
T=1.5s: CloudKit imports 7 categories from Device A
T=2.0s: Core Data merge → 14 total categories (7 local + 7 imported)
T=2.1s: Fatal error: Duplicate keys
```

**Solution**: CloudKit Import Observer Pattern

```swift
private func setupCloudKitImportObserver() {
    let setupKey = "M7.2.2_InitialSetupCompleted"

    guard !UserDefaults.standard.bool(forKey: setupKey) else {
        print("ℹ️ M7.2.2: Initial setup already completed, skipping observer")
        return
    }

    var observer: NSObjectProtocol?
    var timeoutWorkItem: DispatchWorkItem?

    // Helper to execute setup exactly once using serial queue
    let executeSetupOnce = {
        PersistenceController.setupQueue.async {
            // Check flag again inside serial queue (ensures only one execution)
            guard !UserDefaults.standard.bool(forKey: setupKey) else {
                print("ℹ️ M7.2.2: Setup already completed, skipping duplicate call")
                return
            }

            // Mark as completed FIRST (inside serial queue)
            UserDefaults.standard.set(true, forKey: setupKey)

            // Cancel timeout and remove observer
            timeoutWorkItem?.cancel()
            if let obs = observer {
                NotificationCenter.default.removeObserver(obs)
            }

            // Now perform setup (guaranteed to run only once)
            self.performOneTimeSetup()
        }
    }

    // Timeout work item (handles first-launch with no data to import)
    timeoutWorkItem = DispatchWorkItem {
        print("ℹ️ M7.2.2: No CloudKit import detected after 3s, proceeding with setup...")
        executeSetupOnce()
    }

    // Observer for CloudKit import completion
    observer = NotificationCenter.default.addObserver(
        forName: NSPersistentCloudKitContainer.eventChangedNotification,
        object: container,
        queue: .main
    ) { notification in
        if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
            as? NSPersistentCloudKitContainer.Event,
           event.type == .import {

            if event.endDate != nil {
                print("ℹ️ M7.2.2: Initial CloudKit import completed, proceeding with setup...")
                executeSetupOnce()
            }
        }
    }

    // Schedule timeout
    if let workItem = timeoutWorkItem {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }
}
```

**Why This Approach**:
- **Observer**: Waits for CloudKit import to complete
- **Timeout**: Handles first-launch (nothing to import)
- **Serial Queue**: Prevents race condition between observer and timeout
- **UserDefaults**: Persists across app restarts (PersistenceController is struct)

---

### Problem 3: Observer/Timeout Race Condition

**Symptom**: Still getting duplicates even with observer!

**Root Cause - Second Race Condition**:
```swift
T=0s:    Observer registered, 3-second timeout scheduled
T=2.9s:  Both guards pass (flag still false)
T=3.0s:  Timeout sets flag=true, calls performOneTimeSetup()
T=3.1s:  Observer fires, guard passed earlier, calls performOneTimeSetup() AGAIN! 💥
```

**Solution**: Serial Queue Synchronization

```swift
struct PersistenceController {
    static let shared = PersistenceController()

    // M7.2.2: Serial queue for synchronizing one-time setup
    private static let setupQueue = DispatchQueue(label: "com.forager.setup", qos: .userInitiated)
}

// In observer/timeout:
let executeSetupOnce = {
    PersistenceController.setupQueue.async {  // ← Serial queue
        guard !flag else { return }  // ← Checked inside queue
        UserDefaults.set(true, forKey: setupKey)  // ← Atomic with check
        performOneTimeSetup()  // ← Guaranteed only once
    }
}
```

**How Serial Queue Fixes It**:
- Serial queue executes tasks one at a time
- First caller: Sets flag, runs setup ✅
- Second caller: Sees flag=true, returns immediately ✅
- **No race condition possible!**

---

## 🏗️ Race Condition Prevention Patterns

### ❌ Bad: Check-Then-Act (Race Condition)
```swift
guard !flag else { return }
setFlag(true)
doWork()
```
**Problem**: Both paths can check flag at almost same time, both see `false`, both proceed.

### ✅ Good: Serial Queue Synchronization
```swift
serialQueue.async {
    guard !flag else { return }  // ← Atomic with next line
    setFlag(true)
    doWork()
}
```
**Solution**: Serial queue ensures only one task executes at a time.

### ✅ Better: DispatchWorkItem for Cancellation
```swift
let workItem = DispatchWorkItem {
    serialQueue.async {
        guard !flag else { return }
        setFlag(true)
        doWork()
    }
}

// Can cancel if needed
workItem.cancel()
```
**Benefit**: Can cancel timeout if observer fires first.

---

## 📊 CloudKit Dashboard Usage

### Accessing Dashboard
**URL**: https://icloud.developer.apple.com/dashboard

**Key Sections**:
- **Schema → Record Types**: View auto-generated entity types
- **Data → Records**: View actual synced data
- **Logs**: View sync activity (RecordSave, DatabaseChanges)
- **Environment Switcher**: Toggle between Development and Production

### Verification Process
1. Select container (iCloud.com.richhayn.forager)
2. Switch to Development environment
3. Schema tab → confirm record types present (e.g., CD_Category, CD_Recipe)
4. Logs tab → confirm RecordSave activity

### CloudKit Record Type Names
**Pattern**: CloudKit prefixes Core Data entities with "CD_"

**Examples**:
- Core Data: `Category` → CloudKit: `CD_Category`
- Core Data: `GroceryItem` → CloudKit: `CD_GroceryListItem`
- Core Data: `PlannedMeal` → CloudKit: `CD_PlannedMeal`

### Resetting Development Environment
**When needed**:
- Schema changes during development
- Testing clean installs
- Clearing test data

**How**:
1. CloudKit Dashboard → Development environment
2. Schema → Reset Development Environment
3. Confirm reset
4. Reinstall app on all test devices

**Warning**: Deletes ALL data in Development environment!

---

## 📱 Release Build Distribution (Testing)

### Process for Testing CloudKit Sync

**Why necessary**: Debug builds have CloudKit disabled (#if !DEBUG wrapper)

**Steps**:
1. Edit Scheme → Change Build Configuration to Release
2. Product → Archive
3. Distribute App → Debugging (for connected device)
4. Export .ipa file
5. Install via Finder: Drag .ipa onto iPhone in Finder sidebar

**Alternative**: Could create separate "CloudKit Debug" build configuration, but adds complexity.

---

## 🧪 Multi-Device Testing Requirements

### Minimum Setup
- 2 physical devices (simulator doesn't test CloudKit properly)
- Both signed in to same iCloud account
- CloudKit Development environment (can reset as needed)
- Clean app installs (delete apps to clear UserDefaults)

### Testing Checklist
- [ ] Fresh install on both devices
- [ ] Device A launches first (creates data)
- [ ] Device B launches second (syncs data)
- [ ] Verify no duplicates created
- [ ] Test bi-directional sync
- [ ] Measure sync latency (<5s target)
- [ ] Test offline → online scenarios

---

## 🎓 Key Learnings

### 1. NSPersistentCloudKitContainer is API-Compatible
**Discovery**: It's a **subclass** of NSPersistentContainer

**Implications**:
- ✅ No changes needed to views (same .viewContext access)
- ✅ No changes needed to services (same NSManagedObjectContext)
- ✅ No changes needed to @FetchRequest declarations
- ✅ Preview contexts continue working (in-memory stores don't sync)

**Why This Matters**: LOW-RISK change despite touching core infrastructure.

---

### 2. CloudKit Schema Auto-Generation is Powerful
**What Happened**: Simply changing container type triggered automatic schema generation

**Schema Created**:
- All Core Data entities automatically mirrored to CloudKit
- Relationships preserved
- Attributes mapped to CloudKit field types
- Indexes created automatically

**No Manual Work Required**: CloudKit automatically mirrors Core Data schema.

---

### 3. CloudKit Sync Flow (Critical Understanding)
```
App Launch → Core Data Init → CloudKit Import (Background)
     ↓
NSPersistentCloudKitContainer.eventChangedNotification
     ↓
Event Type: .import → Event Completion (endDate != nil)
     ↓
automaticallyMergesChangesFromParent → UI Updates
```

**Critical**: Import happens AFTER app initialization. Must wait for import before checking data existence.

---

### 4. PersistenceController Architecture (Struct vs Class)
```swift
struct PersistenceController {  // ← STRUCT, not class!
    static let shared = PersistenceController()

    // ✅ CAN use static properties
    private static let setupQueue = DispatchQueue(...)

    // ❌ CANNOT use instance properties in closures
    // Must use UserDefaults or static storage
}
```

**Limitations**:
- Structs cannot use `[weak self]` in closures
- Instance properties not accessible in async closures
- Use UserDefaults for persistent state
- Use static properties for synchronization

---

### 5. Environment Configuration is Critical

**Precedence**: Entitlements File > Code-Level Settings

**Always verify**:
1. Entitlements file matches intended environment
2. Code-level environment settings correct
3. CloudKit Dashboard shows correct environment
4. Console logs confirm environment

---

## ⚠️ Common Pitfalls

### 1. Production Schema Lock
- Production schema is immutable
- Plan schema changes before production deployment
- Use Development environment for testing

### 2. Entitlements File
- Easy to forget, hard to debug
- Takes precedence over code settings
- Verify before every release

### 3. Observer Memory Leaks
- Always remove observers when done
- Store observer reference for cleanup
- Use DispatchWorkItem for cancellable timeouts

### 4. UserDefaults Persistence
- Persists across reinstalls (unless device fully reset)
- Use unique keys with milestone prefixes
- Document one-time flags clearly

### 5. Sample Data Pollution
- Don't create fake staples/templates in production
- Keep sample data for SwiftUI previews only
- Users should start with clean slate

---

## 📈 Performance Observations

### Build Times
- Clean build (Debug): ~30 seconds
- Archive (Release): ~2 minutes
- No performance degradation from CloudKit container change

### App Launch
- Debug build: <2 seconds (local Core Data)
- Release build: <3 seconds (CloudKit initialization)
- No noticeable difference to user

### Sync Latency
- Initial schema generation: <60 seconds after first launch
- Data sync: <5 seconds average
- CloudKit Dashboard updates: Near real-time in Development environment

---

## ✅ Success Metrics

When CloudKit foundation is correctly implemented:

- ✅ Build succeeds with zero errors/warnings
- ✅ App launches on simulator (Debug mode)
- ✅ App launches on physical device (Release mode)
- ✅ CloudKit Dashboard shows record types
- ✅ CloudKit logs show sync events
- ✅ Multi-device sync works (<5s latency)
- ✅ Zero duplicate data created
- ✅ Zero data loss
- ✅ Offline → online sync works

---

## 📚 Related Documentation

- **[ADR 008: Shared Zone Architecture](../architecture/008-shared-zone-architecture.md)** - Overall CloudKit strategy
- **[M7.1.1 CloudKit Schema Validation](22-m7.1.1-cloudkit-schema-validation.md)** - Original foundation setup
- **[Session Startup Checklist](../session-startup-checklist.md)** - Always read before sessions

---

**Status**: ✅ Production-ready patterns
**Version**: 1.0
**Last Updated**: January 13, 2026
**Key Lesson**: CloudKit foundation setup is straightforward, but debugging multi-device sync requires understanding async import flow and race condition prevention.

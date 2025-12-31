# Next Implementation Prompt

**Last Updated**: December 31, 2025  
**For Milestone**: M7.2.2 - Member Invitation & Acceptance  
**Status**: 🚀 READY TO START  
**Estimated Duration**: 2-3 hours

---

## 🎯 **CONTEXT: WHERE WE LEFT OFF**

### **M7.2.3 Phase 3.8 COMPLETE - CategoryDeduplicator**

We just completed the duplicate category prevention solution using the **dedupe-after-creation** pattern:

**What Works:**
- ✅ Multi-device CloudKit sync perfect (<5s latency)
- ✅ Automatic deduplication after sync events
- ✅ Self-healing system (converges to 7 categories)
- ✅ Production-ready CloudKit integration
- ✅ Zero data loss, zero crashes

**Test Results:**
- Both devices seeded simultaneously (11s apart)
- Deduplicator detected 7 duplicates per device
- Kept oldest versions, deleted newest
- System converged in ~60 seconds total
- Final state: Exactly 7 categories on both devices ✅

**Architecture:**
1. DefaultSeeder - Simplified (removed KV Store coordination)
2. CategoryDeduplicator - New service (182 lines)
3. CloudKitSyncMonitor - Enhanced (auto-dedupe after sync)

---

## 🚀 **NEXT: M7.2.2 - Member Invitation & Acceptance**

### **Objective**
Implement UICloudSharingController for household member invitations and acceptance flows.

### **What We're Building**

**User Flow:**
1. Owner goes to Settings → Household
2. Owner taps "Invite Member"
3. UICloudSharingController shows
4. Owner sends invitation via Messages/Email/AirDrop
5. Recipient receives CloudKit share invitation
6. Recipient taps link → App opens → Auto-accepts
7. Recipient's data syncs automatically

### **Technical Implementation**

**M7.2.2 has 4 tasks:**

#### **Task 1: UICloudSharingController Integration (45-60 min)**
- Add `UIViewControllerRepresentable` wrapper
- Present sharing controller from Settings
- Configure share options (read/write permissions)
- Handle share completion/cancellation

#### **Task 2: Invitation Acceptance Flow (45-60 min)**
- Handle CloudKit share URL in SceneDelegate
- Auto-accept share programmatically
- Create HouseholdMember record for new member
- Sync member list across devices

#### **Task 3: Member List UI (30-45 min)**
- Show household members in Settings
- Display member status (active/pending)
- Owner can remove members
- Member can leave household

#### **Task 4: Testing (30-45 min)**
- Test invitation send/receive
- Verify member data sync
- Test remove member flow
- Test leave household flow

---

## 📋 **READY TO START?**

### **Prerequisites Met:**
- ✅ M7.2.1 Complete (Household entities exist)
- ✅ M7.2.3 Phase 3.8 Complete (CloudKit sync proven)
- ✅ Multi-device testing environment ready
- ✅ 2 physical devices available (iPhone + iPad)
- ✅ Both devices signed into same iCloud account

### **Next Session Startup:**

**When starting next session, use this prompt:**

```
I'm ready to start M7.2.2 - Member Invitation & Acceptance.

I've completed the mandatory startup sequence:
✅ Read session-startup-checklist.md
✅ Read project-naming-standards.md  
✅ Read current-story.md (M7.2.3 Phase 3.8 complete)
✅ Read next-prompt.md (this file)

Current state:
- CloudKit multi-device sync working perfectly
- CategoryDeduplicator auto-removes duplicates
- 2 physical devices ready for testing (iPhone + iPad)
- Both devices on same iCloud account

Let's start M7.2.2 Task 1: UICloudSharingController integration.

I want to implement the UIViewControllerRepresentable wrapper
and present it from Settings → Household.
```

---

## 🎓 **IMPORTANT NOTES FOR NEXT SESSION**

### **CloudKit Share vs Shared Zone**
We're using **CloudKit Shared Zones** (household database), NOT CKShare per-item sharing. The UICloudSharingController will:
- Create a share for the household's shared zone
- Allow members to access ALL household data automatically
- Not require per-recipe or per-item sharing

### **Current Branch**
We're on: `feature/M7.2.3-phase3.8-dedupe` (or similar)

Before starting M7.2.2:
1. Commit current work
2. Create PR and merge to main
3. Create new branch: `feature/M7.2.2-member-invitation`

### **Key Files to Review**
- `Services/HouseholdService.swift` - Has placeholder invitation methods
- `forager/SettingsView.swift` - Where we'll add "Invite Member" button
- `Services/CloudKitSyncMonitor.swift` - Already monitoring sync events

### **Testing Requirements**
- 2 physical devices (simulator doesn't support CloudKit sharing)
- Different iCloud accounts (or Family Sharing)
- Real CloudKit environment (Development OK, Production for final test)

---

## 📊 **ESTIMATED COMPLETION**

**M7.2.2**: 2-3 hours  
**M7.2.3**: 1-2 hours (sync validation, mostly done!)  
**M7.2.4**: 1-2 hours (household management UI)  

**Total to complete M7.2**: 4-7 hours

**Then M7.6 (External TestFlight)**: 2-3 hours

**Total to public beta**: 6-10 hours! 🚀

---

## 🎯 **SUCCESS CRITERIA**

**M7.2.2 is complete when:**
- ✅ Owner can send household invitations
- ✅ Recipient receives and accepts invitations
- ✅ HouseholdMember records sync across devices
- ✅ Member list shows in Settings
- ✅ Owner can remove members
- ✅ Members can leave household
- ✅ All data syncs to new members automatically
- ✅ No crashes, no data loss
- ✅ Comprehensive testing on 2+ devices

---

**Version**: December 31, 2025 - M7.2.3 Phase 3.8 Complete, Ready for M7.2.2  
**Status**: 🚀 READY TO START (after git workflow completion)

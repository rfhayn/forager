# M7: CloudKit Sync, Household Sharing & External TestFlight - PRD

**Milestone**: M7 - CloudKit Sync, Household Collaboration, External TestFlight  
**Version**: 2.0 - Shared Zone Architecture  
**Created**: December 3, 2025  
**Last Updated**: December 21, 2025  
**Status**: 🚀 READY TO START (M7.1 Complete, M7.2 Ready)  
**Estimated Duration**: 27-37 hours (including M7.0 prerequisites)

**⚠️ ARCHITECTURE UPDATE (Dec 21, 2025)**: Pivoted from CKShare (per-item sharing) to Shared Zone (household database) architecture. See [Learning Note 25](../learning-notes/25-m7-architecture-pivot-ckshare-vs-shared-zone.md) for details on this decision.

---

## 🎯 Executive Summary

M7 transforms Forager from a single-device app into a collaborative household platform with CloudKit shared zone synchronization and public beta testing capability. This milestone enables household members (couples, roommates, families) to automatically share ALL grocery lists, recipes, and meal plans via a single shared database, while expanding the TestFlight beta program for broader feedback and professional portfolio showcase.

**Key Deliverables:**
0. Privacy policy and App Store prerequisites (MANDATORY before external TestFlight)
1. Full CloudKit sync for all data across user's devices
2. **Shared household zone** - automatic sharing of all data with household members
3. Multi-device sync for seamless experience across iPhones/iPads
4. Conflict resolution for concurrent household edits
5. External TestFlight setup with public link
6. Professional beta landing page for LinkedIn/portfolio

**Why This Milestone:**
- **User Value**: Household members seamlessly collaborate on groceries and meal planning
- **Technical Foundation**: CloudKit infrastructure for future features
- **Professional Showcase**: Public beta demonstrates real-world product
- **Strategic**: Positions app for App Store launch readiness
- **Compliance**: Meets Apple's App Store requirements for external testing

---

## 📊 Current State Analysis

### What We Have (Post-M5.0)
- ✅ Local Core Data persistence (single device)
- ✅ NSPersistentCloudKitContainer configured
- ✅ CloudKit entitlements properly set (`iCloud.com.richhayn.forager`)
- ✅ Internal TestFlight operational (up to 100 testers)
- ✅ 8 Core Data entities with complex relationships
- ✅ Professional UI with all M1-M4 features
- ✅ Zero technical debt
- ✅ App icon designed (green sprout theme)

### What We Need
- ❌ **Privacy policy URL and in-app link (REQUIRED by Apple)**
- ❌ **App Privacy questionnaire completed in App Store Connect**
- ❌ **Display name disambiguated from existing "Forager" game**
- ❌ CloudKit schema defined and tested (✅ M7.1.1 complete)
- ❌ Multi-device sync implementation (✅ M7.1.2 complete)
- ❌ **Household shared zone for collaboration**
- ❌ Conflict resolution strategy
- ❌ Sync status UI indicators
- ❌ External TestFlight configuration
- ❌ Public beta landing page
- ❌ App Review submission (for external testing)

---

## 🎯 Goals & Success Criteria

### Primary Goals

**G1: Seamless Multi-Device Sync**
- **Success**: User adds grocery item on iPhone → appears on iPad within 5 seconds
- **Success**: Recipe created on one device syncs to all devices automatically
- **Success**: Meal plans update across devices in real-time
- **Success**: No data loss during sync operations
- **Metric**: 99%+ sync success rate

**G2: Household Collaboration (Shared Zone)**
- **Success**: User creates household and invites partner
- **Success**: Partner accepts and sees all existing data automatically
- **Success**: Both users can add/edit/delete - all changes sync automatically
- **Success**: Changes from all household members sync within 5 seconds
- **Metric**: Zero data corruption from concurrent household edits

**G3: External TestFlight & Public Beta**
- **Success**: Public TestFlight link created and shareable
- **Success**: External testers can install without team access
- **Success**: Professional beta landing page for LinkedIn
- **Success**: Pass Apple's App Review for external testing
- **Metric**: 50+ external beta testers within 2 weeks

**G4: App Store Compliance**
- **Success**: Privacy policy published and accessible
- **Success**: App Privacy questionnaire completed accurately
- **Success**: Display name disambiguated from existing apps
- **Success**: All App Review requirements met

### Secondary Goals

**G5: Sync Status Visibility**
- **Success**: Users can see sync status (synced, syncing, error)
- **Success**: Clear error messages for sync failures
- **Success**: Manual sync retry option available

**G6: Performance Maintenance**
- **Success**: Sync operations don't block UI (<0.5s latency)
- **Success**: Background sync doesn't drain battery
- **Success**: Minimal network data usage

---

## 🏗️ Technical Architecture

**⚠️ ARCHITECTURE DECISION**: Using CloudKit **Shared Zones**, not CKShare. See [m7-shared-zone-architecture.md](../architecture/m7-shared-zone-architecture.md) for complete technical details.

### CloudKit Schema Design

**All Existing Entities Sync to CloudKit (No Changes Required):**
1. **WeeklyList** (CKRecord)
2. **GroceryListItem** (CKRecord)
3. **IngredientTemplate** (CKRecord)
4. **Recipe** (CKRecord)
5. **Ingredient** (CKRecord)
6. **MealPlan** (CKRecord)
7. **PlannedMeal** (CKRecord)
8. **Category** (CKRecord)
9. **UserPreferences** (CKRecord)

**New Entities for Household Management:**
10. **Household** (CKRecord)
    - Fields: id, name, createdDate, ownerEmail, shareRecord
    - Relationships: members (to HouseholdMember)
11. **HouseholdMember** (CKRecord)
    - Fields: id, email, displayName, joinedDate, role
    - Relationships: household (to Household)

**Key Insight**: No `ckShareRecord` attributes needed on existing entities. When records are created in a shared zone, CloudKit automatically handles sharing.

### Sync Architecture

**Strategy: NSPersistentCloudKitContainer with Shared Zone**
- ✅ Built-in automatic sync (same as M7.1)
- ✅ Shared database scope for household zone
- ✅ Private database scope for non-household users
- ✅ Conflict resolution with merge policies
- ✅ Background sync support

**Database Scopes:**
- **Private Database**: User's personal data (before creating household)
- **Shared Database**: Household zone (after creating/joining household) ← **PRIMARY FOCUS**
- **Public Database**: NOT USED (all data is private or shared)

**Household Sharing Model:**
```
Owner creates Household
  → CloudKit shared zone created
  → All owner's data migrated to shared zone
  → Owner invites Participant via email
  → Participant accepts invitation
  → Participant's app switches to shared zone
  → Both users see ALL data automatically
  → Changes sync bidirectionally
```

**Configuration:**
```swift
// Persistence.swift (M7.2.1)
let cloudKitOptions = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.richhayn.forager"
)

// Enable shared database scope for household
cloudKitOptions.databaseScope = .shared

description.cloudKitContainerOptions = cloudKitOptions
```

---

## 📋 Milestone Breakdown

### M7.0: App Store Prerequisites (2-3 hours) 🚨 MANDATORY

**Purpose**: Complete Apple's requirements for ANY external TestFlight submission

**⚠️ CRITICAL**: M7.0 must be completed before M7.5 (External TestFlight). These are not optional.

**Phases:**

**M7.0.1: Privacy Policy Creation & Hosting (1 hour)**
- Draft privacy policy for current local-only data storage
- Content should state:
  - "All data stored locally on your device"
  - "No data transmitted to external servers"
  - "No tracking or analytics"
  - "Data deleted by uninstalling app"
  - (Update when CloudKit added: "Sync via iCloud with Apple's privacy")
- Host on GitHub Pages (e.g., `forager-privacy.md` in docs folder)
- Publish at URL: `https://rfhayn.github.io/forager/privacy.html`

**M7.0.2: Privacy Policy Integration (1 hour)**
- Add Privacy Policy URL to App Store Connect metadata
- Add "Privacy Policy" button/link in SettingsView
- Use `SafariServices` to open URL in-app (or SFSafariViewController)
- Test: Tap link → policy opens correctly

**M7.0.3: App Privacy Questionnaire (30 min)**
- Log into App Store Connect → App Privacy
- Complete questionnaire:
  - Current build: Select "Data Not Collected" (all categories)
  - After CloudKit: Update to reflect iCloud sync
- Review and submit answers
- Verify completion status

**M7.0.4: Display Name Disambiguation (30 min)**
- Update **Display Name** (CFBundleDisplayName) to:
  - "Forager: Smart Meal Planner" OR
  - "Forager Grocery Planner"
  - Shows in: App Store, Settings, App Switcher
- Keep **Bundle Name** (CFBundleName) as:
  - "Forager"
  - Shows under: Home screen icon (clean, simple)
- Keep **Bundle ID**: `com.richhayn.forager`
- Verify app icon is clearly grocery-themed (not game-like)
- Test: Build and verify home screen shows "Forager", Settings shows full name

**Deliverables:**
- ✅ Privacy policy live at public URL
- ✅ In-app privacy policy link functional
- ✅ App Privacy questionnaire submitted
- ✅ Display name disambiguated
- ✅ All App Store Connect fields complete

**Validation Criteria:**
```
✓ Privacy policy accessible at public URL
✓ Tapping "Privacy Policy" in Settings opens policy
✓ App Privacy shows "Complete" status in App Store Connect
✓ Display name is "Forager: Smart Meal Planner" (or chosen variant)
✓ Home screen icon shows "Forager" label
✓ Settings app shows full display name
✓ App icon clearly grocery-themed
```

**Why This Phase Exists:**
Apple's November 2025 policy updates require ALL apps (not just kids/paid apps) to have:
1. Privacy policy URL accessible to users
2. Completed App Privacy questionnaire
3. In-app link to privacy policy

**Attempting external TestFlight without M7.0 = automatic rejection.**

---

### M7.1: CloudKit Schema & Sync Foundation (6-8 hours)

**Purpose**: Establish CloudKit schema, enable basic sync, validate infrastructure

**Phases:**

**M7.1.1: CloudKit Schema Validation (2 hours)**
- Verify NSPersistentCloudKitContainer configuration
- Test CloudKit schema generation from Core Data model
- Validate all 8 entities sync to CloudKit
- Review CloudKit Dashboard schema

**M7.1.2: Basic Sync Implementation (2 hours)**
- Enable automatic background sync
- Implement sync status monitoring
- Add CloudKit error handling
- Test single-device sync (create → sync → verify)

**M7.1.3: Multi-Device Sync Testing (2-4 hours)**
- Test sync between iPhone and iPad
- Validate data consistency across devices
- Test offline → online sync scenarios
- Measure sync latency (<5 seconds target)

**Deliverables:**
- ✅ All entities syncing to CloudKit
- ✅ Multi-device sync operational
- ✅ Sync monitoring infrastructure
- ✅ Error handling for network failures

**Validation Criteria:**
```
✓ Create grocery list on iPhone → appears on iPad within 5s
✓ Add recipe on iPad → syncs to iPhone within 5s
✓ Offline changes sync when online
✓ No data loss during sync
✓ CloudKit Dashboard shows correct records
```

---

### M7.2: Shared Household Zone (8-10 hours)

**Purpose**: Enable household members to share ALL data automatically via CloudKit shared zone

**⚠️ ARCHITECTURE NOTE**: This uses CloudKit Shared Zones, NOT CKShare per-item sharing. See [m7-shared-zone-architecture.md](../architecture/m7-shared-zone-architecture.md) for technical details.

**Use Case**: 
- Sarah and Mike live together and manage groceries/meals jointly
- Sarah creates household → invites Mike
- ALL recipes, lists, meal plans automatically shared
- No manual sharing per item required
- Like sharing an Apple Notes folder

**Phases:**

**M7.2.1: Household Setup & Shared Zone (3.5-4.5 hours)**
- Create `Household` and `HouseholdMember` Core Data entities
- **Add `household` relationship to ALL 8 existing entities** (GroceryItem, Recipe, WeeklyList, MealPlan, Tag, Ingredient, GroceryListItem, **IngredientTemplate**)
- Create `HouseholdService` for shared zone management
- Build Settings → Household UI section
- Implement "Create Household" flow
- Configure NSPersistentCloudKitContainer for shared database scope
- Migrate existing user data to shared zone

**⚠️ ARCHITECTURE DECISION (Dec 23, 2025)**: ALL 8 entities are household-scoped for security and consistency. See [ADR 008](../architecture/008-shared-zone-architecture.md) and [Learning Note 26](../learning-notes/26-m7.2-household-scoped-architecture.md) for rationale.

**M7.2.2: Member Invitation & Acceptance (2-3 hours)**
- Implement invitation sending via UICloudSharingController
- Build member acceptance flow
- Create `HouseholdMember` entity on acceptance
- Welcome screen for new household members
- Member list display with roles (Owner/Member)

**M7.2.3: Sync Validation & Testing (1-2 hours)**
- Multi-device testing (Owner's iPhone + Participant's iPhone)
- Verify all entities sync automatically
- Test concurrent edits across household members
- Validate offline → online sync queue
- Measure sync performance (<5 seconds target)

**M7.2.4: Household Management (1-2 hours)**
- View household members list
- Remove member functionality (owner only)
- Leave household functionality (member only)
- Dissolve household functionality (owner only)
- Data migration back to private zone on dissolution

**Deliverables:**
- ✅ Household creation and shared zone setup
- ✅ Invitation and acceptance flows
- ✅ All data automatically shared with household members
- ✅ Household management (add/remove/leave/dissolve)

**Validation Criteria:**
```
✓ Sarah creates household "Sarah & Mike's Home"
✓ Sarah invites Mike via iCloud email
✓ Mike receives invitation and accepts
✓ Mike sees ALL of Sarah's existing recipes, lists, meal plans
✓ Sarah adds "milk" to grocery list → Mike sees it within 5s
✓ Mike creates meal plan → Sarah sees it within 5s
✓ Both edit same list → changes sync bidirectionally
✓ Owner can remove member (member loses access)
✓ Owner can dissolve household (data migrates back to private)
```

**Key Differences from CKShare Approach:**
- ✅ ONE database for household (not selective sharing)
- ✅ ALL data automatically shared (no share buttons needed)
- ✅ Simpler UX (invite once vs share each item)
- ✅ Better for couples/roommates managing household together
- ❌ Cannot share with people outside household
- ❌ All-or-nothing sharing (not granular per-item)

---

### M7.3: Conflict Resolution & Edge Cases (4-6 hours)

**Purpose**: Handle concurrent household edits, conflicts, and edge cases gracefully

**Phases:**

**M7.3.1: Conflict Resolution Strategy (2-3 hours)**
- Define conflict resolution policies for household zone:
  - **Last-Write-Wins**: For most fields (NSMergeByPropertyObjectTrumpMergePolicy)
  - **Array Merging**: For list items, ingredients (preserve both edits when possible)
  - **Custom Handling**: For critical fields (e.g., isChecked status)
- Implement NSMergePolicy configurations
- Test concurrent edit scenarios between household members
- Add conflict logging for debugging

**M7.3.2: Edge Case Handling (2-3 hours)**
- Offline → Online sync with conflicts (member offline, then reconnects)
- Deleted records during sync (Owner deletes recipe while Member edits it)
- Member removed from household (revoke access gracefully)
- Household dissolved (migrate data back to private zone)
- Network timeout during sync
- CloudKit quota exceeded
- Account mismatch (wrong iCloud user)
- Simultaneous household creation (prevent duplicate households)

**Deliverables:**
- ✅ Conflict resolution policies implemented
- ✅ Household-specific edge cases handled
- ✅ Error recovery mechanisms
- ✅ User-friendly error messages

**Validation Criteria:**
```
✓ Sarah and Mike edit same grocery item concurrently → merges correctly (last-write-wins)
✓ Sarah deletes recipe while Mike edits it → handles gracefully (Mike notified)
✓ Mike offline for 24h, makes changes → syncs correctly when online
✓ Sarah removes Mike from household → Mike's access revoked, data preserved locally
✓ Network timeout doesn't crash app or lose data
✓ Clear error messages for sync failures ("Mike was removed from household")
✓ Sarah dissolves household → data migrates back to private zone
```

---

### M7.4: Sync Status UI & Polish (3-4 hours)

**Purpose**: Add sync status indicators and user controls

**Phases:**

**M7.4.1: Sync Status Indicators (2 hours)**
- Add sync status icon (synced, syncing, error)
- Implement pull-to-refresh for manual sync
- Add "Last Synced" timestamp
- Show sync progress for large operations

**M7.4.2: Settings & Controls (1-2 hours)**
- CloudKit account status display
- Manual sync trigger
- Clear cache option (for debugging)
- Sync diagnostics screen

**Deliverables:**
- ✅ Sync status visible to users
- ✅ Manual sync controls
- ✅ Diagnostic tools for troubleshooting
- ✅ Polish for professional feel

**Validation Criteria:**
```
✓ User can see sync status at a glance
✓ Pull-to-refresh forces sync
✓ "Last Synced" timestamp updates correctly
✓ Error states show helpful messages
```

---

### M7.5: External TestFlight Setup (2-3 hours)

**Purpose**: Configure external testing for public beta program

**Prerequisites:** M7.0 MUST be complete before starting M7.5

**Phases:**

**M7.5.1: External Testing Group Creation (30 min)**
- Create "External Beta Testers" group in App Store Connect
- Configure group settings
- Set up test information

**M7.5.2: Build Submission for External Review (1 hour)**
- Upload new build (with CloudKit sync)
- Fill out external testing metadata:
  - **App Name**: "Forager: Smart Meal Planner" (disambiguated)
  - **What to Test**: Describe CloudKit sync, collaboration features
  - **Feedback email**: Your contact email
  - **Privacy Policy URL**: Link from M7.0.1
  - **App Description**: Clearly grocery/meal planning (NOT a game)
- Submit for App Review
- Note: Build includes CloudKit capabilities that are actively used

**M7.5.3: App Review Preparation (1-1.5 hours)**

**Pre-Submission Validation Checklist:**

**A. Privacy & Compliance**
```
□ Privacy policy URL configured in App Store Connect
□ In-app privacy policy link working (tap in Settings → opens)
□ App Privacy questionnaire complete and shows "Complete" status
□ Privacy policy accurately reflects data usage (local + iCloud sync)
```

**B. Branding & Metadata**
```
□ Display name: "Forager: Smart Meal Planner" (disambiguated)
□ Bundle name: "Forager" (home screen icon label)
□ App icon clearly grocery/meal-themed (green sprout, NOT pixel-art game style)
□ App Store description emphasizes "grocery & meal planning tool"
□ Screenshots show: Lists, Recipes, Meal Planning, Settings
□ No mention of unimplemented features in description
```

**C. Technical Configuration**
```
□ CloudKit capabilities enabled AND actively used (sync working)
□ No unused capabilities enabled (HealthKit, Push if not using, etc.)
□ Info.plist: CFBundleIconName configured correctly via asset catalog
□ Info.plist: No missing NS*UsageDescription strings for sensitive APIs
□ Primary App Icon Set Name matches asset catalog
```

**D. Functional Quality Assurance**
```
□ Fresh install tested on 2+ physical devices (different screen sizes)
□ App launches quickly (< 2s), never hangs on splash
□ Core workflow: Create list → Add items → Sync → Check off → Works perfectly
□ CloudKit sync tested: iPhone ↔ iPad sync within 5 seconds
□ No crashes when: deleting data, editing items, rapid UI taps, offline sync
□ No debug UI visible ("TODO", "Coming Soon", test buttons)
□ No console logs revealing internal implementation details
```

**E. Metadata Accuracy**
```
□ Description only promises features in THIS build
□ CloudKit sync/collaboration described accurately
□ No promises of AI features, nutrition tracking, etc. (future milestones)
□ "What to Test" section honest and specific
```

**M7.5.4: Public Link Generation (30 min)**
- Wait for Apple App Review approval (24-48 hours typically)
- Generate public TestFlight link once approved
- Test public link installation on non-team device
- Prepare installation instructions

**Deliverables:**
- ✅ External testing group configured
- ✅ Build approved by Apple App Review
- ✅ Public TestFlight link active
- ✅ Ready for broad distribution

**Validation Criteria:**
```
✓ External testing group created
✓ Build submitted to App Review
✓ Build passes App Review (24-48h wait)
✓ Public TestFlight link works
✓ Non-team-members can install via link
✓ No App Store guidelines violations
✓ All M7.0 requirements met
```

---

### M7.6: Public Beta Landing Page & Showcase (2-3 hours)

**Purpose**: Create professional beta landing page for LinkedIn/portfolio

**Phases:**

**M7.6.1: Beta Landing Page (1-2 hours)**
- Create simple HTML landing page:
  - Hero section with app icon and tagline
  - Tagline: "Forager: Smart Meal Planner" (disambiguated name)
  - Feature highlights (CloudKit sync, collaboration)
  - Screenshots from TestFlight
  - Public TestFlight link/button
  - Installation instructions
  - Feedback contact info
- Host on GitHub Pages or similar (free)
- URL: `https://rfhayn.github.io/forager/beta.html` (or custom domain)

**M7.6.2: LinkedIn Showcase Post (30 min)**
- Write professional LinkedIn post:
  - App overview: "Forager: Smart Meal Planner - iOS app for grocery & meal planning"
  - Emphasize: "A grocery and meal planning tool, NOT the Humble Bundle game"
  - Technical highlights (CloudKit, SwiftUI, multi-user collaboration)
  - Journey from concept to beta (98.5 hours: M1-M5.0 + M7)
  - Call-to-action: Join public beta
  - Link to landing page
- Include screenshots and app icon
- Publish post

**M7.6.3: Portfolio Documentation (30 min)**
- Update GitHub README with:
  - Beta program information
  - Architecture overview (CloudKit, Core Data, SwiftUI)
  - Tech stack details
  - Link to landing page
  - Clear description: "Grocery and meal planning app"
- Add badge: "Available on TestFlight"
- Update project description

**Deliverables:**
- ✅ Professional beta landing page
- ✅ LinkedIn showcase post
- ✅ Updated GitHub documentation
- ✅ TestFlight installation guide

**Validation Criteria:**
```
✓ Landing page is live and looks professional
✓ TestFlight link works from landing page
✓ LinkedIn post published with screenshots
✓ Post clearly identifies app as grocery/meal planning
✓ GitHub README updated
✓ Installation instructions clear for non-technical users
```

---

## 🚨 Risks & Mitigation

### Technical Risks

**Risk 1: CloudKit Sync Complexity**
- **Impact**: High - Core feature could fail
- **Probability**: Medium - CloudKit has learning curve
- **Mitigation**: 
  - Start with M7.1 learning notes from Apple docs
  - Reference M5.0 learning note (CloudKit entitlements)
  - Test extensively on real devices
  - Build incrementally with validation checkpoints

**Risk 2: Conflict Resolution Bugs**
- **Impact**: High - Could cause data loss
- **Probability**: Medium - Concurrent edits are complex
- **Mitigation**:
  - Use NSPersistentCloudKitContainer default policies
  - Test conflict scenarios systematically
  - Implement comprehensive logging
  - Beta test with multiple users before public launch

**Risk 3: App Review Rejection (External Testing)**
- **Impact**: Medium - Delays public beta
- **Probability**: Low-Medium - First external submission
- **Mitigation**:
  - **Complete M7.0 prerequisites (MANDATORY)**
  - Review App Store guidelines thoroughly
  - Use disambiguated display name
  - Provide clear testing instructions
  - Include demo account if needed
  - Prepare screenshots showing full functionality
  - Ensure CloudKit is actually working (not just enabled)

**Risk 4: Name Collision with Existing "Forager" Game**
- **Impact**: Medium - Could trigger rejection under Guideline 4.1 (Copycats)
- **Probability**: Low - Different categories, but Apple is sensitive
- **Mitigation**:
  - Use "Forager: Smart Meal Planner" as display name
  - Ensure icon/screenshots clearly grocery-themed
  - Description emphasizes grocery/meal planning
  - No similarity to pixel-art game aesthetic

**Risk 5: CloudKit Quota Limits**
- **Impact**: Low - Could limit testing scale
- **Probability**: Low - Development quota is generous
- **Mitigation**:
  - Monitor CloudKit Dashboard for usage
  - Optimize record sizes
  - Implement pagination for large queries
  - Upgrade quota if needed (unlikely for beta)

### Schedule Risks

**Risk 6: External Review Delay**
- **Impact**: Medium - Can't start public beta until approved
- **Probability**: High - Apple review takes 24-48 hours
- **Mitigation**:
  - Plan for 48h wait after M7.5.2
  - Work on M7.6 (landing page) during wait
  - Have contingency if rejected (address feedback, resubmit)

**Risk 7: M7.0 Prerequisites Overlooked**
- **Impact**: Critical - Automatic rejection from App Review
- **Probability**: Medium - Easy to forget new requirements
- **Mitigation**:
  - M7.0 is first phase (cannot skip)
  - Validation checklist in M7.5.3
  - Test privacy policy link before submission

---

## 📈 Success Metrics

### Technical Metrics

**Sync Performance:**
- Sync latency: <5 seconds (target: <3 seconds)
- Sync success rate: >99%
- Conflict resolution accuracy: 100%
- Network data usage: <1MB per sync session

**App Performance:**
- UI responsiveness maintained: 60fps
- Battery impact: <5% increase vs M5.0
- Memory usage: <60MB (was 45MB)
- Crash rate: <0.1%

### User Metrics (Post-Launch)

**Beta Engagement:**
- External beta testers: 50+ within 2 weeks
- Active usage: 70%+ testers use app weekly
- Feedback submissions: 10+ substantive feedback items
- Retention: 60%+ testers still active after 30 days

**Sharing Metrics:**
- Share creation: 20+ shared lists/recipes
- Multi-user collaboration: 10+ active shared groups
- Share acceptance rate: 80%+

**App Store Compliance:**
- Privacy policy accessible: 100% of testers
- App Review approval: First submission passes
- No guideline violations reported

---

## 🛠️ Development Approach

### Phase-Based Implementation

**Incremental Build Strategy:**
0. M7.0: Prerequisites → Meet Apple's requirements
1. M7.1: Foundation → Validate basic sync works
2. M7.2: Sharing → Test with 2-3 users
3. M7.3: Edge cases → Systematic testing
4. M7.4: Polish → Professional finish
5. M7.5: External TestFlight → Public readiness
6. M7.6: Showcase → Portfolio piece

**Validation After Each Phase:**
- Build succeeds
- All existing features work
- New features validated
- Performance targets met
- Git commit checkpoint

### Testing Strategy

**CloudKit Sync Testing:**
- Unit tests: Core Data → CloudKit mapping
- Integration tests: Multi-device sync
- Manual tests: Real iPhone + iPad
- Load tests: 100+ records sync performance

**Sharing Testing:**
- 2-user scenarios (owner + participant)
- 3+ user scenarios (multiple participants)
- Permission testing (read-only, read-write)
- Edge cases (revoke, delete, conflict)

**External TestFlight Testing:**
- Internal validation first (existing testers)
- Limited external launch (10-20 users)
- Full public launch (50+ users)
- Feedback collection and triage

---

## 📚 Learning Resources

### Apple Documentation

**Essential Reading (Before Starting):**
1. [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) - Especially 4.1, 5.1
2. [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) - Requirements
3. [Setting Up Core Data with CloudKit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
4. [Sharing Core Data Objects](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit/sharing_core_data_objects)
5. [CloudKit Best Practices](https://developer.apple.com/videos/play/wwdc2021/10015/)
6. [External Testing Requirements](https://developer.apple.com/testflight/)

**Reference Documentation:**
- NSPersistentCloudKitContainer: Configuration and setup
- CKShare: Multi-user collaboration APIs
- NSMergePolicy: Conflict resolution strategies
- CloudKit Dashboard: Monitoring and debugging

### Internal Documentation

**Existing References:**
- M5.0 Learning Note (21): CloudKit entitlements setup
- M7.1.1 Learning Note (24): CloudKit schema validation
- **M7 Architecture Pivot (25): CKShare vs Shared Zone decision**
- **M7 Shared Zone Architecture**: Complete technical framework
- ADR 007: Core Data Change Process
- session-startup-checklist.md: Development discipline (with validation checkpoint)

**To Create:**
- M7 Learning Note: CloudKit household sharing + App Store readiness journey
- ADR: Shared Zone architecture decision (post-M7 completion)
- CloudKit troubleshooting guide
- App Review preparation checklist (reusable)

---

## 🎯 Definition of Done

**M7.0 is complete when:**

### Technical Completeness
- [ ] All 9+ entities sync to CloudKit (including Household, HouseholdMember)
- [ ] Multi-device sync works (iPhone ↔ iPad)
- [ ] **Household sharing operational** (shared zone with automatic sync)
- [ ] Conflict resolution handles concurrent household edits
- [ ] Sync status visible to users
- [ ] Error handling graceful and user-friendly

### App Store Compliance (M7.0)
- [ ] Privacy policy published and accessible
- [ ] In-app privacy policy link working
- [ ] App Privacy questionnaire complete
- [ ] Display name disambiguated ("Forager: Smart Meal Planner")
- [ ] Bundle name clean ("Forager")
- [ ] App icon clearly grocery-themed

### Testing Validation
- [ ] Internal TestFlight validated (existing testers)
- [ ] Multi-device testing complete (2+ devices)
- [ ] Multi-user testing complete (3+ users)
- [ ] Edge cases tested and handled
- [ ] Performance targets met (<5s sync, <0.5s UI)

### External Beta Launch
- [ ] External TestFlight group created
- [ ] Build approved by Apple App Review
- [ ] Public TestFlight link active
- [ ] Beta landing page live
- [ ] LinkedIn showcase post published
- [ ] GitHub documentation updated

### Quality Gates
- [ ] Zero crashes in testing
- [ ] Zero data loss scenarios
- [ ] All M1-M5.0 features still working
- [ ] Build succeeds with no warnings
- [ ] Code reviewed and documented
- [ ] M7.5.3 checklist 100% complete

### Documentation
- [ ] M7 learning note created (including App Review lessons)
- [ ] current-story.md updated
- [ ] roadmap.md updated
- [ ] project-index.md updated
- [ ] Privacy policy documented

**Final Validation:**
- [ ] Sarah creates household and invites Mike
- [ ] Mike accepts and sees all of Sarah's data automatically
- [ ] Changes sync across household members within 5 seconds
- [ ] External beta tester installs via public link and provides feedback
- [ ] No critical bugs reported within first week of public beta
- [ ] Privacy policy accessible to all testers

---

## 📅 Timeline Estimate

### Phase Breakdown (27-37 hours total)

| Phase | Description | Time Estimate |
|-------|-------------|---------------|
| **M7.0** | **App Store Prerequisites (MANDATORY)** | **2-3 hours** |
| M7.1 | CloudKit Schema & Sync Foundation | 6-8 hours |
| M7.2 | Multi-User Sharing Infrastructure | 8-10 hours |
| M7.3 | Conflict Resolution & Edge Cases | 4-6 hours |
| M7.4 | Sync Status UI & Polish | 3-4 hours |
| M7.5 | External TestFlight Setup | 2-3 hours |
| M7.6 | Public Beta Landing Page & Showcase | 2-3 hours |

**Buffer Time**: +5 hours (15% contingency for CloudKit complexity + App Review)

**Total**: 32-42 hours (with buffer)

### Schedule Considerations

**Wait Times (External to Development):**
- Apple App Review: 24-48 hours (during M7.5)
- Beta tester feedback: Ongoing post-launch

**Recommended Schedule:**
- **Week 1**: M7.0 (prerequisites) + M7.1-M7.2 (sync foundation + sharing) → 16-21 hours
- **Week 2**: M7.3-M7.4 (conflict resolution + polish) → 7-10 hours
- **Week 3**: M7.5 (submit to App Review, wait 24-48h) + M7.6 (landing page) → 4-6 hours
- **Week 4**: Public beta launch + initial feedback collection

**Total Calendar Time**: 3-4 weeks (including Apple review wait)

### Alternative: Path B (Simple-First)
If you choose Path B (defer CloudKit):
- **Week 1**: M7.0 (prerequisites) + M7.5 (submit current build) + M7.6 (landing page) → 5-7 hours
- **Total Calendar Time**: ~1 week (including Apple review)

---

## 🚀 Getting Started

### Pre-Development Checklist

**Before M7.0.1:**
- [ ] Read session-startup-checklist.md
- [ ] Read project-naming-standards.md
- [ ] Read current-story.md
- [ ] Read M7 PRD (this document) completely
- [ ] Review App Store Review Guidelines (focus on 4.1, 5.1)
- [ ] Review App Privacy Requirements
- [ ] Decide: Path A (CloudKit-First) or Path B (Simple-First)

**Before M7.1.1 (if doing CloudKit):**
- [ ] M7.0 completely finished and validated
- [ ] Read M5.0 learning note (21-m5.0-forager-renaming-testflight.md)
- [ ] Read Apple CloudKit documentation (links above)
- [ ] Review Core Data model (all 8 entities)
- [ ] Verify CloudKit entitlements still correct
- [ ] Backup current Core Data database

### First Session Start Prompt

```
I'm ready to start M7.0 - App Store Prerequisites.

I've completed:
✅ session-startup-checklist.md
✅ project-naming-standards.md
✅ current-story.md
✅ M7 PRD review
✅ App Store Review Guidelines review
✅ Decision: Path A (CloudKit-First) / Path B (Simple-First)

Let's start with M7.0.1: Privacy Policy Creation & Hosting.

Current state:
- App renamed to "Forager"
- Internal TestFlight operational
- All M1-M5.0 features working
- Ready for App Store compliance work

First task: Draft privacy policy for local-only data storage.
```

---

## 📝 Post-Milestone Documentation

### After M7 Completion

**Required Documentation Updates:**
1. **Learning Note**: Create `22-m7-cloudkit-sync-external-beta.md`
   - Document CloudKit implementation challenges
   - Share App Review experience and lessons
   - Record sync performance metrics
   - Note sharing implementation patterns
   - Document privacy policy creation process
   - List App Review checklist items that proved critical

2. **Update current-story.md**: Mark M7 complete with actual hours

3. **Update roadmap.md**: Add M7 completion, update M8 status

4. **Update project-index.md**: Add M7 references and links

5. **Git Commit**: "M7 COMPLETE: CloudKit sync, App Store compliance, external beta operational"

6. **Update requirements.md**: Mark M7 requirements complete

---

## 🎉 Success Celebration Criteria

**M7 will be successfully complete when:**

1. ✅ Privacy policy is live and accessible to all users
2. ✅ You create a household and invite your spouse - they see all your recipes/lists instantly
3. ✅ You edit a grocery list on your iPhone, and your spouse sees it update on their iPhone within 5 seconds
4. ✅ 50+ external beta testers have installed Forager via public TestFlight link
5. ✅ Your LinkedIn post about "Forager: Smart Meal Planner" has 100+ views and 10+ reactions
6. ✅ Zero data loss incidents during household collaboration
7. ✅ Professional beta landing page showcases your work
8. ✅ CloudKit Dashboard shows successful sync operations across household zone
9. ✅ App Store Connect shows "Approved" status for external testing

**This milestone transforms Forager from solo project into:**
- Compliant App Store-ready product ✅
- Collaborative household tool with CloudKit shared zone ✅
- Professional portfolio showcase ✅

---

**End of M7 PRD**

**Document Status**: ✅ Complete and Ready for Execution (Updated with App Store Requirements)  
**Version**: 1.1 (Added M7.0 prerequisites based on Principal Engineer feedback)  
**Next Step**: Begin M7.0.1 (Privacy Policy) after completing pre-development checklist  
**Estimated Completion**: 3-4 weeks (Path A) or 1 week (Path B) - including Apple review wait

**Total Project Hours After M7**: 92.5 (M1-M5.0) + 32-42 (M7) = ~130 hours

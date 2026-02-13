# Next Implementation Prompt

**Last Updated**: February 13, 2026
**For Milestone**: M7.6 — Pre-Launch Prep & TestFlight Submission
**Status**: M7.6.1-M7.6.7 code prep ✅ COMPLETE | **M7.6.7 Manual Submission 🚀 NEXT**
**Branch**: `main` (M7.6 branch merged via PR #31, M7.6.7 version bump committed)

---

## **M7.6.7: TESTFLIGHT SUBMISSION**

### **Context**
- All prerequisites complete: app config, production gating, onboarding, schema cleanup, loading screen
- Branch `feature/M7.6-pre-launch-testflight` has all M7.6.1-M7.6.6 changes
- Core Data model is at v5 (v2→v3→v4→v5 lightweight migration chain)
- Schema is clean — dead entities removed, misnamed fields fixed, code-schema mismatches resolved
- CloudKit Development schema needs to be deployed to Production before archiving

### **Pre-Submission Checklist**

✅ **Already completed:**

1. ~~**Merge branch to main**~~ — ✅ DONE (PR #31 squash-merged, M7.6.7 version bump committed on main)

2. ~~**Clean build from main**~~ — ✅ DONE (BUILD SUCCEEDED)

3. **Verify on physical device** — Fresh install, onboarding flows, loading screen (do this before archiving)

### **M7.6.7 Tasks (Manual — Xcode & Apple Portals)**

These steps are performed manually in Xcode and Apple's web portals:

#### 1. Deploy CloudKit Schema to Production
- Open [CloudKit Console](https://icloud.developer.apple.com/dashboard)
- Navigate to Schema → Deploy to Production
- **Review all record types** — verify Tag and LeaveRequest are NOT present
- **Deploy** — this is **permanent and irreversible**
- Verify deployment succeeded

#### 2. Complete App Privacy Questionnaire
- [App Store Connect](https://appstoreconnect.apple.com) → App Privacy
- Mark "Data Not Collected" (local + iCloud only, no analytics)
- Save and verify "Complete" status

#### 3. Verify App Store Metadata
- Display name: "forager - Smart Meal Planner"
- Bundle name: "forager"
- Privacy policy URL working
- Category: Food & Drink
- Age rating: 4+

#### 4. Archive and Upload Build
- Xcode → Product → Archive (Release configuration)
- Distribute App → App Store Connect
- Wait for processing (5-15 minutes)

#### 5. Create External Testing Group
- TestFlight → External Testing → Create Group
- Name: "Public Beta Testers"
- Enable public link

#### 6. Complete Test Information
```
What to Test:
- Create grocery lists organized by store section
- Add recipes and scale ingredient quantities
- Plan meals for the week, then generate your grocery list
- Set up a household and invite family members to collaborate
- Look for the yellow badge on ingredients — it indicates
  the parser wasn't fully confident in how it read the input

Feedback Email: [your email]
Privacy Policy URL: [existing URL]
```

#### 7. Submit for External Review
- Select build → attach to external group → submit
- Apple reviews within 24-48 hours typically

### **After Submission**

- **M7.6.8** (15 min): After Apple approval (24-48h), generate public TestFlight link
- **M7.7**: App Store Submission & Public Presence (3-5h)
  - M7.7.1: Beta Landing Page (GitHub Pages)
  - M7.7.2: GitHub README Update
  - M7.7.3: App Store Listing
  - M7.7.4: App Store Submission

### **Key Files for Context**

```
docs/prds/active/m7.6-pre-launch-prep-testflight.md  # Full PRD with all M7.6 details
docs/prds/active/m7.7-app-store-submission.md         # M7.7 PRD for after TestFlight
docs/learning-notes/31-m7.6-core-data-schema-evolution.md  # Schema evolution learnings
docs/architecture/007-core-data-change-process.md      # Core Data change process ADR
```

### **Risk Mitigation**

| Risk | Mitigation |
|------|------------|
| CloudKit schema deploy fails | All schema changes tested in Development; v5 builds and runs cleanly |
| Apple rejects for missing privacy policy | M7.0 already completed — privacy policy published and linked |
| Lightweight migration fails on Production data | Tested v2→v5 migration with existing data, zero data loss |
| Debug UI visible in Release | M7.6.2 wrapped all dev tools in `#if DEBUG` |
| Crashes on launch | Loading screen + two-phase init tested on physical device |

---

**Version**: February 13, 2026 - M7.6.7 Manual Submission Steps Remaining
**Dependencies**: M7.6.1-M7.6.7 code prep ✅ COMPLETE, merged to main, version bumped to 1.1

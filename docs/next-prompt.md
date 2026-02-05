# Next Implementation Prompt

**Last Updated**: February 5, 2026
**For Milestone**: M7.4 - UI Polish & Pre-Launch Fixes
**Status**: READY TO START
**Prerequisites**: M7.3.4 merged to main
**Branch**: `feature/M7.4-ui-polish-pre-launch`
**PRD**: `docs/prds/active/m7.4-ui-polish-pre-launch.md`

---

## **IMMEDIATE ACTION: MERGE M7.3.4 TO MAIN**

Before starting M7.4, merge the current branch:

```bash
gh pr create --title "M7.3.3 + M7.3.4: Remove Member, Delete Household, Error Handling & Stability" --body "$(cat <<'EOF'
## Summary
- M7.3.3: Remove member (owner-only), delete household with data migration
- M7.3.4: Error handling improvements, ghost data fixes, CloudKit logging

## Changes
- Remove member via swipe-to-delete (owner only)
- Delete household with migrate/clean delete options
- Ghost data bug fix (loadCurrentHousehold no longer auto-clears left flag)
- Check Again button replaces exit(0) in AcceptInvitationSheet
- CloudKitErrorMapper and CloudKitLogger utilities
- Offline leave handling with pending leave queue
- householdKey filtering across all autocomplete surfaces

## Testing
- Offline leave: PASSED
- Rejoin + ghost data: PASSED
- Multi-device leave: SKIPPED (user decision)
- OSLog validation: VALIDATED
- Regression testing: SKIPPED (user decision - exhaustive testing done)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"

gh pr merge --squash --delete-branch
git checkout main && git pull origin main
```

---

## **M7.4: UI POLISH & PRE-LAUNCH FIXES**

**Goal**: Address UI issues and visual polish before App Store submission.

**Estimated Time**: 4-6 hours

**Scope**: Intentionally open - issues identified in real-time through app review.

### **Process**

1. Run the app and systematically review each screen
2. Take screenshots of issues
3. Share with Claude for analysis and code location
4. Fix issues in priority order
5. Verify fixes compile and don't introduce regressions

### **In Scope**
- Visual inconsistencies
- UI alignment issues
- Color/typography inconsistencies
- Missing empty states
- Rough edges in user flows
- Minor UX improvements

### **Out of Scope**
- New features
- Architecture changes (M7.5)
- Performance optimization (M9)
- Parsing improvements (M8)

### **Git Workflow**

```bash
git checkout main && git pull origin main
git checkout -b feature/M7.4-ui-polish-pre-launch
git push -u origin feature/M7.4-ui-polish-pre-launch
```

---

## **PRE-LAUNCH ROADMAP**

| Task | Status | Est. Hours |
|------|--------|------------|
| M7.3.4: Error Handling | ✅ COMPLETE | - |
| **M7.4: UI Polish & Pre-Launch Fixes** | 📋 NEXT | 4-6h |
| M8.1: Parsing Resilience & Telemetry | 📋 PLANNED | 3-4h |
| M8.2: Telemetry Analysis | 📋 PLANNED | 2h |
| M8.3: Hybrid NLP Parser | 📋 PLANNED | 8-10h |
| M7.6: External TestFlight | 📋 PLANNED | 2-3h |
| M7.7: App Store Submission | 📋 PLANNED | 2-3h |
| **Pre-Launch Total** | | **~22-28h** |

---

## **KEY DECISIONS MADE (February 5, 2026)**

1. **Original M7.4 (Sync Status UI) SKIPPED** - Dual-store architecture makes it unnecessary
2. **M7.4 repurposed** for UI Polish & Pre-Launch Fixes
3. **M8.1-M8.3 before launch** - Fix "3 avocados" parsing issue
4. **M7.5, M6, M8.4, M9+ deferred** to post-launch

---

**Version**: February 5, 2026 - M7.4 Ready
**Dependencies**: M7.3.4 merged to main

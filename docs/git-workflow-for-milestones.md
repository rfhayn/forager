# Git Workflow for Milestone Development

**Purpose**: Integrate git best practices with M#.#.# milestone structure  
**Created**: December 3, 2025  
**Based on**: git-cheatsheet.md + session-startup-checklist.md  
**Status**: ACTIVE - Use for all M7+ development

---

## 🎯 **Overview**

This workflow combines:
- ✅ **Feature branch development** (from git-cheatsheet.md)
- ✅ **Milestone naming conventions** (M#.#.# format)
- ✅ **Clean commit history** (squash merges)
- ✅ **Documentation checkpoints** (learning notes, current-story updates)

---

## 🚀 **Phase Start Workflow**

### **Before Writing Any Code**

**1. Ensure main is up to date**
```bash
git checkout main
git pull origin main
```

**2. Create feature branch for phase**
```bash
# Format: feature/M#.#.#-brief-description
git checkout -b feature/M7.1.1-cloudkit-schema-validation

# Examples:
# git checkout -b feature/M7.1.1-cloudkit-schema
# git checkout -b feature/M7.1.2-sync-monitoring  
# git checkout -b feature/M7.1.3-multi-device-testing
```

**Branch Naming Convention**:
- Prefix: `feature/` (always)
- Milestone: `M7.1.1` (exact milestone number)
- Description: brief-kebab-case (3-5 words max)

**3. Verify you're on the new branch**
```bash
git branch  # Should show * feature/M7.1.1-...
```

**4. Create initial checkpoint commit**
```bash
# Immediately commit the impact analysis or planning docs
git add docs/M7.1.1-CORE-DATA-IMPACT-ANALYSIS.md
git commit -m "M7.1.1: Add Core Data impact analysis

- Comprehensive file analysis (1 file to change)
- Risk assessment (LOW risk)
- Time estimate: 1.5 hours
- Following ADR 007 process"

git push -u origin feature/M7.1.1-cloudkit-schema-validation
```

**Why?**: Creates a clean starting point and backs up your planning work immediately.

---

## 💻 **During Development**

### **Commit Frequently (Every 15-30 minutes)**

**Good commit practice**:
```bash
# After completing a logical unit of work
git add Persistence.swift
git commit -m "M7.1.1: Replace NSPersistentContainer with CloudKitContainer

- Changed container type declaration
- Added CloudKit import
- Build succeeds, app launches normally"

git push  # Pushes to your feature branch
```

**Commit Message Format**:
```
M#.#.#: Brief description (imperative mood)

- Bullet point of what changed
- Another change or context
- Test result or validation note
```

**Examples of good commits**:
```bash
git commit -m "M7.1.1: Add CloudKit container configuration

- Set container identifier to iCloud.com.richhayn.forager
- Enable history tracking for sync
- Enable remote change notifications
- Wrapped in #if !DEBUG for development speed"

git commit -m "M7.1.1: Verify CloudKit schema generation

- Created test data on physical device
- Confirmed 8 record types in CloudKit Dashboard
- Schema fields match Core Data model exactly
- Ready for M7.1.2"

git commit -m "M7.1.1: Update documentation for completion

- Mark M7.1.1 complete in current-story.md
- Add learning notes to 24-m7.1.1-cloudkit-setup.md
- Update next-prompt.md for M7.1.2
- Actual time: 1.5 hours (matched estimate)"
```

**What to commit together**:
- ✅ Related code changes (single logical change)
- ✅ Code + tests for that feature
- ✅ Code + related documentation updates

**What NOT to commit together**:
- ❌ Unrelated changes across multiple features
- ❌ Mix of bugfixes and new features
- ❌ WIP code that doesn't build

### **Push Frequently**

```bash
# After every commit (or every few commits)
git push

# Benefits:
# - Backs up your work to GitHub
# - Makes it visible for review
# - Enables switching computers mid-phase
```

---

## ✅ **Phase Completion Workflow**

### **When Phase is Complete**

**1. Final documentation update commit**
```bash
git add docs/current-story.md docs/learning-notes/24-m7.1.1-cloudkit-setup.md
git commit -m "M7.1.1 COMPLETE: Update documentation

✅ Acceptance Criteria:
- Build succeeds with zero warnings
- App launches normally on device
- CloudKit Dashboard shows 8 entities
- Schema matches Core Data model

📊 Metrics:
- Estimated: 1.5 hours
- Actual: 1.5 hours (100% accuracy!)
- Files changed: 1 (Persistence.swift)
- Risk level: LOW (confirmed)

📝 Documentation:
- current-story.md marked complete
- Learning notes created
- next-prompt.md updated for M7.1.2"

git push
```

**2. Open Pull Request**
```bash
# Auto-fill title and body from commits
gh pr create --fill

# OR specify details manually
gh pr create \
  --title "M7.1.1: CloudKit Schema Validation" \
  --body "## Summary
Replaces NSPersistentContainer with NSPersistentCloudKitContainer and validates CloudKit schema generation.

## Changes
- Updated Persistence.swift with CloudKit configuration
- Added #if !DEBUG wrapper for development speed
- Verified schema in CloudKit Dashboard

## Testing
- ✅ Build succeeds
- ✅ App launches normally
- ✅ 8 record types in CloudKit Dashboard
- ✅ Schema matches Core Data model

## Time
- Estimated: 1.5 hours
- Actual: 1.5 hours

## Next
M7.1.2: Basic Sync Implementation" \
  --base main
```

**3. Review PR (optional but recommended)**
```bash
# View PR in browser
gh pr view --web

# Check PR status
gh pr status
```

**4. Merge PR**
```bash
# Squash merge (recommended for clean history)
gh pr merge --squash --delete-branch

# This will:
# - Squash all commits into one
# - Merge to main
# - Delete the feature branch on GitHub
```

**Why squash?**: 
- Clean main branch history (one commit per phase)
- Easy to revert entire phase if needed
- Simple to understand what each phase did

**5. Update local main**
```bash
git checkout main
git pull origin main

# Verify you're on main
git branch  # Should show * main

# Clean up local feature branch
git branch -d feature/M7.1.1-cloudkit-schema-validation
```

**6. Verify clean state**
```bash
git status  # Should show: "nothing to commit, working tree clean"
```

---

## 🔄 **Starting Next Phase**

```bash
# Immediately start next phase
git checkout -b feature/M7.1.2-sync-monitoring

# Start with documentation/planning
git add docs/next-prompt.md  # If you update it for current phase
git commit -m "M7.1.2: Prepare implementation plan"
git push -u origin feature/M7.1.2-sync-monitoring
```

---

## 📊 **Example: Complete M7.1.1 Flow**

```bash
# ========== PHASE START ==========
git checkout main
git pull origin main
git checkout -b feature/M7.1.1-cloudkit-schema

git add docs/M7.1.1-CORE-DATA-IMPACT-ANALYSIS.md
git commit -m "M7.1.1: Add Core Data impact analysis"
git push -u origin feature/M7.1.1-cloudkit-schema

# ========== DEVELOPMENT ==========
# Edit Persistence.swift - add CloudKit import
git add Persistence.swift
git commit -m "M7.1.1: Add CloudKit import and change container type"
git push

# Edit Persistence.swift - add CloudKit configuration
git add Persistence.swift  
git commit -m "M7.1.1: Configure CloudKit container with #if !DEBUG"
git push

# Test on device, verify CloudKit Dashboard
git commit --allow-empty -m "M7.1.1: Verified CloudKit schema in Dashboard

- All 8 entities present
- Schema matches Core Data model
- Test data synced successfully"
git push

# ========== PHASE COMPLETE ==========
git add docs/current-story.md docs/learning-notes/24-*.md
git commit -m "M7.1.1 COMPLETE: Documentation and learning notes"
git push

gh pr create --fill
gh pr merge --squash --delete-branch

git checkout main
git pull origin main
git branch -d feature/M7.1.1-cloudkit-schema

# ========== NEXT PHASE ==========
git checkout -b feature/M7.1.2-sync-monitoring
# ... continue with M7.1.2
```

---

## 🎓 **Best Practices**

### **Commit Messages**

**Structure**:
```
M#.#.#: Brief description (50 chars or less)

- Detailed point 1
- Detailed point 2  
- Test results or validation
```

**Good examples**:
```
✅ M7.1.1: Add CloudKit configuration to Persistence
✅ M7.1.2: Implement CloudKitSyncMonitor service
✅ M7.1.3: Test multi-device sync with 2 iPhones
```

**Bad examples**:
```
❌ Fixed stuff
❌ WIP
❌ Update files
❌ Trying to make it work
```

### **When to Commit**

**Commit when**:
- ✅ Feature buildable and testable
- ✅ Tests pass (if applicable)
- ✅ Logical unit of work complete
- ✅ Before switching tasks
- ✅ Before taking a break
- ✅ Before switching computers

**Don't commit**:
- ❌ Code that doesn't compile
- ❌ Broken tests
- ❌ Debug statements or commented-out code
- ❌ Secrets or API keys
- ❌ Personal environment settings

### **Branch Hygiene**

**Do**:
- ✅ One branch per phase (M7.1.1 = one branch)
- ✅ Delete branches after merge
- ✅ Keep branches short-lived (1-3 hours ideally)
- ✅ Merge to main frequently

**Don't**:
- ❌ Reuse branches for multiple phases
- ❌ Leave old branches around
- ❌ Let branches diverge too far from main
- ❌ Force push to main (ever!)

---

## 🚨 **Emergency Scenarios**

### **Need to Switch Computers Mid-Phase**

```bash
# On Computer A - save work
git add .
git commit -m "M7.1.1 WIP: CloudKit config in progress"
git push

# On Computer B - resume work
git fetch origin
git checkout feature/M7.1.1-cloudkit-schema
git pull origin feature/M7.1.1-cloudkit-schema

# Continue working...
```

### **Made a Mistake in Last Commit**

```bash
# If you haven't pushed yet
git commit --amend

# If you've already pushed
# Just make another commit fixing it
git add .
git commit -m "M7.1.1: Fix typo in CloudKit container ID"
git push
```

### **Need to Abandon Branch and Start Over**

```bash
git checkout main
git branch -D feature/M7.1.1-cloudkit-schema  # Force delete
git checkout -b feature/M7.1.1-cloudkit-schema-v2
```

### **Accidentally Committed to Main**

```bash
# Create branch from current main
git branch feature/M7.1.1-cloudkit-schema

# Reset main to origin
git checkout main
git reset --hard origin/main

# Continue work on feature branch
git checkout feature/M7.1.1-cloudkit-schema
```

---

## 🐙 **GitHub Integration Workflow**

### **At Milestone Start**

When beginning a new milestone (M#.#.#), establish GitHub tracking:

**1. Create GitHub Issue**
```bash
# Create issue with template
gh issue create \
  --title "M7.2.2: Member Invitation & Acceptance" \
  --label "milestone,feature" \
  --milestone "M7: CloudKit Sync & External TestFlight" \
  --body "$(cat <<'EOF'
**Status**: 🔄 IN PROGRESS
**Estimated**: 2-3 hours
**Actual**: TBD

## Task List

### Phase 1: Implementation
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

### Phase 2: Testing
- [ ] Test scenario 1
- [ ] Test scenario 2

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Documentation
- [ ] Learning notes created
- [ ] Wiki updated
- [ ] Current-story updated
EOF
)"

# The issue number will be returned (e.g., #22)
```

**2. Add to Project Board**
```bash
# Add issue to project (auto-adds to "Todo" status)
gh project item-add 1 --owner rfhayn --url https://github.com/rfhayn/forager/issues/22
```

**3. Document in Wiki (if major milestone)**

For significant milestones (M#.#, M#.#.#), update wiki pages:
- CloudKit-Implementation.md (for M7.x milestones)
- Milestones-Overview.md (for all milestones)
- Home.md (for major status changes)

This step is **optional** at milestone start - wiki updates can wait until completion.

---

### **During Milestone**

**Update Issue Progress (Optional)**

```bash
# Edit issue to update progress
gh issue edit 22 --body "$(cat <<'EOF'
**Status**: 🔄 IN PROGRESS (Phase 2 Testing)
**Estimated**: 2-3 hours
**Actual**: 8 hours so far

## Task List

### Phase 1: Implementation ✅
- [x] Task 1
- [x] Task 2
- [x] Task 3

### Phase 2: Testing (In Progress)
- [x] Test scenario 1
- [ ] Test scenario 2  ← Currently here

## Bugs Discovered
- Bug #1: Description and fix
- Bug #2: Description (investigating)

## Documentation
- [x] Implementation notes created
- [ ] Testing notes (in progress)
EOF
)"
```

**Move Project Board Card (Optional)**

```bash
# Move to "In Progress" status
gh project item-edit --project-id <project-id> --id <item-id> --field-id <status-field-id> --value "In Progress"

# Note: Often easier to do this manually via web UI
```

**Key Principle**: During development, focus on **work**, not **tracking**. Update GitHub when natural milestones occur (phase complete, bug discovered, etc.), not for every small change.

---

### **At Milestone Completion**

When the milestone is complete, close out GitHub tracking:

**1. Close GitHub Issue with Completion Summary**

```bash
gh issue close 22 --comment "$(cat <<'EOF'
## ✅ M7.2.2 COMPLETE

**Final Status**: Member invitation and acceptance system working
**Total Time**: 11-12 hours
**Original Estimate**: 2-3 hours
**Variance**: Extended due to iOS 18.x issues and bug fixes

---

## 🎯 Completion Summary

**Implementation Complete**:
✅ Feature 1 working
✅ Feature 2 implemented
✅ Bug fixes applied
✅ Documentation complete

**Testing Complete**:
✅ Test scenario 1 passed
✅ Test scenario 2 passed
✅ All acceptance criteria met

---

## 🐛 Issues Discovered & Resolved

**Bug #1**: Description
- Fix: What was done

**Bug #2**: Description
- Fix: What was done

---

## 📚 Documentation

**Implementation Guides**:
- [32: Guide Name](link) (XX KB)
- [33: Guide Name](link) (XX KB)

**Wiki Updates**:
- CloudKit-Implementation.md updated
- Milestones-Overview.md updated
- Home.md status updated

---

## 💡 Key Lessons

Brief summary of what was learned

---

**Next**: M7.2.3 or next planned milestone

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**Why this format?**:
- ✅ Provides complete closure documentation
- ✅ Captures lessons learned
- ✅ Links to detailed documentation
- ✅ Shows time variance for future planning
- ✅ Searchable summary for future reference

**2. Verify Project Board Auto-Updated**

```bash
# Check that issue closing moved card to "Done"
gh project item-list 1 --owner rfhayn --format json | jq '.items[] | select(.content.number == 22) | {title: .title, status: .status}'

# Should show: "status": "Done"
# GitHub automatically moves closed issues to Done status
```

**3. Update Wiki Pages**

Update relevant wiki pages to reflect completion:

**CloudKit-Implementation.md** (for M7.x milestones):
```markdown
### M7.2.2: Member Invitation ✅ COMPLETE (11-12 hours)
- Feature 1 working
- Feature 2 implemented
- Bug fixes applied
- Documentation complete
```

**Milestones-Overview.md** (for all milestones):
- Move milestone from "In Progress" to "Completed Milestones"
- Update status dashboard table
- Update time tracking summary
- Add to planning accuracy analysis

**Home.md** (for major milestones):
- Update "Current Phase" status
- Update development time total
- Update project stats

**4. Commit Wiki and Documentation Updates**

```bash
cd /tmp/forager-wiki  # Wiki repository
git add -A
git commit -m "Documentation: M7.2.2 complete - Member invitation working (11-12h)

Updated wiki pages to reflect M7.2.2 completion:
- CloudKit-Implementation.md: Added completion summary
- Milestones-Overview.md: Moved to completed section
- Home.md: Updated project status and stats

GitHub:
- Issue #22 closed with completion summary
- Project board automatically updated to Done

Next: M7.3 (Conflict Resolution) or M7.5 (Architecture Hardening)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

git push origin main

cd /Users/rich/Development/forager  # Main repository
```

**5. Create Milestone Completion Git Commit (Main Repo)**

```bash
# In main repository
git add -A
git commit -m "M7.2.2: Mark complete - Member invitation and acceptance working (11-12h)

Member invitation and acceptance system fully operational after comprehensive
bug fixes from physical device testing.

Completion Status:
- Public link sharing system working
- Accept invitation flow with auto-member creation
- All bugs fixed and documented

Bug Fixes:
- Fixed display names showing CloudKit IDs
- Extended sync retry from 3s → 30s
- Integrated auto-member creation
- Added restart alert for edge cases

Documentation:
- docs/learning-notes/26: Public Link Sharing (20.4 KB)
- docs/archive/33: Device B Bug Fixes (19.1 KB)
- docs/learning-notes/27: M7.2.2 Completion
- Wiki updates (CloudKit-Implementation, Milestones-Overview, Home)

GitHub:
- Issue #22 closed with completion summary
- Project board updated to Done

Time Investment:
- Original Estimate: 2-3 hours
- Actual: 11-12 hours (implementation + bug fixes)
- Justification: Real device testing revealed critical production bugs

Next: M7.3 (Conflict Resolution) or M7.5 (Architecture Hardening)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### **GitHub Workflow Summary**

**Milestone Start**:
1. Create GitHub Issue with task list
2. Add to Project Board
3. (Optional) Document in wiki

**During Milestone**:
1. Update issue when phases complete
2. Check off tasks as done
3. Document bugs discovered

**Milestone Complete**:
1. Close issue with comprehensive summary
2. Verify project board auto-updated to Done
3. Update wiki pages (CloudKit-Implementation, Milestones-Overview, Home)
4. Commit wiki changes
5. Commit main repo changes

**Key Principle**: GitHub is for **tracking**, git is for **history**. Use both to maintain complete project visibility.

---

## 📋 **Checklist Integration**

### **Add to session-startup-checklist.md**

When starting a phase, add this step:

```markdown
#### **8. Create Feature Branch** ✅
**When**: At start of any development phase  
**Command**: `git checkout -b feature/M#.#.#-description`  
**Purpose**: Isolate phase work for clean history and easy rollback

**Key Takeaway**: One phase = one branch = one PR = one squash commit to main
```

### **Add to session-completion-checklist.md**

Before ending a phase, verify:

```markdown
- [ ] All changes committed
- [ ] All commits pushed to feature branch
- [ ] Documentation updated (current-story.md, learning notes)
- [ ] PR created and merged
- [ ] Local main updated (git pull origin main)
- [ ] Feature branch deleted locally and remotely
- [ ] git status shows clean working tree
```

---

## 🎯 **Success Metrics**

**This workflow succeeds when:**

1. ✅ **Clean main branch**: One commit per phase, easy to read history
2. ✅ **Safe experimentation**: Can abandon branch if phase goes wrong
3. ✅ **Cross-computer development**: Can switch computers mid-phase
4. ✅ **Clear progress tracking**: PRs show what each phase accomplished
5. ✅ **Easy rollback**: Can revert entire phase with one git revert
6. ✅ **Documentation integration**: Commits reference M#.#.# consistently

---

## 💡 **Pro Tips**

1. **Branch names in commit messages**: Not needed since branch is M7.1.1-prefixed
2. **Commit early, commit often**: Better to have too many commits (we squash anyway)
3. **Push immediately**: Don't wait until phase is "done"
4. **PR descriptions matter**: Future you will thank you for details
5. **Squash merges are your friend**: Clean history is worth it

---

**Next Action**: Use this workflow for M7.1.1!

**Start with**:
```bash
git checkout main
git pull origin main
git checkout -b feature/M7.1.1-cloudkit-schema-validation
git add docs/M7.1.1-CORE-DATA-IMPACT-ANALYSIS.md
git commit -m "M7.1.1: Add Core Data impact analysis"
git push -u origin feature/M7.1.1-cloudkit-schema-validation
```

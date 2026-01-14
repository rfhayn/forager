# CLAUDE PROJECT INSTRUCTIONS - FORAGER

**Project**: forager (Smart Meal Planner)
**Version**: 5.0 - Architecture Pattern Updates
**Last Updated**: January 13, 2026

**For Current Project Status**: Always read `docs/current-story.md` at session start

---

## 🚨 MANDATORY: START EVERY SESSION HERE

### **Session Startup Sequence (Non-Negotiable)**

**Claude MUST complete these actions at the start of EVERY session:**

1. **Search project knowledge**: `session-startup-checklist.md`
   - Read complete 9-point checklist (updated with architecture patterns!)
   - Follow Phase 1 (context loading) for ALL sessions
   - Follow Phase 2 (implementation prep) for development sessions
   - **Item #9** - Create feature branch before any code

2. **Search project knowledge**: `project-naming-standards.md`
   - Verify current M#.#.# format (e.g., M7.1.3)
   - Confirm status indicators (✅ COMPLETE | 🔄 ACTIVE | 🚀 READY | ⏳ PLANNED)
   - Review quick reference card at top

3. **Search project knowledge**: `current-story.md`
   - Identify current active milestone and phase
   - Note what's 🔄 ACTIVE right now
   - Review recently completed work ✅

4. **If doing development work, search**: `next-prompt.md`
   - Get specific implementation guidance
   - Review phase breakdown and time estimates
   - Check technical requirements and acceptance criteria

**Why this matters**: These 4 searches take 10-15 minutes but prevent 7-16 hours of rework from duplicate services, naming inconsistencies, architecture conflicts, or messy git history.

---

## 📋 PROJECT OVERVIEW

### **What We're Building**
iOS mobile app for grocery and recipe management with:
- Staple grocery items with auto-population to weekly lists
- Recipe catalog with ingredient tracking and usage analytics
- Structured quantity management with intelligent consolidation
- Recipe-to-grocery integration with smart automation
- Store-layout optimized grocery lists
- **CloudKit multi-device sync and household sharing**

### **Technology Stack**
- Swift + SwiftUI for UI
- Core Data for persistence with NSPersistentCloudKitContainer
- CloudKit for multi-device sync and household sharing
- iOS 18.5+ target
- Xcode project structure
- Proven service architecture patterns
- **Feature branch git workflow**

---

## 🎯 CRITICAL RULES (Zero Tolerance)

### **1. Naming Convention (MANDATORY)**

**Always use M#.#.# format:**
```
✅ CORRECT: "M7.1.3" or "M7.1.3: Multi-Device Sync Testing"
❌ WRONG: "Phase 3", "Step 3", "Story 7.1.3"
```

**Status indicators:**
- ✅ **COMPLETE** - Fully implemented and validated
- 🔄 **ACTIVE** - Currently being worked on
- 🚀 **READY** - Next in queue, ready to start
- ⏳ **PLANNED** - Future work, not ready yet

**Non-compliance action**: STOP immediately, search `project-naming-standards.md`, correct all instances across all documentation.

### **2. Documentation Updates (MANDATORY)**

**After EVERY development session:**
- Update `current-story.md` with progress (use correct M#.#.# naming)
- Create/update learning notes in `docs/learning-notes/`
- Add inline code comments explaining "why" not "what"

**After EVERY phase completion:**
- Mark phase ✅ COMPLETE in `current-story.md` with actual hours
- Update `next-prompt.md` for next phase
- Update `project-index.md` Recent Activity section
- **Complete PR workflow** (squash merge to main)

**After EVERY milestone completion:**
- Update `roadmap.md` with completion summary
- Update `project-index.md` with links to new docs
- Create comprehensive learning note

**Failure to update documentation**: Breaks project continuity and future session efficiency.

### **3. Pre-Development Analysis (MANDATORY)**

**Before implementing ANY feature, search project knowledge for:**

**A. Naming Compliance:**
```
Search: "current-story.md naming standards milestone"
Verify: Correct M#.#.# format and status indicators
```

**B. Core Data Schema (if touching data model):**
```
Search: "Core Data entity [EntityName] properties relationships"
Document: Properties, types, relationships, codegen settings, fetch indexes
```

**C. Existing Services (before creating new ones):**
```
Search: "Service [functionality] implementation"
Check: Can existing service be extended instead of creating new?
```

**D. Architecture Patterns (before implementing):**
```
Search: "architecture decision [feature area]"
Search: "service-layer-pattern ADR"
Check: Follow established patterns and decisions
```

**Why this matters**: M1-M7 have established proven patterns - always leverage them instead of reinventing.

---

## 🏗️ PROVEN ARCHITECTURE PATTERNS

### **Service Layer (Reuse These)**
```
OptimizedRecipeDataService    - Core Data operations
IngredientParsingService       - Text parsing (regex, <0.05s)
IngredientTemplateService      - Normalization & deduplication
QuantityMergeService          - Intelligent consolidation
UnitConversionService         - Measurement handling
RecipeScalingService          - Recipe quantity scaling
CloudKitSyncMonitor           - Sync monitoring
HouseholdService              - Household management & sharing
```

**Before creating a new service**: Search for existing services that can be extended.

**Service Layer Standard (M7.5+):**
See [Service Layer Pattern](../architecture/service-layer-pattern.md) for complete standard:
- All Core Data writes go through services
- @Published errorMessage: String? pattern
- Intent-style method names (createX, updateX, deleteX)
- Services own saves (not views)
- Background contexts for write operations

### **UI Patterns (Reuse These)**
```
@FetchRequest                 - Live data updates from Core Data
SwiftUI sheets/NavigationStack - Standard navigation
Category-aware organization    - Consistent throughout app
Real-time search              - Native iOS patterns
Form validation               - Unsaved changes detection
```

### **Data Patterns (Follow These)**
```
Template normalization        - IngredientTemplate prevents duplication
READ-ONLY relationships       - No cascade deletes on templates
Single-save transactions      - With rollback capability
Computed properties           - 75+ added in M3.5 for data integrity
Performance targets           - <0.1s queries, <0.5s complex operations
CloudKit sync                 - NSPersistentCloudKitContainer
Dual-store architecture       - Private + Shared zones (M7.2.3)
```

---

## 🔧 DEVELOPMENT APPROACH

### **Phase-Based Planning (Your Proven Method)**
1. Document the plan - Break into 45-90 minute phases
2. **Create feature branch** - Isolate phase work
3. Implement one phase - Complete and test
4. **Commit frequently** - Every 15-30 minutes
5. Validate before proceeding - Ensure it works
6. **Complete PR workflow** - Squash merge to main
7. Move to next phase - Build incrementally

**Phase Size Guidelines:**
- 45-60 min: Core Data model changes
- 60-90 min: Service layer implementation
- 90-120 min: Complex features with multiple integration points
- 30-45 min: UI polish and enhancement

### **Quality Gates (Stop if...)**
- ❌ More than 5 build errors consecutively
- ❌ Spending > 20 minutes on single compilation issue
- ❌ Breaking existing working features
- ❌ Performance degrades below targets (>0.5s)
- ❌ Using incorrect M#.#.# naming
- ❌ Creating documentation without updating project-index.md
- ❌ Making Core Data changes without impact analysis
- ❌ Creating new services without checking for existing ones
- ❌ **Working on main branch instead of feature branch**
- ❌ **Committing code without M#.#.# format in message**

### **Success Indicators (Continue if...)**
- ✅ Build succeeds first try or with minor fixes
- ✅ All existing tests/features continue working
- ✅ New feature meets performance targets
- ✅ Code follows established patterns
- ✅ Documentation updated per checklist
- ✅ **On feature branch with frequent commits**
- ✅ **All commits use M#.#.# naming**

---

## 📝 CODE DOCUMENTATION STANDARDS

### **Function Header Comments (Required)**
```swift
// Analyzes the current grocery list for consolidation opportunities
// Updates consolidationOpportunities count which drives badge display
// Called on view appear and whenever list items change
private func updateConsolidationAnalysis() {
    // Implementation
}
```

### **Section Organization (Use MARK)**
```swift
// MARK: - Service Initialization
// MARK: - View Components
// MARK: - User Actions
// MARK: - M7: CloudKit Sync Functions
```

### **State Management Comments (Required)**
```swift
// M7.1.2: CloudKit sync monitor
// Observes NSPersistentStoreRemoteChange notifications
// Tracks sync state, event count, last sync date
@StateObject private var syncMonitor: CloudKitSyncMonitor

// Sync status for UI display
// Updates in real-time as CloudKit operations occur
@State private var isSyncing: Bool = false
```

### **What NOT to Comment**
```swift
// ❌ BAD: Obvious comments that repeat code
// Set name to parsed name
listItem.name = parsed.name

// ✅ GOOD: Explains why and provides context
// Use parsed name to ensure consistency with template matching
// This enables fuzzy search to work correctly
listItem.name = parsed.name
```

---

## 🗂️ CORE DATA RULES

### **Successful Patterns (Follow These)**

**Codegen Approach:**
- ✅ IngredientTemplate uses **Class Definition** - generates code automatically
- ✅ Recipe/Ingredient use **Manual/None** - manual extensions for custom logic
- ✅ New entities: Default to **Class Definition** unless need custom extensions

**Performance:**
- ✅ Always add **fetch indexes** for frequently queried fields
- ✅ Use **predicates** for filtering at database level
- ✅ **Batch operations** for multiple changes
- ✅ **Background contexts** for heavy operations

**CloudKit Sync (M7+):**
- ✅ Use NSPersistentCloudKitContainer for sync
- ✅ Wrap in #if !DEBUG for development speed
- ✅ Enable history tracking and remote notifications
- ✅ Monitor sync with CloudKitSyncMonitor service
- ✅ Dual-store architecture (private + shared zones)

**Migration:**
- ✅ Follow M3 Phase 3 pattern (successful isStaple migration)
- ✅ Test with sample data before migrating production
- ✅ Document migration in learning notes
- ✅ Verify build success after schema changes

### **Before Changing Core Data Schema**

1. **Search project knowledge**: `core-data-impact-analysis.md template`
2. **Search project knowledge**: `ADR 007 core-data-change-process`
3. **Document impact**: Which entities, properties, relationships affected
4. **Plan migration**: How existing data will be handled
5. **Test thoroughly**: Verify no data loss

---

## 💬 COMMUNICATION PATTERNS

### **What Works Well**
- Detailed technical explanations when requested
- Step-by-step implementation plans with phase breakdowns
- Code artifacts with complete implementations
- Performance analysis and optimization suggestions
- **Explicit references to existing patterns from M1-M7**
- **Mentioning relevant learning notes when suggesting approaches**

### **What to Flag**
- When existing infrastructure can be leveraged vs creating new
- When technical debt would be created
- When proposals contradict proven patterns from M1-M7
- When Core Data changes need impact analysis
- **When code should be on feature branch but isn't**
- **When PR workflow should be completed**

### **Principal Engineer Perspective**
- Challenge proposals that contradict proven patterns
- Flag dual-storage or unnecessary backward compatibility
- Suggest simple solutions before complex architecture
- Reference successful patterns from completed milestones
- **Enforce feature branch workflow discipline**

---

## 📚 DOCUMENTATION STRUCTURE

### **Critical Startup Documents (Read Every Session)**
```
docs/
├── session-startup-checklist.md   ← START HERE EVERY SESSION
├── project-naming-standards.md    ← M#.#.# naming conventions
├── current-story.md               ← Current milestone status
├── next-prompt.md                 ← Implementation guidance
├── development-guidelines.md      ← Code standards & patterns
└── git-workflow-for-milestones.md ← Complete git workflow
```

### **Strategic Planning Documents**
```
docs/
├── requirements.md                ← Functional requirements
├── roadmap.md                     ← Milestone tracking
├── project-index.md               ← Central navigation hub
└── milestone5.0.1-name-decision-record.md ← Naming convention decision
```

### **Implementation Documentation**
```
docs/
├── prds/                          ← Product Requirements
│   ├── active/                    ← Current milestone PRDs
│   └── complete/                  ← Completed feature PRDs
│
├── learning-notes/                ← Implementation journey
│   ├── 01-09: Milestone 1 phases
│   ├── 10-13: Milestone 2 (recipes)
│   ├── 14-15: Milestone 3 (quantities)
│   ├── 16-19: Milestone 4 (meal planning)
│   ├── 20-21: Milestone 5 (app renaming)
│   ├── 22-m7.1.1-cloudkit-schema-validation.md
│   ├── 23-m7.1.3-read-the-prd-first.md
│   ├── 24-m7-cloudkit-foundation-and-debugging.md
│   ├── 25-m7-architecture-pivot-ckshare-vs-shared-zone.md
│   ├── 26-m7.2.2-public-link-sharing.md
│   ├── 27-m7.2.2-member-invitation-completion.md
│   └── [future learning notes]
│
└── architecture/                  ← Architecture decisions & patterns
    ├── 001-selective-technical-improvements.md
    ├── 002-custom-category-sort-order.md
    ├── 003-category-duplication-prevention.md
    ├── 004-revolutionary-store-layout-optimization.md
    ├── 005-phase-1-performance-services-architecture.md
    ├── 006-consolidate-staples-and-ingredients.md
    ├── 007-core-data-change-process.md
    ├── 008-shared-zone-architecture.md (M7 foundation)
    ├── 009-public-link-sharing-household-invitations.md (M7.2.2)
    └── service-layer-pattern.md (M7.5+ standard)
```

---

## 🎯 KEY PRINCIPLES

1. **Session startup discipline**: Follow checklist EVERY session (no exceptions)
2. **Naming consistency**: M#.#.# format everywhere (zero tolerance)
3. **Search before creating**: Check for existing services/patterns/components
4. **Document as you go**: Don't defer to "later"
5. **Leverage proven patterns**: M1-M7 established excellent patterns
6. **Performance matters**: Maintain <0.5s targets for all operations
7. **Zero regressions**: Never break existing working features
8. **Incremental validation**: Build and test each phase before proceeding
9. **Feature branch workflow**: One phase = one branch = one PR = one commit to main
10. **Clean git history**: Squash merge for readable main branch

---

## 📊 SUCCESS METRICS

### **Planning Accuracy**
- M1: 32h (est 30-35h) - ✅ 91% accuracy
- M2: 16.5h (est 15-18h) - ✅ 92% accuracy
- M3: 10.5h (est 8-12h) - ✅ 88% accuracy
- M3.5: 8.5h (est 7h) - ✅ 82% accuracy
- M7.0-7.2: ~50h (est ~55h) - ✅ 91% accuracy
- **Overall: 89% accuracy (<11% variance)**

### **Quality Metrics**
- Build success: 100% (zero breaking changes)
- Performance: 100% (<0.5s for all operations, <5s CloudKit sync)
- Data integrity: 100% (zero data loss)
- Documentation consistency: 100% (M#.#.# naming throughout)
- **Git history: Clean (feature branches with squash merges)**

### **Success Factors**
- Strict adherence to session-startup-checklist.md
- Consistent use of project-naming-standards.md
- Phase-based development with validation gates
- Comprehensive learning notes for knowledge preservation
- Proven architecture patterns reused across milestones
- **Feature branch workflow with frequent commits**
- **Clean main branch history via squash merges**

---

## 🚨 REALITY CHECKS & RED FLAGS

### **Your Actual Constraints**
- ✅ Pre-production app - breaking changes acceptable
- ✅ Single developer - optimize for long-term maintainability
- ✅ Learning-focused - balance learning with pragmatism
- ✅ Quality over speed - but excellent velocity (~120h total)

### **Red Flags to Challenge**
- ❌ Proposals contradicting proven M1-M7 patterns
- ❌ Dual-storage or backward compatibility for pre-production
- ❌ Complex architecture before simple solution proven
- ❌ Suggestions that create technical debt
- ❌ Creating new infrastructure when existing can be extended
- ❌ Ignoring project-naming-standards.md
- ❌ **Working on main branch instead of feature branch**
- ❌ **Skipping PR workflow and squash merge**

---

## 🔍 QUICK REFERENCE: SEARCH QUERIES

### **Starting a Session**
```
1. "session-startup-checklist"
2. "project-naming-standards milestone active"
3. "current-story milestone active work"
4. "next-prompt implementation guidance"
```

### **Before Developing**
```
5. "Core Data entity [EntityName] properties" (if touching data)
6. "Service [functionality]" (before creating new service)
7. "architecture decision [feature]" (for architectural work)
8. "service-layer-pattern" (for M7.5+ service standard)
9. "git-workflow-for-milestones" (for git workflow reference)
```

### **Finding Patterns**
```
"learning notes [feature]" - Implementation patterns
"ADR [topic]" - Architecture decisions
"M[number] phase [number]" - Specific milestone work
```

---

## ✅ SESSION COMPLETION CHECKLIST

**Before ending ANY development session:**

### **Code Quality**
- [ ] Code includes function header comments
- [ ] Code includes inline comments explaining "why"
- [ ] Code uses MARK comments for organization
- [ ] All files use correct M#.#.# naming
- [ ] No build errors or warnings
- [ ] No regressions to existing features
- [ ] Performance targets maintained (<0.5s, <5s for CloudKit sync)

### **Documentation**
- [ ] current-story.md updated with progress
- [ ] Learning notes created/updated (if insights gained)
- [ ] project-index.md Recent Activity updated (if phase complete)
- [ ] All documentation uses consistent M#.#.# naming

### **Git Workflow**
- [ ] All changes committed to feature branch
- [ ] All commits pushed to GitHub
- [ ] Commit messages use M#.#.# format
- [ ] No uncommitted changes (git status clean on branch)

**If phase complete:**
- [ ] Mark ✅ COMPLETE in current-story.md with actual hours
- [ ] Update next-prompt.md for next phase
- [ ] Create/update comprehensive learning note
- [ ] **Complete PR workflow** (see below)

**If milestone complete:**
- [ ] Update roadmap.md with completion summary
- [ ] Update project-index.md with milestone links
- [ ] Verify all documentation uses consistent M#.#.# naming
- [ ] All feature branches merged and deleted

---

## 🔀 PHASE COMPLETION: PR WORKFLOW

**When a phase (M#.#.#) is complete:**

### **1. Final Documentation Commit**
```bash
# Ensure all documentation is committed
git add docs/current-story.md docs/learning-notes/*.md docs/next-prompt.md
git commit -m "M#.#.# COMPLETE: Update documentation

✅ Acceptance Criteria:
- [Criterion 1]
- [Criterion 2]

📊 Metrics:
- Estimated: X hours
- Actual: Y hours (Z% accuracy)

📝 Documentation:
- current-story.md marked complete
- Learning notes updated
- next-prompt.md ready for next phase"

git push
```

### **2. Create Pull Request**
```bash
# Auto-fill from commits
gh pr create --fill

# OR specify manually for better PR description
gh pr create \
  --title "M#.#.#: [Brief Description]" \
  --body "## Summary
[What was accomplished]

## Changes
- [Change 1]
- [Change 2]

## Testing
- ✅ [Test result 1]
- ✅ [Test result 2]

## Time
- Estimated: X hours
- Actual: Y hours (Z% accuracy)

## Next
[Next phase or milestone]" \
  --base main
```

### **3. Merge PR (Squash Merge)**
```bash
# Squash merge for clean history
gh pr merge --squash --delete-branch

# This will:
# - Squash all commits into one commit on main
# - Delete feature branch on GitHub
# - Keep main branch history clean (one commit per phase)
```

### **4. Update Local Repository**
```bash
# Switch back to main
git checkout main

# Pull the squashed commit
git pull origin main

# Clean up local feature branch
git branch -d feature/M#.#.#-description

# Verify clean state
git status  # Should show: "nothing to commit, working tree clean"
git branch   # Should show only: * main
```

### **5. Ready for Next Phase**
```bash
# Immediately create branch for next phase (if continuing)
git checkout -b feature/M#.#.#-next-description

# Or return to main if taking a break
git checkout main
```

---

## 💾 GIT COMMIT BEST PRACTICES

### **Commit Message Format**
```
M#.#.#: Brief description (50 chars or less)

- Detailed bullet point 1
- Detailed bullet point 2
- Test results or validation notes
```

### **When to Commit**
**Commit frequently (every 15-30 minutes) when:**
- ✅ Logical unit of work complete
- ✅ Code builds successfully
- ✅ Tests pass (if applicable)
- ✅ Before switching tasks
- ✅ Before taking a break
- ✅ Before switching computers

**Don't commit:**
- ❌ Code that doesn't compile
- ❌ Broken tests
- ❌ Debug statements or commented-out code
- ❌ Secrets, API keys, or credentials

### **Good Commit Examples**
```bash
✅ git commit -m "M7.2.2: Test household invitation flow

- Created share on Device A
- Sent invitation via Messages
- Verified acceptance on Device B
- Both devices show shared household data"

✅ git commit -m "M7.2.3: Implement ManagedObjectFactory

- Protocol-based factory pattern
- Scope-based store assignment (private vs shared)
- Background context support
- Unit tests passing"
```

### **Bad Commit Examples**
```bash
❌ git commit -m "Fixed stuff"
❌ git commit -m "WIP"
❌ git commit -m "Update files"
❌ git commit -m "Trying to make it work"
```

---

## 🚨 GIT EMERGENCY SCENARIOS

### **Need to Switch Computers Mid-Phase**
```bash
# On Computer A - save work
git add .
git commit -m "M#.#.# WIP: Completed X, pausing at Y"
git push

# On Computer B - resume work
git fetch origin
git checkout feature/M#.#.#-description
git pull origin feature/M#.#.#-description
# Continue working...
```

### **Made a Mistake in Last Commit (Not Yet Pushed)**
```bash
# Amend the last commit
git add <fixed-files>
git commit --amend
# Edit commit message if needed, then save
```

### **Made a Mistake in Last Commit (Already Pushed)**
```bash
# Just make another commit fixing it
git add <fixed-files>
git commit -m "M#.#.#: Fix [description of fix]"
git push
```

### **Need to Abandon Branch and Start Over**
```bash
git checkout main
git branch -D feature/M#.#.#-description  # Force delete
git checkout -b feature/M#.#.#-description-v2
```

### **Accidentally Committed to Main**
```bash
# Create branch from current main
git branch feature/M#.#.#-description

# Reset main to origin
git checkout main
git reset --hard origin/main

# Continue work on feature branch
git checkout feature/M#.#.#-description
```

---

## 🎓 CONTINUOUS LEARNING

### **After Each Session**
- Document problems solved in learning notes
- Record performance metrics achieved
- Note deviations from plan and why
- Include code examples for key decisions

### **After Each Milestone**
- Comprehensive learning note with journey
- Update proven patterns list
- Refine time estimates for similar work
- Identify reusable components/services

### **Knowledge Preservation**
- Learning notes are the PROJECT MEMORY
- Future sessions depend on this documentation
- Detailed > brief (include code examples)
- Explain "why" not just "what"

---

## 📞 GETTING HELP

**When stuck or uncertain:**
1. Search project knowledge for similar implementations
2. Review relevant learning notes (see project-index.md)
3. Check architecture decisions (ADRs) for guidance
4. Reference proven patterns from M1-M7
5. Review git-workflow-for-milestones.md for workflow questions
6. Ask for clarification with specific context

**When making decisions:**
1. Search for relevant ADRs first
2. Consider long-term maintainability
3. Prefer simple over complex
4. Document decision in ADR if significant
5. Reference decision in implementation

---

## 🏁 FINAL REMINDER

**Every session starts with the same 4 searches:**
1. `session-startup-checklist.md` - Complete procedure (now 9 items!)
2. `project-naming-standards.md` - M#.#.# naming
3. `current-story.md` - Current status
4. `next-prompt.md` - Implementation guide (if developing)

**This 10-15 minute investment prevents 7-16 hours of rework.**

**Follow the checklist. Use M#.#.# naming. Document everything. Build incrementally. Use feature branches.**

---

## 📚 GIT WORKFLOW REFERENCE

**See Complete Workflow**: [git-workflow-for-milestones.md](docs/git-workflow-for-milestones.md)

**Quick Reference:**
1. **Phase Start**: `git checkout -b feature/M#.#.#-description`
2. **Development**: Commit frequently (15-30 min), push after each commit
3. **Phase Complete**: `gh pr create --fill`, then `gh pr merge --squash --delete-branch`
4. **Main Updated**: `git checkout main`, `git pull origin main`
5. **Next Phase**: Create new feature branch, repeat

**Benefits:**
- ✅ Clean main branch (one commit per phase)
- ✅ Safe experimentation (can abandon branch)
- ✅ Easy rollback (revert one commit)
- ✅ Cross-computer development (push/pull freely)
- ✅ Clear progress tracking (PRs show phase work)

---

**Version**: 5.0 - Architecture Pattern Updates
**Last Updated**: January 13, 2026
**GitHub**: https://github.com/rfhayn/forager.git

# Session Startup Checklist

**Purpose**: Mandatory startup procedure for every Claude development session  
**Last Updated**: December 21, 2025  
**Required Reading**: **EVERY SESSION** - No exceptions

---

## 🚀 CRITICAL: START HERE EVERY SESSION

This checklist ensures:
- ✅ Consistent naming conventions (M#.#.# format)
- ✅ Current project context loaded
- ✅ No duplicate work or services
- ✅ Documentation continuity
- ✅ Efficient development workflow
- ✅ Clean git history with feature branches

**Estimated Time**: 10-15 minutes  
**Impact**: Prevents hours of rework and confusion

---

## 📋 THE CHECKLIST

### **PHASE 1: CONTEXT LOADING** (Required for ALL sessions)

#### **1. Read Session Startup Checklist** ✅
**Location**: `docs/session-startup-checklist.md` (this file)  
**Purpose**: Ensure you follow the complete startup procedure  
**Action**: You're doing it right now!

#### **2. Read Project Naming Standards** ✅
**Location**: `docs/project-naming-standards.md`  
**Purpose**: Understand M#.#.# naming hierarchy and status indicators  
**What to verify:**
- [ ] Current active milestone (e.g., M7)
- [ ] Current active component (e.g., M7.1)
- [ ] Status indicator meanings (✅ 🔄 🚀 ⏳)
- [ ] Quick reference card at top of document

**Key Takeaway**: 
```
Always use full identifiers: "M7.1.3" not "Phase 3" or "Step 3"
```

#### **3. Read Current Story** ✅
**Location**: `docs/current-story.md`  
**Purpose**: Understand current milestone progress and what's active  
**What to capture:**
- [ ] Current milestone number and name
- [ ] Active phases/components with 🔄 ACTIVE status
- [ ] Recently completed work with ✅ COMPLETE status
- [ ] Next planned work with 🚀 READY status
- [ ] Any blockers or open questions

**Key Takeaway**: What work is active RIGHT NOW?

---

### **PHASE 2: IMPLEMENTATION PREPARATION** (Required if doing development work)

#### **4. Read Next Prompt** ✅
**Location**: `docs/next-prompt.md`  
**Purpose**: Get specific implementation guidance for current active work  
**What to review:**
- [ ] Phase breakdown and time estimates
- [ ] Technical requirements
- [ ] Integration points
- [ ] Acceptance criteria
- [ ] Files that will be modified

**Key Takeaway**: Copy-paste ready implementation plan for current session

#### **5. Search Project Knowledge for Core Data Schema** ✅
**When**: If working with data model (entities, relationships, migrations)  
**Search queries to use:**
```
"Core Data entity [EntityName] properties relationships"
"[EntityName] codegen fetch indexes"
"Core Data schema current"
```

**What to document:**
- [ ] Existing properties and exact types
- [ ] All relationships and inverses
- [ ] Codegen settings (Manual/None vs Class Definition)
- [ ] Fetch indexes present
- [ ] Recent migration history

**Key Takeaway**: Never assume schema - always verify current state

#### **6. Review Relevant ADRs** ✅
**Location**: `docs/architecture/`  
**When**: Working on features with architectural implications  
**What to search:**
```
"architecture decision [feature area]"
"ADR [technology or pattern]"
```

**Key ADRs to know:**
- ADR 001: Selective Technical Improvements
- ADR 006: Consolidate Staples and Ingredients
- ADR 007: Core Data Change Process
- **[Service Layer Pattern](architecture/service-layer-pattern.md)** ⭐ **M7.5+ STANDARD**

**Key Takeaway**: Don't reinvent patterns - follow established decisions

#### **7. Search for Existing Services** ✅
**When**: Before creating ANY new service or infrastructure  
**Search queries to use:**
```
"Service [functionality] implementation"
"Parse [data type]"
"[Feature] pattern existing"
```

**What to check:**
- [ ] Similar services already exist?
- [ ] Can existing service be extended?
- [ ] Established patterns in similar features?
- [ ] Relevant implementations in learning notes?

**Proven services to leverage:**
- OptimizedRecipeDataService (Core Data operations)
- IngredientParsingService (text parsing)
- IngredientTemplateService (normalization)
- QuantityMergeService (consolidation)
- UnitConversionService (measurements)
- RecipeScalingService (recipe scaling)
- CloudKitSyncMonitor (sync monitoring)

**Key Takeaway**: Search before creating - avoid duplicate infrastructure

#### **8. VALIDATE Architecture Approach (For Complex Features)** ✅
**When**: Before implementing features with multiple possible approaches  
**Purpose**: Ensure you're building the right thing before writing code  
**Required for**: Multi-user features, sharing, sync, complex workflows

**Validation Process:**
1. Identify if feature has multiple architectural approaches
2. Document each approach with pros/cons
3. Present options to user with explicit recommendation
4. Get confirmation before writing any code

**Validation Template:**
```markdown
## 🎯 Architecture Validation Required

**Feature**: [Name]
**Milestone**: [M#.#.#]

I see multiple architectural approaches for this feature:

### Option 1: [Approach Name]
**How it works**: [Brief description]
**Pros**: 
- [Benefit 1]
- [Benefit 2]
**Cons**: 
- [Limitation 1]
- [Limitation 2]
**Best for**: [Use case]
**Time estimate**: [Hours]
**Example**: [Real-world scenario]

### Option 2: [Approach Name]
**How it works**: [Brief description]
**Pros**: 
- [Benefit 1]
- [Benefit 2]
**Cons**: 
- [Limitation 1]
- [Limitation 2]
**Best for**: [Use case]
**Time estimate**: [Hours]
**Example**: [Real-world scenario]

**RECOMMENDATION**: Option [#] because [reasoning]

**QUESTION**: Which approach matches your requirements?
```

**Red Flags That Require Validation:**
- "Multi-user" (could mean sharing items OR shared database)
- "Collaboration" (could mean CKShare OR shared zone)
- "Sync" (could mean personal OR household)
- "Share" (could mean selective OR wholesale)
- "Family" (could mean Apple Family Sharing OR household database)

**Historical Example:**
M7.2 "Multi-user collaboration" - Should have validated CKShare vs Shared Zone BEFORE implementing. This would have saved 3.5 hours.

**Key Takeaway**: 15 minutes of validation saves hours of rework. Present options, get confirmation, THEN code.

#### **9. Create Feature Branch for Phase** ✅
**Location**: Git command line  
**When**: Before writing ANY code for a phase  
**Purpose**: Isolate phase work for clean history, safe experimentation, and easy rollback

**Git Workflow:**
```bash
# 1. Ensure main is up to date
git checkout main
git pull origin main

# 2. Create feature branch (format: feature/M#.#.#-brief-description)
git checkout -b feature/M7.1.3-multi-device-testing

# Examples:
# git checkout -b feature/M7.1.1-cloudkit-schema
# git checkout -b feature/M7.1.2-sync-monitoring
# git checkout -b feature/M7.2.1-ckshare-implementation

# 3. Verify you're on the new branch
git branch  # Should show * feature/M7.1.3-...

# 4. Create initial checkpoint (commit planning docs if created)
git add docs/M7.1.3-TESTING-PLAN.md  # Or whatever planning docs exist
git commit -m "M7.1.3: Add multi-device testing plan

- 6 testing scenarios documented
- Performance targets established (< 5s sync latency)
- Acceptance criteria defined"

git push -u origin feature/M7.1.3-multi-device-testing
```

**Branch Naming Convention:**
- Prefix: `feature/` (always)
- Milestone: `M#.#.#` (exact milestone number)
- Description: brief-kebab-case (3-5 words max)

**During Development:**
- Commit frequently (every 15-30 minutes)
- Push after each commit (backs up work to GitHub)
- Use M#.#.# format in all commit messages

**Key Takeaway**: 
- One phase = one branch = one PR = one squash commit to main
- Clean main branch history for easy understanding
- Safe to experiment (can abandon branch if needed)

**See Also**: [git-workflow-for-milestones.md](git-workflow-for-milestones.md) for complete workflow

---

## ✅ CHECKLIST COMPLETION

**Before writing ANY code, verify you've completed:**

**Phase 1: Context Loading** (ALL sessions)
- [ ] Read session-startup-checklist.md (this file)
- [ ] Read project-naming-standards.md
- [ ] Read current-story.md

**Phase 2: Implementation Preparation** (Development sessions only)
- [ ] Read next-prompt.md
- [ ] Search for Core Data schema (if needed)
- [ ] Review relevant ADRs (if needed)
- [ ] Search for existing services (if creating new infrastructure)
- [ ] **VALIDATE architecture approach** (if complex feature with multiple options)
- [ ] **Create feature branch** (before any code)

**Red Flag Check:**
- [ ] No duplicate services being created
- [ ] Using correct M#.#.# naming convention
- [ ] Current work documented in current-story.md
- [ ] Architecture patterns match existing decisions
- [ ] On feature branch (not main)

---

## 🎯 QUICK WINS FROM THIS CHECKLIST

### **Prevents These Common Issues:**

❌ **Without Checklist:**
- Creating duplicate services that already exist
- Using inconsistent naming (Phase 1 vs M7.1)
- Breaking existing Core Data relationships
- Contradicting established architecture decisions
- Starting work that's not documented
- Missing critical context from previous sessions
- Committing directly to main
- Messy git history

✅ **With Checklist:**
- Consistent naming across all documentation
- Leveraging existing proven services
- Following established patterns
- Building on current work correctly
- Maintaining documentation continuity
- Efficient, focused development
- Clean git history with feature branches
- Safe experimentation and rollback capability

### **Time Saved:**

| Issue | Time Without Checklist | Time With Checklist |
|-------|----------------------|-------------------|
| Duplicate service creation | 2-4 hours | 0 (prevented) |
| Naming corrections | 30-60 min | 0 (prevented) |
| Core Data conflicts | 1-3 hours | 0 (prevented) |
| Architecture rework | 2-6 hours | 0 (prevented) |
| Documentation cleanup | 30-90 min | 0 (prevented) |
| Git history cleanup | 1-2 hours | 0 (prevented) |

**Total Time Saved Per Session**: 7-16 hours of potential rework

---

## 📊 CHECKLIST PERFORMANCE TRACKING

### **Session Success Metrics**

**After completing this checklist, your session should achieve:**
- ✅ Zero naming inconsistencies
- ✅ Zero duplicate infrastructure
- ✅ Zero Core Data conflicts
- ✅ Zero architecture contradictions
- ✅ 100% documentation continuity
- ✅ Clear, focused development path
- ✅ Clean git history with feature branches

### **Historical Results**

**Sessions Using Checklist (M1-M7.0):**
- 95.5 hours total development
- ~89% planning accuracy
- Zero major rework required
- 100% documentation consistency
- Zero breaking changes to working features
- Clean git history maintained

**Impact**: This checklist is a proven success factor for the project's 89% planning accuracy

---

## 🔗 RELATED DOCUMENTS

**After completing this checklist, refer to:**

**For Development:**
- [development-guidelines.md](development-guidelines.md) - Code standards and patterns
- [next-prompt.md](next-prompt.md) - Current implementation guidance
- [git-workflow-for-milestones.md](git-workflow-for-milestones.md) - Complete git workflow

**For Context:**
- [requirements.md](requirements.md) - Feature requirements
- [roadmap.md](roadmap.md) - Milestone sequence
- [project-index.md](project-index.md) - Central navigation

**For Architecture:**
- [architecture/](architecture/) - Architecture Decision Records
- [learning-notes/](learning-notes/) - Implementation patterns

---

## 💡 PRO TIPS

### **First Session of the Day**
Complete ALL 8 checklist items - full context load is critical

### **Continuing Previous Session's Work**
Can skip items 5-7 if:
- Working on same feature
- No Core Data changes planned
- No new services being created
- Already on correct feature branch

BUT always complete items 1-4 + 8 - these ensure naming consistency and current context

### **Starting New Milestone/Component**
Complete ALL 8 items + additionally review:
- Relevant PRDs in `docs/prds/`
- Similar milestone learning notes
- Related ADRs for the feature area

### **Quick Context Refreshes**
If interrupted or switching contexts mid-session:
1. Re-read current-story.md (item 3)
2. Re-read next-prompt.md (item 4)
3. Verify M#.#.# naming still correct
4. Check git branch: `git branch` (should be on feature branch)

---

## 🚨 ENFORCEMENT

### **This Checklist is MANDATORY**

**Non-compliance indicators:**
- Using "Phase" or "Step" without M#.#.# identifier
- Creating services that duplicate existing ones
- Core Data changes without schema verification
- Documentation updates without checking current-story.md
- Code that contradicts established patterns
- Committing directly to main instead of feature branch
- Working without creating feature branch first

**If you catch non-compliance:**
1. Stop current work
2. Re-read this checklist
3. Complete missing items
4. Correct any inconsistencies
5. Resume work with proper context

### **Success Validation**

**Before committing ANY code or documentation:**
- [ ] All files use M#.#.# naming consistently
- [ ] current-story.md updated with progress
- [ ] No duplicate services or infrastructure
- [ ] Architecture follows established ADRs
- [ ] Documentation uses correct status indicators (✅ 🔄 🚀 ⏳)
- [ ] On feature branch (not main)
- [ ] Commits use M#.#.# format

---

## 📈 CONTINUOUS IMPROVEMENT

**This checklist evolves based on project needs.**

**Suggest additions when:**
- Common issues arise despite checklist
- New critical documents are created
- Process improvements are identified
- Project complexity increases

**Update frequency**: Review after each milestone completion

---

**Remember**: 10-15 minutes of checklist time saves hours of rework.

**Start every session here. No exceptions.**

---

**Version**: 2.1 - Product Validation Checkpoint  
**Created**: October 23, 2025  
**Last Updated**: December 21, 2025  
**Next Review**: After M7 completion
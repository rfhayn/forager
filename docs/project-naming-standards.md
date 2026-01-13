# Project Naming Standards
**Project**: forager iOS App  
**Version**: 3.0 - Enhanced with Quick Reference & Enforcement  
**Last Updated**: October 23, 2025  

---

## 🎯 QUICK REFERENCE CARD

**Current Active Work**: M4.1 (Settings Infrastructure Foundation)

### **Naming Format**
```
M[Major].[Component].[Task]

Examples:
M4       = Major Feature (Settings & Configuration)
M4.1     = Component (Settings Infrastructure)
M4.1.1   = Task (Core Settings Service)
```

### **Status Indicators**
| Icon | Status | Meaning |
|------|--------|---------|
| ✅ | **COMPLETE** | Fully implemented and validated |
| 🔄 | **ACTIVE** | Currently in development |
| 🚀 | **READY** | Ready to start implementation |
| ⏳ | **PLANNED** | Planned for future development |

### **Critical Rules**
1. **Always use full identifier**: "M4.1.1" not "Phase 1" or "Step 1"
2. **Update status in ALL docs**: current-story.md, project-index.md, roadmap.md
3. **Include descriptive name**: "M4.1.1: Core Settings Service"
4. **Maintain consistency**: Same naming everywhere, no variations

### **Non-Compliance Detection**
❌ **STOP if you see these patterns:**
- References like "Phase 3" or "Step 2" without M#.#.#
- Status icons used incorrectly or inconsistently
- New work not documented in current-story.md
- Missing updates to project-index.md after completion

---

## 📋 NAMING CONVENTION FRAMEWORK

### **3-Level Hierarchy Structure**

#### **Level 1: Major Features (M1, M2, M3...)**
- **Format**: M[Number]: [Feature Name]
- **Purpose**: High-level functional areas that represent complete product features
- **Scope**: 15-60+ hours of work, multiple components
- **Examples**: 
  - M1: Grocery Management
  - M2: Recipe Integration  
  - M3: Structured Quantity Management
  - M4: Meal Planning & Enhanced Grocery Integration

#### **Level 2: Feature Components (M2.1, M2.2, M2.3...)**
- **Format**: M[Major].[Component]: [Component Name]
- **Purpose**: Distinct functional components within a major feature
- **Scope**: 1-20 hours of work, can have multiple tasks
- **Examples**:
  - M2.1: Recipe Architecture Services
  - M2.2: Recipe Catalog
  - M2.3: Recipe Creation & Editing
  - M4.1: Settings Infrastructure Foundation

#### **Level 3: Implementation Tasks (M2.2.1, M2.2.2, M2.2.3...)**
- **Format**: M[Major].[Component].[Task]: [Task Name]
- **Purpose**: Specific implementation tasks or development steps within a component
- **Scope**: 15 minutes - 3 hours of focused work
- **Examples**:
  - M2.2.1: Basic Recipe List
  - M2.2.2: Recipe Detail View
  - M2.2.3: Ingredient Templates
  - M4.1.1: Core Settings Service

---

## 🎯 CURRENT PROJECT MAPPING

### **Completed Features**

#### **M1: Grocery Management** ✅ **COMPLETE** (32 hours - August 2025)
- M1.1: Core Data Foundation ✅
- M1.2: Performance Architecture ✅
- M1.3: Staples Management ✅
- M1.4: Custom Category System ✅
- M1.5: Auto-Generated Lists ✅

**Key Achievements:**
- Store-layout optimized grocery lists
- Custom category management
- Professional iOS UI with accessibility

#### **M2: Recipe Integration** ✅ **COMPLETE** (16.5 hours - Sept-Oct 2025)
- M2.1: Recipe Architecture Services ✅ **COMPLETE** (1 hour)
- M2.2: Recipe Catalog ✅ **COMPLETE** (10.5 hours)
  - M2.2.1: Basic Recipe List ✅
  - M2.2.2: Recipe Detail View ✅
  - M2.2.3: Ingredient Templates ✅
  - M2.2.4: Add to List Enhancement ✅
  - M2.2.5: Unified Ingredients View ✅
  - M2.2.6: Custom Category Integration ✅
- M2.3: Recipe Creation & Editing ✅ **COMPLETE** (5 hours)

**Key Achievements:**
- Complete recipe CRUD operations
- Recipe-to-grocery integration
- Ingredient autocomplete with parse-then-search
- Fuzzy matching and template alignment

#### **M3: Structured Quantity Management** ✅ **COMPLETE** (10.5 hours - October 2025)
- M3 Phase 1-2: Core Data Model & Enhanced Parsing ✅ (3 hours)
- M3 Phase 3: Data Migration ✅ (1.5 hours)
- M3 Phase 4: Recipe Scaling Service ✅ (2.5 hours)
- M3 Phase 5: Quantity Consolidation ✅ (2.5 hours)
- M3 Phase 6: UI Polish & Documentation ✅ (1 hour)

**Key Achievements:**
- Structured quantity parsing (amount + unit)
- Recipe scaling with unit conversion
- Intelligent quantity consolidation
- 30-50% reduction in list redundancy

#### **M3.5: Foundation Validation & Testing** ✅ **COMPLETE** (8.5 hours - October 2025)
- Comprehensive validation with automated test suite
- 75+ computed properties added
- 100% validation pass rate achieved
- Template system validation
- Test automation pattern established

**Key Achievements:**
- 6 comprehensive test suites
- Automated validation infrastructure
- Zero data integrity issues discovered
- Production-ready quality established

### **Active Development**

#### **M4: Meal Planning & Enhanced Grocery Integration** 🔄 **ACTIVE**
**Status**: Ready to begin (M3.5 complete)  
**Estimated Total**: 7.5-10 hours

- **M4.1: Settings Infrastructure Foundation** 🚀 **READY** (1.5 hours) ← **NEXT**
  - UserPreferences Core Data entity
  - Meal planning preferences in Settings tab
  - Duration, start day, auto-naming settings
  - Real-time validation and persistence

- **M4.2: Calendar-Based Meal Planning Core** ⏳ **PLANNED** (2.5 hours)
  - MealPlan and PlannedMeal entities
  - Clean one-week calendar with recipe assignment
  - User-configurable planning periods (3-14 days)
  - "Add to Meal Plan" buttons throughout app

- **M4.3: Enhanced Grocery Integration** ⏳ **PLANNED** (3.5-4 hours)
  - Generate grocery list from meal plan
  - Recipe source tags ("Ground beef [Tacos] [Spaghetti]")
  - Smart consolidation leveraging M3
  - Meal completion tracking
  - Scaled recipe to shopping list integration

### **Future Development**

- **M5: Recipe Tags & Organization** ⏳ **PLANNED**
- **M6: Analytics Dashboard** ⏳ **PLANNED**
- **M7: CloudKit Family Sharing** ⏳ **PLANNED**

---

## 📝 DOCUMENTATION STANDARDS

### **Status Indicators Usage**

**✅ COMPLETE**: 
- Feature fully implemented
- All tests passing
- Documentation updated
- No known bugs
- Ready for production use

**🔄 ACTIVE**: 
- Currently being worked on
- In this development session
- Code changes in progress
- May have temporary states

**🚀 READY**: 
- All prerequisites complete
- Next in queue
- Can start immediately
- Plan and estimates finalized

**⏳ PLANNED**: 
- Future work
- May have PRD or outline
- Not ready to start yet
- May change based on priorities

### **Time Tracking Format**

**For Completed Work:**
```
M2.2.5: Unified Ingredients View ✅ (4.5 hours) - COMPLETE
```

**For Active Work:**
```
M4.1: Settings Infrastructure Foundation 🔄 (1.5 hours estimated)
```

**For Planned Work:**
```
M4.2: Calendar-Based Meal Planning ⏳ (2.5 hours estimated)
```

### **Reference Format**

**In Text:**
```
Currently working on M4.1
Completed M3 Phase 6 (see learning notes)
Starting M4.1.1 next
```

**In Headers:**
```markdown
## M4.1: Settings Infrastructure Foundation
### M4.1.1: Core Settings Service
```

**In File Names:**
Use descriptive names, reference M#.#.# in content:
```
docs/learning-notes/18-m4.1-settings-infrastructure.md
docs/prds/milestone-4-meal-planning-and-settings-integration.md
```

---

## 🔧 IMPLEMENTATION GUIDELINES

### **When Creating New Work**

1. **Identify the appropriate level:**
   - New major feature? → Create M[next number]
   - Component of existing feature? → Create M[major].[next component]
   - Task within component? → Create M[major].[component].[next task]

2. **Assign next sequential number:**
   - Check current-story.md for latest numbers used
   - Don't skip numbers
   - Don't reuse numbers

3. **Use descriptive names:**
   - Clear indication of functionality
   - Consistent with similar features
   - Avoid abbreviations unless standard

4. **Document immediately:**
   - Add to current-story.md with 🚀 READY status
   - Update project-index.md with reference
   - Create PRD if 6+ hours of work

### **When Referencing Work**

**✅ DO:**
- Use full identifier: "M4.1.2"
- Include descriptive name when helpful: "M4.1.2: Calendar View Component"
- Keep status current: READY → ACTIVE → COMPLETE
- Update all documentation when status changes

**❌ DON'T:**
- Use ambiguous references: "Phase 3", "Step 2"
- Mix naming conventions: Don't use both "M4.1" and "Phase 1"
- Reference work not documented in current-story.md
- Leave outdated status indicators

### **Documentation Updates**

**When starting work:**
1. Update current-story.md: 🚀 READY → 🔄 ACTIVE
2. Set clear completion criteria
3. Note start time for tracking

**During work:**
1. Update progress notes in current-story.md
2. Document decisions in learning notes
3. Keep status current

**When completing work:**
1. Update current-story.md: 🔄 ACTIVE → ✅ COMPLETE
2. Add actual time spent
3. Update project-index.md with completion
4. Update roadmap.md if milestone complete
5. Create/update learning notes

**Maintain consistency across:**
- current-story.md
- project-index.md
- requirements.md
- roadmap.md
- learning notes

---

## 🎯 BENEFITS OF THIS SYSTEM

### **Clarity & Navigation**
- **Linear progression**: M2.2.1 → M2.2.2 → M2.2.3
- **Clear hierarchy**: Major → Component → Task
- **Easy reference**: "M4.1.2" is unambiguous
- **Quick lookups**: Know exactly where to find information

### **Scalability**
- **Unlimited expansion**: Can add M4.1.7, M5.3.1, M10.4.12, etc.
- **Logical grouping**: Related tasks stay together
- **Easy reorganization**: Can move tasks between components if needed
- **Consistent patterns**: Same approach scales from 1 to 100+ features

### **Project Management**
- **Progress tracking**: Clear completion percentage per component
- **Dependency management**: Easy to see what blocks what
- **Timeline estimation**: Granular time tracking at task level
- **Historical analysis**: Actual vs estimated hours by level

### **Communication**
- **Precise references**: No ambiguity in what's being discussed
- **Status clarity**: Instant understanding of work state
- **Documentation findability**: Know exactly which doc to check
- **Continuity**: New sessions start with clear context

---

## 📊 NAMING COMPLIANCE CHECKLIST

**Before starting ANY development work:**

- [ ] Read this document (project-naming-standards.md)
- [ ] Check current-story.md for current M#.#.# identifiers
- [ ] Verify work is documented with correct naming
- [ ] Confirm status indicator is accurate
- [ ] Review project-index.md for context

**During development:**

- [ ] Use full M#.#.# identifier in all references
- [ ] Update status when changing phases (READY → ACTIVE → COMPLETE)
- [ ] Document in current-story.md using correct naming
- [ ] Use consistent naming in code comments
- [ ] Reference correct milestone in learning notes

**After completing work:**

- [ ] Mark complete (✅) in current-story.md
- [ ] Add actual time spent
- [ ] Update project-index.md
- [ ] Update roadmap.md if milestone complete
- [ ] Verify all docs use consistent M#.#.# naming

---

## 🚨 ENFORCEMENT & NON-COMPLIANCE

### **Red Flags**

**STOP immediately if you see:**
- ❌ References like "Phase 3" without M#.#.# prefix
- ❌ "Step 2" or "Story 4" without proper hierarchy
- ❌ Mixed naming conventions in same document
- ❌ Work not documented in current-story.md
- ❌ Status indicators used incorrectly
- ❌ Missing updates to project-index.md after completion

### **Correction Process**

1. **Identify non-compliance** in any documentation
2. **Stop current work** - don't propagate incorrect naming
3. **Correct all instances** across all documentation
4. **Verify consistency** in current-story.md, project-index.md, roadmap.md
5. **Resume work** with correct naming

### **Prevention**

- **Session startup**: Always read this document first
- **Regular checks**: Reference this doc when documenting work
- **Documentation reviews**: Verify naming before marking complete
- **Consistency validation**: Cross-check multiple docs for agreement

---

## 📈 PROJECT VELOCITY USING THIS SYSTEM

**Completed with Consistent Naming:**
- M1: 32 hours (estimated 30-35h) - ✅ 91% accuracy
- M2: 16.5 hours (estimated 15-18h) - ✅ 92% accuracy
- M3: 10.5 hours (estimated 8-12h) - ✅ 88% accuracy
- M3.5: 8.5 hours (estimated 7h) - ✅ 82% accuracy

**Average Planning Accuracy**: 88% (< 12% variance)

**Success Factors:**
- Clear milestone/phase/task hierarchy
- Consistent naming enables accurate tracking
- Historical data improves future estimates
- Documentation consistency reduces confusion

---

## 🐙 GITHUB NAMING CONVENTIONS

### **GitHub Issues**

**Format**: `M#.#.#: [Descriptive Title]`

**Examples:**
```
M7.2.2: Member Invitation & Acceptance
M7.2.3: CloudKit Hardening & Shared Data Architecture
M7.5: Architecture Hardening - UX/Service Cleanup
```

**Creation:**
```bash
gh issue create \
  --title "M7.2.2: Member Invitation & Acceptance" \
  --label "milestone,feature" \
  --milestone "M7: CloudKit Sync & External TestFlight"
```

**Required Elements:**
- Milestone number prefix (M#.#.# or M#.#)
- Descriptive title (4-8 words)
- Appropriate labels
- Associated milestone group
- Task list in body

---

### **GitHub Milestones**

**Format**: `M#: [Major Feature Name]`

**Examples:**
```
M7: CloudKit Sync & External TestFlight
M8: Ingredient Parsing Intelligence
M9: Technical Debt & Codebase Optimization
```

**Purpose:**
- Group related issues under major features
- Track completion percentage
- Provide high-level progress visibility

**Note:** GitHub Milestones represent Level 1 (Major Features), while Issues can be Level 2 (Components) or Level 3 (Tasks)

---

### **GitHub Labels**

**Standard Labels:**

**Type Labels:**
- `milestone` - Work tied to documented milestone
- `feature` - New functionality
- `infrastructure` - Architecture, tooling, setup
- `bug` - Defect or incorrect behavior
- `documentation` - Docs, learning notes, ADRs

**Status Labels:**
- `in-progress` - Currently being worked on
- `blocked` - Waiting on dependency
- `completed` - Finished and merged

**Priority Labels:**
- `critical` - Blocking other work
- `high` - Important, schedule soon
- `medium` - Normal priority
- `low` - Nice to have

**Usage:**
```bash
gh issue create \
  --label "milestone,feature,high"
```

---

### **GitHub Project Board**

**Column Naming:**
- `Todo` - Planned work, not started
- `In Progress` - Active development
- `Done` - Completed and merged

**Card Movement:**
- Issues auto-add to "Todo" when created
- Manually move to "In Progress" when starting
- Auto-move to "Done" when issue closed

**Automation:**
- Closing issue → moves card to "Done"
- Reopening issue → moves card to "In Progress"

---

### **Wiki Page Naming**

**Format:** Descriptive kebab-case names (not M# prefixed)

**Examples:**
```
CloudKit-Implementation.md
Milestones-Overview.md
Learning-Notes-Index.md
Architecture-Decisions.md
Quick-Reference.md
```

**Content Structure:**
- Reference M#.#.# within content
- Link to source documentation
- Keep up-to-date with main repo

**Update Pattern:**
```markdown
### M7.2.2: Member Invitation ✅ COMPLETE (11-12 hours)
- Feature description
- Key achievements
- Documentation links
```

---

### **Branch Naming**

**Format**: `feature/M#.#.#-brief-description`

**Examples:**
```
feature/M7.1.1-cloudkit-schema-validation
feature/M7.2.2-member-invitation
feature/M7.5-architecture-hardening
```

**Rules:**
- Prefix: `feature/` (always)
- Milestone: Exact M#.#.# identifier
- Description: 2-5 words, kebab-case
- Delete after PR merge

**See:** [git-workflow-for-milestones.md](git-workflow-for-milestones.md) for complete workflow

---

### **Commit Message Naming**

**Format:**
```
M#.#.#: Brief description (imperative mood)

- Bullet point of changes
- Another change
- Test results
```

**Examples:**
```bash
git commit -m "M7.2.2: Implement public link sharing for household invitations

- Bypass UICloudSharingController (broken on iOS 18.x)
- Add ShareSheet integration for URL sharing
- Update InviteMemberSheet with public link flow
- Successfully tested on Device A

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Milestone Completion Commits:**
```bash
git commit -m "M7.2.2: Mark complete - Member invitation working (11-12h)

Member invitation and acceptance system fully operational.

Completion Status:
- Public link sharing working
- Bug fixes applied
- Documentation complete

Bug Fixes:
- Fixed display name extraction
- Extended sync retry to 30s

Documentation:
- docs/m7-docs/32: Public Link Sharing
- docs/m7-docs/33: Device B Bug Fixes
- Wiki updates complete

GitHub:
- Issue #22 closed
- Project board updated to Done

Time: 11-12h actual vs 2-3h estimated (iOS 18.x bugs)

Next: M7.3 (Conflict Resolution) or M7.5 (Architecture Hardening)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### **Pull Request Naming**

**Title Format**: `M#.#.#: [Descriptive Title]`

**Examples:**
```
M7.1.1: CloudKit Schema Validation
M7.2.2: Member Invitation & Acceptance
M7.5: Architecture Hardening - UX/Service Cleanup
```

**Body Template:**
```markdown
## Summary
Brief description of changes

## Changes
- Change 1
- Change 2
- Change 3

## Testing
- ✅ Test 1
- ✅ Test 2

## Time
- Estimated: X hours
- Actual: Y hours

## Next
M#.#.#: Next milestone
```

---

### **Forward-Only Naming Policy**

**Principle**: Don't rename historical work - maintain naming as it was created

**Rationale:**
- Preserves historical accuracy
- Avoids breaking documentation links
- Maintains git history integrity
- Focuses energy on future work

**Apply To:**
- ✅ **New work**: Use current standards
- ✅ **Documentation updates**: Reference old names correctly
- ❌ **Don't rename**: Past issues, branches, commits, docs

**Example:**
```markdown
# OLD (created before GitHub integration):
M7.2.2 documented in learning notes only

# NEW (created after GitHub integration):
M7.5: Issue #25, Project Board, Wiki, Learning Notes

# CORRECT APPROACH:
- Keep M7.2.2 docs as-is
- Start GitHub integration with M7.5
- Note transition point in documentation
```

**Transition Point Documentation:**
```markdown
## GitHub Integration Timeline

**Before Jan 2026**: Milestones documented in learning notes and wiki only
**After Jan 2026**: Milestones fully tracked in GitHub Issues and Project Board

**Legacy Milestones** (pre-GitHub tracking):
- M7.1: CloudKit Sync Foundation
- M7.2.1: Household Setup Foundation
- M7.2.2: Member Invitation & Acceptance
- M7.2.3: CloudKit Hardening

**GitHub-Tracked Milestones**:
- M7.5: Architecture Hardening (Issue #XX)
- M7.6: External TestFlight (Issue #XX)
- Future milestones...
```

---

### **GitHub Naming Checklist**

**When Starting New Milestone:**
- [ ] Create GitHub Issue with M#.#.# prefix
- [ ] Add to appropriate Milestone group (M#)
- [ ] Apply correct labels (milestone, feature/infrastructure)
- [ ] Add to Project Board
- [ ] Document in wiki (if major milestone)

**During Development:**
- [ ] Use M#.#.# in all commit messages
- [ ] Update issue task list as work progresses
- [ ] Move project board card when status changes

**When Completing Milestone:**
- [ ] Close issue with comprehensive summary
- [ ] Verify project board auto-updated to "Done"
- [ ] Update wiki pages with completion status
- [ ] Create completion commit with M#.#.# prefix
- [ ] Include time variance and lessons learned

---

## 🔗 RELATED DOCUMENTS

**Essential Reading:**
- [session-startup-checklist.md](session-startup-checklist.md) - Start every session here
- [development-guidelines.md](development-guidelines.md) - Code standards and patterns
- [current-story.md](current-story.md) - Current milestone status
- [next-prompt.md](next-prompt.md) - Implementation guidance

**Reference:**
- [project-index.md](project-index.md) - Central navigation hub
- [roadmap.md](roadmap.md) - Milestone sequence and completion
- [requirements.md](requirements.md) - Functional requirements

**Process:**
- [ADR 007](architecture/007-core-data-change-process.md) - Core Data impact analysis
- [learning-notes/](learning-notes/) - Implementation patterns and lessons

---

**Key Rule**: Always use this naming convention in ALL documentation and code references. Zero tolerance for ambiguous or inconsistent naming.

**Version**: 3.0 - Enhanced with Quick Reference & Enforcement  
**Last Updated**: October 23, 2025  
**Next Review**: After M4 completion
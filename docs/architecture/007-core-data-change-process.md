# Architecture Decision Record: 007 - Core Data Schema Change Process

**Date**: October 10, 2025  
**Status**: Accepted  
**Context**: M3 Structured Quantity Management - Phase 1-2 Implementation  
**Deciders**: Development Team  

---

## Decision Summary

We will require a comprehensive **Core Data Impact Analysis** before making ANY schema changes, including mandatory project-wide searches and documented file checklists in all PRDs.

---

## Context

### Problem Encountered (M3 Phase 1-2)

During M3 implementation, we changed the Core Data schema (removed `quantity` and `unit` fields, added structured quantity fields) and encountered:

**What Went Wrong:**
1. Changed schema without searching for property usage first
2. Found affected files through build errors (reactive approach)
3. Spent 30 minutes fixing files one-by-one
4. 10 files affected total (found incrementally through errors)
5. Process was stressful and inefficient

**What Should Have Happened:**
1. Search project for property usage BEFORE changes (10 minutes)
2. Document all affected files in PRD (complete checklist)
3. Update files systematically in dependency order
4. Build once at end with zero errors

**Impact:**
- Time lost: ~30 minutes of reactive fixing
- Developer stress: High (surprise after surprise)
- Process quality: Poor (reactive vs proactive)
- Documentation gap: No impact analysis in PRD

### The Core Problem

**Core Data schema changes have ripple effects**, but we had no systematic way to:
1. Identify all affected files before starting
2. Plan updates in correct dependency order
3. Estimate time accurately based on actual impact
4. Prevent surprise files during implementation

---

## Decision

### Phase 0: Factory Compliance (ADR 014)
Before making schema changes, verify that all creation sites for the affected entity use `ManagedObjectFactory`. Run `/forager-architecture-audit` to check.

### Mandatory Core Data Impact Analysis

**For ANY Core Data schema change, we will:**

1. **Pre-Implementation Search (REQUIRED)**
   - Search entire project for property usage
   - Document ALL affected files with line numbers
   - Categorize files by layer (Core Data, Service, UI, Other)
   - Include search methodology in PRD

2. **Impact Analysis Section in PRD (REQUIRED)**
   - List all affected files with update descriptions
   - Document update strategy in dependency order
   - Provide time estimates per file category
   - Include risk assessment

3. **Systematic Update Process (REQUIRED)**
   - Update files in dependency order (Core Data → Service → UI)
   - Use checklist to track completion
   - Build once after all updates complete
   - Document any unexpected files found

4. **Template Usage (REQUIRED)**
   - Use `docs/templates/core-data-impact-analysis.md`
   - Complete template before PRD approval
   - Validate file list completeness
   - Update template based on lessons learned

---

## Decision Details

### Mandatory Searches

**Before ANY Core Data schema change:**

```bash
# In Xcode (⌘⇧F - Find in Project)

1. Direct property access:
   Search: ".propertyName"
   Example: ".quantity"
   
2. String literals:
   Search: "propertyName"
   Example: "quantity"
   
3. KeyPath references:
   Search: \\Entity.propertyName
   Example: \\Ingredient.quantity
   
4. Predicate usage:
   Search: NSPredicate.*propertyName
   Example: NSPredicate.*quantity
```

**Document Results:**
- List every file found
- Note line numbers
- Describe required change
- Estimate time per file

### Required PRD Section

**Every PRD with Core Data changes MUST include:**

```markdown
## Core Data Impact Analysis

### Schema Changes
- Entities Modified: [List]
- Properties Removed: [List with types]
- Properties Added: [List with types]
- Relationships Changed: [List]

### Comprehensive Search Completed: ✅
**Search Method**: Xcode Find in Project (⌘⇧F)
**Properties Searched**: [List each search term]
**Total Files Found**: [Number]

### Affected Files

#### Core Data Layer
- [ ] File.swift:LineNum - [Change description]

#### Service Layer  
- [ ] File.swift:LineNum - [Change description]

#### UI Layer
- [ ] File.swift:LineNum - [Change description]

#### Other
- [ ] File.swift:LineNum - [Change description]

### Update Strategy
1. Phase 1: Core Data schema + property generation
2. Phase 2: Service layer updates
3. Phase 3: UI layer updates (in order)
4. Phase 4: Sample data + other

### Time Estimate
- Schema: [X] min
- Service ([N] files × 15 min): [Y] min
- UI ([N] files × 10 min): [Z] min
- Other ([N] files × 5 min): [W] min
- Buffer (30%): [B] min
- **Total: [TOTAL] min ([HOURS] hours)**

### Risk Assessment
- High Risk: [Files where errors break app]
- Medium Risk: [Files where errors degrade UX]
- Low Risk: [Files where errors are cosmetic]
```

### Update Dependency Order

**Always update in this order:**

1. **Core Data Schema** (.xcdatamodeld)
   - Modify entities/properties
   - Set codegen appropriately
   - Add indexes if needed

2. **Property Files** (Entity+CoreDataProperties.swift)
   - Delete old property files
   - Regenerate via Editor → Create NSManagedObject Subclass
   - Verify property types match expectations

3. **Service Layer** (Services/*.swift)
   - Update parsing services
   - Update data services
   - Update migration services

4. **UI Layer** (Views/*.swift)
   - Update in dependency order
   - Forms before displays
   - Parent views before child views

5. **Other** (Persistence.swift, Tests, etc.)
   - Update sample data
   - Update test fixtures
   - Update preview providers

### Time Estimation Formula

```
Total Time = Schema Time + (Service Files × 15min) + (UI Files × 10min) + (Other × 5min) + 30% Buffer

Example (M3):
- Schema: 60min
- Service (1 × 15): 15min
- UI (5 × 10): 50min  
- Other (1 × 5): 5min
- Subtotal: 130min
- Buffer (30%): 39min
- Total: 169min (~2.8 hours)
```

---

## Consequences

### Benefits

**Positive:**
- ✅ No surprise files during implementation
- ✅ Accurate time estimates in PRDs
- ✅ Systematic, stress-free updates
- ✅ Professional development process
- ✅ Better PRD quality and completeness
- ✅ Institutional knowledge captured
- ✅ Reusable process for all Core Data changes

**Process Improvements:**
- Complete file list before starting
- Clear update strategy documented
- Risk identification upfront
- Time estimates based on reality
- Checklist-driven implementation

### Costs

**Negative:**
- ⏱️ Additional 10-15 minutes for search and documentation
- 📝 More upfront PRD work required
- 🔄 Template maintenance needed

**Mitigation:**
- Time investment pays for itself (saves 30+ min of fixing)
- Template makes documentation faster
- Process becomes automatic with practice

### Risks

**If We Don't Follow This Process:**
- Repeated reactive fixing (wastes time)
- Incomplete PRD estimates (planning failure)
- Developer stress from surprises
- Quality issues from rushed fixes
- No institutional learning

**If We Do Follow This Process:**
- Minimal risk (systematic approach proven)
- Known files, known changes, known time
- Professional execution
- Continuous process improvement

---

## Compliance

### Required for PRD Approval

**A PRD with Core Data changes CANNOT be approved without:**
- ✅ Completed impact analysis section
- ✅ Comprehensive search results documented
- ✅ All affected files listed with changes described
- ✅ Update strategy in dependency order
- ✅ Time estimates justified by file count
- ✅ Risk assessment completed

### Review Checklist

**Before approving PRD:**
- [ ] Impact analysis section present and complete
- [ ] Search methodology documented (what was searched)
- [ ] All affected files listed with line numbers
- [ ] Update strategy follows dependency order
- [ ] Time estimate formula applied correctly
- [ ] Risk assessment identifies high-risk files
- [ ] Template used correctly

### Implementation Checklist

**During implementation:**
- [ ] Follow file update order from PRD
- [ ] Check off items as completed
- [ ] Document any unexpected files found
- [ ] Build only after all updates complete
- [ ] Update learning notes with lessons

---

## Alternatives Considered

### Alternative 1: "Build Will Tell Us" Approach
**Description**: Make schema changes, fix build errors as they appear  
**Rejected Because**:
- Reactive instead of proactive
- Wastes time on iterative fixing
- Causes developer stress
- Misses files that don't cause immediate errors
- No systematic approach

### Alternative 2: "Dual Storage" Migration
**Description**: Keep old fields, add new fields, migrate gradually  
**Rejected Because**:
- Creates technical debt
- Confusing which field to use
- Doubles storage requirements
- Complicates codebase unnecessarily
- Not suitable for pre-production apps

### Alternative 3: "Manual Expertise" Approach
**Description**: Rely on developer memory of affected files  
**Rejected Because**:
- Human memory is fallible
- Not scalable to team
- No documentation
- Misses files inevitably
- No process improvement

### Why Our Solution Is Better
- ✅ Systematic and repeatable
- ✅ Complete and comprehensive
- ✅ Documented and teachable
- ✅ Proactive not reactive
- ✅ Scales to any team size
- ✅ Creates institutional knowledge

---

## Implementation

### Phase 1: Template Creation (Complete ✅)
- Created `docs/templates/core-data-impact-analysis.md`
- Includes all required sections
- Examples from M3 included
- Ready for immediate use

### Phase 2: Process Documentation (Complete ✅)
- This ADR documents the decision
- Learning notes capture M3 lessons
- Search methodology documented
- Update order established

### Phase 3: Integration (In Progress)
- [ ] Update `docs/development-guidelines.md`
- [ ] Reference in `docs/project-naming-standards.md`
- [ ] Add to PRD template
- [ ] Update `docs/project-index.md`

### Phase 4: Team Adoption (Future)
- [ ] Review this ADR with team
- [ ] Practice on next Core Data change
- [ ] Refine template based on experience
- [ ] Build team expertise

---

## Validation

### Success Criteria

**This decision succeeds if:**
1. Future Core Data PRDs include complete impact analysis
2. No surprise files during Core Data implementations
3. Time estimates are accurate (±20%)
4. Zero reactive build-fix cycles
5. Team follows process consistently

### Metrics to Track

**For Each Core Data Change:**
- Time spent on impact analysis
- Number of files identified in analysis
- Number of unexpected files found during implementation
- Actual vs estimated time
- Developer satisfaction with process

### Review Schedule

- After next 3 Core Data changes: Review template effectiveness
- After 6 months: Assess team adoption and process refinement
- Annually: Update template with accumulated learnings

---

## Related Documents

**Templates:**
- `docs/templates/core-data-impact-analysis.md` - Required template

**Learning Notes:**
- `docs/learning-notes/14-m3-phase1-2-structured-quantities.md` - M3 lessons

**Guidelines:**
- `docs/development-guidelines.md` - References this process
- `docs/project-naming-standards.md` - Naming conventions

**PRDs:**
- `docs/prds/milestone-3-qty-mgmt-prd.md` - Will be updated with impact analysis

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-10-10 | Initial ADR based on M3 learnings | Development Team |

---

**Decision Status**: ✅ **ACCEPTED**

This process is now **mandatory** for all Core Data schema changes. The time investment upfront (10-15 minutes) saves significant time (30+ minutes) and stress during implementation.

**Next Action**: Update all documentation to reference this ADR and require impact analysis for Core Data PRDs.
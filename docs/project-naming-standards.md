# Project Naming Standards

**Project**: forager iOS App

---

## Forward-Only Migration Notice (2026-04-18)

For **new work**, consult [`docs/openspec-workflow-reference.md`](openspec-workflow-reference.md) as the authoritative source for naming and workflow. New OpenSpec changes use descriptive kebab-case change IDs (e.g., `architecture-compliance-sweep`, `migrate-to-structured-logging`) rather than `M#.#.#` milestone numbers.

The M#.#.# specification below remains correct for **historical work**: archived PRDs, git history, ADR references, journal entries, active backlog PRDs not yet picked up, and in-flight legacy branches (e.g., M7.7 launch work). Forward-only policy — no retroactive renames.

See `openspec/specs/architecture/spec.md` for the cross-cutting architectural rules that both naming eras share, and `openspec/specs/developer-tooling/spec.md` for the workflow skills that accept both formats during the transition.

---

## Quick Reference Card

### Naming Format
```
M[Major].[Component].[Task]

M7       = Major Feature (CloudKit Sync & Household Sharing)
M7.2     = Component (Member Invitation & Acceptance)
M7.2.3   = Task (CloudKit Hardening & Shared Data Architecture)
```

### Status Indicators
| Icon | Status | Meaning |
|------|--------|---------|
| COMPLETE | **COMPLETE** | Fully implemented and validated |
| ACTIVE | **ACTIVE** | Currently in development |
| READY | **READY** | Ready to start implementation |
| PLANNED | **PLANNED** | Planned for future development |

### Critical Rules
1. **Always use full identifier**: "M4.1.1" not "Phase 1" or "Step 1"
2. **Update status in ALL docs**: current-story.md, project-index.md
3. **Include descriptive name**: "M4.1.1: Core Settings Service"
4. **Maintain consistency**: Same naming everywhere, no variations

### Non-Compliance Detection
STOP if you see:
- References like "Phase 3" or "Step 2" without M#.#.#
- Status icons used incorrectly
- New work not documented in current-story.md

---

## GitHub Conventions

### Branch Naming
Format: `feature/M#.#.#-brief-description` (2-5 words, kebab-case)
```
feature/M7.1.1-cloudkit-schema-validation
feature/M9.16-grocery-list-item-service
```

### Commit Messages
Format: `M#.#.#: Brief description (imperative mood)`
```
M9.16: Consolidate grocery list item creation into unified service

- New GroceryListItemService replacing 6 independent paths
- Cross-store category resolution via resolveCategory()
- 0 warnings, all tests pass
```
No Co-Authored-By credits.

### Pull Requests
Title: `M#.#.#: Descriptive Title`
Body: Summary, Changes, Testing, Time (estimated vs actual), Next milestone.

### Issues
Format: `M#.#.#: Descriptive Title` with labels `milestone,feature`
```bash
gh issue create --title "M9.16: Unified GroceryListItemService" --label "milestone,feature"
```

### Forward-Only Policy
Don't rename historical work. Apply current standards to new work only.

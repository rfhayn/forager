---
name: forager-prd-audit
description: Audit a PRD against the current codebase before implementation. Verifies entity names, property names, save counts, and API signatures are still accurate.
argument-hint: <path to PRD>
---

# PRD Freshness Audit

**PRD to audit**: $ARGUMENTS

If a PRD is >2 weeks old, it may reference entity names, properties, or APIs that have changed. This audit verifies accuracy before implementation.

## Step 1: Read the PRD

Read the specified PRD file completely.

## Step 2: Entity Verification

For each Core Data entity referenced in the PRD:
- Search `Models/<EntityName>+CoreDataProperties.swift` for actual property names and types
- Compare with what the PRD describes
- Flag any mismatches

## Step 3: Service API Verification

For each service method referenced in the PRD:
- Search the actual service file for the method signature
- Verify parameter names, types, and return values match
- Check if the method still exists or was renamed/removed

## Step 4: View Structure Verification

For each view referenced in the PRD:
- Verify the file exists at the stated path
- Check if the view structure matches the PRD description
- Note any new views or removed views since the PRD was written

## Step 5: Save Count Verification

Count the number of `context.save()` calls described in the PRD flow and compare with the actual service implementation. Mismatched save counts indicate architectural drift.

## Step 6: Report

```markdown
## PRD Audit: [PRD Name]

### PRD Age
- Created: [date]
- Last updated: [date]
- Age: [days]

### Entity Accuracy
- [Entity]: [MATCH / MISMATCH — details]

### API Accuracy
- [Service.method()]: [MATCH / MISMATCH — details]

### View Accuracy
- [ViewName]: [MATCH / MISMATCH — details]

### Save Count Accuracy
- PRD describes: [N] saves
- Actual code: [N] saves
- [MATCH / MISMATCH]

### Recommended PRD Updates
- [List of specific corrections needed]
```

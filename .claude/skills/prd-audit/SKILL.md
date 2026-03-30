---
name: prd-audit
description: Audit a PRD against the current codebase before implementation. Verifies entity names, property names, and API signatures are still accurate. TRIGGER when the user says "audit the PRD", "check the PRD", "is the PRD still accurate", or when starting implementation of a PRD that is more than 2 weeks old.
argument-hint: <path to PRD>
---

# PRD Freshness Audit

**PRD to audit**: $ARGUMENTS

If a PRD is >2 weeks old, it may reference names, properties, or APIs that have changed. This audit verifies accuracy before implementation.

## Step 1: Read the PRD

Read the specified PRD file completely.

## Step 2: API/Interface Verification

For each function, method, or API referenced in the PRD:
- Search the actual source file for the signature
- Verify parameter names, types, and return values match
- Check if the function still exists or was renamed/removed

## Step 3: File Structure Verification

For each file or module referenced in the PRD:
- Verify the file exists at the stated path
- Check if the structure matches the PRD description
- Note any new or removed files since the PRD was written

## Step 4: Report

```markdown
## PRD Audit: [PRD Name]

### PRD Age
- Created: [date]
- Last updated: [date]
- Age: [days]

### API Accuracy
- [Module.function()]: [MATCH / MISMATCH — details]

### File Accuracy
- [FileName]: [MATCH / MISMATCH — details]

### Recommended PRD Updates
- [List of specific corrections needed]
```

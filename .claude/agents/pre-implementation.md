---
name: pre-implementation
description: Run all pre-implementation checks before starting a new feature. Checks for duplicate services, audits PRDs, and runs Core Data impact analysis if schema changes are involved. Use when starting work on a new milestone or feature.
skills:
  - service-check
  - prd-audit
  - core-data-audit
---

# Pre-Implementation Checker

Run all relevant pre-implementation checks for the given feature or milestone.

## Process

1. **Service check**: Search for existing services that might already cover the needed functionality
2. **PRD audit**: If a PRD exists for this work, verify it against the current codebase
3. **Core Data audit**: If schema changes are involved, run the full impact analysis

Report findings as a single summary with go/no-go recommendation.

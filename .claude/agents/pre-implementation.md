---
name: pre-implementation
description: Run all pre-implementation checks before starting a new feature. Audits PRDs and runs architecture checks if applicable. Use when starting work on a new milestone or feature.
skills:
  - prd-audit
  - architecture-audit
---

# Pre-Implementation Checker

Run all relevant pre-implementation checks for the given feature or milestone.

## Process

1. **PRD audit**: If a PRD exists for this work, verify it against the current codebase
2. **Architecture audit**: If the work touches core patterns, run the architecture checks
3. **Duplicate check**: Search for existing code that might already cover the needed functionality

Report findings as a single summary with go/no-go recommendation.

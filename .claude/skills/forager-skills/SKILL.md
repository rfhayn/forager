# Forager Skills

List all available forager project skills.

## Instructions

Print the following skills table. Do not run any tools — just output the table directly.

## Output

```
Forager Project Skills
======================

Workflow:
  /forager-session-start      Startup checklist + status line (every session)
  /forager-new-milestone      Set up new milestone (branch + per-milestone docs)
  /forager-build              Build with correct Xcode config
  /forager-commit             Commit with M#.#.# conventions + journal check
  /forager-pr                 Create PR with project format
  /forager-release-prep       Full pipeline: branch → PR → merge → TestFlight
  /forager-archive            Archive + upload to TestFlight

Documentation:
  /forager-dev-journal        Write session narrative entry
  /forager-log-insight        Log a technical insight
  /forager-milestone-complete Update all 7 core docs + cleanup

Pre-Development:
  /forager-core-data-audit    Schema impact analysis (ADR 007)
  /forager-service-check      Check for existing services
  /forager-prd-audit          Verify PRD against current code
  /forager-architecture-audit Factory/scope/service layer violations

Meta:
  /forager-skills             This list

Multi-Session Notes:
  - Each milestone gets its own next-prompt: docs/next-prompt-M#.#.md
  - Status line is branch-keyed (no cross-session conflicts)
  - current-story.md supports multiple ACTIVE milestones
```

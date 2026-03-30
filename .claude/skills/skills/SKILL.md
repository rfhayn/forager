---
name: skills
description: "List all available project skills with usage guidance. TRIGGER when the user says \"list skills\", \"what skills are available\", \"show skills\", \"what can you do\", \"help\", or any request to see available commands."
---

# Project Skills

List all available project skills with usage guidance.

## Instructions

Print the following skills reference. Do not run any tools — just output the content directly.

## Output

```
Project Skills Reference
========================

WORKFLOW — Daily development cycle
  /session-start        Start here. Every session. Loads context, registers worker,
                        reports status. MANDATORY.
  /new-milestone        Creates feature branch + next-prompt file + updates docs.
                        Usage: /new-milestone AUTH-1 Build user login
  /build                Runs the project's build command. Configure in SKILL.md first.
  /commit               Stages files, formats commit with PREFIX-#.# prefix.
                        Logs event to orchestration if available.
  /pr                   Creates a PR with structured body. Suggests /review first.
  /release-prep         Full deployment pipeline. Configure for your stack first.

DOCUMENTATION — Knowledge capture
  /dev-journal          Write session narrative (decisions, learning, AI observations).
                        MANDATORY before every commit.
  /log-insight          Capture a technical insight immediately. Don't defer.
                        Usage: /log-insight topic The insight text
  /milestone-complete   Wraps up a milestone: updates docs, cleans up next-prompt
                        file, releases locks, writes retro.
                        Usage: /milestone-complete AUTH-1

PRE-DEVELOPMENT — Quality gates
  /prd-audit            Verify a PRD against current codebase. Use if PRD is >2 weeks old.
                        Includes Core Data entity + save count verification.
  /architecture-audit   Check for factory bypass, raw assign, scope compliance,
                        service layer violations (ADR 013/014).
  /core-data-audit      Full Core Data impact analysis. Required by ADR 007 before
                        schema changes. Checks entities, relationships, codegen, usage.
  /service-check        Search 28+ existing services before creating new ones.
                        Prevents duplication, enforces service layer pattern.
  /review               Pre-PR quality check. Validates naming, manifest, docs, code quality.
                        Usage: /review (branch) or /review 42 (PR number)

iOS DEPLOYMENT — App Store / TestFlight
  /archive              Full TestFlight automation: bump build, archive, upload,
                        distribute. Handles API keys, export compliance, beta groups.

ORCHESTRATION — Multi-worker coordination
  /claim                Declare session type (build/research), generate file manifest,
                        lock files. Required before modifying code in orchestration mode.
                        Usage: /claim AUTH-1 or /claim auto (self-assign)
  /release              Release all file locks and deregister this worker.
  /blocked              Report that you're blocked on a locked file. Starts 15-min
                        wait/escalation cycle with options (wait, skip, force-claim).
  /status               Quick inline view of workers, locks, and recent activity.
  /supervisor           Launch the orchestration loop. Dispatches work, monitors
                        progress, resolves conflicts. One supervisor at a time.
  /spawn                Launch a new Claude Code session in a tmux pane.
                        Usage: /spawn build AUTH-1 Login flow
                        Usage: /spawn research CACHE-1 Caching strategies
  /handoff              Structured handoff between workers. Commits pending work,
                        creates a handoff doc, releases locks, notifies target.
  /assign               Supervisor-only. Auto-dispatches unclaimed milestones to agents.
                        Usage: /assign 3 (spawn 3 agents for top priorities)

META
  /skills               This reference
```

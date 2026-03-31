---
name: start-project
description: "Guided first-time setup wizard for a Clauductor project. Walks through each configuration step, skipping items already completed. TRIGGER when the user says \"start project\", \"set up project\", \"configure project\", \"first time setup\", \"initialize project\", \"onboard\", or at initial project setup."
---

# Start Project — Guided Setup Wizard

Walk through each setup step interactively. Skip items that are already configured.

## Step 1: Check CLAUDE.md Setup Checklist

Read `CLAUDE.md` and check the Setup Checklist section. For each item:
- If already completed (checked `[x]`), skip it
- If uncompleted (`[ ]`), guide the user through it below

Report which items are done and which remain.

## Step 2: Define PREFIX Registry

Read `CLAUDE.md` and check the Prefix Registry table.

If it still contains the `_TODO_` placeholder:
1. Ask the user: "What are the main domain areas of your project? (e.g., AUTH for authentication, API for public API, UI for user interface)"
2. For each domain they name, add a row to the Prefix Registry table in `CLAUDE.md`
3. Also update the table in `docs/project-naming-standards.md`
4. Mark the "First milestone" checklist item as in-progress

If already populated, show the current registry and ask if any new prefixes are needed.

## Step 3: Configure Build Command

Read the Build & Run section in `CLAUDE.md`.

If it contains `echo "BUILD COMMAND NOT CONFIGURED"`:
1. Ask the user: "What command builds your project? (e.g., `npm run build`, `cargo build`, `go build ./...`)"
2. Replace the placeholder in `CLAUDE.md`
3. Also update `.claude/skills/build/SKILL.md` with the same command
4. Mark the checklist item as done: change `[ ]` to `[x]`

If already configured, confirm it and skip.

## Step 4: Configure Test Command

Read the Build & Run section in `CLAUDE.md`.

If it contains `echo "TEST COMMAND NOT CONFIGURED"`:
1. Ask: "What command runs your tests? (e.g., `npm test`, `pytest`, `go test ./...`). Enter 'skip' if no tests yet."
2. If not skipped, replace the placeholder in `CLAUDE.md`
3. Mark the checklist item as done

If already configured, confirm it and skip.

## Step 5: Describe Project Architecture

Read the Architecture section in `CLAUDE.md`.

If it still contains the `TODO: Describe your project's architecture` placeholder:
1. Scan the project structure: !`ls -la` and !`find . -maxdepth 2 -type f -name '*.go' -o -name '*.ts' -o -name '*.py' -o -name '*.rs' -o -name '*.java' | head -30`
2. Ask the user to describe or confirm:
   - Tech stack and frameworks
   - Key directories and their purpose
   - Data layer (database, ORM)
   - Any important patterns or conventions
3. Write a concise architecture section in `CLAUDE.md`
4. Mark the checklist item as done

If already populated, skip.

## Step 6: Configure Deployment Pipeline

Read `.claude/skills/release-prep/SKILL.md`.

If it contains unconfigured placeholders:
1. Ask: "Do you have a deployment pipeline? If yes, describe the steps (e.g., `npm run deploy`, `kubectl apply`, push to branch). Enter 'skip' if not applicable."
2. If not skipped, update the release-prep skill with the deployment commands
3. Mark the checklist item as done

## Step 7: Define Architecture Audit Rules

Read `.claude/skills/architecture-audit/SKILL.md`.

If it contains unconfigured placeholders:
1. Ask: "What architectural rules should be enforced? Examples: 'no direct DB access outside the data layer', 'all API routes go through middleware', 'components must not import from pages'. Enter 'skip' to configure later."
2. If not skipped, update the architecture-audit skill
3. Mark the checklist item as done

## Step 8: Create First Milestone

If `docs/current-story.md` has no active milestones:
1. Ask: "What's the first piece of work? Give it a PREFIX-#.# identifier and brief title (e.g., AUTH-1: User login flow)"
2. Run `/new-milestone [PREFIX-#.#] [title]` to create the branch and next-prompt file
3. Mark the checklist item as done

If milestones already exist, skip.

## Step 9: Summary

Report what was configured:
```
Project Setup Complete
======================
✓ Prefix registry: [prefixes]
✓ Build command: [command]
✓ Test command: [command or "not configured"]
✓ Architecture: [described or "needs description"]
✓ Deployment: [configured or "not configured"]
✓ Audit rules: [configured or "not configured"]
✓ First milestone: [PREFIX-#.# or "not yet created"]

Remaining:
- [any uncompleted items]

Next: Run /start-work [PREFIX-#.#] to begin development.
```

---
name: release-prep
description: "Full release pipeline from feature branch to deployment. ⚠️ CONFIGURE FIRST: Define your deployment steps below. TRIGGER when the user says \"release this\", \"ship it\", \"deploy\", \"push to production\", \"go live\", \"let's deploy\", or any request to take a feature branch through to deployment."
---

# Release Prep — Branch to Deployment

## ⚠️ CONFIGURATION REQUIRED

This skill needs your project's deployment pipeline. Update the steps below.

## Current State

- Branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`
- Commits since main: !`git log main..HEAD --oneline 2>&1`

## Pre-Flight Checks

- [ ] NOT on `main` (must be on a feature branch)
- [ ] All changes committed
- [ ] At least one commit ahead of main
- [ ] `docs/development-journal.md` has current session entry

## Step 1: Push Branch

```bash
git push -u origin <branch-name>
```

## Step 2: Create Pull Request

Detect milestone from branch name and create PR using `/pr` conventions.

## Step 3: Merge to Main

```bash
gh pr merge <PR-NUMBER> --squash --delete-branch
git checkout main
git pull origin main
```

## Step 4: Deploy

```bash
# TODO: Replace with your deployment steps. Examples:
#   npm run deploy
#   ./deploy.sh production
#   docker build && docker push
#   fastlane release
echo "DEPLOYMENT NOT CONFIGURED — edit .claude/skills/release-prep/SKILL.md"
```

## Step 5: Final Report

```
Release Pipeline Complete

Git:
  Branch:    <branch-name> → main (squash merged)
  PR:        #<number> (<url>)

Deploy:
  Status:    [from deployment output]
```

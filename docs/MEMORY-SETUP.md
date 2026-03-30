# Memory System Setup

Claude Code has a persistent memory system that survives across conversations. This framework uses it to capture user preferences, feedback, project context, and external references.

## How It Works

Memory files live at `~/.claude/projects/<project-path-hash>/memory/`. Claude Code reads `MEMORY.md` from this directory at the start of every conversation, which acts as an index pointing to individual memory files.

## Setting Up Memory

Memory is automatically created by Claude Code when you tell it to remember something. You can also set it up proactively:

### 1. Tell Claude Code about yourself

In your first session, share context that will help across all sessions:
- Your role and experience level
- How you prefer to collaborate (terse vs detailed, autonomous vs confirmatory)
- Tech stack familiarity (expert in X, learning Y)

Example: "I'm a senior iOS developer, new to CloudKit. Keep explanations focused on CloudKit concepts, skip the Swift basics."

### 2. Give feedback and confirm approaches

When Claude Code does something well or poorly, say so:
- "Don't mock the database in tests — use the real one"
- "Yes, the single PR was the right call"
- "Stop summarizing at the end of every response"

These get saved as feedback memories and guide future behavior.

### 3. Share project context

Information not derivable from the code:
- "We're freezing merges after Thursday for release"
- "The auth rewrite is driven by compliance, not tech debt"
- "Bugs are tracked in Linear project BACKEND"

## Memory Types

| Type | What to store | Example |
|------|--------------|---------|
| **user** | Role, preferences, expertise | "Senior dev, new to React" |
| **feedback** | Corrections and confirmations | "Don't add type annotations to unchanged code" |
| **project** | Ongoing work, goals, deadlines | "Merge freeze starts March 5" |
| **reference** | Pointers to external systems | "Bugs tracked in Linear project INGEST" |

## What NOT to Store

- Code patterns (derivable from reading the code)
- Git history (use `git log`)
- Debugging solutions (the fix is in the code)
- Anything in CLAUDE.md (already loaded every conversation)
- Ephemeral task state (use Claude Code's task system instead)

## Tips

- Memory builds up naturally over sessions — you don't need to front-load it
- If something keeps going wrong, save a feedback memory so it doesn't recur
- Check `~/.claude/projects/.../memory/MEMORY.md` to see what's been stored
- Tell Claude "forget X" to remove a memory that's no longer accurate

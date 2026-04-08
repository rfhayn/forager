# Claude Code Hooks

Shell scripts triggered by Claude Code session lifecycle events. These hooks enforce architectural constraints and documentation standards.

## Design Principles

1. **Warn, don't block** — Hooks inform; humans decide. Default exit code is 0 (allow). Hooks that want hard enforcement use exit 2 (block).

2. **Fast path** — Target <200ms execution.

3. **No side effects in PreToolUse** — Sync/blocking hooks (PreToolUse) only read state, never write.

4. **JSON protocol** — Hooks receive JSON on stdin describing the event. Hooks may write JSON to stdout for messages. Exit 0 = allow, exit 2 = block.

5. **Self-contained** — Each hook is a standalone shell script. No shared libraries. Only dependency: `jq`.

## Hook Inventory

| Hook | Event | Mode | Purpose |
|------|-------|------|---------|
| `architecture-guard.sh` | PreToolUse | sync | ADR 014 factory enforcement — warns on direct entity creation |
| `core-data-guard.sh` | PreToolUse | sync | ADR 007 schema change warning |
| `doc-freshness.sh` | PreToolUse | sync | Warn about stale/missing docs before commits |

## Configuration

Hooks are wired in `.claude/settings.json` under the `hooks` key. See that file for the full configuration.

## Adding New Hooks

Create new `.sh` files in this directory following the same patterns:
- Use async unless the hook must block tool execution
- Keep execution under 200ms
- Test with `echo '{}' | bash .claude/hooks/your-hook.sh`

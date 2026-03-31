# Claude Code Hooks

Shell scripts triggered by Claude Code session lifecycle events. These hooks integrate Clauductor orchestration with Claude Code's native hook system.

## Design Principles

1. **Graceful degradation** — No orchestration directory = no-op. Every hook starts with `test -d "$PROJECT_DIR/orchestration" || exit 0`. No crash, no error, no output.

2. **Fast path** — Target <200ms execution. Use file stat before SQLite queries. Throttle high-frequency hooks (e.g., heartbeat uses a timestamp file to avoid firing on every tool call).

3. **Warn, don't block** — Hooks inform; humans decide. Default exit code is 0 (allow). Projects that want hard enforcement on specific hooks can change to exit 2 (block).

4. **No side effects in PreToolUse** — Sync/blocking hooks (PreToolUse) only read state, never write to DB. This prevents deadlocks and keeps tool execution predictable.

5. **JSON protocol** — Hooks receive JSON on stdin describing the event. Hooks may write JSON to stdout for messages. Exit 0 = allow, exit 2 = block.

6. **Self-contained** — Each hook is a standalone shell script. No shared libraries. Only dependencies: `jq` and `clauductor` CLI.

## Hook Inventory

| Hook | Event | Mode | Purpose |
|------|-------|------|---------|
| `session-register.sh` | SessionStart | async | Auto-register worker on session start |
| `heartbeat.sh` | PostToolUse | async | Keep worker alive in orchestration DB |
| `lock-guard.sh` | PreToolUse | sync | Warn before editing locked files |
| `doc-freshness.sh` | PreToolUse | sync | Warn about stale/missing docs before commits |
| `status-sync.sh` | PostToolUse | async | Sync milestone status on current-story.md changes |

## Configuration

Hooks are wired in `.claude/settings.json` under the `hooks` key. See that file for the full configuration.

## Adding Project-Specific Hooks

Create new `.sh` files in this directory following the same patterns:
- Guard with orchestration directory check
- Use async unless the hook must block tool execution
- Keep execution under 200ms
- Test with `echo '{}' | bash .claude/hooks/your-hook.sh`

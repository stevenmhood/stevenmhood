# Personal dotfiles agent guidance

## Agent hooks

Hooks in `.config/agent-hooks/` are shared by Claude Code and Codex. Do not
identify the harness from environment variables: a Claude process launched by
Codex can inherit `CODEX_*` variables. Read `hook_event_name` from the hook's
JSON stdin instead.

For pre-tool permission hooks, the event names and response contracts are:

| Harness | `hook_event_name` | Allowed operation | Blocked operation |
| --- | --- | --- | --- |
| Claude Code | `PreToolUse` | Exit 0; `permissionDecision: "allow"` JSON on stdout is supported | Denial JSON on stdout with `permissionDecision: "deny"` and `permissionDecisionReason`; exit 2; no stderr |
| Codex | `pre_tool_use` | Exit 0 with no stdout or stderr | Human-readable reason on stderr; exit 2; no stdout |

Unknown event-name variants must never receive a Claude-specific allow or deny
decision. For a mutation or destructive operation, fail closed with a readable
stderr reason and exit 2. Commands outside a permission hook's scope may exit 0
silently.

Only permission hooks need this allow/deny bifurcation. Lifecycle hooks that do
not make permission decisions should remain silent unless their configured
event explicitly supports output. Preserve the incoming event name when an
event-specific JSON response is supported; do not translate event-name casing.

When adding or changing a permission hook:

1. Add tests before changing the hook.
2. Exercise both `PreToolUse` and `pre_tool_use` inputs.
3. Assert stdout, stderr, and exit code independently for an allowed operation
   and a blocked operation.
4. Cover an unknown event-name variant and require fail-closed behavior for
   operations that need a permission decision.
5. Keep endpoint or command classification tests separate from harness output
   contract tests.
6. Run the focused test, all tests in `.config/agent-hooks/tests/`, `bash -n` on
   changed shell files, and `git diff --check`.

Do not modify the separate Range dotfiles checkout when working on these
personal hooks.

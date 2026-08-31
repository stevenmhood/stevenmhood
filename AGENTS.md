# Personal dotfiles agent guidance

## Agent hooks

Hooks in `.config/agent-hooks/` are shared by Claude Code and Codex. When a
permission hook needs different harness contracts, pass the harness explicitly
in its registration (for example, `hook.sh claude` or `hook.sh codex`). Do not
infer it from environment variables, process ancestry, or `hook_event_name`.

For pre-tool permission hooks, use these response contracts:

| Harness and operation | stdout | stderr | Exit code |
| --- | --- | --- | --- |
| Claude allowed, when an explicit grant is needed | `permissionDecision: "allow"` JSON | Empty | 0 |
| Codex allowed | Empty | Empty | 0 |
| Blocked, any harness | Empty | Human-readable blocking reason | 2 |

For a mutation or destructive operation, fail closed with a readable stderr
reason and exit 2. Commands outside a permission hook's scope must exit 0
silently. An unknown harness argument must never receive a structured grant;
operations classified as unsafe must still fail closed.

Lifecycle hooks that do not make permission decisions should remain silent
unless their configured event explicitly supports output. Preserve the incoming
event name when event-specific JSON output is supported.

When adding or changing a permission hook:

1. Add tests before changing the hook.
2. Exercise every explicitly supported harness argument.
3. Assert stdout, stderr, and exit code independently for an allowed operation
   and a blocked operation.
4. Cover both an allowed operation and every blocked-operation category.
5. Keep endpoint or command classification tests separate from harness output
   contract tests.
6. Run the focused test, all tests in `.config/agent-hooks/tests/`, `bash -n` on
   changed shell files, and `git diff --check`.

Do not modify the separate Range dotfiles checkout when working on these
personal hooks.

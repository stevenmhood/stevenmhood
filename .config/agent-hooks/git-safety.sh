#!/bin/bash

# Git Safety Hook - Blocks destructive git operations for agent harnesses.
# Triggered on PreToolUse for shell commands.

# Read hook JSON input.
json_input=$(cat)
command=$(echo "$json_input" | jq -r '.tool_input.command // empty')

deny() {
  local reason="$1"
  printf '%s' "$reason" | jq -r . >&2
  exit 2
}

# Exit early if no command
if [ -z "$command" ]; then
  exit 0
fi

# Only process commands that contain a git invocation.
# Broad match — specific blocking patterns below do the real filtering.
if ! echo "$command" | grep -qE '(^|[;&|]\s*)([A-Z_]+=\S*\s+)*git\b'; then
  exit 0
fi

# Block: git reset --hard
if echo "$command" | grep -qE '\bgit\b.*\breset\b.*--hard'; then
  reason=$(cat <<'REASON' | jq -Rs .
# Destructive Operation Blocked

`git reset --hard` is blocked. Use `git stash` or `git checkout -- <file>` instead.
REASON
)
  deny "$reason"
fi

# Block: git clean -f
if echo "$command" | grep -qE '\bgit\b.*\bclean\b.*-[a-zA-Z]*f'; then
  reason=$(cat <<'REASON' | jq -Rs .
# Destructive Operation Blocked

`git clean -f` is blocked. Review untracked files manually before removing them.
REASON
)
  deny "$reason"
fi

# Block: git branch -D
if echo "$command" | grep -qE '\bgit\b.*\bbranch\b.*-[a-zA-Z]*D'; then
  reason=$(cat <<'REASON' | jq -Rs .
# Destructive Operation Blocked

`git branch -D` (force delete) is blocked. Use `git branch -d` for safe deletion.
REASON
)
  deny "$reason"
fi

# Block: git stash clear
if echo "$command" | grep -qE '\bgit\b.*\bstash\b.*\bclear\b'; then
  reason=$(cat <<'REASON' | jq -Rs .
# Destructive Operation Blocked

`git stash clear` is blocked. Use `git stash drop` to remove individual stashes.
REASON
)
  deny "$reason"
fi

# Block: git commit --amend
if echo "$command" | grep -qE '\bgit\b.*\bcommit\b.*--amend'; then
  reason=$(cat <<'REASON' | jq -Rs .
# Amend Blocked

`git commit --amend` is blocked. Create a new commit instead.
REASON
)
  deny "$reason"
fi

# Block: git push --force / -f (but not --force-with-lease which is safer)
if echo "$command" | grep -qE '\bgit\b.*\bpush\b.*(--force\b|-f\b)' && ! echo "$command" | grep -qE '\bgit\b.*\bpush\b.*--force-with-lease'; then
  reason=$(cat <<'REASON' | jq -Rs .
# Force Push Blocked

`git push --force` is blocked. Use `git push --force-with-lease` for safer force pushes, or regular push.
REASON
)
  deny "$reason"
fi

# Block: git checkout -- . / git checkout . (discard all working tree changes)
if echo "$command" | grep -qE '\bgit\b.*\bcheckout\b.*--\s*\.' || echo "$command" | grep -qE '\bgit\b.*\brestore\b.*--worktree\s+\.'; then
  reason=$(cat <<'REASON' | jq -Rs .
# Bulk Discard Blocked

`git checkout -- .` is blocked. Use `git stash` to save changes, or checkout specific files.
REASON
)
  deny "$reason"
fi

# Block: cd <path> && git ... — use git -C so it matches Bash(git *) permissions
if echo "$command" | grep -qE '\bcd\b.*[;&|]+.*\bgit\b'; then
  reason=$(cat <<'REASON' | jq -Rs .
# Use git -C Instead

"cd <path> && git ..." does not match the Bash(git *) permission rule. Use "git -C <path> ..." instead.
REASON
)
  deny "$reason"
fi

# All other git commands are allowed
exit 0

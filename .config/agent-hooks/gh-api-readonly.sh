#!/bin/bash

# Blocks mutating `gh api` calls from agent harnesses.
# Comment, reply, and review endpoints remain writable.

harness="${1:-}"
json_input=$(cat)
command=$(printf '%s' "$json_input" | jq -r '.tool_input.command // empty')

[ -n "$command" ] || exit 0

if ! printf '%s' "$command" | grep -qE '\bgh\s+api\b'; then
  exit 0
fi

allow() {
  if [ "$harness" = claude ]; then
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow"
      }
    }'
  fi
  exit 0
}

deny() {
  local msg="$1"
  printf '%s\n' "$msg" >&2
  exit 2
}

# Explicit GET is safe even with --raw-field/-f; gh treats those as query
# parameters when the request method is GET.
if printf '%s' "$command" | grep -iE '(-X|--method)\s+GET\b' >/dev/null; then
  exit 0
fi

is_mutation=false
if printf '%s' "$command" | grep -iE '(-X|--method)\s+(POST|PUT|DELETE|PATCH)' >/dev/null; then
  is_mutation=true
fi
if printf '%s' "$command" | grep -E '(--input\b|--raw-field\b|-f\s)' >/dev/null; then
  is_mutation=true
fi

[ "$is_mutation" = true ] || exit 0

repo='repos/[^/]+/[^/]+'

printf '%s' "$command" | grep -qE "$repo/issues/[0-9]+/comments" && allow
printf '%s' "$command" | grep -qE "$repo/pulls/[0-9]+/comments" && allow
printf '%s' "$command" | grep -qE "$repo/pulls/[0-9]+/comments/[0-9]+/replies" && allow
printf '%s' "$command" | grep -qE "$repo/pulls/comments/[0-9]+/replies" && allow
printf '%s' "$command" | grep -qE "$repo/pulls/comments/[0-9]+([[:space:]]|$)" && allow
printf '%s' "$command" | grep -qE "$repo/pulls/[0-9]+/reviews" && allow

deny "# Mutating GitHub API Call Blocked

\`gh api\` write operations are only allowed on comment/reply endpoints.

Allowed endpoints:
- \`.../issues/{num}/comments\`
- \`.../pulls/{num}/comments\`
- \`.../pulls/{num}/comments/{id}/replies\`
- \`.../pulls/comments/{id}/replies\`
- \`.../pulls/comments/{id}\`
- \`.../pulls/{num}/reviews\`

All other write operations are blocked."

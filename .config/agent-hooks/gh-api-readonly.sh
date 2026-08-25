#!/bin/bash

# Blocks mutating `gh api` calls from agent harnesses.
# Comment, reply, and review endpoints remain writable.

json_input=$(cat)
command=$(printf '%s' "$json_input" | jq -r '.tool_input.command // empty')
hook_event=$(printf '%s' "$json_input" | jq -r '.hook_event_name // empty')

[ -n "$command" ] || exit 0

if ! printf '%s' "$command" | grep -qE '\bgh\s+api\b'; then
  exit 0
fi

allow() {
  case "$hook_event" in
    PreToolUse)
      cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "$hook_event",
    "permissionDecision": "allow"
  }
}
EOF
      exit 0
      ;;
    pre_tool_use)
      exit 0
      ;;
    *)
      printf 'Unknown hook event %q; blocking mutating GitHub API call.\n' "$hook_event" >&2
      exit 2
      ;;
  esac
}

deny() {
  local msg="$1"
  case "$hook_event" in
    PreToolUse)
      local reason
      reason=$(printf '%s' "$msg" | jq -Rs .)
      cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "$hook_event",
    "permissionDecision": "deny",
    "permissionDecisionReason": $reason
  }
}
EOF
      ;;
    *)
      printf '%s\n' "$msg" >&2
      ;;
  esac
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

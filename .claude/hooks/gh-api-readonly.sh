#!/bin/bash

# GH API Read-Only Hook - Blocks mutating gh api calls
# Exception: allows POST to comment/reply endpoints
# Triggered on PreToolUse for Bash commands

# Read JSON input from Claude Code
json_input=$(cat)
command=$(echo "$json_input" | jq -r '.tool_input.command // empty')
hook_event=$(echo "$json_input" | jq -r '.hook_event_name // empty')

# Exit early if no command
if [ -z "$command" ]; then
  exit 0
fi

# Only process gh api commands
if ! echo "$command" | grep -qE '\bgh\s+api\b'; then
  exit 0
fi

allow() {
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "$hook_event",
    "permissionDecision": "allow"
  }
}
EOF
  exit 0
}

deny() {
  local msg="$1"
  reason=$(echo "$msg" | jq -Rs .)
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "$hook_event",
    "permissionDecision": "deny",
    "permissionDecisionReason": $reason
  }
}
EOF
  exit 2
}

# Check if this is a mutating request
is_mutation=false
if echo "$command" | grep -iE '(-X|--method)\s+(POST|PUT|DELETE|PATCH)' > /dev/null; then
  is_mutation=true
fi
if echo "$command" | grep -E '(--input\b|--raw-field\b|-f\s)' > /dev/null; then
  is_mutation=true
fi

# If not a mutation, allow (GET is default)
if [ "$is_mutation" = false ]; then
  exit 0
fi

# Mutation detected — check if it's an allowed comment/reply endpoint
# Allowed write patterns:
#   /repos/{owner}/{repo}/issues/{num}/comments
#   /repos/{owner}/{repo}/pulls/{num}/comments
#   /repos/{owner}/{repo}/pulls/{num}/comments/{id}/replies
#   /repos/{owner}/{repo}/pulls/comments/{id}/replies
#   /repos/{owner}/{repo}/pulls/{num}/reviews
repo='repos/[^/]+/[^/]+'

# .../issues/{num}/comments
echo "$command" | grep -qE "$repo/issues/[0-9]+/comments" && allow
# .../pulls/{num}/comments
echo "$command" | grep -qE "$repo/pulls/[0-9]+/comments" && allow
# .../pulls/{num}/comments/{id}/replies
echo "$command" | grep -qE "$repo/pulls/[0-9]+/comments/[0-9]+/replies" && allow
# .../pulls/comments/{id}/replies (no PR number)
echo "$command" | grep -qE "$repo/pulls/comments/[0-9]+/replies" && allow
# .../pulls/{num}/reviews
echo "$command" | grep -qE "$repo/pulls/[0-9]+/reviews" && allow

# All other mutations are blocked
deny "# Mutating GitHub API Call Blocked

\`gh api\` write operations are only allowed on comment/reply endpoints.

Allowed endpoints:
- \`.../issues/{num}/comments\`
- \`.../pulls/{num}/comments\`
- \`.../pulls/{num}/comments/{id}/replies\`
- \`.../pulls/comments/{id}/replies\`
- \`.../pulls/{num}/reviews\`

All other write operations are blocked."

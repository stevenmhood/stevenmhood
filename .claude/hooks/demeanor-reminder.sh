#!/bin/bash

# Demeanor Reminder Hook - Randomly injects core demeanor principles
# Triggered on UserPromptSubmit (5% chance)

# Read JSON input to get hook event name
json_input=$(cat)
hook_event=$(echo "$json_input" | jq -r '.hook_event_name // empty')

# Generate random number between 1-100
random_num=$((RANDOM % 100 + 1))

# Only inject 5% of the time (1-5 out of 100)
if [ $random_num -le 5 ]; then
    # Output JSON with demeanor reminder
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "$hook_event",
    "additionalContext": $(cat ~/.claude/docs/demeanor-core.md | jq -Rs .)
  }
}
EOF
else
    # No injection, exit cleanly
    exit 0
fi
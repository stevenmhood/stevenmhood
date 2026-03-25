#!/bin/bash
# Sets @branch pane option for tmux status bar in Claude sessions.
# Fired from SessionStart and PostToolUse(Bash) hooks.
[ -n "$TMUX" ] || exit 0

# PostToolUse sends JSON with tool_input.command; skip non-git commands.
# SessionStart has no tool_input, so it falls through.
input=$(cat)
if printf '%s' "$input" | grep -q '"tool_input"'; then
    printf '%s' "$input" | grep -qw 'git' || exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$branch" ] && [ "$branch" != HEAD ] && [ "$branch" != main ] && [ "$branch" != master ]; then
    name="${branch##*/}"
else
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
    [ -n "$toplevel" ] && name="$(basename "$toplevel")"
fi
tmux set-option -p -t "$TMUX_PANE" @branch "${name:-$(basename "$PWD")}" 2>/dev/null

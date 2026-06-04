#!/bin/bash
# Sets @branch pane option for tmux status bar in Claude sessions.
# Fired from SessionStart and PostToolUse(Bash) hooks.

LOG="${BASH_SOURCE%.sh}.log"
log() {
    printf '%s pane=%s pwd=%s cwd=%s %s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${TMUX_PANE:-<unset>}" "$PWD" "$(pwd)" "$*" >> "$LOG"
}

[ -n "$TMUX" ] || { log "skip reason=no-tmux"; exit 0; }

# PostToolUse sends JSON with tool_input.command; skip non-git commands.
# SessionStart has no tool_input, so it falls through.
input=$(cat)
stdin_preview=$(printf '%s' "$input" | head -c 200 | tr '\n\t' '  ')
if printf '%s' "$input" | grep -q '"tool_input"'; then
    if ! printf '%s' "$input" | grep -qw 'git'; then
        log "skip reason=non-git stdin=[$stdin_preview]"
        exit 0
    fi
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$branch" ] && [ "$branch" != HEAD ] && [ "$branch" != main ] && [ "$branch" != master ]; then
    name="${branch##*/}"
else
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
    [ -n "$toplevel" ] && name="$(basename "$toplevel")"
fi
final="${name:-$(basename "$PWD")}"
set_err=$(tmux set-option -p -t "$TMUX_PANE" @branch "$final" 2>&1)
set_rc=$?
log "set rc=$set_rc branch_raw=[$branch] name=[$name] final=[$final] err=[$set_err] stdin=[$stdin_preview]"

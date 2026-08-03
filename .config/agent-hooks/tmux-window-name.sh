#!/bin/bash
# Sets the pane-level @branch option used by the tmux status bar.
# Intended for SessionStart and PostToolUse(Bash) hooks in agent harnesses.

state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
log_dir="$state_home/agent-hooks"
log_file="$log_dir/tmux-window-name.log"

log() {
    mkdir -p "$log_dir" 2>/dev/null || return 0
    printf '%s pane=%s pwd=%s cwd=%s %s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${TMUX_PANE:-<unset>}" "$PWD" "$(pwd)" "$*" >> "$log_file"
}

[ -n "$TMUX" ] || { log "skip reason=no-tmux"; exit 0; }

# PostToolUse sends tool_input; skip non-git commands. SessionStart has no
# tool_input and therefore always refreshes the displayed repository name.
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

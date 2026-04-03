#!/bin/bash
# Sets tmux window attention flag when Claude needs input,
# but only if this window is NOT the currently focused window.
# Uses $TMUX_PANE to target the correct window from hook context.
if [ -n "$TMUX" ]; then
    current_window=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}')
    active_window=$(tmux display-message -p '#{active_window_index}')
    if [ "$current_window" != "$active_window" ]; then
        tmux set-option -w -t "$TMUX_PANE" @claude-attention 1
    fi
fi

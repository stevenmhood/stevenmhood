#!/bin/bash
# Marks an unfocused tmux window when an agent needs user attention.

if [ -n "$TMUX" ]; then
    current_window=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}')
    active_window=$(tmux display-message -p '#{active_window_index}')
    if [ "$current_window" != "$active_window" ]; then
        tmux set-option -w -t "$TMUX_PANE" @agent-attention 1
    fi
fi

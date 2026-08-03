#!/bin/bash
# Clears the tmux attention marker when an agent starts working.

if [ -n "$TMUX" ]; then
    tmux set-option -w -t "$TMUX_PANE" @agent-attention 0
fi

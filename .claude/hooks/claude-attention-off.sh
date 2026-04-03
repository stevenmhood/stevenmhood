#!/bin/bash
# Clears tmux window attention flag when Claude starts working
if [ -n "$TMUX" ]; then
    tmux set-option -w -t "$TMUX_PANE" @claude-attention 0
fi

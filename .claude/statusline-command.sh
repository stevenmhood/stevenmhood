#!/bin/bash

# Claude Code statusLine script
# Replicates Starship prompt format with model and context info

# Colors (matching Starship config)
GREEN='\033[32m'
RED='\033[31m'
CYAN='\033[36m'
YELLOW='\033[33m'
CLAUDE_ORANGE='\033[38;2;255;107;53m'
WHITE='\033[37m'
BOLD='\033[1m'
RESET='\033[0m'

# Read JSON input from Claude Code
INPUT=$(cat)
echo "$INPUT" >> ~/.claude/statusline-command.log

# Extract workspace info from JSON
WORKSPACE_PATH=$(echo "$INPUT" | jq -r '.workspace.project_dir // ""')
MODEL_ID=$(echo "$INPUT" | jq -r '.model.id // "unknown"')
VERSION=$(echo "$INPUT" | jq -r '.version // "unknown"')

# Extract cost and line info
TOTAL_COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
LINES_ADDED=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')

# Extract context window usage
CONTEXT_USED_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')

# Directory info
if [ -n "$WORKSPACE_PATH" ]; then
    cd "$WORKSPACE_PATH" 2>/dev/null || true
fi

# Get current directory, truncate to repo if in git
PWD_DISPLAY="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_NAME=$(basename "$REPO_ROOT")
    REL_PATH="${PWD#$REPO_ROOT}"
    REL_PATH="${REL_PATH#/}"
    [ -z "$REL_PATH" ] && REL_PATH="."
    if [ "$REL_PATH" = "." ]; then
        PWD_DISPLAY="$REPO_NAME"
    else
        PWD_DISPLAY="$REPO_NAME/$REL_PATH"
    fi
else
    # Home symbol replacement
    PWD_DISPLAY="${PWD/#$HOME//U/steven}"
fi

# Git info
GIT_INFO=""
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
if [ -n "$GIT_DIR" ]; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "HEAD")
    GIT_STATE=""
    
    # Check for git state
    if [ -f "$GIT_DIR/MERGE_HEAD" ]; then
        GIT_STATE=" (MERGING)"
    elif [ -f "$GIT_DIR/CHERRY_PICK_HEAD" ]; then
        GIT_STATE=" (CHERRY-PICKING)"
    elif [ -f "$GIT_DIR/REVERT_HEAD" ]; then
        GIT_STATE=" (REVERTING)"
    elif [ -f "$GIT_DIR/BISECT_LOG" ]; then
        GIT_STATE=" (BISECTING)"
    fi
    
    GIT_INFO=" ${CYAN}[${BRANCH}]${RESET}${YELLOW}${GIT_STATE}${RESET}"
fi

# Model display — extract context window suffix like [1m] if present
CONTEXT_SUFFIX=""
if [[ "$MODEL_ID" =~ \[([0-9]+[km])\]$ ]]; then
    CONTEXT_SUFFIX=" (${BASH_REMATCH[1]^^})"
    MODEL_ID="${MODEL_ID%\[*\]}"
fi

MODEL_DISPLAY=""
case "$MODEL_ID" in
    *"opus-4-7"*) MODEL_DISPLAY="Opus 4.7" ;;
    *"opus-4-6"*) MODEL_DISPLAY="Opus 4.6" ;;
    *"sonnet-4-6"*) MODEL_DISPLAY="Sonnet 4.6" ;;
    *"haiku-4-5"*) MODEL_DISPLAY="Haiku 4.5" ;;
    *) MODEL_DISPLAY="${BOLD}${RED}${MODEL_ID}${RESET}" ;;
esac
MODEL_DISPLAY="${MODEL_DISPLAY}${CONTEXT_SUFFIX}"

# Format cost (round to 2 decimal places)
COST_DISPLAY=$(printf "%.2f" "$TOTAL_COST")

# Build context meter (20 blocks, each = 5%)
FILLED=$(( (CONTEXT_USED_PCT + 2) / 5 ))
[ "$CONTEXT_USED_PCT" -gt 0 ] && [ "$FILLED" -eq 0 ] && FILLED=1
[ "$FILLED" -gt 20 ] && FILLED=20
METER=""
for i in $(seq 1 20); do
    if [ "$i" -le "$FILLED" ]; then
        METER="${METER}■"
    else
        METER="${METER}□"
    fi
done
if [ "$CONTEXT_USED_PCT" -ge 90 ]; then
    METER_COLOR="$RED"
elif [ "$CONTEXT_USED_PCT" -ge 70 ]; then
    METER_COLOR="$YELLOW"
else
    METER_COLOR="$GREEN"
fi

# Assemble status lines
echo -e "${RESET}${WHITE}${PWD_DISPLAY}${RESET}${GIT_INFO}"
echo -e "${RESET}${CLAUDE_ORANGE}CC ${VERSION}${RESET} ${WHITE}·${RESET} ${GREEN}\$${COST_DISPLAY}${RESET} ${WHITE}·${RESET} ${WHITE}(${GREEN}+${LINES_ADDED}${RESET}/${RED}-${LINES_REMOVED}${WHITE})${RESET}"
echo -e "${RESET}${YELLOW}${MODEL_DISPLAY}${RESET} ${METER_COLOR}${METER}${RESET}"

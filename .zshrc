# .zshrc is sourced in interactive shells.

# Confirm umask is an appropriate value
if [[ "$(umask)" = "000" ]]; then
    umask 022
fi

# Check for WSL
if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
    source ~/.zshrcs/wsl.zsh
fi

# Add ~/bin to $PATH
case ":${PATH}:" in
    *:"$HOME/bin":*) ;;   # Already exists
    *) PATH="$PATH:$HOME/bin" ;;
esac

# Add ~/.local/bin to $PATH
case ":${PATH}:" in
    *:"$HOME/.local/bin":*) ;;   # Already exists
    *) PATH="$PATH:$HOME/.local/bin" ;;
esac

# Add ~/scripts to $PATH
case ":${PATH}:" in
    *:"$HOME/scripts":*) ;;   # Already exists
    *) PATH="$PATH:$HOME/scripts" ;;
esac

# Add ~/go/bin to $PATH
case ":${PATH}:" in
    *:"$HOME/go/bin":*) ;;   # Already exists
    *) PATH="$PATH:$HOME/go/bin" ;;
esac

# Add homebrew to $PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
    case ":${PATH}:" in
        *:/opt/homebrew/bin:*) ;; # Already exists
        *)
            eval "$(/opt/homebrew/bin/brew shellenv)"
            export FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

            # gnu tooling
            GNU_PATH=$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin
            export PATH=$GNU_PATH:$PATH
            GNU_MANPATH=$HOMEBREW_PREFIX/opt/coreutils/libexec/gnuman
            MANPATH=$GNU_MANPATH:$MANPATH
    esac
fi

if [[ -f ~/.zshrcs/range.zsh ]]; then
    echo "Sourcing Range config"
    source ~/.zshrcs/range.zsh
fi

# Always UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Colorize directories
eval $(dircolors -b ~/.dir_colors)

# Prompt colors
autoload -U colors
colors

# Used in tmux window titles
SHORT_HOST="$(hostname | cut -f1 -d.) - "

# Prompt settings
if [[ -z $(which starship) ]]; then
    echo "Install starship!"
else
    eval "$(starship init zsh)"
fi

export EDITOR=vim
export PAGER="less -FiMRX"

# Command line keybindings
bindkey -v      # VI is better than Emacs
bindkey "^R" history-incremental-search-backward
bindkey "^E" end-of-line
bindkey "^A" beginning-of-line
# Push current command on stack, pops after next command
bindkey "^t" push-line-or-edit
bindkey "^b" backward-word
bindkey "^f" forward-word

# VI editing mode is a pain to use if you have to wait for <ESC> to register.
# This times out multi-char key combos as fast as possible (1/100th of second)
KEYTIMEOUT=1

# History settings
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST  # unique events are more useful
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
HISTSIZE=110000
SAVEHIST=100000
HISTFILE=${HOME}/.history

# Type in a directory to cd there
setopt AUTO_CD

# Shell shortcuts
# unalias $(alias | cut -d= -f2) 2&> /dev/null
# Do -F separate, so eza can handle it (it takes an argument in eza)
alias d='ls -lao -F --color=auto'
alias du1='du -h --max-depth=1'
alias h='cd ~'
alias x='exit'
alias grep='grep -n --color=auto'
alias p='ps -ef | grep $1'
alias w='cd /workplace'

# Custom functions
# Tail last
function tl() {
    tail -f $(/usr/bin/ls -t1 $1* | head -1)
}
# Go up N directories
function u() {
    ud="."
    # ${1-1} means use $1 if defined, else default to 1.
    for i ( $(seq 1 ${1-1}) ) {
        ud="${ud}/.."
    }
    cd $ud
}

# Colorize log files
function lc() {
    sed 's/\(\[DEBUG\]\)/\o033[36m\1\o033[0m/g
         s/\(\[INFO\]\)/\o033[32m\1\o033[0m/g
         s/\(\[WARN\]\)/\o033[33m\1\o033[0m/g
         s/\(\[ERROR\]\)/\o033[31m\1\o033[0m/g
         s/\(\[FATAL\]\)/\o033[31;1m\1\o033[0m/g'
}

# Set up SSH
if [[ -f ~/.ssh-agent-rc ]]; then
    source ~/.ssh-agent-rc
fi

# Hook up direnv, if it exists
if [[ -f ~/.zshrcs/direnv.zsh ]]; then
    source ~/.zshrcs/direnv.zsh
fi

if [[ -d ~/.zshrcs/completions ]]; then
    export FPATH="~/.zshrcs/completions:${FPATH}"
fi

autoload -Uz compinit && compinit

# Tmux window naming: clear @branch pane option so status bar
# falls back to #{b:pane_current_path} for interactive shells
_tmux_window_name() {
  [[ -n "$TMUX" ]] || return
  tmux set-option -pu @branch 2>/dev/null
}
add-zsh-hook precmd _tmux_window_name

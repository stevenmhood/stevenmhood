# .zshrc is sourced in interactive shells.
# It should contain commands to set up aliases,
# functions, options, key bindings, etc.

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

# Environment
# \e[0; sets the window title
# \e[30; sets the middle window title in Konsole
precmd()
{
    # Title is the current directory
    case $TERM in
        xterm*)
            echo -ne "\e]0;$SHORT_HOST - $(/usr/bin/basename $PWD)\a"
        ;;
        screen*)
            echo -ne "\ek$SHORT_HOST - $(/usr/bin/basename $PWD)\e\\"
        ;;
    esac

    # Shortened form of the directory, removes all lowercase letters, except the
    # first letter of a word/fragment.
    SHORT_PWD=$(pwd | sed -e 's_\([A-Z]\)[a-z]*_\1_g' -e 's_\([a-z]\)[a-z]*_\1_g')

    # Git branch info
    vcs_info
    GIT_PROMPT='%{$terminfo[bold]${fg[cyan]}%}${vcs_info_msg_0_}%{$reset_color$terminfo[sgr0]%}'
}

preexec()
{
    local CMD=${1/% */}  # kill all text after and including the first space

    case $TERM in
        xterm*)
            echo -ne "\e]0;$SHORT_HOST - $CMD\a"
        ;;
        screen*)
            echo -ne "\ek$SHORT_HOST - $CMD\e\\"
        ;;
    esac
}

case $TERM in
    (xterm*|screen*)
        setopt prompt_subst
        USER_PROMPT='%{$fg[green]%}%m:%{$reset_color%}'
        # Must line wrap to display correctly
        PROMPT='${(e)USER_PROMPT} $SHORT_PWD ${(e)GIT_PROMPT}
%h > '
        # Right prompt
        export RPS1="%D{%a, %b %d, %Y %T}"
        ;;

    dumb*)
        PROMPT='> '
        ;;
esac

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
alias d='ls -laFo --color=auto'
alias du1='du -h --max-depth=1'
alias h='cd ~'
alias x='exit'
alias grep='grep -n --color=auto'
alias p='ps -ef | grep $1'

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

# Set up Bitbucket/Github SSH
source ~/.ssh-agent-rc

autoload -Uz compinit && compinit


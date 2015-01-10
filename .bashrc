#!/bin/bash

alias d="ls -al"
alias u="cd .."
alias h="cd ~"
alias x='ssh-agent -k;exit'

# non-printable characters must be enclosed inside \[ and \]
PS1='\[\033]0;$MSYSTEM:${PWD//[^[:ascii:]]/?}\007\]' # set window title
PS1="$PS1"'\n'                 # new line
PS1="$PS1"'\[\033[32m\]'       # change color
PS1="$PS1"'\u@\h '             # user@host<space>
PS1="$PS1"'\[\033[33m\]'       # change color
PS1="$PS1"'\w'                 # current working directory
if test -z "$WINELOADERNOEXEC"
then
    PS1="$PS1"' ($((git symbolic-ref -q HEAD || git rev-parse -q --short HEAD) 2> /dev/null))'   # bash function
fi
PS1="$PS1"'\[\033[0m\]'        # change color
PS1="$PS1"'\n'                 # new line
PS1="$PS1"'> '                 # prompt: always >


# Allow SSH keyphrase storage while agent is running
source ~/.ssh-agent-rc

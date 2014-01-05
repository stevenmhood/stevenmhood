#!/bin/bash

alias d="ls -al"
alias u="cd .."
alias h="cd ~"
alias x='ssh-agent -k;exit'

# Allow SSH keyphrase storage while agent is running
source ~/.ssh-agent-rc

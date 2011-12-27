# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored _correct _approximate
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*'
zstyle ':completion:*' max-errors 2
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle :compinstall filename '/home/ec2-user/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
setopt appendhistory autocd nobeep extendedglob notify
# End of lines configured by zsh-newuser-install


export EDITOR=vim
export PAGER="less -RX"

bindkey -v
bindkey "^R" history-incremental-search-backward
bindkey "^E" end-of-line
bindkey "^A" beginning-of-line
# Push current command on stack
bindkey "^t" push-line-or-edit
bindkey "^b" backward-word
bindkey "^f" forward-word

# Times out multi-key combos ASAP for vi editing mode
KEYTIMEOUT=1

# History settings
setopt appendhistory SHARE_HISTORY HIST_IGNORE_DUPS
HISTFILE=${HOME}/.history
HISTSIZE=100000
SAVEHIST=110000


alias h='cd ~'
alias d='ls -al'
alias p='ps -ef | grep $1'
alias x='exit'
alias grep='grep --color=auto'

function u() {
  ud="."
  # ${1-1} means use $1 if defined, else default to 1
  for i ( `seq 1 ${1-1}` ) {
    ud="${ud}/.."
  }
  cd $ud
}

# Prompt settings
HOSTNAME=`hostname`

autoload colors
colors

prompt_color="%{$fg[green]%}"

precmd()
{
  case $TERM in
    xterm*)
      echo -ne "\e]0;$HOSTNAME - $(/bin/basename $PWD)\a"
    ;;
  esac
 
  SHORT_PWD=`pwd | sed -e 's_\([A-Z]\)[a-z]*_\1_g' -e 's_\([a-z]\)[a-z]*_\1_g'`
}

preexec()
{
  local CMD=${1/% */} # Kill all text after and including the first space

  case $TERM in
    xterm*)
      echo -ne "\e]0;$HOSTNAME - $CMD\a"
    ;;
  esac
}

case $TERM in
  xterm*)
    setopt prompt_subst
    USER_PROMPT='$prompt_color%m:%{$reset_color%}'
    PROMPT='${(e)USER_PROMPT} $SHORT_PWD
%h > '

    export RPS1="%D{%a, %b %d, %Y %T}"
  ;;

  dumb*)
    PROMPT='> '
  ;;
esac


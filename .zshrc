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

# Clear PATH
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$HOME/bin:$HOME/scripts:$HOME/.local/bin:$HOME/.cargo/bin:.
unalias $(alias | cut -d= -f1) 2&> /dev/null

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Used in tmux window titles
SHORT_HOST="$(hostname | cut -f1 -d.) - "

eval $(dircolors -b ~/.dir_colors)

# Prompt colors
autoload -U colors
colors

prompt_color_name=green
prompt_color="%{$fg[${prompt_color_name}]%}"


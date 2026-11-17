# Make sure we read git config from the desired location
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/config"


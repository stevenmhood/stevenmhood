# Python version manager — initialize only if installed
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    eval "$(pyenv init -)"
fi

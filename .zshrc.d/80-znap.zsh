# znap zsh plugin manager
if [[ ! -f ~/.zsh_addons/zsh-znap/znap.zsh ]]; then
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git ~/.zsh_addons/zsh-znap
fi
source ~/.zsh_addons/zsh-znap/znap.zsh

# Plugins
znap source zsh-users/zsh-syntax-highlighting

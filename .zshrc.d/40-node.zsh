# Node version manager — prefer Range's /workplace/nvm, fall back to ~/.nvm at home
if [[ -z "$NVM_DIR" ]]; then
    if [[ -d /workplace/nvm ]]; then
        export NVM_DIR="/workplace/nvm"
    else
        export NVM_DIR="$HOME/.nvm"
    fi
fi

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

    # Auto-switch node version on cd via .nvmrc
    autoload -U add-zsh-hook
    load-nvmrc() {
        local node_version="$(nvm version)"
        local nvmrc_path="$(nvm_find_nvmrc)"
        if [[ -n "$nvmrc_path" ]]; then
            local nvmrc_node_version=$(nvm version "$(cat "$nvmrc_path")")
            if [[ "$nvmrc_node_version" = "N/A" ]]; then
                nvm install
            elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
                nvm use
            fi
        elif [[ "$node_version" != "$(nvm version default)" ]]; then
            echo "Reverting to nvm default version"
            nvm use default
        fi
    }
    add-zsh-hook chpwd load-nvmrc
    load-nvmrc
fi

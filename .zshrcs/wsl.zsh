# https://github.com/microsoft/WSL/issues/5065
function wsl_interop() {
    export WSL_INTEROP=/run/WSL/$(ls -tr /run/WSL | head -n1)
}
wsl_interop

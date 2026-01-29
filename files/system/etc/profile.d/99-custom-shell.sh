# Configuração global do Shell para Kinoite Bootc

# Inicia o Starship se estiver instalado
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# Executa fastfetch no login interativo
# A verificação extra [ -z "$FASTFETCH_RAN" ] impede que ele rode
# novamente ao abrir subshells (ex: terminal do VSCode ou tmux)
if [[ $- == *i* ]] && command -v fastfetch &> /dev/null; then
    if [ -z "$FASTFETCH_RAN" ]; then
        fastfetch
        export FASTFETCH_RAN=1
    fi
fi
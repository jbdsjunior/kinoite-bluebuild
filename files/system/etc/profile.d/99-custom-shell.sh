# Configuração global do Shell para Kinoite Bootc

# Inicia o Starship se estiver instalado
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# Executa fastfetch no login interativo (opcional)
# Verifica se é um shell interativo e não é uma sessão de login remoto automática
if [[ $- == *i* ]] && command -v fastfetch &> /dev/null; then
    fastfetch
fi
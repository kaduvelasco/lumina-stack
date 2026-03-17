#!/usr/bin/env bash

# Função interna para evitar repetição de código
install_binary() {
    local SCRIPT_NAME=$1
    local COMMAND_NAME=$2
    local PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local SOURCE="$PROJECT_ROOT/scripts/$SCRIPT_NAME"
    local TARGET="/usr/local/bin/$COMMAND_NAME"

    if [ ! -f "$SOURCE" ]; then
        echo "❌ Erro: Arquivo $SOURCE não encontrado."
        return 1
    fi

    echo "🚀 Instalando comando '$COMMAND_NAME'..."
    sudo cp "$SOURCE" "$TARGET"
    sudo chmod +x "$TARGET"

    if [ $? -eq 0 ]; then
        echo "✅ Comando '$COMMAND_NAME' instalado com sucesso em $TARGET"
    else
        echo "❌ Falha ao instalar '$COMMAND_NAME'."
    fi
}

# Função chamada pela Opção 5
install_my_docker() {
    install_binary "lumina.sh" "lumina"
}

# Função chamada pela Opção 6
install_db_manager() {
    install_binary "lumina-db.sh" "lumina-db"
}

#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Instalador de Comandos Globais
# ==============================================================================
# Descrição   : Copia os scripts de runtime para /usr/local/bin, tornando
#               os comandos 'lumina' e 'lumina-db' disponíveis globalmente.
# Dependências: lib/colors.sh (carregado via install.sh), pasta scripts/
# Uso         : source lib/scripts-installer.sh  (carregado automaticamente pelo install.sh)
# Versão      : 2.0.0
# ==============================================================================

# Função interna para evitar repetição de código
install_binary() {
    local SCRIPT_NAME="$1"
    local COMMAND_NAME="$2"
    local PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local SOURCE="$PROJECT_ROOT/scripts/$SCRIPT_NAME"
    local TARGET="/usr/local/bin/$COMMAND_NAME"

    echo -e "\n${AZUL}🚀 Instalando comando '${AMARELO}$COMMAND_NAME${AZUL}'...${RESET}"

    if [ ! -f "$SOURCE" ]; then
        echo -e "${VERMELHO}❌ Erro: Arquivo não encontrado em $SOURCE${RESET}"
        echo -e "   Verifique se a pasta ${AMARELO}scripts/${RESET} existe na raiz do projeto."
        return 1
    fi

    sudo cp "$SOURCE" "$TARGET"
    sudo chmod +x "$TARGET"

    if [ $? -eq 0 ]; then
        echo -e "${VERDE}✅ Comando '${AMARELO}$COMMAND_NAME${VERDE}' instalado em $TARGET${RESET}"
    else
        echo -e "${VERMELHO}❌ Falha ao instalar '$COMMAND_NAME'. Verifique as permissões de sudo.${RESET}"
        return 1
    fi
}

# Função chamada pela opção 5 do menu
install_my_docker() {
    install_binary "lumina.sh" "lumina"
}

# Função chamada pela opção 6 do menu
install_db_manager() {
    install_binary "lumina-db.sh" "lumina-db"
}

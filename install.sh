#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Instalador Principal
# ==============================================================================
# Descrição   : Ponto de entrada do instalador. Carrega as bibliotecas e exibe
#               o menu interativo para configuração do ambiente.
# Dependências: lib/colors.sh, lib/menu.sh, lib/system.sh, lib/workspace.sh,
#               lib/docker.sh, lib/scripts-installer.sh
# Uso         : ./install.sh
# Versão      : 2.0.0
# ==============================================================================

# Define a base do projeto
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Carrega as bibliotecas
# shellcheck source=lib/colors.sh
source "$BASE_DIR/lib/colors.sh"
# shellcheck source=lib/menu.sh
source "$BASE_DIR/lib/menu.sh"
# shellcheck source=lib/system.sh
source "$BASE_DIR/lib/system.sh"
# shellcheck source=lib/workspace.sh
source "$BASE_DIR/lib/workspace.sh"
# shellcheck source=lib/docker.sh
source "$BASE_DIR/lib/docker.sh"
# shellcheck source=lib/scripts-installer.sh
source "$BASE_DIR/lib/scripts-installer.sh"

# Exibe mensagem de conclusão e aguarda o usuário antes de voltar ao menu
concluir_acao() {
    local LABEL="$1"
    echo -e "\n${VERDE}✅ $LABEL concluída com sucesso!${RESET}"
    echo -e "${AZUL}──────────────────────────────────${RESET}"
    read -r -p "   Pressione Enter para voltar ao menu..."
}

# Garante que o terminal comece limpo
clear

while true
do
    show_menu

    read -r -p "Selecione uma opção: " opt

    case $opt in
        1)
            install_prereqs
            concluir_acao "Instalação de pré-requisitos"
            ;;
        2)
            install_docker
            concluir_acao "Instalação do Docker"
            ;;
        3)
            create_workspace
            concluir_acao "Criação do workspace"
            ;;
        4)
            generate_docker_stack
            concluir_acao "Geração da stack Docker"
            ;;
        5)
            install_my_docker
            concluir_acao "Instalação do comando lumina"
            ;;
        6)
            install_db_manager
            concluir_acao "Instalação do comando lumina-db"
            ;;
        0)
            echo -e "\n${VERDE}Saindo do LuminaStack. Até logo!${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "\n${VERMELHO}❌ Opção inválida! Tente novamente.${RESET}"
            sleep 1
            ;;
    esac
done

#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Instalador Principal
# ==============================================================================

# Define a base do projeto
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Carrega as bibliotecas
source "$BASE_DIR/lib/menu.sh"
source "$BASE_DIR/lib/system.sh"
source "$BASE_DIR/lib/workspace.sh"
source "$BASE_DIR/lib/docker.sh"
source "$BASE_DIR/lib/scripts-installer.sh"

# Cores para o instalador
VERDE='\033[0;32m'
RESET='\033[0m'

# Garante que o terminal comece limpo
clear

while true
do
    show_menu

    read -p "Selecione uma opção: " opt

    case $opt in
        1)
            install_prereqs
            ;;
        2)
            install_docker
            ;;
        3)
            create_workspace
            ;;
        4)
            generate_docker_stack
            ;;
        5)
            install_my_docker
            ;;
        6)
            install_db_manager
            ;;
        0)
            echo -e "\n${VERDE}Saindo do LuminaStack. Até logo!${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "\n❌ Opção inválida! Tente novamente."
            sleep 1
            clear
            ;;
    esac
done

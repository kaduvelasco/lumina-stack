#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Menu Principal
# ==============================================================================
# Descrição   : Exibe o menu interativo do instalador. As cores dependem do
#               colors.sh carregado previamente pelo install.sh.
# Dependências: lib/colors.sh (carregado via install.sh)
# Uso         : source lib/menu.sh  (carregado automaticamente pelo install.sh)
# Versão      : 2.0.0
# ==============================================================================

show_menu() {
    clear
    echo -e "${AZUL}====================================${RESET}"
    echo -e "${AZUL}        LUMINA STACK${RESET}"
    echo -e "${AZUL}====================================${RESET}"
    echo -e " ${VERDE}1.${RESET} Instalar pré-requisitos"
    echo -e "    ${AZUL}↳ curl, git, openssl, lsof${RESET}"
    echo -e " ${VERDE}2.${RESET} Instalar Docker"
    echo -e "    ${AZUL}↳ Engine + adiciona usuário ao grupo docker${RESET}"
    echo -e " ${VERDE}3.${RESET} Criar workspace"
    echo -e "    ${AZUL}↳ Cria ~/workspace com toda a estrutura de pastas${RESET}"
    echo -e " ${VERDE}4.${RESET} Gerar stack Docker"
    echo -e "    ${AZUL}↳ Configura PHP, Nginx e MariaDB via docker-compose${RESET}"
    echo -e " ${VERDE}5.${RESET} Instalar comando ${AMARELO}lumina${RESET}"
    echo -e "    ${AZUL}↳ Gerencia containers (iniciar, parar, logs)${RESET}"
    echo -e " ${VERDE}6.${RESET} Instalar comando ${AMARELO}lumina-db${RESET}"
    echo -e "    ${AZUL}↳ Gerencia banco (backup, restore, otimização)${RESET}"
    echo -e " ${VERMELHO}0.${RESET} Sair"
    echo -e "${AZUL}====================================${RESET}"
    echo ""
}

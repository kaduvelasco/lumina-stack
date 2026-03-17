#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Gestor de Ambiente (lumina)
# ==============================================================================

# Cores para o terminal
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
RESET='\033[0m'

# Caminhos absolutos usando a variável de ambiente HOME
WORKSPACE_DEFAULT="$HOME/workspace/docker"
WORKSPACE="$WORKSPACE_DEFAULT"

detect_workspace() {
    if [ ! -d "$WORKSPACE" ]; then
        echo -e "\n${AMARELO}⚠️ Workspace Lumina não encontrado em: $WORKSPACE_DEFAULT${RESET}"
        read -p "Informe o caminho completo do diretório docker: " CUSTOM
        CUSTOM_EVAL=$(eval echo $CUSTOM)
        if [ -d "$CUSTOM_EVAL" ]; then
            WORKSPACE="$CUSTOM_EVAL"
        else
            echo -e "${VERMELHO}❌ Diretório inválido.${RESET}"
            return 1
        fi
    fi
    return 0
}

# --- FUNÇÃO DE PERMISSÕES (Baseada no seu fix-permissions.sh testado) ---
fix_permissions() {
    WORKSPACE_DIR="$HOME/workspace"

    echo -e "\n${AZUL}🔧 Ajustando permissões em $WORKSPACE_DIR...${RESET}"

    if [ ! -d "$WORKSPACE_DIR" ]; then
        echo -e "${VERMELHO}⚠️ Erro: Pasta workspace não encontrada em $WORKSPACE_DIR${RESET}"
        return 1
    fi

    # 1. Ajusta Dono e Grupo (Ponte entre você e o Docker)
    sudo chown -R $USER:www-data "$WORKSPACE_DIR/www"
    sudo chown -R $USER:www-data "$WORKSPACE_DIR/backups"

    # 2. Permissões de Pastas (775: Você e Docker gravam, outros leem)
    find "$WORKSPACE_DIR/www" -type d -exec sudo chmod 775 {} +
    find "$WORKSPACE_DIR/backups" -type d -exec sudo chmod 775 {} +

    # 3. Permissões de Arquivos (664: Você e Docker editam)
    find "$WORKSPACE_DIR/www" -type f -exec sudo chmod 664 {} +

    # 4. Exceção Moodle: Dataroot precisa de 777 para evitar bloqueios de escrita
    if [ -d "$WORKSPACE_DIR/www/data" ]; then
        sudo chmod -R 777 "$WORKSPACE_DIR/www/data"
    fi

    echo -e "${VERDE}✅ Permissões sincronizadas com sucesso!${RESET}"
}

start_environment() {
    detect_workspace || return
    echo -e "\n${VERDE}🚀 Iniciando LuminaStack...${RESET}"
    cd "$WORKSPACE" || return
    docker compose up -d
    echo -e "\n✅ Ambiente online em http://phpXX.localhost"
}

stop_environment() {
    detect_workspace || return
    echo -e "\n${AMARELO}🛑 Preparando para finalizar ambiente...${RESET}"
    echo -ne "💾 Abrir lumina-db para backup antes de parar? (${VERDE}S${RESET}/n): "
    read -r DO_BACKUP

    if [[ -z "$DO_BACKUP" || "$DO_BACKUP" =~ ^[sS]$ ]]; then
        if command -v lumina-db >/dev/null 2>&1; then
            echo -e "${AZUL}⚙️ Abrindo lumina-db...${RESET}"
            lumina-db
        else
            echo -e "${VERMELHO}⚠️ Comando 'lumina-db' não encontrado no sistema.${RESET}"
        fi
    fi

    echo -e "\n${VERMELHO}🔌 Desligando containers...${RESET}"
    cd "$WORKSPACE" || return
    docker compose down
    echo -e "\n✅ LuminaStack finalizado."
}

show_db_info() {
    detect_workspace || return
    echo -e "\n${AZUL}🗄️ Banco de Dados (MariaDB)${RESET}\n"
    echo "📍 Host: localhost"
    echo "🔌 Porta: 3306"

    if [ -f "$WORKSPACE/.env" ]; then
        echo -n "👤 Usuário: "
        grep DB_USER "$WORKSPACE/.env" | cut -d '=' -f2
        echo -n "🔑 Senha: "
        grep DB_PASS "$WORKSPACE/.env" | cut -d '=' -f2
    fi
    echo ""
}

logs_menu() {
    local LOG_DIR="$HOME/workspace/logs"
    if [ ! -d "$LOG_DIR" ]; then
        echo -e "${VERMELHO}❌ Diretório de logs não encontrado em $LOG_DIR${RESET}"
        return
    fi

    while true
    do
        echo -e "\n${AZUL}===== 📜 Visualizador de Logs Lumina =====${RESET}"
        PHP_LOGS=$(ls "$LOG_DIR" 2>/dev/null | grep php)
        INDEX=1
        declare -A MAP
        for p in $PHP_LOGS; do
            VERSION=$(echo "$p" | sed 's/php//')
            echo "$INDEX. PHP $VERSION"
            MAP[$INDEX]="$p"
            ((INDEX++))
        done
        echo "$INDEX. Nginx"
        MAP[$INDEX]="nginx"
        echo "0. Voltar"
        echo ""
        read -p "Escolha o serviço: " OPTION
        if [ "$OPTION" = "0" ] || [ -z "$OPTION" ]; then break; fi
        DIR="${MAP[$OPTION]}"
        if [ -n "$DIR" ] && [ -d "$LOG_DIR/$DIR" ]; then
            echo -e "${AMARELO}👀 Lendo logs de $DIR... (Ctrl+C para sair)${RESET}"
            if ls "$LOG_DIR/$DIR"/*.log >/dev/null 2>&1; then
                tail -f "$LOG_DIR/$DIR"/*.log
            else
                echo -e "${AMARELO}⚠️ Nenhum log encontrado em $LOG_DIR/$DIR${RESET}"
            fi
        fi
    done
}

# Loop Principal do Menu
while true
do
    echo -e "\n${VERDE}✨ LUMINA STACK MANAGER${RESET}"
    echo "------------------------"
    echo "1. Iniciar ambiente (up)"
    echo "2. Verificar logs"
    echo "3. Dados do Banco (MariaDB)"
    echo "4. Finalizar ambiente (down)"
    echo -e "5. ${AMARELO}Corrigir permissões${RESET}"
    echo "0. Sair"
    echo "------------------------"

    read -p "Escolha uma opção: " OPTION

    case $OPTION in
        1) start_environment ;;
        2) logs_menu ;;
        3) show_db_info ;;
        4) stop_environment ;;
        5) fix_permissions ;;
        0) exit 0 ;;
        *) echo -e "${VERMELHO}❌ Opção inválida.${RESET}" ;;
    esac
done

#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Gestor de Ambiente
# ==============================================================================
# Descrição   : Comando global 'lumina' para gerenciar o ambiente Docker.
#               Permite iniciar/parar containers, visualizar logs, consultar
#               credenciais do banco e corrigir permissões do workspace.
# Dependências: docker, lumina-db (opcional, para backup antes do down)
# Uso         : lumina  (instalado em /usr/local/bin pelo scripts-installer.sh)
# Versão      : 2.0.0
# ==============================================================================

# Cores (definidas localmente — este script roda fora do projeto)
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
RESET='\033[0m'

# Caminhos base
WORKSPACE_DEFAULT="$HOME/workspace/docker"
WORKSPACE="$WORKSPACE_DEFAULT"

# ==============================================================================
# FUNÇÕES AUXILIARES
# ==============================================================================

detect_workspace() {
    if [ ! -d "$WORKSPACE" ]; then
        echo -e "\n${AMARELO}⚠️  Workspace Lumina não encontrado em: $WORKSPACE_DEFAULT${RESET}"
        read -r -p "   Informe o caminho completo do diretório docker: " CUSTOM
        # Expansão segura de ~ sem uso de eval
        CUSTOM="${CUSTOM/#\~/$HOME}"
        if [ -d "$CUSTOM" ]; then
            WORKSPACE="$CUSTOM"
        else
            echo -e "${VERMELHO}❌ Diretório inválido: $CUSTOM${RESET}"
            return 1
        fi
    fi
    return 0
}

mostrar_ultimo_backup() {
    local BACKUP_DIR="$HOME/workspace/backups"
    local ULTIMO
    ULTIMO=$(ls -t "$BACKUP_DIR"/*.sql 2>/dev/null | head -1)

    if [ -n "$ULTIMO" ]; then
        local DATA
        DATA=$(stat -c %y "$ULTIMO" | cut -d' ' -f1)
        echo -e "   ${AZUL}💾 Último backup: ${AMARELO}$DATA${AZUL} — $(basename "$ULTIMO")${RESET}"
    else
        echo -e "   ${VERMELHO}⚠️  Nenhum backup encontrado em $BACKUP_DIR${RESET}"
        echo -e "   ${AMARELO}   Considere executar 'lumina-db' para criar um backup.${RESET}"
    fi
}

fix_permissions() {
    local WORKSPACE_DIR="$HOME/workspace"
    local SILENT="${1:-}"

    [ -z "$SILENT" ] && echo -e "\n${AZUL}🔧 Ajustando permissões em $WORKSPACE_DIR...${RESET}"

    if [ ! -d "$WORKSPACE_DIR" ]; then
        echo -e "${VERMELHO}❌ Erro: Pasta workspace não encontrada em $WORKSPACE_DIR${RESET}"
        return 1
    fi

    # 1. Ajusta dono e grupo (ponte entre usuário e Docker)
    sudo chown -R "$USER":www-data "$WORKSPACE_DIR/www"
    sudo chown -R "$USER":www-data "$WORKSPACE_DIR/backups"

    # 2. Permissões de pastas (775: usuário e Docker gravam, outros leem)
    find "$WORKSPACE_DIR/www" -type d -exec sudo chmod 775 {} +
    find "$WORKSPACE_DIR/backups" -type d -exec sudo chmod 775 {} +

    # 3. Permissões de arquivos (664: usuário e Docker editam)
    find "$WORKSPACE_DIR/www" -type f -exec sudo chmod 664 {} +

    # 4. Exceção Moodle: dataroot precisa de 777 para evitar bloqueios de escrita
    #    Necessário pois o MegaSync não preserva permissões ao sincronizar
    if [ -d "$WORKSPACE_DIR/www/data" ]; then
        sudo chmod -R 777 "$WORKSPACE_DIR/www/data"
    fi

    [ -z "$SILENT" ] && echo -e "${VERDE}✅ Permissões sincronizadas com sucesso!${RESET}"
}

# ==============================================================================
# FUNÇÕES DO MENU
# ==============================================================================

start_environment() {
    detect_workspace || return

    # Ajusta permissões silenciosamente (garante integridade após MegaSync)
    fix_permissions "silent"

    # Exibe informações do último backup antes de subir
    echo -e "\n${AZUL}──────────────────────────────────${RESET}"
    mostrar_ultimo_backup
    echo -e "${AZUL}──────────────────────────────────${RESET}"

    echo -e "\n${VERDE}🚀 Iniciando LuminaStack...${RESET}"
    cd "$WORKSPACE" || return
    docker compose up -d

    echo -e "\n${VERDE}✅ Ambiente online!${RESET}"
    echo -e "   Acesse: ${AMARELO}http://localhost${RESET} para o dashboard"
    echo -e "   Ou use: ${AMARELO}http://phpXX.localhost${RESET} para uma versão específica"
}

stop_environment() {
    detect_workspace || return

    echo -e "\n${AMARELO}🛑 Preparando para finalizar o ambiente...${RESET}"
    echo -ne "   💾 Abrir lumina-db para backup antes de parar? (${VERDE}S${RESET}/n): "
    read -r DO_BACKUP

    if [[ -z "$DO_BACKUP" || "$DO_BACKUP" =~ ^[sS]$ ]]; then
        if command -v lumina-db >/dev/null 2>&1; then
            echo -e "${AZUL}⚙️  Abrindo lumina-db...${RESET}"
            lumina-db
        else
            echo -e "${VERMELHO}⚠️  Comando 'lumina-db' não encontrado.${RESET}"
            echo -e "   Execute a opção 6 do instalador para instalá-lo."
        fi
    fi

    echo -e "\n${VERMELHO}🔌 Desligando containers...${RESET}"
    cd "$WORKSPACE" || return
    docker compose down
    echo -e "\n${VERDE}✅ LuminaStack finalizado.${RESET}"
}

show_db_info() {
    detect_workspace || return
    echo -e "\n${AZUL}🗄️  Banco de Dados (MariaDB)${RESET}"
    echo -e "${AZUL}──────────────────────────────────${RESET}"
    echo -e "   📍 Host  : ${AMARELO}localhost${RESET}"
    echo -e "   🔌 Porta : ${AMARELO}3306${RESET}"

    if [ -f "$WORKSPACE/.env" ]; then
        local DB_USER DB_PASS
        # cut -f2- garante que senhas com '=' não sejam truncadas
        DB_USER=$(grep '^DB_USER=' "$WORKSPACE/.env" | cut -d '=' -f2-)
        DB_PASS=$(grep '^DB_PASS=' "$WORKSPACE/.env" | cut -d '=' -f2-)
        echo -e "   👤 Usuário: ${AMARELO}$DB_USER${RESET}"
        echo -e "   🔑 Senha  : ${AMARELO}$DB_PASS${RESET}"
    else
        echo -e "   ${VERMELHO}⚠️  Arquivo .env não encontrado em $WORKSPACE${RESET}"
    fi
    echo -e "${AZUL}──────────────────────────────────${RESET}\n"
}

logs_menu() {
    local LOG_DIR="$HOME/workspace/logs"

    if [ ! -d "$LOG_DIR" ]; then
        echo -e "${VERMELHO}❌ Diretório de logs não encontrado em $LOG_DIR${RESET}"
        return
    fi

    while true; do
        echo -e "\n${AZUL}===== 📜 Visualizador de Logs =====${RESET}"
        local PHP_LOGS INDEX=1
        declare -A MAP
        PHP_LOGS=$(ls "$LOG_DIR" 2>/dev/null | grep php)

        for p in $PHP_LOGS; do
            local VERSION
            VERSION=$(echo "$p" | sed 's/php//')
            echo -e "   ${VERDE}$INDEX.${RESET} PHP $VERSION"
            MAP[$INDEX]="$p"
            ((INDEX++))
        done

        echo -e "   ${VERDE}$INDEX.${RESET} Nginx"
        MAP[$INDEX]="nginx"
        echo -e "   ${VERMELHO}0.${RESET} Voltar"
        echo ""

        read -r -p "Escolha o serviço: " OPTION
        [ "$OPTION" = "0" ] || [ -z "$OPTION" ] && break

        local DIR="${MAP[$OPTION]}"
        if [ -n "$DIR" ] && [ -d "$LOG_DIR/$DIR" ]; then
            echo -e "${AMARELO}👀 Lendo logs de $DIR... (Ctrl+C para sair)${RESET}"
            if ls "$LOG_DIR/$DIR"/*.log >/dev/null 2>&1; then
                tail -f "$LOG_DIR/$DIR"/*.log
            else
                echo -e "${AMARELO}⚠️  Nenhum log encontrado em $LOG_DIR/$DIR${RESET}"
            fi
        else
            echo -e "${VERMELHO}❌ Opção inválida.${RESET}"
        fi
    done
}

show_menu() {
    echo -e "\n${AZUL}====================================${RESET}"
    echo -e "${AZUL}      LUMINA STACK MANAGER${RESET}"
    echo -e "${AZUL}====================================${RESET}"
    echo -e "   ${VERDE}1.${RESET} Iniciar ambiente"
    echo -e "   ${VERDE}2.${RESET} Visualizar logs"
    echo -e "   ${VERDE}3.${RESET} Dados do banco (MariaDB)"
    echo -e "   ${VERDE}4.${RESET} Finalizar ambiente"
    echo -e "   ${AMARELO}5.${RESET} Corrigir permissões"
    echo -e "   ${VERMELHO}0.${RESET} Sair"
    echo -e "${AZUL}====================================${RESET}"
}

# ==============================================================================
# LOOP PRINCIPAL
# ==============================================================================

while true; do
    show_menu
    read -r -p "Escolha uma opção: " OPTION

    case $OPTION in
        1) start_environment ;;
        2) logs_menu ;;
        3) show_db_info ;;
        4) stop_environment ;;
        5) fix_permissions ;;
        0)
            echo -e "\n${VERDE}Até logo!${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${VERMELHO}❌ Opção inválida.${RESET}"
            sleep 1
            ;;
    esac
done

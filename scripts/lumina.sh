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

# --- Help ---
show_help() {
    cat << EOF
lumina — Gerenciador do ambiente Docker LuminaStack

USO:
  lumina                  Abre o menu interativo
  lumina -h, --help       Exibe esta ajuda
  lumina -v, --version    Exibe a versão

OPÇÕES DO MENU:
  1  Iniciar ambiente     Sobe containers PHP, Nginx e MariaDB
  2  Visualizar logs      Acompanha logs em tempo real
  3  Dados do banco       Exibe credenciais e porta do MariaDB
  4  Finalizar ambiente   Desce containers (com opção de backup)
  5  Corrigir permissões  Resincroniza permissões após MegaSync
  6  Status               Saúde e uso de recursos dos containers

EXEMPLOS:
  lumina                  # Abre o menu
  lumina --help           # Esta ajuda
EOF
}

[[ "$1" == "-h" || "$1" == "--help" ]] && show_help && exit 0
[[ "$1" == "-v" || "$1" == "--version" ]] && echo "LuminaStack Manager v2.0.0" && exit 0

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
    ULTIMO=$(find "$BACKUP_DIR" -maxdepth 1 -name "*.sql" -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -1 | cut -d" " -f2-)

    if [ -n "$ULTIMO" ]; then
        local DATA
        # stat -c é GNU/Linux; fallback via date -r para sistemas sem GNU coreutils
        if ! DATA=$(stat -c %y "$ULTIMO" 2>/dev/null | cut -d' ' -f1); then
            DATA=$(date -r "$ULTIMO" +%Y-%m-%d 2>/dev/null || echo "data desconhecida")
        fi
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

pre_flight_check() {
    local ISSUES=0

    # 1. Docker daemon
    if ! docker ps > /dev/null 2>&1; then
        echo -e "   ${VERMELHO}❌ Docker daemon não está rodando (systemctl start docker)${RESET}"
        (( ISSUES++ ))
    fi

    # 2. Espaço em disco (avisa acima de 85%)
    local DISK_USE
    DISK_USE=$(df "$HOME" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    if [[ -n "$DISK_USE" && "$DISK_USE" -gt 85 ]]; then
        echo -e "   ${AMARELO}⚠️  Disco com ${DISK_USE}% de uso — pode faltar espaço para imagens Docker${RESET}"
        (( ISSUES++ ))
    fi

    # 3. Permissão de escrita no workspace
    if [[ -d "$HOME/workspace/www/html" && ! -w "$HOME/workspace/www/html" ]]; then
        echo -e "   ${AMARELO}⚠️  Sem permissão de escrita em ~/workspace/www/html${RESET}"
        echo -e "      Execute: lumina → opção 5 (Corrigir permissões)"
        (( ISSUES++ ))
    fi

    # 4. Porta 80 ocupada por outro processo
    if command -v lsof >/dev/null 2>&1; then
        if sudo lsof -i :80 2>/dev/null | grep -qv "nginx"; then
            echo -e "   ${AMARELO}⚠️  Porta 80 em uso por outro processo (sudo lsof -i :80)${RESET}"
            (( ISSUES++ ))
        fi
    fi

    if [[ "$ISSUES" -gt 0 ]]; then
        echo -e "   ${AMARELO}$ISSUES aviso(s) encontrado(s). Continuar mesmo assim? (s/N):${RESET} \c"
        read -r CONTINUE_ANYWAY
        [[ ! "$CONTINUE_ANYWAY" =~ ^[sS]$ ]] && return 1
    fi

    return 0
}

start_environment() {
    detect_workspace || return

    echo -e "\n${AZUL}🔍 Verificações pré-inicialização...${RESET}"
    pre_flight_check || return

    # Ajusta permissões silenciosamente (garante integridade após MegaSync)
    fix_permissions "silent"

    # Exibe informações do último backup antes de subir
    echo -e "\n${AZUL}──────────────────────────────────${RESET}"
    mostrar_ultimo_backup
    echo -e "${AZUL}──────────────────────────────────${RESET}"

    echo -e "\n${VERDE}🚀 Iniciando LuminaStack...${RESET}"
    cd "$WORKSPACE" || return
    if ! docker compose up -d; then
        echo -e "\n${VERMELHO}❌ Falha ao iniciar a stack. Verifique:${RESET}"
        echo -e "   • A porta 80 ou 3306 está em uso? (sudo lsof -i :80)"
        echo -e "   • Os volumes estão acessíveis?"
        echo -e "   • O Docker daemon está rodando? (systemctl status docker)"
        return 1
    fi

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
    if ! docker compose down --timeout 5 --remove-orphans; then
        echo -e "\n${VERMELHO}❌ Erro ao desligar os containers. Verifique com: docker ps${RESET}"
        return 1
    fi
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
        local INDEX=1
        unset MAP
        declare -A MAP
        for p in "$LOG_DIR"/php*/; do
            p=$(basename "$p")
            local VERSION
            VERSION="${p#php}"
            echo -e "   ${VERDE}$INDEX.${RESET} PHP $VERSION"
            MAP[$INDEX]="$p"
            ((INDEX++))
        done

        if [ "${#MAP[@]}" -eq 0 ]; then
            echo -e "   ${AMARELO}⚠️  Nenhum diretório de log PHP encontrado em $LOG_DIR${RESET}"
        fi

        echo -e "   ${VERDE}$INDEX.${RESET} Nginx"
        MAP[$INDEX]="nginx"
        echo -e "   ${VERMELHO}0.${RESET} Voltar"
        echo ""

        read -r -p "Escolha o serviço: " OPTION
        [ "$OPTION" = "0" ] || [ -z "$OPTION" ] && break

        local DIR="${MAP[$OPTION]}"
        if [ -n "$DIR" ] && [ -d "$LOG_DIR/$DIR" ]; then
            echo -e "${AMARELO}👀 Lendo logs de $DIR... (Ctrl+C para sair)${RESET}"
            if find "$LOG_DIR/$DIR" -maxdepth 1 -name "*.log" -type f | grep -q .; then
                tail -f "$LOG_DIR/$DIR"/*.log
            else
                echo -e "${AMARELO}⚠️  Nenhum log encontrado em $LOG_DIR/$DIR${RESET}"
            fi
        else
            echo -e "${VERMELHO}❌ Opção inválida.${RESET}"
        fi
    done
}

show_status() {
    detect_workspace || return

    echo -e "\n${AZUL}🔍 Status da Stack LuminaStack${RESET}"
    echo -e "${AZUL}──────────────────────────────────${RESET}"

    local SERVICES=("nginx" "mariadb")
    local PHP_VERSIONS_ENV
    PHP_VERSIONS_ENV=$(grep '^PHP_VERSIONS=' "$WORKSPACE/.env" 2>/dev/null | cut -d'=' -f2-)
    for v in $PHP_VERSIONS_ENV; do
        SERVICES+=("php${v//./}")
    done

    local ANY_RUNNING=false
    for SVC in "${SERVICES[@]}"; do
        local STATUS
        STATUS=$(docker ps --filter "name=^${SVC}$" --format "{{.Status}}" 2>/dev/null)
        if [[ -n "$STATUS" ]]; then
            echo -e "   ${VERDE}●${RESET} ${AMARELO}${SVC}${RESET}  —  $STATUS"
            ANY_RUNNING=true
        else
            echo -e "   ${VERMELHO}●${RESET} ${AMARELO}${SVC}${RESET}  —  parado"
        fi
    done

    echo -e "${AZUL}──────────────────────────────────${RESET}"

    if [[ "$ANY_RUNNING" == "true" ]]; then
        echo -e "\n${AZUL}📊 Uso de recursos (containers ativos):${RESET}"
        docker stats --no-stream --format \
            "   {{.Name}}\t CPU: {{.CPUPerc}}\t MEM: {{.MemUsage}}" 2>/dev/null \
            | grep -E "$(IFS="|"; echo "${SERVICES[*]}")" || true
    fi
    echo ""
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
    echo -e "   ${AZUL}6.${RESET} Status e recursos"
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
        6) show_status ;;
        0)
            echo -e "\n${VERDE}Até logo!${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${VERMELHO}❌ Opção inválida. Digite um número de 0 a 6.${RESET}"
            sleep 1
            ;;
    esac
done

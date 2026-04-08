#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Gerenciador de Banco de Dados
# ==============================================================================
# Descrição   : Comando global 'lumina-db' para gerenciar backups, restores,
#               otimização de tabelas e configuração de performance do MariaDB.
#               Os backups são sempre salvos em ~/workspace/backups,
#               sincronizado automaticamente via MegaSync.
# Dependências: docker (container mariadb em execução)
# Uso         : lumina-db  (instalado em /usr/local/bin pelo scripts-installer.sh)
# Versão      : 2.0.0
# ==============================================================================

# --- Help ---
show_help() {
    cat << EOF
lumina-db — Gerenciador de banco de dados LuminaStack

USO:
  lumina-db               Abre o menu interativo
  lumina-db -h, --help    Exibe esta ajuda
  lumina-db -v, --version Exibe a versão

OPÇÕES DO MENU:
  1  Backup (dump)                Exporta todos os bancos para ~/workspace/backups
  2  Remover bancos               Remove bancos individualmente (com confirmação)
  3  Restaurar (restore)          Importa um backup SQL existente
  4  Verificar / Otimizar tabelas Executa mariadb-check --optimize
  5  Otimizar MariaDB para Moodle Ajusta buffer pool conforme a RAM disponível

REQUISITO:
  O container '${CONTAINER_NAME:-mariadb}' deve estar em execução.
  Inicie o ambiente com: lumina → opção 1
EOF
}

[[ "$1" == "-h" || "$1" == "--help" ]] && show_help && exit 0
[[ "$1" == "-v" || "$1" == "--version" ]] && echo "LuminaStack DB Manager v2.0.0" && exit 0

# Cores (definidas localmente — este script roda fora do projeto)
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
RESET='\033[0m'

# Configurações
CONTAINER_NAME="mariadb"
DOCKER_BASE_DIR="$HOME/workspace/docker"
CONF_MOODLE_DIR="$DOCKER_BASE_DIR/mariadb/conf.d"
BACKUP_DIR="$HOME/workspace/backups"
BACKUPS_MANTER=3

trap 'printf "\n❌ Operação interrompida pelo usuário.\n"; exit 1' SIGINT

# ==============================================================================
# FUNÇÕES AUXILIARES
# ==============================================================================

verificar_docker() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        echo -e "${VERMELHO}❌ Container '$CONTAINER_NAME' não está rodando.${RESET}"
        echo -e "   Inicie o ambiente com o comando ${AMARELO}lumina${RESET} antes de prosseguir."
        exit 1
    fi
}

ler_credenciais() {
    local tentativas=0
    while [ "$tentativas" -lt 3 ]; do
        read -r -p "   👤 Usuário MariaDB: " DB_USER
        if [[ -z "$DB_USER" ]]; then
            echo -e "   ${VERMELHO}❌ Usuário não pode ser vazio.${RESET}"
            (( tentativas++ )); continue
        fi
        if ! [[ "$DB_USER" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo -e "   ${VERMELHO}❌ Usuário inválido. Use apenas letras, números, _ e -.${RESET}"
            (( tentativas++ )); continue
        fi
        read -r -s -p "   🔑 Senha MariaDB: " DB_PASS
        echo ""
        if [[ -z "$DB_PASS" ]]; then
            echo -e "   ${VERMELHO}❌ Senha não pode ser vazia.${RESET}"
            (( tentativas++ )); continue
        fi
        return 0
    done
    echo -e "${VERMELHO}❌ Falha após 3 tentativas de autenticação.${RESET}"
    return 1
}

executar_mysql() {
    # Usa MYSQL_PWD para evitar exposição da senha no ps aux
    docker exec -i -e MYSQL_PWD="$DB_PASS" "$CONTAINER_NAME" \
        mariadb -u "$DB_USER" "$@"
}

limpar_backups_antigos() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        return 0
    fi

    local TOTAL
    TOTAL=$(find "$BACKUP_DIR" -maxdepth 1 -name "*.sql" | wc -l)

    if [ "$TOTAL" -gt "$BACKUPS_MANTER" ]; then
        local REMOVER=$(( TOTAL - BACKUPS_MANTER ))
        echo -e "\n${AMARELO}🧹 Mantendo os $BACKUPS_MANTER backups mais recentes...${RESET}"
        # Usa process substitution para que erros de rm sejam detectados
        while IFS= read -r ARQUIVO; do
            if rm "$ARQUIVO"; then
                echo -e "   Removido: $(basename "$ARQUIVO")"
            else
                echo -e "   ${VERMELHO}❌ Erro ao remover: $(basename "$ARQUIVO")${RESET}"
            fi
        done < <(find "$BACKUP_DIR" -maxdepth 1 -name "*.sql" -printf "%T@ %p\n" | sort -rn | tail -n "$REMOVER" | cut -d" " -f2-)
        echo -e "${VERDE}✅ $REMOVER arquivo(s) antigo(s) removido(s) localmente.${RESET}"
        echo -e "   ${AZUL}(O histórico completo permanece no Mega)${RESET}"
    fi
}

# ==============================================================================
# FUNÇÕES DE BANCO
# ==============================================================================

executar_backup() {
    clear
    verificar_docker
    mkdir -p "$BACKUP_DIR"

    local TIMESTAMP
    TIMESTAMP=$(date +"%Y%m%d-%H%M")
    local FILE_NAME="backup_full_${TIMESTAMP}.sql"
    local FULL_PATH="$BACKUP_DIR/$FILE_NAME"

    echo -e "${AZUL}⚙️  Executando Backup Completo (MariaDB)...${RESET}"
    echo -e "   📁 Destino: ${AMARELO}$FULL_PATH${RESET}\n"

    ler_credenciais || { read -r -p "Pressione Enter para continuar..."; return; }

    if docker exec -e MYSQL_PWD="$DB_PASS" "$CONTAINER_NAME" \
        mariadb-dump -u "$DB_USER" --all-databases > "$FULL_PATH"; then
        echo -e "\n${VERDE}✅ Backup concluído com sucesso!${RESET}"
        echo -e "   📄 Arquivo: ${AMARELO}$FILE_NAME${RESET}"
        limpar_backups_antigos
    else
        echo -e "\n${VERMELHO}❌ Erro ao realizar o backup.${RESET}"
        [ -f "$FULL_PATH" ] && rm -f "$FULL_PATH"
    fi

    echo ""
    read -r -p "Pressione Enter para continuar..."
}

remover_bancos_de_dados() {
    clear
    verificar_docker

    echo -e "${VERMELHO}⚠️  REMOÇÃO DE BANCOS — Use com cuidado!${RESET}\n"
    ler_credenciais || { read -r -p "Pressione Enter para continuar..."; return; }
    echo ""

    local DBS DB_OUTPUT
    if ! DB_OUTPUT=$(executar_mysql -e "SHOW DATABASES;" 2>&1); then
        echo -e "${VERMELHO}❌ Falha ao conectar ao banco. Verifique as credenciais.${RESET}"
        read -r -p "Pressione Enter para continuar..."
        return
    fi
    DBS=$(echo "$DB_OUTPUT" | grep -Ev "^(Database|mysql|information_schema|performance_schema|sys)$")

    if [ -z "$DBS" ]; then
        echo -e "${AMARELO}ℹ️  Nenhum banco de dados personalizado encontrado.${RESET}"
    else
        for db in $DBS; do
            read -r -p "   Remover o banco '${db}'? (s/N): " resp
            if [[ "$resp" =~ ^[sS]$ ]]; then
                executar_mysql -e "DROP DATABASE \`$db\`;"
                echo -e "   ${VERDE}✅ Banco '$db' removido.${RESET}"
            fi
        done
    fi

    echo ""
    read -r -p "Pressione Enter para continuar..."
}

executar_restore() {
    clear
    verificar_docker

    echo -e "${AZUL}⚙️  Executando Restore${RESET}"
    echo -e "   📁 Buscando backups em: ${AMARELO}$BACKUP_DIR${RESET}\n"

    # Lista os arquivos SQL disponíveis com seleção numerada
    mapfile -t ARQUIVOS < <(find "$BACKUP_DIR" -maxdepth 1 -name "*.sql" -printf "%T@ %p\n" 2>/dev/null | sort -rn | cut -d" " -f2-)

    if [ ${#ARQUIVOS[@]} -eq 0 ]; then
        echo -e "${VERMELHO}❌ Nenhum arquivo SQL encontrado em $BACKUP_DIR${RESET}"
        read -r -p "Pressione Enter para continuar..."
        return
    fi

    for i in "${!ARQUIVOS[@]}"; do
        echo -e "   ${VERDE}$((i+1)).${RESET} $(basename "${ARQUIVOS[$i]}")"
    done
    echo ""

    local NUM
    read -r -p "Selecione o arquivo [1-${#ARQUIVOS[@]}]: " NUM

    if ! [[ "$NUM" =~ ^[0-9]+$ ]] || [ "$NUM" -lt 1 ] || [ "$NUM" -gt "${#ARQUIVOS[@]}" ]; then
        echo -e "${VERMELHO}❌ Opção inválida.${RESET}"
        read -r -p "Pressione Enter para continuar..."
        return
    fi

    local FILE_FULL="${ARQUIVOS[$((NUM-1))]}"

    if [[ ! -f "$FILE_FULL" ]]; then
        echo -e "${VERMELHO}❌ Arquivo não encontrado ou inacessível.${RESET}"
        read -r -p "Pressione Enter para continuar..."
        return
    fi

    echo -e "\n   Arquivo selecionado: ${AMARELO}$(basename "$FILE_FULL")${RESET}\n"

    ler_credenciais || { read -r -p "Pressione Enter para continuar..."; return; }
    echo -e "\n${AMARELO}⏳ Restaurando... Isso pode levar alguns minutos.${RESET}"

    if executar_mysql < "$FILE_FULL"; then
        echo -e "${VERDE}✅ Restore concluído com sucesso!${RESET}"
    else
        echo -e "${VERMELHO}❌ Erro durante o restore.${RESET}"
    fi

    echo ""
    read -r -p "Pressione Enter para continuar..."
}

verificar_tabelas() {
    clear
    verificar_docker

    echo -e "${AZUL}🛠️  Verificando e Otimizando Tabelas${RESET}\n"
    ler_credenciais || { read -r -p "Pressione Enter para continuar..."; return; }
    echo ""

    # -i apenas (sem -t) para funcionar corretamente dentro de scripts
    docker exec -i -e MYSQL_PWD="$DB_PASS" "$CONTAINER_NAME" \
        mariadb-check -u "$DB_USER" --all-databases --optimize

    echo ""
    read -r -p "Pressione Enter para continuar..."
}

detect_system_ram() {
    local TOTAL_RAM_MB
    TOTAL_RAM_MB=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}')
    if [[ -n "$TOTAL_RAM_MB" && "$TOTAL_RAM_MB" -gt 0 ]]; then
        echo "$TOTAL_RAM_MB"
        return 0
    fi
    return 1
}

prompt_buffer_pool_allocation() {
    local TOTAL_RAM_MB="$1"
    echo -e "${AZUL}Quanto desta RAM deseja dedicar ao Buffer Pool do MariaDB?${RESET}"
    echo -e "   ${VERDE}1.${RESET} 1/2 da RAM — $(( TOTAL_RAM_MB / 2 ))MB  (Ideal para DB dedicado)"
    echo -e "   ${VERDE}2.${RESET} 1/3 da RAM — $(( TOTAL_RAM_MB / 3 ))MB  (Equilibrado - Recomendado)"
    echo -e "   ${VERDE}3.${RESET} 1/4 da RAM — $(( TOTAL_RAM_MB / 4 ))MB  (Econômico)"
    echo ""
    read -r -p "   Opção [1-3]: " escolha_ram
    case "$escolha_ram" in
        1) echo $(( TOTAL_RAM_MB / 2 )) ;;
        2) echo $(( TOTAL_RAM_MB / 3 )) ;;
        3) echo $(( TOTAL_RAM_MB / 4 )) ;;
        *)
            echo -e "   ${AMARELO}⚠️  Opção inválida. Usando 1/3 como padrão.${RESET}" >&2
            echo $(( TOTAL_RAM_MB / 3 ))
            ;;
    esac
}

write_mariadb_config() {
    local BUFFER_POOL_MB="$1"
    mkdir -p "$CONF_MOODLE_DIR"
cat > "$CONF_MOODLE_DIR/moodle-performance.cnf" << EOF
[mariadb]
max_allowed_packet = 64M
innodb_buffer_pool_size = ${BUFFER_POOL_MB}M
innodb_log_file_size = 256M
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2
binlog_format = ROW
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
EOF
}

otimizar_mariadb_moodle() {
    clear
    verificar_docker || return 1
    echo -e "${AZUL}⚡ Otimizando MariaDB para Moodle${RESET}\n"

    local TOTAL_RAM_MB
    if TOTAL_RAM_MB=$(detect_system_ram); then
        echo -e "   ${VERDE}✅ RAM detectada: ${AMARELO}${TOTAL_RAM_MB}MB (~$(( TOTAL_RAM_MB / 1024 ))GB)${RESET}\n"
    else
        echo -e "   ${AMARELO}⚠️  Não foi possível detectar a RAM automaticamente.${RESET}"
        local TOTAL_RAM_GB
        read -r -p "   Informe a quantidade de RAM em GB (ex: 12): " TOTAL_RAM_GB
        while ! [[ "$TOTAL_RAM_GB" =~ ^[0-9]+$ ]] || [ "$TOTAL_RAM_GB" -lt 1 ]; do
            echo -e "   ${VERMELHO}❌ Valor inválido. Digite apenas números inteiros.${RESET}"
            read -r -p "   Informe a quantidade de RAM em GB: " TOTAL_RAM_GB
        done
        TOTAL_RAM_MB=$(( TOTAL_RAM_GB * 1024 ))
    fi

    local BUFFER_POOL_MB
    BUFFER_POOL_MB=$(prompt_buffer_pool_allocation "$TOTAL_RAM_MB")

    echo -e "\n${VERDE}📦 Configurando innodb_buffer_pool_size para: ${AMARELO}${BUFFER_POOL_MB}MB${RESET}"
    write_mariadb_config "$BUFFER_POOL_MB"

    echo -e "${AMARELO}🔄 Reiniciando container para carregar as novas configurações...${RESET}"
    if docker restart "$CONTAINER_NAME"; then
        echo -e "${VERDE}✅ Configurações aplicadas com sucesso.${RESET}"
    else
        echo -e "${VERMELHO}❌ Falha ao reiniciar o container. Verifique com: docker ps${RESET}"
    fi
    echo ""
    read -r -p "Pressione Enter para continuar..."
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

exibir_menu() {
    clear
    echo -e "${AZUL}====================================${RESET}"
    echo -e "${AZUL}    LUMINA-DB :: GESTÃO DE DADOS${RESET}"
    echo -e "${AZUL}====================================${RESET}"
    echo -e "   ${VERDE}1.${RESET} Backup (dump)"
    echo -e "   ${VERDE}2.${RESET} Remover bancos"
    echo -e "   ${VERDE}3.${RESET} Restaurar (restore)"
    echo -e "   ${VERDE}4.${RESET} Verificar / Otimizar tabelas"
    echo -e "   ${VERDE}5.${RESET} Otimizar MariaDB para Moodle"
    echo -e "   ${VERMELHO}0.${RESET} Sair"
    echo -e "${AZUL}====================================${RESET}"
    echo ""
}

while true; do
    exibir_menu
    read -r -p "Opção: " escolha
    case "$escolha" in
        1) executar_backup ;;
        2) remover_bancos_de_dados ;;
        3) executar_restore ;;
        4) verificar_tabelas ;;
        5) otimizar_mariadb_moodle ;;
        0)
            echo -e "\n${VERDE}Até logo!${RESET}\n"
            exit 0
            ;;
        *) echo -e "${VERMELHO}❌ Opção inválida. Digite um número de 0 a 5.${RESET}"; sleep 1 ;;
    esac
done

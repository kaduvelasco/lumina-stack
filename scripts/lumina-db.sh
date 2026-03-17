#!/bin/bash

# ==============================================================================
# LuminaStack - Gerenciador de Banco de Dados (lumina-db)
# ==============================================================================

# Configurações do Docker
CONTAINER_NAME="mariadb"
DOCKER_BASE_DIR="$HOME/workspace/docker"
CONF_MOODLE_DIR="$DOCKER_BASE_DIR/mariadb/conf.d"
BACKUP_WORKSPACE="$HOME/workspace/backups"

trap "echo -e '\n❌ Operação interrompida pelo usuário.'; exit 1" SIGINT

# Cores para interface
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
RESET='\033[0m'

# -------------------------
# FUNÇÕES AUXILIARES
# -------------------------

verificar_docker() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        echo -e "${VERMELHO}❌ Erro: Container '$CONTAINER_NAME' não está rodando.${RESET}"
        echo "Inicie o ambiente com o comando 'lumina' antes de prosseguir."
        exit 1
    fi
}

selecionar_diretorio() {
    echo -e "${AZUL}===== Selecione o local de destino/origem =====${RESET}"
    echo "1. Downloads ($HOME/Downloads)"
    echo "2. Workspace Backups (Sincronizado Mega) ($BACKUP_WORKSPACE)"
    echo "3. Documentos ($HOME/Documents)"
    read -p "Opção [1-3]: " escolha_dir

    case "$escolha_dir" in
        1) DIR_PATH="$HOME/Downloads" ;;
        2) DIR_PATH="$BACKUP_WORKSPACE" ;;
        *) DIR_PATH="$HOME/Documents" ;;
    esac

    mkdir -p "$DIR_PATH"
}

# -------------------------
# FUNÇÕES DE BANCO
# -------------------------

executar_backup() {
    clear
    verificar_docker
    selecionar_diretorio

    local TIMESTAMP=$(date +"%Y%m%d-%H%M")
    local FILE_NAME="backup_full_${TIMESTAMP}.sql"
    local FULL_PATH="$DIR_PATH/$FILE_NAME"

    echo -e "${AZUL}⚙️ Executando Backup Geral Automático (MariaDB 11)...${RESET}"
    read -p "👤 Usuário MariaDB: " DB_USER
    read -s -p "🔑 Senha MariaDB: " DB_PASS
    echo -e "\n"

    docker exec "$CONTAINER_NAME" mariadb-dump -u "$DB_USER" -p"$DB_PASS" --all-databases > "$FULL_PATH"

    if [ $? -eq 0 ]; then
        echo -e "${VERDE}✅ Backup concluído com sucesso!${RESET}"
        echo -e "📄 Arquivo: ${AMARELO}$FULL_PATH${RESET}"
    else
        echo -e "${VERMELHO}❌ Erro ao realizar o backup.${RESET}"
        [ -f "$FULL_PATH" ] && rm "$FULL_PATH"
    fi

    read -p "Pressione Enter para continuar..."
}

remover_bancos_de_dados() {
    clear
    verificar_docker
    echo -e "${VERMELHO}⚠️ REMOÇÃO DE BANCOS (Cuidado!)${RESET}"
    read -p "👤 Usuário MariaDB: " DB_USER
    read -s -p "🔑 Senha MariaDB: " DB_PASS
    echo -e "\n"

    DBS=$(docker exec "$CONTAINER_NAME" mariadb -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "^(Database|mysql|information_schema|performance_schema|sys)$")

    if [ -z "$DBS" ]; then
        echo "Nenhum banco de dados personalizado encontrado."
    else
        for db in $DBS; do
            read -p "Deseja remover o banco '$db'? (s/N): " resp
            if [[ "$resp" =~ ^[sS]$ ]]; then
                docker exec "$CONTAINER_NAME" mariadb -u "$DB_USER" -p"$DB_PASS" -e "DROP DATABASE \`$db\`;"
                echo "✅ Banco '$db' removido."
            fi
        done
    fi

    read -p "Pressione Enter para continuar..."
}

executar_restore() {
    clear
    verificar_docker
    selecionar_diretorio

    echo -e "${AZUL}⚙️ Executando Restore${RESET}"
    echo "Arquivos SQL disponíveis em $DIR_PATH:"
    ls -1 "$DIR_PATH"/*.sql 2>/dev/null
    echo ""
    read -p "Digite o nome exato do arquivo: " FILE_NAME

    if [ ! -f "$DIR_PATH/$FILE_NAME" ]; then
        echo -e "${VERMELHO}❌ Arquivo não encontrado em $DIR_PATH/$FILE_NAME${RESET}"
    else
        read -p "👤 Usuário MariaDB: " DB_USER
        read -s -p "🔑 Senha MariaDB: " DB_PASS
        echo -e "\n⏳ Restaurando... Isso pode levar alguns minutos."

        docker exec -i "$CONTAINER_NAME" mariadb -u "$DB_USER" -p"$DB_PASS" < "$DIR_PATH/$FILE_NAME"

        if [ $? -eq 0 ]; then
            echo -e "${VERDE}✅ Restore concluído com sucesso!${RESET}"
        else
            echo -e "${VERMELHO}❌ Erro durante o restore.${RESET}"
        fi
    fi

    read -p "Pressione Enter para continuar..."
}

verificar_tabelas() {
    clear
    verificar_docker
    echo -e "${AZUL}🛠️ Verificando e Otimizando Tabelas${RESET}"
    read -p "👤 Usuário MariaDB: " DB_USER
    read -s -p "🔑 Senha MariaDB: " DB_PASS
    echo ""

    docker exec -it "$CONTAINER_NAME" mariadb-check -u "$DB_USER" -p"$DB_PASS" --all-databases --optimize

    read -p "Pressione Enter para continuar..."
}

otimizar_mariadb_moodle() {
    clear
    echo -e "${AZUL}⚡ Otimizando MariaDB para Moodle (Docker Mode)${RESET}"

    # Perguntar RAM instalada
    echo -e "${AMARELO}Quanto de RAM este computador possui no total (em GB)?${RESET}"
    read -p "Ex: 12: " TOTAL_RAM_GB

    # Converter para MB para cálculos
    TOTAL_RAM_MB=$((TOTAL_RAM_GB * 1024))

    echo -e "\n${AZUL}Quanto desta RAM você deseja dedicar ao Buffer Pool do MariaDB?${RESET}"
    echo "1. 1/2 da RAM (Ideal para DB dedicado)"
    echo "2. 1/3 da RAM (Equilibrado - Recomendado)"
    echo "3. 1/4 da RAM (Econômico)"
    read -p "Opção: " escolha_ram

    case "$escolha_ram" in
        1) BUFFER_POOL_MB=$((TOTAL_RAM_MB / 2)) ;;
        2) BUFFER_POOL_MB=$((TOTAL_RAM_MB / 3)) ;;
        3) BUFFER_POOL_MB=$((TOTAL_RAM_MB / 4)) ;;
        *) echo "Opção inválida. Usando 1/3."; BUFFER_POOL_MB=$((TOTAL_RAM_MB / 3)) ;;
    esac

    echo -e "\n${VERDE}📦 Configurando innodb_buffer_pool_size para: ${BUFFER_POOL_MB}MB${RESET}"

    mkdir -p "$CONF_MOODLE_DIR"

    cat <<EOF > "$CONF_MOODLE_DIR/moodle-performance.cnf"
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

    echo -e "${AMARELO}🔄 Reiniciando container para carregar novas configurações...${RESET}"
    docker restart "$CONTAINER_NAME"

    echo -e "${VERDE}✅ Configurações aplicadas com sucesso.${RESET}"
    read -p "Pressione Enter para continuar..."
}

# -------------------------
# MENU PRINCIPAL
# -------------------------

exibir_menu() {
    clear
    echo -e "${AZUL}✨ LUMINA-DB :: GESTÃO DE DADOS${RESET}"
    echo "1. 📤 Backup (dump)"
    echo "2. 🧹 Remover Bancos"
    echo "3. 📥 Restaurar (restore)"
    echo "4. 🛠️ Verificar/Otimizar Tabelas"
    echo "5. ⚡ Otimizar MariaDB para Moodle"
    echo "0. 🚪 Sair"
}

while true; do
    exibir_menu
    read -p "Opção: " escolha
    case "$escolha" in
        1) executar_backup ;;
        2) remover_bancos_de_dados ;;
        3) executar_restore ;;
        4) verificar_tabelas ;;
        5) otimizar_mariadb_moodle ;;
        0) exit 0 ;;
        *) echo -e "${VERMELHO}Opção inválida${RESET}"; sleep 1 ;;
    esac
done

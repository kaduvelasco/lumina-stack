#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Gerador de Stack Docker
# ==============================================================================
# Descrição   : Valida versões PHP e credenciais do banco, gera o
#               docker-compose.yml a partir dos templates e configura
#               o roteamento local via update_hosts.
# Dependências: lib/colors.sh, lib/system.sh (carregados via install.sh)
#               openssl, docker, pasta templates/
# Uso         : source lib/docker.sh  (carregado automaticamente pelo install.sh)
# Versão      : 2.0.0
# ==============================================================================

validate_php_versions() {
    local versions="$1"
    local supported_versions="7.4 8.0 8.1 8.2 8.3 8.4"
    for v in $versions; do
        local pattern=" $v "
        if [[ ! " $supported_versions " =~ $pattern ]]; then
            echo -e "${VERMELHO}❌ Versão PHP '$v' não é suportada.${RESET}"
            echo -e "   Disponíveis: ${AMARELO}$supported_versions${RESET}"
            return 1
        fi
    done
    return 0
}

validate_db_credentials() {
    local user="$1" pass="$2"
    if [[ -z "$user" ]]; then
        echo -e "${VERMELHO}❌ O nome de usuário não pode ser vazio.${RESET}"
        return 1
    fi
    if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo -e "${VERMELHO}❌ O usuário '$user' contém caracteres inválidos. Use apenas letras, números e _.${RESET}"
        return 1
    fi
    if [[ ${#pass} -lt 8 ]]; then
        echo -e "${VERMELHO}❌ A senha deve ter pelo menos 8 caracteres.${RESET}"
        return 1
    fi
    return 0
}

generate_secure_password() {
    openssl rand -base64 16 | tr -d "=+/" | cut -c1-16
}

generate_docker_stack() {
    local WORKSPACE="$HOME/workspace"
    local DOCKER_DIR="$WORKSPACE/docker"
    local TEMPLATE_DIR
    TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)"

    if [[ ! -d "$WORKSPACE" ]]; then
        echo -e "${VERMELHO}❌ Workspace não encontrado. Execute a ${AMARELO}opção 3${RESET}${VERMELHO} primeiro.${RESET}"
        return 1
    fi

    echo -e "\n${AZUL}🛠️  Gerando Stack Docker Lumina...${RESET}"

    # Cria pastas necessárias
    mkdir -p "$DOCKER_DIR"/{nginx,php,php-config,php-base,mariadb/init,mariadb/conf.d}

    # --- Versões do PHP ---
    while true; do
        read -r -p "Versões do PHP (ex: 7.4 8.1 8.2): " PHP_VERSIONS
        [[ -n "$PHP_VERSIONS" ]] && validate_php_versions "$PHP_VERSIONS" && break
        [[ -z "$PHP_VERSIONS" ]] && echo -e "${VERMELHO}❌ Informe ao menos uma versão.${RESET}"
    done

    # --- Credenciais do banco ---
    while true; do
        read -r -p "Usuário do banco [admin]: " DB_USER
        DB_USER=${DB_USER:-admin}

        read -r -s -p "Senha do banco (Enter para gerar automaticamente): " DB_PASS
        echo ""

        if [[ -z "$DB_PASS" ]]; then
            DB_PASS=$(generate_secure_password)
            echo -e "   ${AMARELO}🔐 Senha gerada: $DB_PASS${RESET}"
        fi

        validate_db_credentials "$DB_USER" "$DB_PASS" && break
    done

    # --- Senha root do banco (sempre gerada automaticamente) ---
    local DB_ROOT_PASSWORD
    DB_ROOT_PASSWORD=$(generate_secure_password)
    echo -e "   ${AMARELO}🔐 Senha root gerada: $DB_ROOT_PASSWORD${RESET}"

    # --- Script de permissões MariaDB ---
cat > "$DOCKER_DIR/mariadb/init/01-permissions.sql" << EOF
-- Atualiza o host do usuário criado pelas variáveis de ambiente (localhost → %)
-- Isso permite conexões externas ao container (ex: DBeaver, phpMyAdmin)
RENAME USER '$DB_USER'@'localhost' TO '$DB_USER'@'%';
GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

    # --- Gera os serviços PHP para o docker-compose ---
    local PHP_SERVICES=""
    local FIRST_VERSION=""

    for v in $PHP_VERSIONS; do
        local NAME="php${v//./}"
        [[ -z "$FIRST_VERSION" ]] && FIRST_VERSION="$NAME"
        mkdir -p "$WORKSPACE/logs/$NAME"

        PHP_SERVICES="$PHP_SERVICES
  $NAME:
    container_name: $NAME
    build:
      context: .
      dockerfile: php/Dockerfile
      args:
        PHP_VERSION: $v
    restart: unless-stopped
    volumes:
      - ../www/html:/var/www/html
      - ../www/data:/var/www/data
      - ../logs/$NAME:/var/log/php
      - ./php-config/php.ini:/usr/local/etc/php/php.ini
    environment:
      - XDEBUG_MODE=off
    healthcheck:
      test: [\"CMD\", \"php\", \"-v\"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - docker-php-network
"
    done

    # --- Gera o docker-compose.yml substituindo os dois placeholders ---
    awk -v php_services="$PHP_SERVICES" -v default_php="$FIRST_VERSION" '{
        if ($0 ~ /{{PHP_SERVICES}}/)  { print php_services }
        else if ($0 ~ /{{DEFAULT_PHP}}/) { gsub(/{{DEFAULT_PHP}}/, default_php); print }
        else { print }
    }' "$TEMPLATE_DIR/docker-compose.tpl" > "$DOCKER_DIR/docker-compose.yml"

    # --- Copia os templates restantes ---
    cp "$TEMPLATE_DIR/nginx.conf.tpl"          "$DOCKER_DIR/nginx/default.conf"
    cp "$TEMPLATE_DIR/php.Dockerfile.tpl"      "$DOCKER_DIR/php/Dockerfile"
    cp "$TEMPLATE_DIR/php.ini.tpl"             "$DOCKER_DIR/php-config/php.ini"
    cp "$TEMPLATE_DIR/php-base.Dockerfile.tpl" "$DOCKER_DIR/php-base/Dockerfile"

    # Substitui os placeholders no nginx.conf gerado:
    # {{DEFAULT_PHP}}     → ex: php81  (nome completo do container)
    # {{DEFAULT_PHP_VER}} → ex: 81     (apenas o número, usado no fallback do regex)
    local FIRST_VER_NUM="${FIRST_VERSION#php}"
    sed -i \
        -e "s/{{DEFAULT_PHP}}/$FIRST_VERSION/g" \
        -e "s/{{DEFAULT_PHP_VER}}/$FIRST_VER_NUM/g" \
        "$DOCKER_DIR/nginx/default.conf"

    # --- Gera o .env com permissão restrita ---
    cat > "$DOCKER_DIR/.env" << EOF
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD
PHP_VERSIONS=$PHP_VERSIONS
EOF
    chmod 600 "$DOCKER_DIR/.env"

    # --- Atualiza o /etc/hosts ---
    export PHP_VERSIONS
    update_hosts

    echo -e "\n${VERDE}✅ Stack criada em: ${AMARELO}$DOCKER_DIR${RESET}"
    echo -e "   ${AZUL}Versões PHP   :${RESET} $PHP_VERSIONS"
    echo -e "   ${AZUL}PHP padrão    :${RESET} $FIRST_VERSION (usado em localhost)"
    echo -e "   ${AZUL}Usuário DB    :${RESET} $DB_USER"
    echo -e "   ${AZUL}Credenciais   :${RESET} $DOCKER_DIR/.env ${AMARELO}(chmod 600)${RESET}"

    echo -e "\n${AMARELO}🔨 Construindo imagem base PHP...${RESET}"
    docker build -t php-base "$DOCKER_DIR/php-base"
    echo -e "${VERDE}✅ Imagem base construída com sucesso.${RESET}"
}

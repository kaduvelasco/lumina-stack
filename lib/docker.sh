#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Gerador de Stack Docker (docker.sh)
# ==============================================================================

validate_php_versions() {
    local versions="$1"
    local supported_versions="7.4 8.0 8.1 8.2 8.3 8.4"
    for v in $versions; do
        if [[ ! " $supported_versions " =~ " $v " ]]; then
            echo "❌ Versão PHP $v não é suportada. Disponíveis: $supported_versions"
            return 1
        fi
    done
    return 0
}

validate_db_credentials() {
    local user="$1" pass="$2"
    [[ -z "$user" ]] && return 1
    [[ ${#pass} -lt 8 ]] && return 1
    return 0
}

generate_secure_password() {
    openssl rand -base64 16 | tr -d "=+/" | cut -c1-16
}

generate_docker_stack() {
    WORKSPACE="$HOME/workspace"
    DOCKER_DIR="$WORKSPACE/docker"
    # Ajuste para garantir que o caminho do template seja achado independente de onde o script é chamado
    TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)"

    if [[ ! -d "$WORKSPACE" ]]; then
        echo "❌ Workspace não encontrado. Execute a ${AMARELO}opção 3${RESET} primeiro."
        return 1
    fi

    echo -e "\n${AZUL}🛠️ Gerando Stack Docker Lumina...${RESET}"

    # Criando pastas necessárias (incluindo as novas para MariaDB)
    mkdir -p "$DOCKER_DIR"/{nginx,php,php-config,php-base,mariadb/init,mariadb/conf.d}

    while true; do
        read -p "Versões do PHP (ex: 7.4 8.1 8.2): " PHP_VERSIONS
        validate_php_versions "$PHP_VERSIONS" && break
    done

    while true; do
        read -p "Usuário do banco (admin): " DB_USER
        DB_USER=${DB_USER:-admin}
        read -s -p "Senha do banco (Enter para gerar): " DB_PASS
        echo ""
        [[ -z "$DB_PASS" ]] && DB_PASS=$(generate_secure_password) && echo "🔐 Senha: $DB_PASS"
        validate_db_credentials "$DB_USER" "$DB_PASS" && break
    done

    # --- CORREÇÃO: Geração do Script de Permissões MariaDB ---
    # Removi a indentação interna para evitar erros de sintaxe no SQL
cat > "$DOCKER_DIR/mariadb/init/01-permissions.sql" << EOF
GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

    PHP_SERVICES=""
    for v in $PHP_VERSIONS; do
        NAME="php${v//./}"
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

    # Gera o docker-compose.yml
    awk -v php_services="$PHP_SERVICES" '{
        if ($0 ~ /{{PHP_SERVICES}}/) { print php_services } else { print }
    }' "$TEMPLATE_DIR/docker-compose.tpl" > "$DOCKER_DIR/docker-compose.yml"

    # Copia templates (Certifique-se que o nginx.conf.tpl já tem os 2 blocos server)
    cp "$TEMPLATE_DIR/nginx.conf.tpl" "$DOCKER_DIR/nginx/default.conf"
    cp "$TEMPLATE_DIR/php.Dockerfile.tpl" "$DOCKER_DIR/php/Dockerfile"
    cp "$TEMPLATE_DIR/php.ini.tpl" "$DOCKER_DIR/php-config/php.ini"
    cp "$TEMPLATE_DIR/php-base.Dockerfile.tpl" "$DOCKER_DIR/php-base/Dockerfile"

    cat > "$DOCKER_DIR/.env" << EOF
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_ROOT_PASSWORD=root
PHP_VERSIONS=$PHP_VERSIONS
EOF

    # Exporta a variável para o update_hosts enxergar
    export PHP_VERSIONS
    update_hosts

    echo "✅ Stack criada em $DOCKER_DIR"
    echo "Construindo imagem base..."
    docker build -t php-base "$DOCKER_DIR/php-base"
}

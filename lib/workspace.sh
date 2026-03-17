#!/usr/bin/env bash

create_workspace() {
    WORKSPACE="$HOME/workspace"
    # Localiza a pasta de templates baseada na estrutura do seu projeto
    # Assume-se: /projeto/lib/workspace.sh e /projeto/templates/
    TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)"

    echo "📂 Criando estrutura de workspace em $WORKSPACE..."

    # 1. Cria diretórios principais
    mkdir -p "$WORKSPACE"/{www/html,www/data,databases/mariadb,logs/nginx,docker,docker/mariadb/conf.d,backups}

    # Pasta específica para o mydb guardar e buscar backups .sql
    mkdir -p "$WORKSPACE/backups"

    # 2. Cria pastas de logs dinâmicas para o PHP
    # Se PHP_VERSIONS estiver vazio (Opção 3 rodada antes da 4), cria as padrão
    local VERSIONS=${PHP_VERSIONS:-"7.4 8.1 8.2 8.3 8.4"}
    for v in $VERSIONS; do
        V_CLEAN="php${v/./}"
        mkdir -p "$WORKSPACE/logs/$V_CLEAN"
    done

    # 3. Instala os arquivos de interface a partir dos templates
    echo "📄 Instalando templates de interface..."
    if [[ -d "$TEMPLATE_DIR" ]]; then
        cp "$TEMPLATE_DIR/info.php.tpl" "$WORKSPACE/www/html/info.php"
        cp "$TEMPLATE_DIR/index.php.tpl" "$WORKSPACE/www/html/index.php"
        echo "✅ index.php e info.php instalados."
    else
        echo "⚠️ Erro: Pasta de templates não encontrada em $TEMPLATE_DIR"
    fi

    # 4. Ajusta permissões
    # Garante que o usuário e o container consigam manipular os arquivos
    chmod -R 755 "$WORKSPACE/www"

    # Garante permissão na pasta de configuração do MariaDB para o script de otimização
    chmod -R 775 "$WORKSPACE/docker/mariadb"

    echo ""
    echo "✅ Estrutura finalizada em: $WORKSPACE"
    echo "    - Web: $WORKSPACE/www/html"
    echo "    - Backups SQL: $WORKSPACE/backups"
    echo "    - Configs MariaDB: $WORKSPACE/docker/mariadb/conf.d"
    echo "   Dica: Seus projetos devem ficar em $WORKSPACE/www/html"
    echo ""
}

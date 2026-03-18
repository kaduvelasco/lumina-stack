#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Criação do Workspace
# ==============================================================================
# Descrição   : Cria a estrutura de diretórios do workspace, instala os
#               arquivos de interface a partir dos templates e ajusta as
#               permissões iniciais.
# Dependências: lib/colors.sh (carregado via install.sh), pasta templates/
# Uso         : source lib/workspace.sh  (carregado automaticamente pelo install.sh)
# Versão      : 2.0.0
# ==============================================================================

create_workspace() {
    local WORKSPACE="$HOME/workspace"
    local TEMPLATE_DIR
    TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)"

    echo -e "\n${AZUL}📂 Criando estrutura de workspace em $WORKSPACE...${RESET}"

    # 1. Cria diretórios principais
    mkdir -p "$WORKSPACE"/{www/html,www/data,databases/mariadb,logs/nginx,docker,docker/mariadb/conf.d,backups}

    # 2. Cria pastas de logs dinâmicas para o PHP
    # Se PHP_VERSIONS estiver vazio (opção 3 executada antes da 4), cria as versões padrão
    local VERSIONS=${PHP_VERSIONS:-"7.4 8.1 8.2 8.3 8.4"}
    for v in $VERSIONS; do
        local V_CLEAN="php${v/./}"
        mkdir -p "$WORKSPACE/logs/$V_CLEAN"
    done

    # 3. Instala os arquivos de interface a partir dos templates
    echo -e "${AZUL}📄 Instalando templates de interface...${RESET}"
    if [[ -d "$TEMPLATE_DIR" ]]; then
        cp "$TEMPLATE_DIR/info.php.tpl" "$WORKSPACE/www/html/info.php"
        cp "$TEMPLATE_DIR/index.php.tpl" "$WORKSPACE/www/html/index.php"
        echo -e "${VERDE}✅ index.php e info.php instalados.${RESET}"
    else
        echo -e "${VERMELHO}❌ Erro: Pasta de templates não encontrada em $TEMPLATE_DIR${RESET}"
        return 1
    fi

    # 4. Ajusta permissões iniciais
    # 755: usuário e container conseguem ler/executar; escrita apenas pelo dono
    chmod -R 755 "$WORKSPACE/www"

    # 775: necessário para o lumina-db gravar o moodle-performance.cnf
    chmod -R 775 "$WORKSPACE/docker/mariadb"

    # 5. Resumo final
    echo -e ""
    echo -e "${VERDE}✅ Workspace criado com sucesso em: ${AMARELO}$WORKSPACE${RESET}"
    echo -e "   ${AZUL}Projetos PHP  :${RESET} $WORKSPACE/www/html"
    echo -e "   ${AZUL}Backups SQL   :${RESET} $WORKSPACE/backups  ${AMARELO}(sincronizado via MegaSync)${RESET}"
    echo -e "   ${AZUL}Dados Moodle  :${RESET} $WORKSPACE/www/data  ${AMARELO}(sincronizado via MegaSync)${RESET}"
    echo -e "   ${AZUL}Config MariaDB:${RESET} $WORKSPACE/docker/mariadb/conf.d"
    echo -e ""
    echo -e "   ${AMARELO}💡 Dica: Use a opção 4 para gerar a stack Docker antes de iniciar o ambiente.${RESET}"
    echo -e ""
}

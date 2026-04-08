#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Versões Suportadas
# ==============================================================================
# Descrição   : Fonte única de verdade para versões de todos os componentes.
#               Alterar aqui reflete em todo o projeto automaticamente.
# Uso         : source lib/versions.sh  (carregado automaticamente pelo install.sh)
# Versão      : 2.0.0
# ==============================================================================

export SUPPORTED_PHP_VERSIONS="7.4 8.0 8.1 8.2 8.3 8.4"
export NGINX_IMAGE="nginx:1.26-alpine"
export MARIADB_IMAGE="mariadb:11.4"

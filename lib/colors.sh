#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Paleta de Cores
# ==============================================================================
# Descrição   : Define as variáveis de cor ANSI usadas em toda a lib/.
#               Os scripts instalados em /usr/local/bin (lumina, lumina-db)
#               definem suas próprias cores localmente por serem independentes.
# Dependências: nenhuma
# Uso         : source lib/colors.sh  (carregado automaticamente pelo install.sh)
# Versão      : 2.0.0
# ==============================================================================

# export: variáveis compartilhadas via source com os demais scripts da lib/
export VERDE='\033[0;32m'
export AMARELO='\033[1;33m'
export VERMELHO='\033[0;31m'
export AZUL='\033[0;34m'
export RESET='\033[0m'

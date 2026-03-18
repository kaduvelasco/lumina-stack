#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Limpeza do Ambiente Docker
# ==============================================================================
# Descrição   : Remove todos os containers, imagens, volumes e networks do
#               Docker. Use para resetar completamente o ambiente.
# Dependências: docker
# Uso         : ./clean-docker.sh  (executado manualmente quando necessário)
# Versão      : 2.0.0
# ==============================================================================

# Cores (definidas localmente — este script é executado de forma independente)
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
RESET='\033[0m'

# ==============================================================================
# CONFIRMAÇÃO DE SEGURANÇA
# ==============================================================================

echo -e "\n${VERMELHO}⚠️  ATENÇÃO — Esta operação irá remover:${RESET}"
echo -e "   • Todos os containers (rodando ou parados)"
echo -e "   • Todas as imagens Docker"
echo -e "   • Todos os volumes não utilizados"
echo -e "   • Todas as networks não utilizadas"
echo -e "   • ~/workspace/databases/  (dados binários do MariaDB)"
echo -e "   • ~/workspace/docker/     (docker-compose.yml, .env e configs)"
echo -e "\n${VERDE}   Os seguintes dados do usuário NÃO serão apagados:${RESET}"
echo -e "   ✅ ~/workspace/www/html    (seus projetos PHP)"
echo -e "   ✅ ~/workspace/www/data    (moodledata)"
echo -e "   ✅ ~/workspace/backups/    (dumps SQL)"
echo -e "\n${AMARELO}   Após a limpeza, execute ./install.sh e siga as opções 3 → 4 → 5 → 6.${RESET}\n"

read -r -p "Tem certeza que deseja continuar? (s/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
    echo -e "\n${VERDE}Operação cancelada.${RESET}\n"
    exit 0
fi

echo -e "\n${AZUL}🧹 Iniciando limpeza do Docker...${RESET}\n"

# ==============================================================================
# LIMPEZA
# ==============================================================================

echo -e "${AMARELO}⏹️  Parando containers em execução...${RESET}"
mapfile -t CONTAINERS < <(docker ps -aq)
if [ ${#CONTAINERS[@]} -gt 0 ]; then
    docker stop "${CONTAINERS[@]}" 2>/dev/null
    echo -e "${VERDE}✅ Containers parados.${RESET}"
else
    echo -e "   Nenhum container em execução."
fi

echo -e "\n${AMARELO}🗑️  Removendo containers...${RESET}"
if [ ${#CONTAINERS[@]} -gt 0 ]; then
    docker rm "${CONTAINERS[@]}" 2>/dev/null
    echo -e "${VERDE}✅ Containers removidos.${RESET}"
else
    echo -e "   Nenhum container para remover."
fi

echo -e "\n${AMARELO}🗑️  Removendo imagens...${RESET}"
mapfile -t IMAGES < <(docker images -q)
if [ ${#IMAGES[@]} -gt 0 ]; then
    docker rmi "${IMAGES[@]}" -f 2>/dev/null
    echo -e "${VERDE}✅ Imagens removidas.${RESET}"
else
    echo -e "   Nenhuma imagem para remover."
fi

echo -e "\n${AMARELO}🗑️  Removendo volumes não utilizados...${RESET}"
docker volume prune -f 2>/dev/null
echo -e "${VERDE}✅ Volumes limpos.${RESET}"

echo -e "\n${AMARELO}🗑️  Removendo networks não utilizadas...${RESET}"
docker network prune -f 2>/dev/null
echo -e "${VERDE}✅ Networks limpas.${RESET}"

echo -e "\n${AMARELO}🗑️  Removendo dados binários do banco...${RESET}"
if [ -d "$HOME/workspace/databases" ]; then
    rm -rf "$HOME/workspace/databases"
    echo -e "${VERDE}✅ ~/workspace/databases/ removido.${RESET}"
else
    echo -e "   Pasta não encontrada, nada a remover."
fi

echo -e "\n${AMARELO}🗑️  Removendo configurações da stack...${RESET}"
if [ -d "$HOME/workspace/docker" ]; then
    rm -rf "$HOME/workspace/docker"
    echo -e "${VERDE}✅ ~/workspace/docker/ removido.${RESET}"
else
    echo -e "   Pasta não encontrada, nada a remover."
fi

# ==============================================================================
# RESUMO
# ==============================================================================

echo -e "\n${VERDE}✅ Limpeza concluída com sucesso!${RESET}"
echo -e "${AZUL}──────────────────────────────────────────────────${RESET}"
echo -e "   Para recriar o ambiente, execute ${AMARELO}./install.sh${RESET}"
echo -e "   e siga as opções ${AMARELO}3 → 4 → 5 → 6${RESET} do menu."
echo -e "${AZUL}──────────────────────────────────────────────────${RESET}\n"

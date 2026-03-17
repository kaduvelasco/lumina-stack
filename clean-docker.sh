#!/bin/bash

echo "Parando todos os containers..."

docker stop $(docker ps -aq) 2>/dev/null

echo "Removendo todos os containers..."

docker rm $(docker ps -aq) 2>/dev/null

echo "Removendo todas as imagens..."

docker rmi $(docker images -q) -f 2>/dev/null

echo "Removendo volumes não utilizados..."

docker volume prune -f

echo "Removendo networks não utilizadas..."

docker network prune -f

echo "Limpeza concluída."

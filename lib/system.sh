#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Sistema e Ambiente
# ==============================================================================
# Descrição   : Detecta a distribuição Linux, instala pré-requisitos, instala
#               o Docker e gerencia o roteamento local via /etc/hosts.
# Dependências: lib/colors.sh (carregado via install.sh)
# Uso         : source lib/system.sh  (carregado automaticamente pelo install.sh)
# Versão      : 2.0.0
# ==============================================================================

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        return 0
    fi
    echo -e "${VERMELHO}❌ Não foi possível detectar a distribuição.${RESET}"
    return 1
}

install_prereqs() {
    echo -e "\n${AZUL}🚀 Verificando e instalando pré-requisitos...${RESET}"
    detect_distro || return 1

    case "$DISTRO" in
        ubuntu|linuxmint|pop|debian)
            sudo apt update
            sudo apt install -y curl git openssl lsof
            ;;
        fedora)
            sudo dnf install -y curl git openssl lsof
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm curl git openssl lsof
            ;;
        *)
            echo -e "${AMARELO}⚠️  Distribuição '$DISTRO' pode não ser totalmente suportada.${RESET}"
            ;;
    esac

    echo -e "${VERDE}✅ Pré-requisitos verificados.${RESET}"
}

install_docker() {
    echo -e "\n${AZUL}🐳 Verificando Docker...${RESET}"
    detect_distro || return 1

    if command -v docker >/dev/null 2>&1; then
        echo -e "${VERDE}✅ Docker já está instalado.${RESET}"
    else
        echo -e "${AMARELO}📦 Instalando Docker para '$DISTRO'...${RESET}"

        case "$DISTRO" in
            arch|manjaro)
                sudo pacman -S --noconfirm docker docker-compose
                sudo systemctl enable --now docker
                ;;
            *)
                # Script oficial funciona bem em Ubuntu, Debian e Fedora
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo systemctl enable --now docker
                rm get-docker.sh
                ;;
        esac
    fi

    # Adiciona usuário ao grupo docker se necessário
    if ! groups "$USER" | grep -q "\bdocker\b"; then
        echo -e "${AMARELO}👤 Adicionando $USER ao grupo docker...${RESET}"
        sudo usermod -aG docker "$USER"
        echo -e "${AMARELO}⚠️  Você precisará reiniciar a sessão para aplicar as permissões do grupo docker.${RESET}"
    fi

    # Aviso específico para Fedora: SELinux pode bloquear volumes Docker
    if [[ "$DISTRO" == "fedora" ]]; then
        echo -e "\n${AMARELO}⚠️  Fedora detectado: se os containers não conseguirem ler/escrever nos volumes,"
        echo -e "    verifique se o SELinux está bloqueando o acesso. Solução:"
        echo -e "    sudo setsebool -P container_manage_cgroup on"
        echo -e "    Ou adicione ':z' ao final dos volumes no docker-compose.yml.${RESET}"
    fi

    # Verifica se a porta 80 está em uso antes de finalizar
    check_port_80

    echo -e "${VERDE}✅ Docker configurado com sucesso.${RESET}"
}

update_hosts() {
    echo -e "\n${AZUL}📝 Atualizando /etc/hosts para roteamento local...${RESET}"

    local VERSIONS=${PHP_VERSIONS:-"7.4 8.1 8.2 8.3 8.4"}
    local HOSTS_LINE="127.0.0.1"

    for v in $VERSIONS; do
        V_CLEAN=${v/./}
        HOSTS_LINE="$HOSTS_LINE php$V_CLEAN.localhost"
    done

    # Remove apenas entradas anteriores do LuminaStack (cirúrgico)
    sudo sed -i '/# lumina-stack/d' /etc/hosts

    # Adiciona a nova entrada identificada com comentário
    echo "$HOSTS_LINE # lumina-stack" | sudo tee -a /etc/hosts > /dev/null

    echo -e "${VERDE}✅ Arquivo /etc/hosts atualizado.${RESET}"
}

check_port_80() {
    if sudo lsof -i :80 > /dev/null 2>&1; then
        echo -e "\n${AMARELO}⚠️  Aviso: A porta 80 já está em uso por outro processo:${RESET}"
        sudo lsof -i :80
        echo -e "${AMARELO}    Solução: sudo systemctl stop apache2  ou  sudo systemctl stop nginx${RESET}"
        return 1
    fi
    return 0
}

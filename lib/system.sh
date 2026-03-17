#!/usr/bin/env bash

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        return 0
    fi
    echo "❌ Não foi possível detectar a distribuição."
    return 1
}

install_prereqs() {
    echo "🚀 Verificando e instalando pré-requisitos..."
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
            echo "⚠️ Distribuição $DISTRO pode não ser totalmente suportada."
            ;;
    esac
}

install_docker() {
    echo "🐳 Verificando Docker..."

    if command -v docker >/dev/null 2>&1; then
        echo "✅ Docker já está instalado."
    else
        echo "📦 Instalando Docker para $DISTRO..."
        detect_distro

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
    if ! groups $USER | grep -q "\bdocker\b"; then
        echo "👤 Adicionando $USER ao grupo docker..."
        sudo usermod -aG docker $USER
        echo "⚠️ Você precisará reiniciar a sessão para aplicar as permissões do grupo docker."
    fi
}

update_hosts() {
    echo "📝 Atualizando /etc/hosts para roteamento local..."

    # Pega as versões do .env ou da variável global
    local VERSIONS=${PHP_VERSIONS:-"7.4 8.1 8.2 8.3 8.4"}
    local HOSTS_LINE="127.0.0.1"

    for v in $VERSIONS; do
        V_CLEAN=${v/./}
        HOSTS_LINE="$HOSTS_LINE php$V_CLEAN.localhost"
    done

    # Remove entradas antigas para evitar duplicidade e adiciona a nova
    # Procura por qualquer entrada que contenha '.localhost' e limpa
    sudo sed -i '/\.localhost/d' /etc/hosts

    echo "$HOSTS_LINE" | sudo tee -a /etc/hosts > /dev/null
    echo "✅ Arquivo /etc/hosts atualizado."
}

check_port_80() {
    if sudo lsof -i :80 > /dev/null 2>&1; then
        echo "⚠️ Aviso: A porta 80 já está em uso por outro processo."
        sudo lsof -i :80
        return 1
    fi
    return 0
}

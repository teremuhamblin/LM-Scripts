#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - install_core.sh
# Installe les paquets de base pour Linux Mint

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; RESET="\e[0m"

info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté en root (sudo)."
        exit 1
    fi
}

install_core_packages() {
    local packages=(
        curl
        wget
        git
        htop
        vim
        neofetch
    )

    info "Mise à jour de la liste des paquets..."
    apt update -y

    info "Installation des paquets de base..."
    apt install -y "${packages[@]}"

    info "Installation terminée."
}

require_root
install_core_packages

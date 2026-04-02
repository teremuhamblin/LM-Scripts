#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - install_devtools.sh
# Installe des outils de développement

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté en root (sudo)."
        exit 1
    fi
}

install_devtools() {
    local packages=(
        build-essential
        git
        python3
        python3-pip
        shellcheck
    )

    info "Installation des outils de développement..."
    apt update -y
    apt install -y "${packages[@]}"

    info "Outils de développement installés."
}

require_root
install_devtools

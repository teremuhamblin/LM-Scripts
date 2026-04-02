#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - install_drivers.sh
# Gère l'installation des pilotes via les outils Mint

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

install_drivers() {
    info "Ouverture de l'outil de gestion des pilotes (mintdrivers)..."
    if command -v mintdrivers >/dev/null 2>&1; then
        mintdrivers
    else
        warn "mintdrivers n'est pas disponible sur ce système."
    fi
}

require_root
install_drivers

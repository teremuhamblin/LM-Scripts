#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - update_system.sh
# Met à jour le système Linux Mint

GREEN="\e[32m"; RED="\e[31m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté en root (sudo)."
        exit 1
    fi
}

update_system() {
    info "Mise à jour de la liste des paquets..."
    apt update -y

    info "Mise à niveau des paquets..."
    apt upgrade -y

    info "Nettoyage..."
    apt autoremove -y
    apt autoclean -y

    info "Mise à jour terminée."
}

require_root
update_system

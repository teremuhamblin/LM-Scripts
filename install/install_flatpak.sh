#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - install_flatpak.sh
# Active Flatpak et ajoute Flathub

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté en root (sudo)."
        exit 1
    fi
}

setup_flatpak() {
    info "Installation de Flatpak..."
    apt update -y
    apt install -y flatpak

    info "Ajout du dépôt Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    info "Flatpak est configuré avec Flathub."
}

require_root
setup_flatpak

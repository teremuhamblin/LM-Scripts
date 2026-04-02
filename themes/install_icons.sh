#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - install_icons.sh
# Installe des packs d'icônes (exemple générique, à adapter)

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

install_icons() {
    local icons_dir="$HOME/.icons"
    mkdir -p "$icons_dir"

    info "Ce script est un exemple. Ajoute ici le téléchargement et l'installation de tes packs d'icônes."
    info "Dossier des icônes : $icons_dir"
}

install_icons

#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - install_themes.sh
# Installe des thèmes (exemple générique, à adapter)

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

install_themes() {
    local themes_dir="$HOME/.themes"
    mkdir -p "$themes_dir"

    info "Ce script est un exemple. Ajoute ici le téléchargement et l'installation de tes thèmes favoris."
    info "Dossier des thèmes : $themes_dir"
}

install_themes

#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - backup_home.sh
# Sauvegarde simple du dossier HOME vers un fichier tar.gz

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

backup_home() {
    local dest_dir="${1:-$HOME/Backups}"
    mkdir -p "$dest_dir"

    local date_str
    date_str="$(date +%Y%m%d_%H%M)"
    local archive="${dest_dir}/home_backup_${date_str}.tar.gz"

    info "Création de la sauvegarde de $HOME vers $archive"
    tar -czf "$archive" "$HOME" \
        --exclude="$HOME/Backups" \
        --exclude="$HOME/.cache" \
        --exclude="$HOME/.local/share/Trash"

    info "Sauvegarde terminée."
}

backup_home "$@"

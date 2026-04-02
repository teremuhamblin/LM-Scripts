#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - check_internet.sh
# Vérifie la connectivité Internet

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

check_internet() {
    local host="8.8.8.8"

    info "Test de connectivité vers $host..."
    if ping -c 2 "$host" >/dev/null 2>&1; then
        info "Connexion Internet OK."
    else
        warn "Pas de réponse de $host. Vérifiez votre connexion."
    fi
}

check_internet

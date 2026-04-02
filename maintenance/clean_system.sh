#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - clean_system.sh
# Nettoyage simple du système

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

clean_system() {
    info "Suppression des paquets inutilisés..."
    apt autoremove -y

    info "Nettoyage du cache APT..."
    apt autoclean -y

    info "Nettoyage du cache utilisateur (~/.cache)..."
    rm -rf "${HOME}/.cache/"* || warn "Impossible de nettoyer ~/.cache (droits ?)"

    info "Nettoyage terminé."
}

require_root
clean_system

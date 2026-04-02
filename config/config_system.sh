#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - config_system.sh
# Applique quelques réglages système généraux

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté en root (sudo)."
        exit 1
    fi
}

tune_system() {
    info "Activation des mises à jour automatiques de sécurité (unattended-upgrades)..."
    apt install -y unattended-upgrades
    dpkg-reconfigure -plow unattended-upgrades || warn "Configuration unattended-upgrades à vérifier manuellement."

    info "Nettoyage des paquets orphelins..."
    apt autoremove -y
}

require_root
tune_system

#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - config_cinnamon.sh
# Applique quelques réglages Cinnamon via gsettings

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

check_cinnamon() {
    if ! echo "$XDG_CURRENT_DESKTOP" | grep -qi "cinnamon"; then
        warn "Cinnamon ne semble pas être l'environnement actuel."
    fi
}

apply_settings() {
    info "Activation de l'affichage des secondes dans l'horloge..."
    gsettings set org.cinnamon.desktop.interface clock-show-seconds true || warn "Impossible de modifier l'horloge."

    info "Réduction du délai d'affichage des notifications..."
    gsettings set org.cinnamon.desktop.notifications display-timeout 4000 || warn "Impossible de modifier les notifications."
}

check_cinnamon
apply_settings

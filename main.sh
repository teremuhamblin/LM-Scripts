#!/usr/bin/env bash
set -euo pipefail

#############################################
# LM-Scripts — Script principal interactif
# Auteur : The MadDoG.tmdg 
# Version : 1.0.0
# Description :
#   Menu interactif permettant d'exécuter
#   tous les scripts du projet LM-Scripts.
#############################################

# ============
#  COULEURS
# ============
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ============
#  FONCTIONS UI
# ============
info()    { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
title()   { echo -e "\n${BLUE}=== $1 ===${RESET}\n"; }

pause() {
    read -rp "Appuyez sur Entrée pour continuer..."
}

# ============
#  VERIFICATIONS
# ============
check_root() {
    if [[ $EUID -ne 0 ]]; then
        warn "Certaines actions nécessitent les droits administrateur."
        echo "Voulez-vous relancer le script avec sudo ? (o/n)"
        read -r choice
        if [[ "$choice" == "o" ]]; then
            sudo bash "$0"
            exit 0
        fi
    fi
}

check_dependencies() {
    local deps=("bash" "ls" "grep" "awk")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            error "Dépendance manquante : $dep"
            exit 1
        fi
    done
}

# ============
#  EXECUTION DYNAMIQUE
# ============
run_script() {
    local script="$1"

    if [[ ! -f "$script" ]]; then
        error "Script introuvable : $script"
        return
    fi

    chmod +x "$script"
    info "Exécution de : $script"
    bash "$script"
}

list_scripts() {
    local folder="$1"
    find "$folder" -maxdepth 1 -type f -name "*.sh" | sort
}

submenu() {
    local folder="$1"
    local title_menu="$2"

    title "$title_menu"

    local scripts=()
    mapfile -t scripts < <(list_scripts "$folder")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        warn "Aucun script disponible dans $folder"
        pause
        return
    fi

    local i=1
    for script in "${scripts[@]}"; do
        echo "$i) $(basename "$script")"
        ((i++))
    done
    echo "0) Retour"

    echo -ne "\nVotre choix : "
    read -r choice

    if [[ "$choice" == "0" ]]; then
        return
    fi

    if [[ "$choice" -gt 0 && "$choice" -le ${#scripts[@]} ]]; then
        run_script "${scripts[$((choice-1))]}"
    else
        warn "Choix invalide."
    fi

    pause
}

# ============
#  MENU PRINCIPAL
# ============
main_menu() {
    while true; do
        clear
        title "LM-Scripts — Menu Principal"

        echo "1) Installation"
        echo "2) Configuration"
        echo "3) Maintenance"
        echo "4) Utilitaires"
        echo "5) Thèmes & Icônes"
        echo "6) Informations système"
        echo "0) Quitter"

        echo -ne "\nVotre choix : "
        read -r choice

        case "$choice" in
            1) submenu "install" "Scripts d'installation" ;;
            2) submenu "config" "Scripts de configuration" ;;
            3) submenu "maintenance" "Scripts de maintenance" ;;
            4) submenu "utils" "Scripts utilitaires" ;;
            5) submenu "themes" "Thèmes & Icônes" ;;
            6) run_script "utils/system_info.sh"; pause ;;
            0) info "Fermeture de LM-Scripts. À bientôt !"; exit 0 ;;
            *) warn "Choix invalide." ; pause ;;
        esac
    done
}

# ============
#  EXECUTION
# ============
check_root
check_dependencies
main_menu

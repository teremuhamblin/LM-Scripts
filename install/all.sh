#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - all.sh
# Lance les différents scripts d'installation (core, drivers, flatpak, devtools)
# Mode interactif + options en ligne de commande.

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_root() {
    if [[ $EUID -ne 0 ]]; then
        warn "Certaines installations nécessitent les droits root."
        echo "Voulez-vous relancer ce script avec sudo ? (o/n)"
        read -r ans
        if [[ "$ans" == "o" ]]; then
            exec sudo bash "$0" "$@"
        fi
    fi
}

run_script_if_exists() {
    local script_path="$1"
    if [[ -f "$script_path" ]]; then
        chmod +x "$script_path"
        info "Exécution de : $(basename "$script_path")"
        bash "$script_path"
    else
        warn "Script introuvable : $script_path"
    fi
}

run_core()      { run_script_if_exists "${SCRIPT_DIR}/install_core.sh"; }
run_drivers()   { run_script_if_exists "${SCRIPT_DIR}/install_drivers.sh"; }
run_flatpak()   { run_script_if_exists "${SCRIPT_DIR}/install_flatpak.sh"; }
run_devtools()  { run_script_if_exists "${SCRIPT_DIR}/install_devtools.sh"; }

run_all() {
    run_core
    run_drivers
    run_flatpak
    run_devtools
}

print_help() {
    cat <<EOF
LM-Scripts - install_all.sh

Utilisation :
  Mode interactif :
    ./install_all.sh

  Mode non interactif :
    ./install_all.sh [options]

Options :
  --core        Installer les paquets de base
  --drivers     Lancer l'outil de pilotes
  --flatpak     Installer et configurer Flatpak + Flathub
  --devtools    Installer les outils de développement
  --all         Tout installer
  --help        Afficher cette aide

EOF
}

interactive_menu() {
    while true; do
        clear
        echo -e "${BLUE}=== LM-Scripts — Installateur global ===${RESET}"
        echo
        echo "1) Installer les paquets de base (core)"
        echo "2) Gérer les pilotes (drivers)"
        echo "3) Configurer Flatpak + Flathub"
        echo "4) Installer les outils de développement"
        echo "5) Tout installer"
        echo "0) Quitter"
        echo
        echo -n "Votre choix : "
        read -r choice

        case "$choice" in
            1) run_core ;;
            2) run_drivers ;;
            3) run_flatpak ;;
            4) run_devtools ;;
            5) run_all ;;
            0) info "Fin de l'installateur."; exit 0 ;;
            *) warn "Choix invalide." ;;
        esac

        echo
        read -rp "Appuyez sur Entrée pour continuer..." _
    done
}

main() {
    require_root "$@"

    if [[ $# -eq 0 ]]; then
        interactive_menu
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --core)     run_core ;;
            --drivers)  run_drivers ;;
            --flatpak)  run_flatpak ;;
            --devtools) run_devtools ;;
            --all)      run_all ;;
            --help|-h)  print_help; exit 0 ;;
            *)          warn "Option inconnue : $1" ;;
        esac
        shift
    done
}

main "$@"

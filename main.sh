#!/usr/bin/env bash
set -euo pipefail

###############################################################
#  LM‑Scripts — Launcher Premium
#  Auteur : The MadDoG.tmdg 
#  Version : 2.0.0
#  Description :
#     Menu interactif avancé, moderne et dynamique
#     pour exécuter tous les scripts LM‑Scripts.
###############################################################

#############################
#        COULEURS
#############################
RESET="\e[0m"
BOLD="\e[1m"

# Palette moderne
C1="\e[38;5;39m"   # Bleu cyan
C2="\e[38;5;82m"   # Vert néon
C3="\e[38;5;214m"  # Orange
C4="\e[38;5;199m"  # Rose
CERR="\e[38;5;196m" # Rouge vif
CWARN="\e[38;5;226m" # Jaune

#############################
#        UI MODERNE
#############################
banner() {
    clear
    echo -e "${C1}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                                              ║"
    echo "║        🚀  LM‑Scripts — Launcher Pro         ║"
    echo "║                                              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

info()  { echo -e "${C2}[INFO]${RESET} $1"; }
warn()  { echo -e "${CWARN}[WARN]${RESET} $1"; }
error() { echo -e "${CERR}[ERROR]${RESET} $1"; }

pause() { read -rp "Appuyez sur Entrée pour continuer..."; }

#############################
#     VERIFICATIONS
#############################
check_dependencies() {
    local deps=("bash" "ls" "grep" "awk" "tput")
    for d in "${deps[@]}"; do
        if ! command -v "$d" >/dev/null 2>&1; then
            error "Dépendance manquante : $d"
            exit 1
        fi
    done
}

#############################
#   EXECUTION DYNAMIQUE
#############################
run_script() {
    local script="$1"
    chmod +x "$script"
    info "Exécution de : $script"
    bash "$script"
}

list_scripts() {
    local folder="$1"
    find "$folder" -maxdepth 1 -type f -name "*.sh" | sort
}

#############################
#   SOUS‑MENU AVANCÉ
#############################
submenu() {
    local folder="$1"
    local title="$2"

    banner
    echo -e "${C3}${BOLD}📂 $title${RESET}\n"

    local scripts=()
    mapfile -t scripts < <(list_scripts "$folder")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        warn "Aucun script dans $folder"
        pause
        return
    fi

    local i=1
    for s in "${scripts[@]}"; do
        echo -e "${C2}$i)${RESET} $(basename "$s")"
        ((i++))
    done

    echo -e "${CERR}0) Retour${RESET}"
    echo -ne "\nVotre choix : "
    read -r choice

    if [[ "$choice" == "0" ]]; then return; fi

    if [[ "$choice" -gt 0 && "$choice" -le ${#scripts[@]} ]]; then
        run_script "${scripts[$((choice-1))]}"
    else
        warn "Choix invalide."
    fi

    pause
}

#############################
#   OPTIONS AVANCÉES
#############################
search_script() {
    banner
    echo -e "${C4}${BOLD}🔍 Recherche d’un script${RESET}\n"
    read -rp "Nom ou mot‑clé : " query

    local results
    results=$(grep -Ril "$query" install config maintenance utils themes || true)

    if [[ -z "$results" ]]; then
        warn "Aucun script trouvé."
    else
        echo -e "${C2}Résultats :${RESET}"
        echo "$results"
    fi

    pause
}

quick_run() {
    banner
    echo -e "${C4}${BOLD}⚡ Exécution rapide${RESET}\n"
    read -rp "Chemin du script : " path

    if [[ -f "$path" ]]; then
        run_script "$path"
    else
        error "Script introuvable."
    fi

    pause
}

#############################
#     MENU PRINCIPAL
#############################
main_menu() {
    while true; do
        banner
        echo -e "${C1}${BOLD}Menu Principal${RESET}\n"

        echo -e "${C2}1)${RESET} Installation"
        echo -e "${C2}2)${RESET} Configuration"
        echo -e "${C2}3)${RESET} Maintenance"
        echo -e "${C2}4)${RESET} Utilitaires"
        echo -e "${C2}5)${RESET} Thèmes & Icônes"
        echo -e "${C2}6)${RESET} Informations système"
        echo -e "${C3}7)${RESET} 🔍 Recherche d’un script"
        echo -e "${C3}8)${RESET} ⚡ Exécution rapide"
        echo -e "${CERR}0) Quitter${RESET}"

        echo -ne "\nVotre choix : "
        read -r choice

        case "$choice" in
            1) submenu "install" "Scripts d'installation" ;;
            2) submenu "config" "Scripts de configuration" ;;
            3) submenu "maintenance" "Scripts de maintenance" ;;
            4) submenu "utils" "Scripts utilitaires" ;;
            5) submenu "themes" "Thèmes & Icônes" ;;
            6) run_script "utils/system_info.sh" ; pause ;;
            7) search_script ;;
            8) quick_run ;;
            0) info "Fermeture de LM‑Scripts. À bientôt !" ; exit 0 ;;
            *) warn "Choix invalide." ; pause ;;
        esac
    done
}

#############################
#     EXECUTION
#############################
check_dependencies
main_menu

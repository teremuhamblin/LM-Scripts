#!/usr/bin/env bash
#
# Script personnel avancé d'installation de logiciels
# Multi-sélection, mode graphique, dry-run, configuration, auto-update
#

set -euo pipefail

############################################
# CONFIGURATION PERSONNELLE
############################################
CONFIG_FILE="$HOME/.config/custom-installer.conf"
LOG_FILE="$HOME/.local/share/custom-install.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Valeurs par défaut
DRY_RUN=false
USE_GUI=false
AUTO_UPDATE_CHECK=true

# Charger config si existe
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

############################################
# COLORS & LOGGING
############################################
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

log()      { echo -e "${BLUE}[INFO]${RESET} $1"; echo "[INFO] $1" >> "$LOG_FILE"; }
success()  { echo -e "${GREEN}[OK]${RESET} $1"; echo "[OK] $1" >> "$LOG_FILE"; }
warn()     { echo -e "${YELLOW}[WARN]${RESET} $1"; echo "[WARN] $1" >> "$LOG_FILE"; }
error()    { echo -e "${RED}[ERROR]${RESET} $1"; echo "[ERROR] $1" >> "$LOG_FILE"; exit 1; }

############################################
# DRY-RUN WRAPPER
############################################
run() {
    if [[ "$DRY_RUN" == true ]]; then
        log "[DRY-RUN] $*"
    else
        eval "$@"
    fi
}

############################################
# DEPENDENCY CHECK
############################################
for dep in curl wget gpg sudo tee; do
    command -v "$dep" >/dev/null || error "Dépendance manquante : $dep"
done

############################################
# GPG & REPO FUNCTIONS
############################################
import_key() {
    local url="$1"
    local keyring="$2"

    log "Importation de la clé GPG : $url"
    run "curl -fsSL '$url' | gpg --dearmor | sudo tee '$keyring' >/dev/null"
}

add_repo() {
    local repo="$1"
    local file="$2"

    log "Ajout du dépôt : $file"
    run "echo '$repo' | sudo tee '$file' >/dev/null"
}

repo_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

############################################
# INSTALLATION FUNCTIONS
############################################
install_vivaldi() {
    local repo="/etc/apt/sources.list.d/vivaldi.list"

    if repo_exists "$repo" && [[ "$AUTO_UPDATE_CHECK" == true ]]; then
        warn "Dépôt Vivaldi déjà présent — vérification ignorée"
        return
    fi

    import_key "https://repo.vivaldi.com/archive/linux_signing_key.pub" "/usr/share/keyrings/vivaldi.gpg"
    add_repo "deb [signed-by=/usr/share/keyrings/vivaldi.gpg] https://repo.vivaldi.com/archive/deb/ stable main" "$repo"
}

install_chrome() {
    local repo="/etc/apt/sources.list.d/google-chrome.list"

    if repo_exists "$repo" && [[ "$AUTO_UPDATE_CHECK" == true ]]; then
        warn "Dépôt Chrome déjà présent — vérification ignorée"
        return
    fi

    import_key "https://dl.google.com/linux/linux_signing_key.pub" "/usr/share/keyrings/google-chrome.gpg"
    add_repo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" "$repo"
}

install_brave() {
    local repo="/etc/apt/sources.list.d/brave-browser.list"

    if repo_exists "$repo" && [[ "$AUTO_UPDATE_CHECK" == true ]]; then
        warn "Dépôt Brave déjà présent — vérification ignorée"
        return
    fi

    import_key "https://brave-browser-apt-release.s3.brave.com/brave-core.asc" "/usr/share/keyrings/brave-browser.gpg"
    add_repo "deb [arch=amd64 signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" "$repo"
}

install_vscode() {
    local repo="/etc/apt/sources.list.d/vscode.list"

    if repo_exists "$repo" && [[ "$AUTO_UPDATE_CHECK" == true ]]; then
        warn "Dépôt VSCode déjà présent — vérification ignorée"
        return
    fi

    import_key "https://packages.microsoft.com/keys/microsoft.asc" "/usr/share/keyrings/microsoft.gpg"
    add_repo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" "$repo"
}

install_alacritty() {
    log "Ajout du PPA Alacritty"
    run "sudo add-apt-repository -y ppa:aslatter/ppa"
}

############################################
# MENU MULTI-SELECTION (TERMINAL)
############################################
terminal_menu() {
    echo "Sélectionnez les logiciels (séparés par des espaces) :"
    echo "1) Vivaldi"
    echo "2) Google Chrome"
    echo "3) Brave"
    echo "4) Visual Studio Code"
    echo "5) Alacritty"
    echo "6) Tout"
    echo

    read -rp "Votre choix : " -a choices
}

############################################
# MENU GRAPHIQUE (WHIPTAIL)
############################################
gui_menu() {
    choices=$(whiptail --title "Installateur personnel" \
        --checklist "Sélectionnez les logiciels :" 20 60 10 \
        "1" "Vivaldi" OFF \
        "2" "Google Chrome" OFF \
        "3" "Brave" OFF \
        "4" "Visual Studio Code" OFF \
        "5" "Alacritty" OFF \
        "6" "Tout" OFF \
        3>&1 1>&2 2>&3)

    # Nettoyage des guillemets
    choices=(${choices//\"/})
}

############################################
# MAIN
############################################
main() {
    log "Démarrage du script personnel"

    if [[ "$USE_GUI" == true ]]; then
        gui_menu
    else
        terminal_menu
    fi

    for choice in "${choices[@]}"; do
        case "$choice" in
            1) install_vivaldi ;;
            2) install_chrome ;;
            3) install_brave ;;
            4) install_vscode ;;
            5) install_alacritty ;;
            6)
                install_vivaldi
                install_chrome
                install_brave
                install_vscode
                install_alacritty
                ;;
        esac
    done

    log "Mise à jour des dépôts"
    run "sudo apt update -y"

    success "Terminé. Logs : $LOG_FILE"
}

main

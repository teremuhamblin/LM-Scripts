#!/usr/bin/env bash
#
# =====================================================================
#  LM-Scripts — install_desktop_apps.sh
#  Installation avancée d’applications desktop (Chromium, Gimp, OBS…)
#  - Profils : minimal / complete / custom / dev / creator / gamer
#  - Catégories : internet / dev / multimedia / utilities / virtualization
#  - Interfaces : CLI, TUI (whiptail), TUI Gum, GUI (zenity)
#  - Hooks : pre_install, post_install
#  - Plugins : extensions dans plugins/desktop_apps
#  - Rollback : suppression des paquets installés en cas d’échec
#  - Logs : /var/log/lm-scripts/install_desktop_apps.log
# =====================================================================

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_NAME="install_desktop_apps"
VERSION="2.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LM_SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null || echo "${SCRIPT_DIR}")"

LOG_DIR="/var/log/lm-scripts"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

HOOKS_DIR="${SCRIPT_DIR}/hooks"
PLUGINS_DIR="${SCRIPT_DIR}/plugins/desktop_apps"

DRY_RUN=false
DEBUG=false
PROFILE="complete"   # minimal | complete | custom | dev | creator | gamer

ROLLBACK_ACTIONS=()

# ---------------------------------------------------------------------
# COULEURS
# ---------------------------------------------------------------------

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ---------------------------------------------------------------------
# LOGGING
# ---------------------------------------------------------------------

init_logging() {
    sudo mkdir -p "$LOG_DIR"
    sudo touch "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
}

log() {
    local level="$1"; shift
    local msg="$*"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" | sudo tee -a "$LOG_FILE"
}

info()    { log "INFO"    "$*"; }
warn()    { log "WARN"    "$*"; }
error()   { log "ERROR"   "$*"; }
success() { log "SUCCESS" "$*"; }

run() {
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] $*"
    else
        eval "$*"
    fi
}

# ---------------------------------------------------------------------
# ROLLBACK
# ---------------------------------------------------------------------

add_rollback_action() {
    ROLLBACK_ACTIONS+=("$*")
}

perform_rollback() {
    warn "Rollback en cours…"
    for (( i=${#ROLLBACK_ACTIONS[@]}-1 ; i>=0 ; i-- )); do
        warn "Rollback: ${ROLLBACK_ACTIONS[$i]}"
        eval "${ROLLBACK_ACTIONS[$i]}" || warn "Échec rollback: ${ROLLBACK_ACTIONS[$i]}"
    done
}

on_error() {
    local code=$?
    error "Erreur détectée (code $code)."
    perform_rollback
    exit "$code"
}

on_exit() {
    [[ $? -eq 0 ]] && success "Script terminé avec succès."
}

trap on_error ERR
trap on_exit EXIT

# ---------------------------------------------------------------------
# ARGUMENTS
# ---------------------------------------------------------------------

usage() {
    echo -e "${BLUE}${SCRIPT_NAME} v${VERSION}${RESET}"
    echo "Options :"
    echo "  -d, --dry-run     Simule les actions"
    echo "  -v, --verbose     Mode debug"
    echo "  -h, --help        Affiche l’aide"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dry-run) DRY_RUN=true ;;
        -v|--verbose) DEBUG=true; set -x ;;
        -h|--help) usage ;;
        *) error "Option inconnue : $1"; exit 1 ;;
    esac
    shift
done

# ---------------------------------------------------------------------
# DETECTION OUTILS
# ---------------------------------------------------------------------

has_gui()      { [[ -n "${DISPLAY:-}" ]] && command -v zenity &>/dev/null; }
has_tui()      { command -v whiptail &>/dev/null; }
has_gum()      { command -v gum &>/dev/null; }

# ---------------------------------------------------------------------
# HOOKS
# ---------------------------------------------------------------------

run_hooks() {
    local phase="$1"
    local dir="${HOOKS_DIR}/${phase}.d"
    [[ ! -d "$dir" ]] && return 0

    info "Exécution des hooks : $phase"
    for hook in "$dir"/*; do
        [[ -x "$hook" ]] && "$hook"
    done
}

# ---------------------------------------------------------------------
# PLUGINS
# ---------------------------------------------------------------------

load_plugins() {
    [[ ! -d "$PLUGINS_DIR" ]] && return 0

    info "Chargement des plugins Desktop Apps…"
    for plugin in "$PLUGINS_DIR"/*.sh; do
        [[ -f "$plugin" ]] && source "$plugin"
    done
}

# ---------------------------------------------------------------------
# LISTES DE PAQUETS PAR CATÉGORIE
# ---------------------------------------------------------------------

PKG_INTERNET=(
    chromium
    qbittorrent
    telegram-desktop
    spotify-client
)

PKG_DEV=(
    git
    meld
    sublime-text
)

PKG_MULTIMEDIA=(
    gimp
    inkscape
    obs-studio
    simplescreenrecorder
    vlc
    flameshot
)

PKG_UTILITIES=(
    dconf-editor
    rxvt-unicode
)

PKG_VIRTUALIZATION=(
    virtualbox
)

# Profils de haut niveau
PACKAGES_MINIMAL=(
    chromium
    gimp
    vlc
)

PACKAGES_COMPLETE=(
    "${PKG_INTERNET[@]}"
    "${PKG_DEV[@]}"
    "${PKG_MULTIMEDIA[@]}"
    "${PKG_UTILITIES[@]}"
    "${PKG_VIRTUALIZATION[@]}"
)

PACKAGES_DEV_PROFILE=(
    "${PKG_DEV[@]}"
    chromium
    vlc
)

PACKAGES_CREATOR_PROFILE=(
    "${PKG_MULTIMEDIA[@]}"
    chromium
)

PACKAGES_GAMER_PROFILE=(
    "${PKG_INTERNET[@]}"
    vlc
    virtualbox
)

SELECTED_PACKAGES=()

# ---------------------------------------------------------------------
# PROFILS
# ---------------------------------------------------------------------

set_profile_from_choice() {
    case "$1" in
        minimal) PROFILE="minimal" ;;
        complete) PROFILE="complete" ;;
        custom) PROFILE="custom" ;;
        dev) PROFILE="dev" ;;
        creator) PROFILE="creator" ;;
        gamer) PROFILE="gamer" ;;
        *) PROFILE="complete" ;;
    esac
}

select_profile_cli() {
    echo -e "${BLUE}Choix du profil d’installation${RESET}"
    echo "1) Minimal"
    echo "2) Complet"
    echo "3) Custom"
    echo "4) Dev"
    echo "5) Creator"
    echo "6) Gamer"
    read -r -p "Choix [1-6] : " c
    case "$c" in
        1) set_profile_from_choice minimal ;;
        3) set_profile_from_choice custom ;;
        4) set_profile_from_choice dev ;;
        5) set_profile_from_choice creator ;;
        6) set_profile_from_choice gamer ;;
        *) set_profile_from_choice complete ;;
    esac
}

select_profile() {
    if has_gum; then
        PROFILE=$(printf "minimal\ncomplete\ncustom\ndev\ncreator\ngamer\n" \
            | gum choose --header "Choisissez un profil") || PROFILE="complete"
    elif has_gui; then
        PROFILE=$(zenity --list --title="Profil" --column="Profil" \
            minimal complete custom dev creator gamer 2>/dev/null) || PROFILE="complete"
    elif has_tui; then
        PROFILE=$(whiptail --title "Profil" --menu "Choisissez un profil" 20 70 10 \
            "minimal" "Essentiel" \
            "complete" "Tous les paquets" \
            "custom" "Personnalisé" \
            "dev" "Développeur" \
            "creator" "Créateur (graphisme / vidéo)" \
            "gamer" "Joueur / multimédia" \
            3>&1 1>&2 2>&3) || PROFILE="complete"
    else
        select_profile_cli
    fi

    info "Profil sélectionné : $PROFILE"
}

build_package_list() {
    case "$PROFILE" in
        minimal)  SELECTED_PACKAGES=("${PACKAGES_MINIMAL[@]}") ;;
        complete) SELECTED_PACKAGES=("${PACKAGES_COMPLETE[@]}") ;;
        dev)      SELECTED_PACKAGES=("${PACKAGES_DEV_PROFILE[@]}") ;;
        creator)  SELECTED_PACKAGES=("${PACKAGES_CREATOR_PROFILE[@]}") ;;
        gamer)    SELECTED_PACKAGES=("${PACKAGES_GAMER_PROFILE[@]}") ;;
        custom)
            if has_gum; then
                mapfile -t SELECTED_PACKAGES < <(printf "%s\n" "${PACKAGES_COMPLETE[@]}" | gum choose --no-limit)
            elif has_gui; then
                # zenity ne gère pas facilement le multi-select en ligne de commande simple,
                # on prend tout par défaut pour ce mode.
                SELECTED_PACKAGES=("${PACKAGES_COMPLETE[@]}")
            elif has_tui; then
                # whiptail checklist possible, mais plus verbeux ; on simplifie : tout
                SELECTED_PACKAGES=("${PACKAGES_COMPLETE[@]}")
            else
                SELECTED_PACKAGES=("${PACKAGES_COMPLETE[@]}")
            fi
            ;;
    esac
}

# ---------------------------------------------------------------------
# INSTALLATION
# ---------------------------------------------------------------------

install_packages() {
    select_profile
    build_package_list

    info "Mise à jour APT…"
    run "sudo apt-get update"

    run_hooks "pre_install"

    local missing=()
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        info "Installation des paquets : ${missing[*]}"
        run "sudo apt-get install -y --no-install-recommends ${missing[*]}"
        add_rollback_action "sudo apt-get remove -y ${missing[*]}"
    else
        success "Tous les paquets du profil sont déjà installés."
    fi

    run_hooks "post_install"
    success "Installation terminée."
}

verify_packages() {
    info "Vérification des paquets installés…"
    dpkg -l | less
}

# ---------------------------------------------------------------------
# MENUS
# ---------------------------------------------------------------------

menu_cli() {
    while true; do
        echo -e "${BLUE}Menu Desktop Apps (CLI)${RESET}"
        echo "1) Installer (profil)"
        echo "2) Vérifier installation"
        echo "3) Afficher logs"
        echo "4) Quitter"
        read -r -p "Choix : " c
        case "$c" in
            1) install_packages ;;
            2) verify_packages ;;
            3) less "$LOG_FILE" ;;
            4) break ;;
            *) echo "Choix invalide." ;;
        esac
    done
}

menu_tui() {
    while true; do
        local c
        c=$(whiptail --title "Desktop Apps" --menu "Choisissez une action" 20 70 10 \
            "1" "Installer (profil)" \
            "2" "Vérifier installation" \
            "3" "Afficher logs" \
            "4" "Quitter" \
            3>&1 1>&2 2>&3) || return 0

        case "$c" in
            1) install_packages ;;
            2) verify_packages ;;
            3) whiptail --textbox "$LOG_FILE" 30 100 ;;
            4) break ;;
        esac
    done
}

menu_gum() {
    while true; do
        local c
        c=$(printf "Installer (profil)\nVérifier installation\nLogs\nQuitter\n" \
            | gum choose --header "Desktop Apps") || return 0

        case "$c" in
            "Installer (profil)") install_packages ;;
            "Vérifier installation") verify_packages ;;
            "Logs") less "$LOG_FILE" ;;
            "Quitter") break ;;
        esac
    done
}

menu_gui() {
    while true; do
        local c
        c=$(zenity --list \
            --title="Desktop Apps" \
            --column="Action" --column="Description" \
            "install" "Installer (profil)" \
            "verify" "Vérifier installation" \
            "log" "Afficher logs" \
            "quit" "Quitter" \
            2>/dev/null) || return 0

        case "$c" in
            install) install_packages ;;
            verify)  verify_packages ;;
            log)     zenity --text-info --filename="$LOG_FILE" ;;
            quit)    break ;;
        esac
    done
}

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------

main() {
    init_logging
    info "Démarrage ${SCRIPT_NAME} v${VERSION}"

    load_plugins

    if has_gui; then
        menu_gui
    elif has_gum; then
        menu_gum
    elif has_tui; then
        menu_tui
    else
        menu_cli
    fi
}

main

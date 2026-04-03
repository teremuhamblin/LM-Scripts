#!/usr/bin/env bash
#
# =====================================================================
#  LM-Scripts — install_chadwm_extras.sh
#  Installation avancée, modulaire et sécurisée des extras ChadWM
#  - Profils : minimal / complet / custom
#  - Interfaces : GUI (zenity), TUI (gum, whiptail), CLI
#  - Hooks : pre/post install & uninstall
#  - Plugins : pack “sources officielles” (modifiables)
#  - Rollback : apt remove sur paquets installés
# =====================================================================

set -o errexit
set -o pipefail
set -o nounset

# ---------------------------------------------------------------------
#  MÉTADONNÉES & CHEMINS
# ---------------------------------------------------------------------

SCRIPT_NAME="install_chadwm_extras"
VERSION="4.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LM_SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null || echo "${SCRIPT_DIR}")"

LOG_DIR="/var/log/lm-scripts"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

DRY_RUN=false
DEBUG=false

HOOKS_DIR="${SCRIPT_DIR}/hooks"
PLUGINS_DIR="${SCRIPT_DIR}/plugins/chadwm_extras"

ROLLBACK_ACTIONS=()
PROFILE="complete"          # minimal | complete | custom
SELECTED_PACKAGES=()

# ---------------------------------------------------------------------
#  COULEURS
# ---------------------------------------------------------------------

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ---------------------------------------------------------------------
#  LOGGING
# ---------------------------------------------------------------------

init_logging() {
    sudo mkdir -p "$LOG_DIR"
    sudo touch "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
}

log() {
    local level="$1"; shift
    local msg="$*"
    local line="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg"
    echo -e "$line"
    echo -e "$line" | sudo tee -a "$LOG_FILE" >/dev/null
}

info()    { log "INFO"    "$*"; }
warn()    { log "WARN"    "$*"; }
error()   { log "ERROR"   "$*"; }
success() { log "SUCCESS" "$*"; }

run() {
    local cmd="$*"
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] $cmd"
    else
        eval "$cmd"
    fi
}

# ---------------------------------------------------------------------
#  ROLLBACK
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
    local code=$?
    if [[ $code -eq 0 ]]; then
        success "Script terminé avec succès."
    fi
}

trap on_error ERR
trap on_exit EXIT

# ---------------------------------------------------------------------
#  AIDE & ARGUMENTS
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
#  LISTES DE PAQUETS (PROFILS)
# ---------------------------------------------------------------------

PACKAGES_MINIMAL=(
    acpi
    arandr
    pavucontrol
    rofi
    xfce4-terminal
)

PACKAGES_COMPLETE=(
    acpi
    arandr
    autorandr
    catfish
    duf
    feh
    font-manager
    hwinfo
    hw-probe
    lolcat
    lxappearance
    most
    nitrogen
    nomacs
    numlockx
    pavucontrol
    picom
    ripgrep
    rofi
    suckless-tools
    sxhkd
    thunar
    thunar-archive-plugin
    variety
    xfce4-taskmanager
    xfce4-terminal
    silversearcher-ag
)

# ---------------------------------------------------------------------
#  DÉTECTION OUTILS
# ---------------------------------------------------------------------

has_gui()      { [[ -n "${DISPLAY:-}" ]] && command -v zenity &>/dev/null; }
has_tui()      { command -v whiptail &>/dev/null; }
has_gum()      { command -v gum &>/dev/null; }

# ---------------------------------------------------------------------
#  HOOKS
# ---------------------------------------------------------------------

run_hooks() {
    local phase="$1"
    local dir="${HOOKS_DIR}/${phase}.d"

    [[ ! -d "$dir" ]] && return 0

    info "Exécution des hooks : $phase"

    for hook in "$dir"/*; do
        [[ -x "$hook" ]] || continue
        info "Hook : $hook"
        "$hook"
    done
}

# ---------------------------------------------------------------------
#  PLUGINS (PACK “SOURCES OFFICIELLES”)
# ---------------------------------------------------------------------
# Ici on charge des plugins qui peuvent :
# - étendre les listes de paquets
# - ajouter des profils
# - récupérer des listes depuis des sources officielles (via curl/wget)
#
# Exemples de sources très utilisées (à adapter dans les plugins) :
# - GitHub (ex: https://github.com/chadwm/chadwm)
# - GitLab / Codeberg pour des dotfiles ChadWM
# - Repos AUR / ArchWiki pour listes d’outils recommandés
# ---------------------------------------------------------------------

load_plugins() {
    [[ ! -d "$PLUGINS_DIR" ]] && return 0

    info "Chargement des plugins ChadWM Extras…"

    for plugin in "$PLUGINS_DIR"/*.sh; do
        [[ -f "$plugin" ]] || continue
        info "Plugin : $plugin"
        # shellcheck disable=SC1090
        source "$plugin"
    done
}

# ---------------------------------------------------------------------
#  PROFILS
# ---------------------------------------------------------------------

set_profile_from_choice() {
    local choice="$1"
    case "$choice" in
        minimal) PROFILE="minimal" ;;
        complete) PROFILE="complete" ;;
        custom) PROFILE="custom" ;;
        *) PROFILE="complete" ;;
    esac
}

build_selected_packages() {
    SELECTED_PACKAGES=()
    case "$PROFILE" in
        minimal)
            SELECTED_PACKAGES=("${PACKAGES_MINIMAL[@]}")
            ;;
        complete)
            SELECTED_PACKAGES=("${PACKAGES_COMPLETE[@]}")
            ;;
        custom)
            # Par défaut : on part de la liste complète, puis on laisse
            # l’utilisateur filtrer (via gum/GUI/CLI).
            SELECTED_PACKAGES=("${PACKAGES_COMPLETE[@]}")
            ;;
    esac
}

select_profile_cli() {
    echo ""
    echo -e "${BLUE}Choix du profil d’installation${RESET}"
    echo "1) Minimal"
    echo "2) Complet"
    echo "3) Custom"
    read -r -p "Choix [1-3] (défaut: 2) : " c
    case "$c" in
        1) set_profile_from_choice "minimal" ;;
        3) set_profile_from_choice "custom" ;;
        *) set_profile_from_choice "complete" ;;
    esac
}

select_profile_tui() {
    local c
    c=$(whiptail --title "Profil d’installation" --menu "Choisissez un profil" 20 70 10 \
        "minimal" "Profil léger (essentiel)" \
        "complete" "Profil complet (tous les extras)" \
        "custom" "Profil personnalisé" \
        3>&1 1>&2 2>&3) || return 1
    set_profile_from_choice "$c"
}

select_profile_gui() {
    local c
    c=$(zenity --list \
        --title="Profil d’installation" \
        --column="Profil" --column="Description" \
        "minimal" "Profil léger (essentiel)" \
        "complete" "Profil complet (tous les extras)" \
        "custom" "Profil personnalisé" \
        2>/dev/null) || return 1
    set_profile_from_choice "$c"
}

select_profile_gum() {
    local c
    c=$(printf "minimal\ncomplete\ncustom\n" | gum choose --header "Choisissez un profil d’installation") || return 1
    set_profile_from_choice "$c"
}

select_profile() {
    if has_gum; then
        select_profile_gum || select_profile_cli
    elif has_gui; then
        select_profile_gui || select_profile_cli
    elif has_tui; then
        select_profile_tui || select_profile_cli
    else
        select_profile_cli
    fi
    info "Profil sélectionné : $PROFILE"
    build_selected_packages
}

# ---------------------------------------------------------------------
#  CUSTOM : SÉLECTION DES PAQUETS
# ---------------------------------------------------------------------

custom_select_packages_cli() {
    echo ""
    echo -e "${BLUE}Profil custom : sélection des paquets${RESET}"
    echo "Liste complète actuelle :"
    printf ' - %s\n' "${PACKAGES_COMPLETE[@]}"
    echo ""
    read -r -p "Entrez les paquets à installer (séparés par des espaces, vide = tous) : " line || true
    if [[ -z "${line:-}" ]]; then
        SELECTED_PACKAGES=("${PACKAGES_COMPLETE[@]}")
    else
        # On ne valide pas finement ici, on laisse apt gérer les erreurs
        read -r -a SELECTED_PACKAGES <<< "$line"
    fi
}

custom_select_packages_gum() {
    # gum choose --no-limit pour multi-sélection
    local selection
    selection=$(printf '%s\n' "${PACKAGES_COMPLETE[@]}" | gum choose --no-limit --header "Sélectionnez les paquets à installer (profil custom)") || true
    if [[ -z "${selection:-}" ]]; then
        SELECTED_PACKAGES=("${PACKAGES_COMPLETE[@]}")
    else
        mapfile -t SELECTED_PACKAGES <<< "$selection"
    fi
}

custom_select_packages_gui() {
    # Zenity n’a pas de multi-select simple en liste, on reste simple :
    custom_select_packages_cli
}

custom_select_packages_tui() {
    # Pour ne pas exploser la complexité, on repasse en CLI pour custom
    custom_select_packages_cli
}

handle_custom_selection() {
    [[ "$PROFILE" != "custom" ]] && return 0

    if has_gum; then
        custom_select_packages_gum || custom_select_packages_cli
    elif has_gui; then
        custom_select_packages_gui
    elif has_tui; then
        custom_select_packages_tui
    else
        custom_select_packages_cli
    fi

    info "Paquets sélectionnés (custom) : ${SELECTED_PACKAGES[*]}"
}

# ---------------------------------------------------------------------
#  INSTALLATION DES PAQUETS
# ---------------------------------------------------------------------

install_packages() {
    select_profile
    handle_custom_selection

    info "Analyse des paquets nécessaires pour le profil : $PROFILE"

    local missing=()
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Paquets manquants : ${missing[*]}"
        run_hooks "pre_install"

        info "Mise à jour APT…"
        run "sudo apt-get update"

        info "Installation sécurisée des paquets…"
        run "sudo apt-get install -y --no-install-recommends ${missing[*]}"

        add_rollback_action "sudo apt-get remove -y ${missing[*]}"

        run_hooks "post_install"
    else
        success "Tous les paquets du profil sont déjà installés."
    fi
}

# ---------------------------------------------------------------------
#  VÉRIFICATION
# ---------------------------------------------------------------------

verify_install() {
    info "Vérification des installations (profil complet)…"

    local ok=true

    for pkg in "${PACKAGES_COMPLETE[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            info "OK : $pkg"
        else
            warn "Manquant : $pkg"
            ok=false
        fi
    done

    if [[ "$ok" == true ]]; then
        success "Tous les extras ChadWM (profil complet) sont installés."
    else
        warn "Des paquets sont manquants."
        return 1
    fi
}

# ---------------------------------------------------------------------
#  DÉSINSTALLATION
# ---------------------------------------------------------------------

uninstall_extras() {
    info "Désinstallation des extras ChadWM (profil complet)…"
    run_hooks "pre_uninstall"

    run "sudo apt-get remove -y ${PACKAGES_COMPLETE[*]}"

    run_hooks "post_uninstall"
    success "Désinstallation terminée."
}

# ---------------------------------------------------------------------
#  MENUS (CLI / TUI / GUM / GUI)
# ---------------------------------------------------------------------

menu_cli() {
    while true; do
        echo ""
        echo -e "${BLUE}Menu ChadWM Extras (CLI)${RESET}"
        echo "1) Installer (profil)"
        echo "2) Vérifier (profil complet)"
        echo "3) Désinstaller (profil complet)"
        echo "4) Logs"
        echo "5) Quitter"
        read -r -p "Choix : " c
        case "$c" in
            1) install_packages ;;
            2) verify_install ;;
            3) uninstall_extras ;;
            4) less "$LOG_FILE" ;;
            5) break ;;
            *) echo "Choix invalide." ;;
        esac
    done
}

menu_tui() {
    while true; do
        local c
        c=$(whiptail --title "ChadWM Extras" --menu "Choisissez une action" 20 70 10 \
            "1" "Installer (profil)" \
            "2" "Vérifier (profil complet)" \
            "3" "Désinstaller (profil complet)" \
            "4" "Afficher les logs" \
            "5" "Quitter" \
            3>&1 1>&2 2>&3) || return 0

        case "$c" in
            1) install_packages ;;
            2) verify_install ;;
            3) uninstall_extras ;;
            4) whiptail --textbox "$LOG_FILE" 30 100 ;;
            5) break ;;
        esac
    done
}

menu_gum() {
    while true; do
        local c
        c=$(printf "Installer (profil)\nVérifier (complet)\nDésinstaller (complet)\nLogs\nQuitter\n" \
            | gum choose --header "ChadWM Extras") || return 0

        case "$c" in
            "Installer (profil)") install_packages ;;
            "Vérifier (complet)") verify_install ;;
            "Désinstaller (complet)") uninstall_extras ;;
            "Logs") less "$LOG_FILE" ;;
            "Quitter") break ;;
        esac
    done
}

menu_gui() {
    while true; do
        local c
        c=$(zenity --list \
            --title="ChadWM Extras" \
            --column="Action" --column="Description" \
            "install" "Installer (profil)" \
            "verify" "Vérifier (profil complet)" \
            "uninstall" "Désinstaller (profil complet)" \
            "log" "Afficher les logs" \
            "quit" "Quitter" \
            2>/dev/null) || return 0

        case "$c" in
            install) install_packages ;;
            verify) verify_install ;;
            uninstall) uninstall_extras ;;
            log) zenity --text-info --filename="$LOG_FILE" ;;
            quit) break ;;
        esac
    done
}

# ---------------------------------------------------------------------
#  MAIN
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

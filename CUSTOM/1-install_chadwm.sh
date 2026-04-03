#!/usr/bin/env bash
#
# =====================================================================
#  LM-Scripts — install_chadwm.sh
#  Installation avancée, modulaire et sécurisée de ChadWM pour Linux Mint
# =====================================================================

set -o errexit
set -o pipefail
set -o nounset

# ---------------------------------------------------------------------
#  MÉTADONNÉES
# ---------------------------------------------------------------------

SCRIPT_NAME="install_chadwm"
VERSION="2.0.0"

# Détection du répertoire racine du script (pour hooks/plugins)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LM_SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null || echo "${SCRIPT_DIR}")"

CONFIG_DIR="$HOME/.config"
CHADWM_DIR="$CONFIG_DIR/arco-chadwm"
CHADWM_SOURCE_DIR="${SCRIPT_DIR}/arco-chadwm"   # à adapter si besoin
DESKTOP_FILE="/usr/share/xsessions/chadwm.desktop"

LOG_DIR="/var/log/lm-scripts"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

DRY_RUN=false
DEBUG=false

# Hooks & plugins
HOOKS_DIR="${SCRIPT_DIR}/hooks"
PLUGINS_DIR="${SCRIPT_DIR}/plugins/chadwm"

# Rollback
ROLLBACK_ACTIONS=()

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
    if [[ ! -d "$LOG_DIR" ]]; then
        sudo mkdir -p "$LOG_DIR"
        sudo chmod 755 "$LOG_DIR"
    fi
    if [[ ! -f "$LOG_FILE" ]]; then
        sudo touch "$LOG_FILE"
        sudo chmod 644 "$LOG_FILE"
    fi
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
    # On stocke une commande shell à exécuter en rollback
    local action="$*"
    ROLLBACK_ACTIONS+=("$action")
}

perform_rollback() {
    warn "Exécution du rollback…"
    # On exécute en ordre inverse
    for (( idx=${#ROLLBACK_ACTIONS[@]}-1 ; idx>=0 ; idx-- )); do
        local action="${ROLLBACK_ACTIONS[$idx]}"
        warn "Rollback: $action"
        if [[ "$DRY_RUN" == true ]]; then
            info "[DRY-RUN] rollback: $action"
        else
            eval "$action" || warn "Échec rollback: $action"
        fi
    done
}

on_error() {
    local exit_code=$?
    error "Une erreur est survenue (code $exit_code)."
    perform_rollback
    error "Arrêt du script."
    exit "$exit_code"
}

on_exit() {
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        success "Script terminé avec succès."
    fi
}

trap on_error ERR
trap on_exit EXIT

# ---------------------------------------------------------------------
#  AIDE
# ---------------------------------------------------------------------

usage() {
    echo -e "${BLUE}${SCRIPT_NAME} v${VERSION}${RESET}"
    echo "Usage : $0 [options]"
    echo ""
    echo "Options :"
    echo "  -d, --dry-run     Simule les actions sans les exécuter"
    echo "  -v, --verbose     Active le mode debug"
    echo "  -h, --help        Affiche cette aide"
    exit 0
}

# ---------------------------------------------------------------------
#  PARSING DES ARGUMENTS
# ---------------------------------------------------------------------

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
#  DÉPENDANCES
# ---------------------------------------------------------------------

APT_PACKAGES=(
    build-essential
    libimlib2-dev
    libx11-dev
    libxft-dev
    libxinerama-dev
    libfreetype6-dev
    libfontconfig1-dev
    zenity
    whiptail
)

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        return 1
    fi
    return 0
}

install_apt_packages() {
    info "Vérification des paquets APT nécessaires…"
    local missing=()
    for pkg in "${APT_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Paquets manquants : ${missing[*]}"
        info "Installation des paquets manquants…"
        run "sudo apt-get update"
        run "sudo apt-get install -y --no-install-recommends ${missing[*]}"
        # On ne rollback pas automatiquement les paquets (risque élevé),
        # mais on log ce qui a été installé.
        info "Paquets installés : ${missing[*]}"
    else
        success "Tous les paquets APT requis sont déjà installés."
    fi
}

# ---------------------------------------------------------------------
#  HOOKS
# ---------------------------------------------------------------------

run_hooks() {
    local phase="$1"  # ex: pre_install, post_install, pre_uninstall, post_uninstall
    local dir="${HOOKS_DIR}/${phase}.d"

    if [[ -d "$dir" ]]; then
        info "Exécution des hooks pour la phase : ${phase}"
        local hook
        # shellcheck disable=SC2045
        for hook in $(ls -1 "$dir" 2>/dev/null || true); do
            local path="${dir}/${hook}"
            if [[ -x "$path" ]]; then
                info "Hook : $path"
                if [[ "$DRY_RUN" == true ]]; then
                    info "[DRY-RUN] hook: $path"
                else
                    "$path"
                fi
            fi
        done
    fi
}

# ---------------------------------------------------------------------
#  PLUGINS
# ---------------------------------------------------------------------

load_plugins() {
    if [[ -d "$PLUGINS_DIR" ]]; then
        info "Chargement des plugins ChadWM…"
        local plugin
        # shellcheck disable=SC2045
        for plugin in $(ls -1 "$PLUGINS_DIR"/*.sh 2>/dev/null || true); do
            info "Plugin : $plugin"
            # On source pour permettre l’extension du script
            # (ajout de fonctions, menus, etc.)
            # shellcheck disable=SC1090
            source "$plugin"
        done
    fi
}

# ---------------------------------------------------------------------
#  INSTALLATION
# ---------------------------------------------------------------------

install_chadwm() {
    info "=== Installation de ChadWM ==="

    run_hooks "pre_install"

    # Copie des sources
    if [[ ! -d "$CHADWM_SOURCE_DIR" ]]; then
        error "Répertoire source ChadWM introuvable : $CHADWM_SOURCE_DIR"
        return 1
    fi

    if [[ -d "$CHADWM_DIR" ]]; then
        warn "Répertoire cible déjà présent : $CHADWM_DIR"
    else
        info "Copie de ${CHADWM_SOURCE_DIR} vers ${CHADWM_DIR}…"
        run "cp -r \"$CHADWM_SOURCE_DIR\" \"$CHADWM_DIR\""
        add_rollback_action "rm -rf \"$CHADWM_DIR\""
    fi

    # Compilation
    info "Compilation de ChadWM…"
    run "cd \"$CHADWM_DIR/chadwm\" && make"
    # Pas de rollback direct sur make, mais on peut supprimer le binaire si besoin
    if [[ -f "$CHADWM_DIR/chadwm/chadwm" ]]; then
        add_rollback_action "rm -f \"$CHADWM_DIR/chadwm/chadwm\""
    fi

    # Installation système
    info "Installation système de ChadWM…"
    run "cd \"$CHADWM_DIR/chadwm\" && sudo make install"
    # On suppose que le binaire s’appelle chadwm dans /usr/local/bin ou similaire
    if command -v chadwm &>/dev/null; then
        local bin_path
        bin_path="$(command -v chadwm)"
        add_rollback_action "sudo rm -f \"$bin_path\""
    fi

    # Fichier .desktop
    info "Création du fichier .desktop : $DESKTOP_FILE"
    run "sudo tee \"$DESKTOP_FILE\" >/dev/null <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=ChadWM
Comment=Dynamic window manager
Exec=$CHADWM_DIR/scripts/run.sh
Icon=chadwm
Type=Application
EOF"
    add_rollback_action "sudo rm -f \"$DESKTOP_FILE\""

    run_hooks "post_install"

    success "Installation de ChadWM terminée."
}

# ---------------------------------------------------------------------
#  VÉRIFICATION
# ---------------------------------------------------------------------

verify_chadwm() {
    info "=== Vérification de l’installation ChadWM ==="

    local ok=true

    if ! command -v chadwm &>/dev/null; then
        error "Binaire chadwm introuvable dans le PATH."
        ok=false
    else
        info "Binaire chadwm trouvé : $(command -v chadwm)"
    fi

    if [[ ! -f "$DESKTOP_FILE" ]]; then
        error "Fichier .desktop introuvable : $DESKTOP_FILE"
        ok=false
    else
        info "Fichier .desktop présent : $DESKTOP_FILE"
    fi

    local run_script="$CHADWM_DIR/scripts/run.sh"
    if [[ ! -x "$run_script" ]]; then
        error "Script run.sh introuvable ou non exécutable : $run_script"
        ok=false
    else
        info "Script run.sh présent et exécutable : $run_script"
    fi

    if [[ "$ok" == true ]]; then
        success "Vérification réussie : ChadWM semble correctement installé."
    else
        warn "Vérification terminée avec des erreurs."
        return 1
    fi
}

# ---------------------------------------------------------------------
#  DÉSINSTALLATION
# ---------------------------------------------------------------------

uninstall_chadwm() {
    info "=== Désinstallation de ChadWM ==="

    run_hooks "pre_uninstall"

    # Suppression du .desktop
    if [[ -f "$DESKTOP_FILE" ]]; then
        info "Suppression du fichier .desktop : $DESKTOP_FILE"
        run "sudo rm -f \"$DESKTOP_FILE\""
    fi

    # Suppression du binaire (si connu)
    if command -v chadwm &>/dev/null; then
        local bin_path
        bin_path="$(command -v chadwm)"
        info "Suppression du binaire : $bin_path"
        run "sudo rm -f \"$bin_path\""
    fi

    # Suppression du répertoire de config
    if [[ -d "$CHADWM_DIR" ]]; then
        info "Suppression du répertoire : $CHADWM_DIR"
        run "rm -rf \"$CHADWM_DIR\""
    fi

    run_hooks "post_uninstall"

    success "Désinstallation de ChadWM terminée."
}

# ---------------------------------------------------------------------
#  INTERFACES (GUI / TUI / CLI)
# ---------------------------------------------------------------------

has_gui() {
    [[ -n "${DISPLAY:-}" ]] && check_command zenity
}

has_tui() {
    check_command whiptail
}

menu_cli() {
    while true; do
        echo ""
        echo -e "${BLUE}Menu ChadWM (CLI)${RESET}"
        echo "1) Installer ChadWM"
        echo "2) Vérifier l’installation"
        echo "3) Désinstaller ChadWM"
        echo "4) Afficher le log"
        echo "5) Quitter"
        read -r -p "Choix : " choice
        case "$choice" in
            1) install_chadwm ;;
            2) verify_chadwm ;;
            3) uninstall_chadwm ;;
            4) less "$LOG_FILE" ;;
            5) break ;;
            *) echo "Choix invalide." ;;
        esac
    done
}

menu_tui() {
    local choice
    while true; do
        choice=$(whiptail --title "LM-Scripts - ChadWM" --menu "Choisissez une action" 20 70 10 \
            "1" "Installer ChadWM" \
            "2" "Vérifier l’installation" \
            "3" "Désinstaller ChadWM" \
            "4" "Afficher le log" \
            "5" "Quitter" \
            3>&1 1>&2 2>&3) || return 0

        case "$choice" in
            1) install_chadwm ;;
            2) verify_chadwm ;;
            3) uninstall_chadwm ;;
            4) whiptail --textbox "$LOG_FILE" 30 100 ;;
            5) break ;;
        esac
    done
}

menu_gui() {
    while true; do
        local choice
        choice=$(zenity --list \
            --title="LM-Scripts - ChadWM" \
            --column="Action" --column="Description" \
            "install" "Installer ChadWM" \
            "verify" "Vérifier l’installation" \
            "uninstall" "Désinstaller ChadWM" \
            "log" "Afficher le log" \
            "quit" "Quitter" \
            2>/dev/null) || return 0

        case "$choice" in
            install) install_chadwm ;;
            verify)  verify_chadwm ;;
            uninstall) uninstall_chadwm ;;
            log) zenity --text-info --filename="$LOG_FILE" --width=800 --height=600 ;;
            quit) break ;;
        esac
    done
}

# ---------------------------------------------------------------------
#  MAIN
# ---------------------------------------------------------------------

main() {
    init_logging
    info "Démarrage de ${SCRIPT_NAME} v${VERSION}"

    install_apt_packages
    load_plugins

    if has_gui; then
        info "Interface graphique détectée (Zenity)."
        menu_gui
    elif has_tui; then
        info "Interface TUI détectée (whiptail)."
        menu_tui
    else
        info "Aucune interface graphique/TUI disponible, utilisation du mode CLI."
        menu_cli
    fi
}

main

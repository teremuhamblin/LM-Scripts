#!/usr/bin/env bash
#
# =====================================================================
#  LM-Scripts — configure_git_project.sh
#  Configuration avancée Git pour un projet (local/global/system)
#  - Profils : minimal / complet / custom
#  - Interfaces : GUI (zenity), TUI (gum, whiptail), CLI
#  - Hooks : pre/post_config
#  - Plugins : pack “providers officiels” (GitHub/GitLab/Codeberg, etc.)
#  - Rollback : restauration des anciennes valeurs git config
# =====================================================================

set -o errexit
set -o pipefail
set -o nounset

# ---------------------------------------------------------------------
#  MÉTADONNÉES & CHEMINS
# ---------------------------------------------------------------------

SCRIPT_NAME="configure_git_project"
VERSION="1.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LM_SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null || echo "${SCRIPT_DIR}")"

LOG_DIR="/var/log/lm-scripts"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

DRY_RUN=false
DEBUG=false

HOOKS_DIR="${SCRIPT_DIR}/hooks"
PLUGINS_DIR="${SCRIPT_DIR}/plugins/git_project"

ROLLBACK_ACTIONS=()
PROFILE="complete"   # minimal | complete | custom

PROJECT_NAME=""
PROJECT_ROOT=""

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
#  PLUGINS (PACK “PROVIDERS OFFICIELS”)
# ---------------------------------------------------------------------
# Les plugins peuvent :
# - proposer des modèles d’URL remote (GitHub, GitLab, Codeberg, etc.)
# - surcharger des valeurs par défaut
# - ajouter des profils
# ---------------------------------------------------------------------

load_plugins() {
    [[ ! -d "$PLUGINS_DIR" ]] && return 0

    info "Chargement des plugins Git Project…"

    for plugin in "$PLUGINS_DIR"/*.sh; do
        [[ -f "$plugin" ]] || continue
        info "Plugin : $plugin"
        # shellcheck disable=SC1090
        source "$plugin"
    done
}

# ---------------------------------------------------------------------
#  VÉRIFICATIONS DE BASE
# ---------------------------------------------------------------------

check_requirements() {
    if ! command -v git &>/dev/null; then
        error "git n’est pas installé."
        exit 1
    fi

    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        error "Ce répertoire n’est pas un dépôt git."
        exit 1
    fi

    PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    PROJECT_NAME="$(basename "$PROJECT_ROOT")"
    info "Projet détecté : $PROJECT_NAME ($PROJECT_ROOT)"
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

select_profile_cli() {
    echo ""
    echo -e "${BLUE}Choix du profil de configuration Git${RESET}"
    echo "1) Minimal (local uniquement)"
    echo "2) Complet (local + global + system editor)"
    echo "3) Custom (choix fin)"
    read -r -p "Choix [1-3] (défaut: 2) : " c
    case "$c" in
        1) set_profile_from_choice "minimal" ;;
        3) set_profile_from_choice "custom" ;;
        *) set_profile_from_choice "complete" ;;
    esac
}

select_profile_tui() {
    local c
    c=$(whiptail --title "Profil Git" --menu "Choisissez un profil" 20 70 10 \
        "minimal" "Local uniquement" \
        "complete" "Local + global + system editor" \
        "custom" "Profil personnalisé" \
        3>&1 1>&2 2>&3) || return 1
    set_profile_from_choice "$c"
}

select_profile_gui() {
    local c
    c=$(zenity --list \
        --title="Profil Git" \
        --column="Profil" --column="Description" \
        "minimal" "Local uniquement" \
        "complete" "Local + global + system editor" \
        "custom" "Profil personnalisé" \
        2>/dev/null) || return 1
    set_profile_from_choice "$c"
}

select_profile_gum() {
    local c
    c=$(printf "minimal\ncomplete\ncustom\n" | gum choose --header "Choisissez un profil Git") || return 1
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
}

# ---------------------------------------------------------------------
#  SAISIE DES INFOS UTILISATEUR
# ---------------------------------------------------------------------

prompt_value_cli() {
    local label="$1"
    local default="${2:-}"
    local var
    if [[ -n "$default" ]]; then
        read -r -p "$label [$default] : " var || true
        echo "${var:-$default}"
    else
        read -r -p "$label : " var || true
        echo "$var"
    fi
}

prompt_value_gum() {
    local label="$1"
    local default="${2:-}"
    if [[ -n "$default" ]]; then
        gum input --placeholder "$label" --value "$default" || echo "$default"
    else
        gum input --placeholder "$label" || echo ""
    fi
}

prompt_value_gui() {
    local label="$1"
    local default="${2:-}"
    zenity --entry --title="Git config" --text="$label" --entry-text="$default" 2>/dev/null || echo "$default"
}

prompt_value_tui() {
    local label="$1"
    local default="${2:-}"
    whiptail --inputbox "$label" 10 70 "$default" 3>&1 1>&2 2>&3 || echo "$default"
}

prompt_value() {
    local label="$1"
    local default="${2:-}"
    if has_gum; then
        prompt_value_gum "$label" "$default"
    elif has_gui; then
        prompt_value_gui "$label" "$default"
    elif has_tui; then
        prompt_value_tui "$label" "$default"
    else
        prompt_value_cli "$label" "$default"
    fi
}

# ---------------------------------------------------------------------
#  WRAPPERS GIT CONFIG + ROLLBACK
# ---------------------------------------------------------------------

git_config_with_rollback() {
    local scope="$1"   # local | global | system
    local key="$2"
    local value="$3"

    local cmd_get="git config"
    local cmd_set="git config"
    case "$scope" in
        local)  cmd_get="git config --local";  cmd_set="git config --local" ;;
        global) cmd_get="git config --global"; cmd_set="git config --global" ;;
        system) cmd_get="sudo git config --system"; cmd_set="sudo git config --system" ;;
    esac

    local old
    old="$($cmd_get "$key" 2>/dev/null || true)"

    if [[ -n "$old" ]]; then
        add_rollback_action "$cmd_set \"$key\" \"${old//\"/\\\"}\""
    else
        add_rollback_action "$cmd_get --unset \"$key\" || true"
    fi

    info "git ($scope) : $key = $value"
    run "$cmd_set \"$key\" \"$value\""
}

git_remote_set_url_with_rollback() {
    local name="$1"
    local url="$2"

    local old
    old="$(git remote get-url "$name" 2>/dev/null || true)"

    if [[ -n "$old" ]]; then
        add_rollback_action "git remote set-url \"$name\" \"$old\""
    else
        add_rollback_action "git remote remove \"$name\" || true"
    fi

    info "git remote $name -> $url"
    run "git remote set-url \"$name\" \"$url\""
}

# ---------------------------------------------------------------------
#  CONFIGURATION SELON PROFIL
# ---------------------------------------------------------------------

configure_git_minimal() {
    info "Configuration Git (profil minimal : local uniquement)…"

    run_hooks "pre_config"

    local current_name current_email
    current_name="$(git config --local user.name 2>/dev/null || git config --global user.name 2>/dev/null || echo "")"
    current_email="$(git config --local user.email 2>/dev/null || git config --global user.email 2>/dev/null || echo "")"

    local name email remote
    name="$(prompt_value "Nom Git (user.name)" "$current_name")"
    email="$(prompt_value "Email Git (user.email)" "$current_email")"

    local default_remote="git@github.com:${USER}/${PROJECT_NAME}.git"
    remote="$(prompt_value "URL remote origin" "$default_remote")"

    git_config_with_rollback local user.name  "$name"
    git_config_with_rollback local user.email "$email"
    git_config_with_rollback local pull.rebase false
    git_config_with_rollback local push.default simple

    git_remote_set_url_with_rollback origin "$remote"

    run_hooks "post_config"
    success "Configuration Git (minimal) appliquée."
}

configure_git_complete() {
    info "Configuration Git (profil complet : local + global + system)…"

    run_hooks "pre_config"

    local current_name current_email
    current_name="$(git config --global user.name 2>/dev/null || echo "")"
    current_email="$(git config --global user.email 2>/dev/null || echo "")"

    local name email remote
    name="$(prompt_value "Nom Git global (user.name)" "$current_name")"
    email="$(prompt_value "Email Git global (user.email)" "$current_email")"

    local default_remote="git@github.com:${USER}/${PROJECT_NAME}.git"
    remote="$(prompt_value "URL remote origin" "$default_remote")"

    # Local
    git_config_with_rollback local  user.name  "$name"
    git_config_with_rollback local  user.email "$email"
    git_config_with_rollback local  pull.rebase false
    git_config_with_rollback local  push.default simple

    # Global
    git_config_with_rollback global user.name  "$name"
    git_config_with_rollback global user.email "$email"
    git_config_with_rollback global pull.rebase false
    git_config_with_rollback global push.default simple

    # System editor
    git_config_with_rollback system core.editor "nano"

    git_remote_set_url_with_rollback origin "$remote"

    run_hooks "post_config"
    success "Configuration Git (complète) appliquée."
}

configure_git_custom() {
    info "Configuration Git (profil custom)…"

    run_hooks "pre_config"

    # Choix des scopes
    local do_local=true
    local do_global=false
    local do_system=false

    # Simple : on demande via prompts
    local ans
    ans="$(prompt_value "Configurer scope local ? (y/n)" "y")"
    [[ "$ans" =~ ^[Yy] ]] || do_local=false

    ans="$(prompt_value "Configurer scope global ? (y/n)" "n")"
    [[ "$ans" =~ ^[Yy] ]] && do_global=true

    ans="$(prompt_value "Configurer core.editor au niveau system ? (y/n)" "n")"
    [[ "$ans" =~ ^[Yy] ]] && do_system=true

    local current_name current_email
    current_name="$(git config --global user.name 2>/dev/null || echo "")"
    current_email="$(git config --global user.email 2>/dev/null || echo "")"

    local name email remote
    name="$(prompt_value "Nom Git (user.name)" "$current_name")"
    email="$(prompt_value "Email Git (user.email)" "$current_email")"

    local default_remote="git@github.com:${USER}/${PROJECT_NAME}.git"
    remote="$(prompt_value "URL remote origin" "$default_remote")"

    if [[ "$do_local" == true ]]; then
        git_config_with_rollback local  user.name  "$name"
        git_config_with_rollback local  user.email "$email"
        git_config_with_rollback local  pull.rebase false
        git_config_with_rollback local  push.default simple
    fi

    if [[ "$do_global" == true ]]; then
        git_config_with_rollback global user.name  "$name"
        git_config_with_rollback global user.email "$email"
        git_config_with_rollback global pull.rebase false
        git_config_with_rollback global push.default simple
    fi

    if [[ "$do_system" == true ]]; then
        git_config_with_rollback system core.editor "nano"
    fi

    git_remote_set_url_with_rollback origin "$remote"

    run_hooks "post_config"
    success "Configuration Git (custom) appliquée."
}

configure_git() {
    select_profile
    case "$PROFILE" in
        minimal)  configure_git_minimal ;;
        complete) configure_git_complete ;;
        custom)   configure_git_custom ;;
    esac
}

# ---------------------------------------------------------------------
#  MENUS (CLI / TUI / GUM / GUI)
# ---------------------------------------------------------------------

menu_cli() {
    while true; do
        echo ""
        echo -e "${BLUE}Menu Git Project (CLI)${RESET}"
        echo "1) Configurer Git (profil)"
        echo "2) Afficher la config locale"
        echo "3) Afficher la config globale"
        echo "4) Logs"
        echo "5) Quitter"
        read -r -p "Choix : " c
        case "$c" in
            1) configure_git ;;
            2) git config --local --list || echo "Pas de config locale." ;;
            3) git config --global --list || echo "Pas de config globale." ;;
            4) less "$LOG_FILE" ;;
            5) break ;;
            *) echo "Choix invalide." ;;
        esac
    done
}

menu_tui() {
    while true; do
        local c
        c=$(whiptail --title "Git Project" --menu "Choisissez une action" 20 70 10 \
            "1" "Configurer Git (profil)" \
            "2" "Afficher config locale" \
            "3" "Afficher config globale" \
            "4" "Afficher logs" \
            "5" "Quitter" \
            3>&1 1>&2 2>&3) || return 0

        case "$c" in
            1) configure_git ;;
            2) whiptail --textbox <(git config --local --list 2>/dev/null || echo "Pas de config locale.") 30 100 ;;
            3) whiptail --textbox <(git config --global --list 2>/dev/null || echo "Pas de config globale.") 30 100 ;;
            4) whiptail --textbox "$LOG_FILE" 30 100 ;;
            5) break ;;
        esac
    done
}

menu_gum() {
    while true; do
        local c
        c=$(printf "Configurer Git (profil)\nAfficher config locale\nAfficher config globale\nLogs\nQuitter\n" \
            | gum choose --header "Git Project") || return 0

        case "$c" in
            "Configurer Git (profil)") configure_git ;;
            "Afficher config locale")  git config --local --list || echo "Pas de config locale." ;;
            "Afficher config globale") git config --global --list || echo "Pas de config globale." ;;
            "Logs")                    less "$LOG_FILE" ;;
            "Quitter")                 break ;;
        esac
    done
}

menu_gui() {
    while true; do
        local c
        c=$(zenity --list \
            --title="Git Project" \
            --column="Action" --column="Description" \
            "config" "Configurer Git (profil)" \
            "local"  "Afficher config locale" \
            "global" "Afficher config globale" \
            "log"    "Afficher logs" \
            "quit"   "Quitter" \
            2>/dev/null) || return 0

        case "$c" in
            config) configure_git ;;
            local)  zenity --text-info --title="Config locale"  --width=800 --height=600 --filename=<(git config --local --list 2>/dev/null || echo "Pas de config locale.") ;;
            global) zenity --text-info --title="Config globale" --width=800 --height=600 --filename=<(git config --global --list 2>/dev/null || echo "Pas de config globale.") ;;
            log)    zenity --text-info --title="Logs"           --width=800 --height=600 --filename="$LOG_FILE" ;;
            quit)   break ;;
        esac
    done
}

# ---------------------------------------------------------------------
#  MAIN
# ---------------------------------------------------------------------

main() {
    init_logging
    info "Démarrage ${SCRIPT_NAME} v${VERSION}"

    check_requirements
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

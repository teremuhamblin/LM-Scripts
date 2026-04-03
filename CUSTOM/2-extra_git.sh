#!/usr/bin/env bash
#
# =====================================================================
#  LM-Scripts — install_git_plugins_and_config.sh
#  Configuration Git + Installation des plugins Git modernes
#  - Profils : minimal / complet / custom
#  - Plugins Git : gh, glab, hub, delta, lazygit, git-extras, pre-commit
#  - Providers : GitHub / GitLab / Codeberg (via plugins)
#  - Profils avancés : DEV / OPS / SECURE (via plugins)
#  - Interfaces : GUI (zenity), TUI (gum, whiptail), CLI
#  - Hooks : pre/post_config, pre/post_plugins
#  - Rollback : restauration des anciennes valeurs git config
# =====================================================================

set -o errexit
set -o pipefail
set -o nounset

# ---------------------------------------------------------------------
#  MÉTADONNÉES & CHEMINS
# ---------------------------------------------------------------------

SCRIPT_NAME="install_git_plugins_and_config"
VERSION="5.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LM_SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null || echo "${SCRIPT_DIR}")"

LOG_DIR="/var/log/lm-scripts"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

DRY_RUN=false
DEBUG=false

HOOKS_DIR="${SCRIPT_DIR}/hooks"
PLUGINS_DIR="${SCRIPT_DIR}/plugins/git"

ROLLBACK_ACTIONS=()
PROFILE="complete"   # minimal | complete | custom

PROJECT_NAME=""
PROJECT_ROOT=""

# Flags potentiels exposés par les plugins
PROFILE_DEV_ENABLED=false
PROFILE_OPS_ENABLED=false
PROFILE_SECURE_ENABLED=false

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
#  PROMPTS GÉNÉRIQUES
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
#  PLUGINS
# ---------------------------------------------------------------------

load_plugins() {
    [[ ! -d "$PLUGINS_DIR" ]] && return 0

    info "Chargement des plugins Git…"

    for plugin in "$PLUGINS_DIR"/*.sh; do
        [[ -f "$plugin" ]] || continue
        info "Plugin : $plugin"
        # shellcheck disable=SC1090
        source "$plugin"
    done
}

# ---------------------------------------------------------------------
#  PACK DE PLUGINS GIT (INSTALLATION)
# ---------------------------------------------------------------------

GIT_PLUGIN_PACK=(
    gh
    glab
    hub
    delta
    lazygit
    git-extras
    pre-commit
)

install_git_plugins() {
    info "Installation du pack complet de plugins Git…"

    run_hooks "pre_plugins"

    run "sudo apt-get update"
    run "sudo apt-get install -y --no-install-recommends \
        gh glab hub git-delta lazygit git-extras pre-commit"

    run_hooks "post_plugins"

    success "Plugins Git installés."
}

verify_git_plugins() {
    info "Vérification des plugins Git…"

    local ok=true

    for p in "${GIT_PLUGIN_PACK[@]}"; do
        if command -v "$p" &>/dev/null; then
            info "OK : $p"
        else
            warn "Manquant : $p"
            ok=false
        fi
    done

    if [[ "$ok" == true ]]; then
        success "Tous les plugins Git sont installés."
    else
        warn "Certains plugins Git sont manquants."
    fi
}

# ---------------------------------------------------------------------
#  VÉRIFICATIONS DE BASE
# ---------------------------------------------------------------------

check_requirements() {
    if ! command -v git &>/dev/null; then
        error "git n’est pas installé."
        exit 1
    fi

    if git rev-parse --is-inside-work-tree &>/dev/null; then
        PROJECT_ROOT="$(git rev-parse --show-toplevel)"
        PROJECT_NAME="$(basename "$PROJECT_ROOT")"
        info "Projet détecté : $PROJECT_NAME ($PROJECT_ROOT)"
    else
        PROJECT_ROOT=""
        PROJECT_NAME=""
        info "Aucun dépôt Git détecté (mode global uniquement)."
    fi
}

# ---------------------------------------------------------------------
#  PROFILS GIT
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
    echo -e "${BLUE}Choix du profil Git${RESET}"
    echo "1) Minimal"
    echo "2) Complet"
    echo "3) Custom"
    read -r -p "Choix [1-3] : " c
    case "$c" in
        1) set_profile_from_choice "minimal" ;;
        3) set_profile_from_choice "custom" ;;
        *) set_profile_from_choice "complete" ;;
    esac
}

select_profile() {
    if has_gum; then
        PROFILE=$(printf "minimal\ncomplete\ncustom\n" | gum choose --header "Choisissez un profil Git") || PROFILE="complete"
    elif has_gui; then
        PROFILE=$(zenity --list --title="Profil Git" --column="Profil" minimal complete custom 2>/dev/null) || PROFILE="complete"
    elif has_tui; then
        PROFILE=$(whiptail --title "Profil Git" --menu "Choisissez un profil" 20 70 10 \
            "minimal" "Local uniquement" \
            "complete" "Local + global + system" \
            "custom" "Personnalisé" \
            3>&1 1>&2 2>&3) || PROFILE="complete"
    else
        select_profile_cli
    fi
    info "Profil sélectionné : $PROFILE"
}

# ---------------------------------------------------------------------
#  WRAPPERS GIT CONFIG + ROLLBACK
# ---------------------------------------------------------------------

git_config_with_rollback() {
    local scope="$1" key="$2" value="$3"

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
    local name="$1" url="$2"

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
#  PROVIDERS & REMOTE AUTO
# ---------------------------------------------------------------------

select_provider() {
    local provider
    if has_gum; then
        provider=$(printf "github\ngitlab\ncodeberg\ncustom\n" | gum choose --header "Choisissez un provider") || provider="github"
    elif has_gui; then
        provider=$(zenity --list --title="Provider Git" --column="Provider" github gitlab codeberg custom 2>/dev/null) || provider="github"
    elif has_tui; then
        provider=$(whiptail --title "Provider Git" --menu "Choisissez un provider" 20 70 10 \
            "github"  "GitHub" \
            "gitlab"  "GitLab" \
            "codeberg" "Codeberg" \
            "custom"  "Saisir une URL manuelle" \
            3>&1 1>&2 2>&3) || provider="github"
    else
        read -r -p "Provider [github/gitlab/codeberg/custom] (defaut: github) : " provider || provider="github"
        provider="${provider:-github}"
    fi
    echo "$provider"
}

generate_remote_url() {
    local provider="$1"
    local user="$2"
    local repo="$3"

    if [[ "$provider" == "custom" ]]; then
        prompt_value "URL remote origin" "git@github.com:${user}/${repo}.git"
        return
    fi

    if declare -f generate_remote_auto >/dev/null; then
        local url
        url="$(generate_remote_auto "$provider" "$user" "$repo")"
        if [[ -n "$url" ]]; then
            echo "$url"
            return
        fi
    fi

    case "$provider" in
        github)   echo "git@github.com:${user}/${repo}.git" ;;
        gitlab)   echo "git@gitlab.com:${user}/${repo}.git" ;;
        codeberg) echo "git@codeberg.org:${user}/${repo}.git" ;;
        *)        echo "git@github.com:${user}/${repo}.git" ;;
    esac
}

# ---------------------------------------------------------------------
#  CONFIGURATION GIT (PROFILS DE BASE)
# ---------------------------------------------------------------------

configure_git_minimal() {
    info "Configuration Git (minimal)…"

    run_hooks "pre_config"

    local name email remote provider user repo
    name="$(git config user.name || echo "$USER")"
    email="$(git config user.email || echo "$USER@example.com")"

    user="$(prompt_value "Nom de compte (provider)" "$USER")"
    repo="${PROJECT_NAME:-example-repo}"
    provider="$(select_provider)"
    remote="$(generate_remote_url "$provider" "$user" "$repo")"

    git_config_with_rollback local user.name "$name"
    git_config_with_rollback local user.email "$email"
    git_config_with_rollback local pull.rebase false
    git_config_with_rollback local push.default simple

    if [[ -n "$PROJECT_ROOT" ]]; then
        git_remote_set_url_with_rollback origin "$remote"
    fi

    run_hooks "post_config"
    success "Configuration Git (minimal) appliquée."
}

configure_git_complete() {
    info "Configuration Git (complète)…"

    run_hooks "pre_config"

    local name email remote provider user repo
    name="$(git config --global user.name || echo "$USER")"
    email="$(git config --global user.email || echo "$USER@example.com")"

    user="$(prompt_value "Nom de compte (provider)" "$USER")"
    repo="${PROJECT_NAME:-example-repo}"
    provider="$(select_provider)"
    remote="$(generate_remote_url "$provider" "$user" "$repo")"

    git_config_with_rollback local  user.name "$name"
    git_config_with_rollback local  user.email "$email"
    git_config_with_rollback local  pull.rebase false
    git_config_with_rollback local  push.default simple

    git_config_with_rollback global user.name "$name"
    git_config_with_rollback global user.email "$email"
    git_config_with_rollback global pull.rebase false
    git_config_with_rollback global push.default simple

    git_config_with_rollback system core.editor "nano"

    if [[ -n "$PROJECT_ROOT" ]]; then
        git_remote_set_url_with_rollback origin "$remote"
    fi

    run_hooks "post_config"
    success "Configuration Git (complète) appliquée."
}

configure_git_custom() {
    info "Configuration Git (custom)…"

    run_hooks "pre_config"

    local name email remote provider user repo
    name="$(git config --global user.name || echo "$USER")"
    email="$(git config --global user.email || echo "$USER@example.com")"

    name="$(prompt_value "Nom Git" "$name")"
    email="$(prompt_value "Email Git" "$email")"

    user="$(prompt_value "Nom de compte (provider)" "$USER")"
    repo="${PROJECT_NAME:-example-repo}"
    provider="$(select_provider)"
    remote="$(generate_remote_url "$provider" "$user" "$repo")"

    git_config_with_rollback local user.name "$name"
    git_config_with_rollback local user.email "$email"

    if [[ -n "$PROJECT_ROOT" ]]; then
        git_remote_set_url_with_rollback origin "$remote"
    fi

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
#  PROFILS AVANCÉS (DEV / OPS / SECURE) VIA PLUGINS
# ---------------------------------------------------------------------

apply_profile_dev() {
    if declare -f configure_git_profile_dev >/dev/null; then
        configure_git_profile_dev
        success "Profil DEV appliqué."
    else
        warn "Profil DEV non disponible (plugin manquant)."
    fi
}

apply_profile_ops() {
    if declare -f configure_git_profile_ops >/dev/null; then
        configure_git_profile_ops
        success "Profil OPS appliqué."
    else
        warn "Profil OPS non disponible (plugin manquant)."
    fi
}

apply_profile_secure() {
    if declare -f configure_git_profile_secure >/dev/null; then
        configure_git_profile_secure
        success "Profil SECURE appliqué."
    else
        warn "Profil SECURE non disponible (plugin manquant)."
    fi
}

# ---------------------------------------------------------------------
#  MENUS (CLI / TUI / GUM / GUI)
# ---------------------------------------------------------------------

menu_cli() {
    while true; do
        echo ""
        echo -e "${BLUE}Menu Git (CLI)${RESET}"
        echo "1) Installer plugins Git"
        echo "2) Configurer Git (profil)"
        echo "3) Vérifier plugins"
        echo "4) Appliquer profil DEV"
        echo "5) Appliquer profil OPS"
        echo "6) Appliquer profil SECURE"
        echo "7) Logs"
        echo "8) Quitter"
        read -r -p "Choix : " c
        case "$c" in
            1) install_git_plugins ;;
            2) configure_git ;;
            3) verify_git_plugins ;;
            4) apply_profile_dev ;;
            5) apply_profile_ops ;;
            6) apply_profile_secure ;;
            7) less "$LOG_FILE" ;;
            8) break ;;
        esac
    done
}

menu_tui() {
    while true; do
        local c
        c=$(whiptail --title "Git Project" --menu "Choisissez une action" 20 70 10 \
            "1" "Installer plugins Git" \
            "2" "Configurer Git (profil)" \
            "3" "Vérifier plugins" \
            "4" "Appliquer profil DEV" \
            "5" "Appliquer profil OPS" \
            "6" "Appliquer profil SECURE" \
            "7" "Afficher logs" \
            "8" "Quitter" \
            3>&1 1>&2 2>&3) || return 0

        case "$c" in
            1) install_git_plugins ;;
            2) configure_git ;;
            3) verify_git_plugins ;;
            4) apply_profile_dev ;;
            5) apply_profile_ops ;;
            6) apply_profile_secure ;;
            7) whiptail --textbox "$LOG_FILE" 30 100 ;;
            8) break ;;
        esac
    done
}

menu_gum() {
    while true; do
        local c
        c=$(printf "Installer plugins Git\nConfigurer Git (profil)\nVérifier plugins\nAppliquer profil DEV\nAppliquer profil OPS\nAppliquer profil SECURE\nLogs\nQuitter\n" \
            | gum choose --header "Git Project") || return 0

        case "$c" in
            "Installer plugins Git")      install_git_plugins ;;
            "Configurer Git (profil)")    configure_git ;;
            "Vérifier plugins")           verify_git_plugins ;;
            "Appliquer profil DEV")       apply_profile_dev ;;
            "Appliquer profil OPS")       apply_profile_ops ;;
            "Appliquer profil SECURE")    apply_profile_secure ;;
            "Logs")                       less "$LOG_FILE" ;;
            "Quitter")                    break ;;
        esac
    done
}

menu_gui() {
    while true; do
        local c
        c=$(zenity --list \
            --title="Git Project" \
            --column="Action" --column="Description" \
            "install" "Installer plugins Git" \
            "config"  "Configurer Git (profil)" \
            "verify"  "Vérifier plugins" \
            "dev"     "Appliquer profil DEV" \
            "ops"     "Appliquer profil OPS" \
            "secure"  "Appliquer profil SECURE" \
            "log"     "Afficher logs" \
            "quit"    "Quitter" \
            2>/dev/null) || return 0

        case "$c" in
            install) install_git_plugins ;;
            config)  configure_git ;;
            verify)  verify_git_plugins ;;
            dev)     apply_profile_dev ;;
            ops)     apply_profile_ops ;;
            secure)  apply_profile_secure ;;
            log)     zenity --text-info --filename="$LOG_FILE" ;;
            quit)    break ;;
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

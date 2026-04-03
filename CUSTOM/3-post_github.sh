#!/usr/bin/env bash
#
# =====================================================================
#  LM-Scripts — git_commit_push.sh
#  Workflow Git avancé : add + commit + push (main/master)
#  - Profils : minimal / complet / custom
#  - Interfaces : CLI, TUI (whiptail), TUI Gum, GUI (zenity)
#  - Hooks : pre_add, post_add, pre_commit, post_commit, pre_push, post_push
#  - Rollback : annulation du dernier commit local en cas d’échec
#  - Logs : /var/log/lm-scripts/git_commit_push.log
# =====================================================================

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_NAME="git_commit_push"
VERSION="1.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LM_SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null || echo "${SCRIPT_DIR}")"

LOG_DIR="/var/log/lm-scripts"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

HOOKS_DIR="${SCRIPT_DIR}/hooks"
DRY_RUN=false
DEBUG=false
PROFILE="complete"   # minimal | complete | custom

BRANCH=""
PROJECT_ROOT=""
PROJECT_NAME=""

ROLLBACK_ACTIONS=()

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ---------------------------------------------------------------------
# Logging
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
# Rollback
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
# Args & usage
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
# Tools detection
# ---------------------------------------------------------------------

has_gui()      { [[ -n "${DISPLAY:-}" ]] && command -v zenity &>/dev/null; }
has_tui()      { command -v whiptail &>/dev/null; }
has_gum()      { command -v gum &>/dev/null; }

# ---------------------------------------------------------------------
# Hooks
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
# Prompts
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
    zenity --entry --title="Git commit" --text="$label" --entry-text="$default" 2>/dev/null || echo "$default"
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
# Git checks
# ---------------------------------------------------------------------

check_git_repo() {
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
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"

    info "Projet : $PROJECT_NAME"
    info "Racine : $PROJECT_ROOT"
    info "Branche courante : $BRANCH"
}

detect_push_branch() {
    # Si main ou master existent dans config, on privilégie
    if grep -q "\[branch \"main\"\]" .git/config 2>/dev/null; then
        BRANCH="main"
    elif grep -q "\[branch \"master\"\]" .git/config 2>/dev/null; then
        BRANCH="master"
    else
        BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    fi
    info "Branche de push : $BRANCH"
}

# ---------------------------------------------------------------------
# Profils
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
    echo -e "${BLUE}Choix du profil Git commit/push${RESET}"
    echo "1) Minimal (add + commit + push)"
    echo "2) Complet (pull + add + commit + push + vérifs)"
    echo "3) Custom (choix fin)"
    read -r -p "Choix [1-3] : " c
    case "$c" in
        1) set_profile_from_choice "minimal" ;;
        3) set_profile_from_choice "custom" ;;
        *) set_profile_from_choice "complete" ;;
    esac
}

select_profile() {
    if has_gum; then
        PROFILE=$(printf "minimal\ncomplete\ncustom\n" | gum choose --header "Choisissez un profil") || PROFILE="complete"
    elif has_gui; then
        PROFILE=$(zenity --list --title="Profil Git" --column="Profil" minimal complete custom 2>/dev/null) || PROFILE="complete"
    elif has_tui; then
        PROFILE=$(whiptail --title "Profil Git" --menu "Choisissez un profil" 20 70 10 \
            "minimal" "add + commit + push" \
            "complete" "pull + add + commit + push" \
            "custom" "Personnalisé" \
            3>&1 1>&2 2>&3) || PROFILE="complete"
    else
        select_profile_cli
    fi
    info "Profil sélectionné : $PROFILE"
}

# ---------------------------------------------------------------------
# Core actions
# ---------------------------------------------------------------------

git_pull_if_needed() {
    if [[ "$PROFILE" == "complete" ]]; then
        info "Mise à jour depuis le remote (git pull)…"
        run "git pull --ff-only"
    fi
}

git_add_all() {
    run_hooks "pre_add"
    info "Ajout de tous les fichiers (git add --all .)…"
    run "git add --all ."
    run_hooks "post_add"
}

git_commit_with_message() {
    run_hooks "pre_commit"

    local default_msg="Update $(date '+%Y-%m-%d %H:%M:%S')"
    local msg
    msg="$(prompt_value 'Message de commit' "$default_msg")"

    if [[ -z "$msg" ]]; then
        warn "Message vide, utilisation du message par défaut."
        msg="$default_msg"
    fi

    # On prépare un rollback : annuler le dernier commit si besoin
    local before_commit
    before_commit="$(git rev-parse HEAD 2>/dev/null || echo "")"
    if [[ -n "$before_commit" ]]; then
        add_rollback_action "git reset --hard ${before_commit}"
    fi

    info "Commit avec message : $msg"
    run "git commit -m \"$msg\""

    run_hooks "post_commit"
}

git_push_branch() {
    run_hooks "pre_push"

    detect_push_branch

    info "Push vers origin/$BRANCH…"
    run "git push -u origin \"$BRANCH\""

    run_hooks "post_push"
}

# ---------------------------------------------------------------------
# High-level workflows
# ---------------------------------------------------------------------

workflow_minimal() {
    git_add_all
    git_commit_with_message
    git_push_branch
}

workflow_complete() {
    git_pull_if_needed
    git_add_all
    git_commit_with_message
    git_push_branch
}

workflow_custom() {
    # Simple custom : on demande si on veut pull avant
    local ans
    ans="$(prompt_value 'Effectuer un git pull avant ? (y/n)' 'y')"
    if [[ "$ans" =~ ^[Yy] ]]; then
        git_pull_if_needed
    fi
    git_add_all
    git_commit_with_message
    git_push_branch
}

run_workflow() {
    select_profile
    case "$PROFILE" in
        minimal)  workflow_minimal ;;
        complete) workflow_complete ;;
        custom)   workflow_custom ;;
    esac
}

# ---------------------------------------------------------------------
# Menus
# ---------------------------------------------------------------------

menu_cli() {
    while true; do
        echo ""
        echo -e "${BLUE}Menu Git Commit/Push (CLI)${RESET}"
        echo "1) Exécuter workflow (profil)"
        echo "2) Afficher statut git"
        echo "3) Afficher logs"
        echo "4) Quitter"
        read -r -p "Choix : " c
        case "$c" in
            1) run_workflow ;;
            2) git status ;;
            3) less "$LOG_FILE" ;;
            4) break ;;
            *) echo "Choix invalide." ;;
        esac
    done
}

menu_tui() {
    while true; do
        local c
        c=$(whiptail --title "Git Commit/Push" --menu "Choisissez une action" 20 70 10 \
            "1" "Exécuter workflow (profil)" \
            "2" "Afficher statut git" \
            "3" "Afficher logs" \
            "4" "Quitter" \
            3>&1 1>&2 2>&3) || return 0

        case "$c" in
            1) run_workflow ;;
            2) whiptail --textbox <(git status) 30 100 ;;
            3) whiptail --textbox "$LOG_FILE" 30 100 ;;
            4) break ;;
        esac
    done
}

menu_gum() {
    while true; do
        local c
        c=$(printf "Exécuter workflow (profil)\nAfficher statut git\nAfficher logs\nQuitter\n" \
            | gum choose --header "Git Commit/Push") || return 0

        case "$c" in
            "Exécuter workflow (profil)") run_workflow ;;
            "Afficher statut git")        git status | less ;;
            "Afficher logs")              less "$LOG_FILE" ;;
            "Quitter")                    break ;;
        esac
    done
}

menu_gui() {
    while true; do
        local c
        c=$(zenity --list \
            --title="Git Commit/Push" \
            --column="Action" --column="Description" \
            "run"  "Exécuter workflow (profil)" \
            "stat" "Afficher statut git" \
            "log"  "Afficher logs" \
            "quit" "Quitter" \
            2>/dev/null) || return 0

        case "$c" in
            run)  run_workflow ;;
            stat) zenity --text-info --title="git status" --width=800 --height=600 --filename=<(git status) ;;
            log)  zenity --text-info --title="Logs"       --width=800 --height=600 --filename="$LOG_FILE" ;;
            quit) break ;;
        esac
    done
}

# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

main() {
    init_logging
    info "Démarrage ${SCRIPT_NAME} v${VERSION}"

    check_git_repo

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

#!/usr/bin/env bash
#
# =====================================================================
#  LM-Scripts — ufw_hardening_suite.sh
#  Suite de configuration UFW + Hardening réseau (défensif)
# =====================================================================

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_NAME="ufw_hardening_suite"
VERSION="1.1.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LM_SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null || echo "${SCRIPT_DIR}")"

LOG_DIR="/var/log/lm-scripts"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

HOOKS_DIR="${SCRIPT_DIR}/hooks"
PLUGINS_DIR="${SCRIPT_DIR}/plugins/ufw"

DRY_RUN=false
DEBUG=false
PROFILE="basic"

ROLLBACK_ACTIONS=()

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
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" \
        | sudo tee -a "$LOG_FILE" >/dev/null
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
        eval "${ROLLBACK_ACTIONS[$i]}" || warn "Échec rollback: ${ROLLBACK_ACTIONS[$i]}"
    done
}

on_error() {
    local code=$?
    error "Erreur détectée (code $code)."
    perform_rollback
    exit "$code"
}

trap on_error ERR

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
    info "Chargement des plugins UFW…"
    for plugin in "$PLUGINS_DIR"/*.sh; do
        [[ -f "$plugin" ]] && source "$plugin"
    done
}

# ---------------------------------------------------------------------
# PROFILS
# ---------------------------------------------------------------------

select_profile_cli() {
    echo "1) Basic"
    echo "2) Strict"
    echo "3) Reinforced"
    read -r -p "Choix [1-3] : " c
    case "$c" in
        1) PROFILE="basic" ;;
        2) PROFILE="strict" ;;
        3) PROFILE="reinforced" ;;
        *) PROFILE="basic" ;;
    esac
}

select_profile() {
    if has_gum; then
        PROFILE=$(printf "basic\nstrict\nreinforced\n" | gum choose --header "Choisissez un profil") || PROFILE="basic"
    elif has_gui; then
        PROFILE=$(zenity --list --title="Profil UFW" --column="Profil" basic strict reinforced 2>/dev/null) || PROFILE="basic"
    elif has_tui; then
        PROFILE=$(whiptail --title "Profil UFW" --menu "Choisissez un profil" 20 70 10 \
            "basic" "Firewall standard" \
            "strict" "Ports essentiels uniquement" \
            "reinforced" "Hardening maximal" \
            3>&1 1>&2 2>&3) || PROFILE="basic"
    else
        select_profile_cli
    fi

    info "Profil sélectionné : $PROFILE"
}

# ---------------------------------------------------------------------
# SYSCTL HARDENING
# ---------------------------------------------------------------------

apply_sysctl_hardening() {
    info "Application du hardening sysctl…"

    local sysctl_file="/etc/sysctl.d/99-lmscripts-hardening.conf"

    add_rollback_action "sudo rm -f $sysctl_file"

    sudo tee "$sysctl_file" >/dev/null <<EOF
# Hardening réseau défensif
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1

net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
EOF

    run "sudo sysctl --system"
}

# ---------------------------------------------------------------------
# SERVICES
# ---------------------------------------------------------------------

disable_unneeded_services() {
    info "Désactivation des services réseau non essentiels…"

    for svc in avahi-daemon cups smbd nmbd; do
        if systemctl is-enabled "$svc" &>/dev/null; then
            add_rollback_action "sudo systemctl enable $svc"
            run "sudo systemctl disable --now $svc"
        fi
    done
}

# ---------------------------------------------------------------------
# UFW RULESETS
# ---------------------------------------------------------------------

reset_ufw() {
    info "Réinitialisation UFW…"
    add_rollback_action "sudo ufw reset"
    run "sudo ufw --force reset"
}

apply_ufw_basic() {
    info "Application du profil BASIC…"

    run "sudo ufw default deny incoming"
    run "sudo ufw default allow outgoing"

    run "sudo ufw limit 22/tcp"

    run "sudo ufw allow out 53"
    run "sudo ufw allow out 80"
    run "sudo ufw allow out 443"
    run "sudo ufw allow out 123"

    run "sudo ufw enable"
}

apply_ufw_strict() {
    info "Application du profil STRICT…"

    run "sudo ufw default deny incoming"
    run "sudo ufw default allow outgoing"

    run "sudo ufw limit 22/tcp"

    run "sudo ufw allow out 53"
    run "sudo ufw allow out 80"
    run "sudo ufw allow out 443"
    run "sudo ufw allow out 123"

    run "sudo ufw enable"
}

apply_ufw_reinforced() {
    info "Application du profil REINFORCED…"

    run "sudo ufw default deny incoming"
    run "sudo ufw default deny outgoing"

    run "sudo ufw limit 22/tcp"
    run "sudo ufw limit out 22/tcp"

    run "sudo ufw allow out 53"
    run "sudo ufw allow out 443"

    run "sudo ufw enable"
}

apply_ufw_profile() {
    case "$PROFILE" in
        basic)      apply_ufw_basic ;;
        strict)     apply_ufw_strict ;;
        reinforced) apply_ufw_reinforced ;;
    esac
}

# ---------------------------------------------------------------------
# WORKFLOW
# ---------------------------------------------------------------------

apply_full_hardening() {
    select_profile
    run_hooks "pre_apply"

    reset_ufw
    apply_sysctl_hardening
    disable_unneeded_services
    apply_ufw_profile

    run_hooks "post_apply"
    success "Configuration UFW + Hardening appliquée."
}

# ---------------------------------------------------------------------
# MENUS
# ---------------------------------------------------------------------

menu_cli() {
    while true; do
        echo "1) Appliquer configuration"
        echo "2) Voir statut UFW"
        echo "3) Voir logs"
        echo "4) Quitter"
        read -r -p "Choix : " c
        case "$c" in
            1) apply_full_hardening ;;
            2) sudo ufw status verbose ;;
            3) less "$LOG_FILE" ;;
            4) break ;;
        esac
    done
}

menu_tui() {
    while true; do
        local c
        c=$(whiptail --title "UFW Hardening Suite" --menu "Choisissez une action" 20 70 10 \
            "1" "Appliquer configuration" \
            "2" "Voir statut UFW" \
            "3" "Voir logs" \
            "4" "Quitter" \
            3>&1 1>&2 2>&3) || return 0

        case "$c" in
            1) apply_full_hardening ;;
            2) whiptail --textbox <(sudo ufw status verbose) 30 100 ;;
            3) whiptail --textbox "$LOG_FILE" 30 100 ;;
            4) break ;;
        esac
    done
}

menu_gum() {
    while true; do
        local c
        c=$(printf "Appliquer configuration\nVoir statut UFW\nVoir logs\nQuitter\n" \
            | gum choose --header "UFW Hardening Suite") || return 0

        case "$c" in
            "Appliquer configuration") apply_full_hardening ;;
            "Voir statut UFW")         sudo ufw status verbose | less ;;
            "Voir logs")               less "$LOG_FILE" ;;
            "Quitter")                 break ;;
        esac
    done
}

menu_gui() {
    while true; do
        local c
        c=$(zenity --list \
            --title="UFW Hardening Suite" \
            --column="Action" --column="Description" \
            "apply" "Appliquer configuration" \
            "status" "Voir statut UFW" \
            "log" "Voir logs" \
            "quit" "Quitter" \
            2>/dev/null) || return 0

        case "$c" in
            apply)  apply_full_hardening ;;
            status) zenity --text-info --filename=<(sudo ufw status verbose) ;;
            log)    zenity --text-info --filename="$LOG_FILE" ;;
            quit)   break ;;
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

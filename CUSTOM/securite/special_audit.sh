#!/usr/bin/env bash
#
# =====================================================================
#  audit.sh — Audit défensif UFW & réseau pour Linux Mint
#
#  Caractéristiques :
#    - Lecture seule (aucune modification)
#    - Audit UFW (statut, règles)
#    - Audit sysctl (paramètres réseau sensibles)
#    - Audit services réseau (SSH, CUPS, Avahi, Samba)
#    - Audit ports ouverts (ss -tulpen)
#    - Audit IPv6
#    - Audit journaux UFW
#    - Rapport complet dans /tmp + affichage
#    - UI : CLI / gum / whiptail / zenity
#
#  Usage :
#    ./audit.sh
#    ./audit.sh --no-gui
# =====================================================================

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_NAME="audit"
VERSION="1.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_DIR="/var/log/lm-scripts"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"

USE_GUI=true
USE_TUI=true
USE_GUM=true

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

# ---------------------------------------------------------------------
# DETECTION OUTILS
# ---------------------------------------------------------------------

has_gui()      { [[ "$USE_GUI" == true ]] && [[ -n "${DISPLAY:-}" ]] && command -v zenity &>/dev/null; }
has_tui()      { [[ "$USE_TUI" == true ]] && command -v whiptail &>/dev/null; }
has_gum()      { [[ "$USE_GUM" == true ]] && command -v gum &>/dev/null; }

# ---------------------------------------------------------------------
# ARGUMENTS
# ---------------------------------------------------------------------

usage() {
    echo "${SCRIPT_NAME} v${VERSION}"
    echo "Audit défensif UFW & réseau (lecture seule)."
    echo
    echo "Options :"
    echo "  --no-gui   Désactive zenity"
    echo "  --no-tui   Désactive whiptail"
    echo "  --no-gum   Désactive gum"
    echo "  -h, --help Affiche cette aide"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-gui) USE_GUI=false ;;
        --no-tui) USE_TUI=false ;;
        --no-gum) USE_GUM=false ;;
        -h|--help) usage ;;
        *) echo "Option inconnue : $1"; usage ;;
    esac
    shift
done

# ---------------------------------------------------------------------
# AUDIT
# ---------------------------------------------------------------------

run_audit_core() {
    info "Démarrage du mode audit…"

    local report="/tmp/lmscripts_ufw_audit_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "============================================================"
        echo " LM-SCRIPTS — RAPPORT D'AUDIT UFW & HARDENING"
        echo " Date : $(date)"
        echo "============================================================"
        echo ""

        echo "------------------------------------------------------------"
        echo " 🔐 1. STATUT UFW"
        echo "------------------------------------------------------------"
        if command -v ufw &>/dev/null; then
            sudo ufw status verbose || true
        else
            echo "UFW n'est pas installé."
        fi
        echo ""

        echo "------------------------------------------------------------"
        echo " 🔐 2. RÈGLES UFW (raw)"
        echo "------------------------------------------------------------"
        if command -v ufw &>/dev/null; then
            sudo ufw show raw 2>/dev/null || echo "Impossible d'afficher les règles raw."
        else
            echo "UFW n'est pas installé."
        fi
        echo ""

        echo "------------------------------------------------------------"
        echo " 🔐 3. PORTS OUVERTS (ss -tulpen)"
        echo "------------------------------------------------------------"
        if command -v ss &>/dev/null; then
            ss -tulpen || true
        else
            echo "ss n'est pas disponible."
        fi
        echo ""

        echo "------------------------------------------------------------"
        echo " 🔐 4. SERVICES RÉSEAU ACTIFS (SSH, CUPS, Avahi, Samba)"
        echo "------------------------------------------------------------"
        if command -v systemctl &>/dev/null; then
            systemctl list-units --type=service --state=running \
                | grep -E "ssh|cups|avahi|smb|nmb" || echo "Aucun service réseau ciblé détecté."
        else
            echo "systemctl n'est pas disponible."
        fi
        echo ""

        echo "------------------------------------------------------------"
        echo " 🔐 5. PARAMÈTRES SYSCTL SENSIBLES"
        echo "------------------------------------------------------------"
        if command -v sysctl &>/dev/null; then
            sysctl net.ipv4.conf.all.rp_filter 2>/dev/null || true
            sysctl net.ipv4.tcp_syncookies 2>/dev/null || true
            sysctl net.ipv4.conf.all.accept_redirects 2>/dev/null || true
            sysctl net.ipv4.conf.all.send_redirects 2>/dev/null || true
            sysctl net.ipv4.conf.all.accept_source_route 2>/dev/null || true
            sysctl net.ipv4.conf.all.log_martians 2>/dev/null || true
        else
            echo "sysctl n'est pas disponible."
        fi
        echo ""

        echo "------------------------------------------------------------"
        echo " 🔐 6. IPV6"
        echo "------------------------------------------------------------"
        if command -v sysctl &>/dev/null; then
            sysctl net.ipv6.conf.all.accept_redirects 2>/dev/null || true
        else
            echo "sysctl n'est pas disponible."
        fi
        echo ""

        echo "------------------------------------------------------------"
        echo " 🔐 7. JOURNAUX UFW (dernier 50)"
        echo "------------------------------------------------------------"
        if [[ -f /var/log/ufw.log ]]; then
            sudo tail -n 50 /var/log/ufw.log 2>/dev/null || echo "Impossible de lire /var/log/ufw.log."
        else
            echo "Aucun journal UFW trouvé."
        fi
        echo ""

        echo "------------------------------------------------------------"
        echo " 🔐 8. INFORMATIONS SYSTÈME RÉSEAU"
        echo "------------------------------------------------------------"
        echo "Hostname : $(hostname)"
        echo "IP(s)    :"
        ip addr show 2>/dev/null | sed 's/^/  /' || echo "ip non disponible."
        echo ""

        echo "============================================================"
        echo " FIN DU RAPPORT"
        echo "============================================================"
    } | tee "$report" | sudo tee -a "$LOG_FILE" >/dev/null

    success "Audit terminé. Rapport enregistré : $report"
    echo
    echo "Résumé rapide :"
    echo "  - Rapport : $report"
    echo "  - Logs    : $LOG_FILE"
    echo
    echo "Vous pouvez consulter le rapport avec :"
    echo "  less $report"
    echo
    echo "Ce script n'a effectué AUCUNE modification système (lecture seule)."

    echo "$report"
}

# ---------------------------------------------------------------------
# UI WRAPPERS
# ---------------------------------------------------------------------

run_audit_cli() {
    local report
    report=$(run_audit_core)
    echo
    read -r -p "Voulez-vous ouvrir le rapport avec less ? [o/N] : " ans
    if [[ "${ans,,}" == "o" ]]; then
        less "$report"
    fi
}

run_audit_tui() {
    local report
    report=$(run_audit_core)
    whiptail --title "Rapport d'audit UFW" --textbox "$report" 30 100
}

run_audit_gum() {
    local report
    report=$(run_audit_core)
    printf "Ouvrir le rapport dans less\nQuitter\n" \
        | gum choose --header "Audit terminé" | while read -r choice; do
            [[ "$choice" == "Ouvrir le rapport dans less" ]] && less "$report"
        done
}

run_audit_gui() {
    local report
    report=$(run_audit_core)
    zenity --text-info --title="Rapport d'audit UFW" --filename="$report" --width=900 --height=700
}

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------

main() {
    init_logging
    info "Démarrage ${SCRIPT_NAME} v${VERSION}"

    if has_gui; then
        run_audit_gui
    elif has_gum; then
        run_audit_gum
    elif has_tui; then
        run_audit_tui
    else
        run_audit_cli
    fi

    success "Fin de l'audit."
}

main

#!/bin/bash
# =====================================================================
# LM-Scripts - Custom Module
# File      : setup_personal.sh
# Purpose   : Personal environment setup with dependency checks,
#             optional installations, logging, and multi-selection menu.
# Author    : The MadDoG.tmdg
# Version : 1.0.0
# =====================================================================

# ---------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
RESET="\e[0m"

# ---------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------
LOG_DIR="$HOME/.local/share/lm-scripts/logs"
LOG_FILE="$LOG_DIR/setup_personal_$(date +'%Y%m%d').log"

init_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE" 2>/dev/null || {
        echo -e "${RED}[ERROR] Cannot write log file: $LOG_FILE${RESET}"
        exit 1
    }
}

log_raw() {
    local level="$1"
    local msg="$2"
    local ts
    ts="$(date +'%Y-%m-%d %H:%M:%S')"
    echo "[$ts] [$level] $msg" >>"$LOG_FILE"
}

log_info() { echo -e "${GREEN}[INFO]${RESET} $1"; log_raw "INFO" "$1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; log_raw "WARN" "$1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; log_raw "ERROR" "$1"; }

log_section() {
    echo
    echo -e "${CYAN}==============================================================${RESET}"
    echo -e "${CYAN}$1${RESET}"
    echo -e "${CYAN}==============================================================${RESET}"
    echo
    log_raw "SECTION" "$1"
}

# ---------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$CUSTOM_DIR")"
PERSONAL_DIR="$CUSTOM_DIR/personal"

# ---------------------------------------------------------------------
# Dependency Management
# ---------------------------------------------------------------------

DEPENDENCIES=( "thunar" "variety" "bash" )

check_dependencies() {
    log_section "Checking dependencies"

    for dep in "${DEPENDENCIES[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            log_info "Dependency OK: $dep"
        else
            log_warn "Missing dependency: $dep"

            read -rp "Install $dep ? (y/n): " ans
            if [[ "$ans" =~ ^[Yy]$ ]]; then
                if sudo apt install -y "$dep"; then
                    log_info "Installed dependency: $dep"
                else
                    log_error "Failed to install dependency: $dep"
                fi
            else
                log_warn "Skipped installation of: $dep"
            fi
        fi
    done
}

# ---------------------------------------------------------------------
# System Update Check
# ---------------------------------------------------------------------

check_system_updates() {
    log_section "Checking for system updates"

    if ! command -v apt >/dev/null 2>&1; then
        log_warn "apt not found. Skipping update check."
        return
    fi

    sudo apt update >/dev/null 2>&1

    local upgradable
    upgradable=$(apt list --upgradeable 2>/dev/null | grep -v "Listing..." || true)

    if [ -z "$upgradable" ]; then
        log_info "System is up to date."
    else
        local count
        count=$(echo "$upgradable" | wc -l)
        log_warn "$count packages can be upgraded."
        log_raw "UPDATES" "$upgradable"

        echo
        read -rp "Do you want to install updates now? (y/n): " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            sudo apt upgrade -y
            log_info "System updated."
        else
            log_warn "Updates skipped."
        fi
    fi
}

# ---------------------------------------------------------------------
# Operations
# ---------------------------------------------------------------------

create_directories() {
    log_section "Creating personal directories"

    local dirs=(
        "$HOME/.bin"
        "$HOME/.fonts"
        "$HOME/.icons"
        "$HOME/.themes"
        "$HOME/.local/share/icons"
        "$HOME/.local/share/themes"
        "$HOME/.config"
        "$HOME/.config/gtk-3.0"
        "$HOME/.config/variety"
        "$HOME/.config/variety/scripts"
        "$HOME/DATA"
        "$HOME/Insync"
        "$HOME/Projects"
    )

    for d in "${dirs[@]}"; do
        if [ -d "$d" ]; then
            log_info "Directory exists: $d"
        else
            mkdir -p "$d" && log_info "Created: $d" || log_error "Failed: $d"
        fi
    done
}

install_thunar_config() {
    log_section "Installing Thunar configuration"

    local src="$PERSONAL_DIR/thunar/uca.xml"
    local dest="$HOME/.config/Thunar/uca.xml"

    mkdir -p "$HOME/.config/Thunar"

    if [ -f "$src" ]; then
        cp "$src" "$dest" && log_info "Installed Thunar config" || log_error "Failed to install Thunar config"
    else
        log_warn "Missing file: $src"
    fi
}

install_variety_config() {
    log_section "Installing Variety configuration"

    local base="$PERSONAL_DIR/variety"
    local conf="$base/variety.conf"
    local script="$base/set_wallpaper"

    mkdir -p "$HOME/.config/variety/scripts"

    [ -f "$conf" ] && cp "$conf" "$HOME/.config/variety/" && log_info "Variety config installed"
    [ -f "$script" ] && cp "$script" "$HOME/.config/variety/scripts/" && chmod +x "$HOME/.config/variety/scripts/set_wallpaper" && log_info "Variety script installed"
}

install_bashrc() {
    log_section "Installing .bashrc"

    local src="$PERSONAL_DIR/bash/bashrc"
    local dest="$HOME/.bashrc"

    if [ -f "$src" ]; then
        cp "$src" "$dest" && log_info ".bashrc installed" || log_error "Failed to install .bashrc"
    else
        log_warn "Missing file: $src"
    fi
}

# ---------------------------------------------------------------------
# Menu / Multi-selection
# ---------------------------------------------------------------------

show_menu() {
    echo
    echo -e "${CYAN}Select operations (comma-separated or 'all'):${RESET}"
    echo "  1) Check dependencies"
    echo "  2) Create personal directories"
    echo "  3) Install Thunar configuration"
    echo "  4) Install Variety configuration"
    echo "  5) Install .bashrc"
    echo "  6) Check system updates"
    echo
    read -rp "Your choice: " choice
    echo

    choice="$(echo "$choice" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"

    if [ "$choice" = "all" ]; then
        run_all_operations
        return
    fi

    IFS=',' read -r -a selections <<<"$choice"

    for sel in "${selections[@]}"; do
        case "$sel" in
            1) check_dependencies ;;
            2) create_directories ;;
            3) install_thunar_config ;;
            4) install_variety_config ;;
            5) install_bashrc ;;
            6) check_system_updates ;;
            *) log_warn "Unknown selection: $sel" ;;
        esac
    done
}

run_all_operations() {
    check_dependencies
    create_directories
    install_thunar_config
    install_variety_config
    install_bashrc
    check_system_updates
}

# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------
main() {
    init_logging
    log_section "LM-Scripts - Personal Setup"

    show_menu

    log_section "Setup completed"
    log_info "Log file: $LOG_FILE"
}

main "$@"

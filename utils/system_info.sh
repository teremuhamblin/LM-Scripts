#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - system_info.sh
# Affiche des informations système de base

GREEN="\e[32m"; RESET="\e[0m"

info() { echo -e "${GREEN}[INFO]${RESET} $1"; }

info "Utilisateur : $(whoami)"
info "Hôte       : $(hostname)"
info "Distribution : $(lsb_release -d 2>/dev/null | cut -f2- || echo 'N/A')"
info "Kernel       : $(uname -r)"
info "Architecture : $(uname -m)"
info "Uptime       : $(uptime -p)"
info "Mémoire      :"
free -h
info "Disques      :"
df -h /

#!/usr/bin/env bash
set -euo pipefail

# LM-Scripts - benchmark.sh
# Petit benchmark CPU / disque très simple

GREEN="\e[32m"; RESET="\e[0m"
info() { echo -e "${GREEN}[INFO]${RESET} $1"; }

info "Test CPU (calcul de PI avec bc)..."
time echo "scale=5000; 4*a(1)" | bc -lq >/dev/null

info "Test disque (écriture/lecture sur /tmp)..."
tmpfile="/tmp/lm_scripts_bench"
dd if=/dev/zero of="$tmpfile" bs=1M count=256 conv=fdatasync status=none
dd if="$tmpfile" of=/dev/null bs=1M status=none
rm -f "$tmpfile"

info "Benchmark terminé."

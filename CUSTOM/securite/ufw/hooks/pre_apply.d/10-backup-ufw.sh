#!/usr/bin/env bash
info "[HOOK] Sauvegarde des règles UFW"
sudo cp /etc/ufw/user.rules /etc/ufw/user.rules.bak 2>/dev/null || true

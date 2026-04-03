#!/usr/bin/env bash
info "[PLUGIN] Règles personnalisées UFW chargées"
# Exemple défensif :
sudo ufw deny 23/tcp
sudo ufw deny 445/tcp
sudo ufw deny 137:139/udp

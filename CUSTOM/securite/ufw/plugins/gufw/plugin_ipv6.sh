#!/usr/bin/env bash
info "[PLUGIN] Activation IPv6 UFW"
sudo sed -i 's/IPV6=no/IPV6=yes/' /etc/default/ufw

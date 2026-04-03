#!/usr/bin/env bash
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté avec sudo."
    exit 1
fi

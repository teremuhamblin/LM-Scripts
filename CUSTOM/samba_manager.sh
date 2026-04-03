#!/usr/bin/env bash
#
# LM-Scripts — Module custom : Gestion avancée de Samba
#
# - Menu interactif complet
# - Installation des dépendances Samba
# - Sauvegarde et génération guidée de smb.conf
# - Validation de la configuration
# - Création de partage
# - Gestion des services
# - Rollback en cas de problème
#

set -euo pipefail

############################################
# Chargement du framework LM-Scripts
############################################
# shellcheck disable=SC1091
source "$LM_SCRIPTS_CORE/logging.sh"
source "$LM_SCRIPTS_CORE/utils.sh"

SCRIPT_NAME="$(basename "$0")"

BACKUP_DIR="/var/backups/lm-scripts/samba"
ROLLBACK_SMB_CONF=""
ROLLBACK_CREATED_DIR=""

############################################
# Dépendances Samba
############################################
SAMBAPACKAGES=(
  samba
  samba-common
  samba-common-bin
  smbclient
  cifs-utils
)

############################################
# Prérequis
############################################
check_requirements() {
    require_root

    check_command apt-get "Le gestionnaire APT est requis."
    check_command systemctl "systemd est requis pour gérer les services."
    # testparm est fourni par samba-common-bin
}

############################################
# Installation des dépendances
############################################
install_dependencies() {
    log_header "Installation / vérification des dépendances Samba"

    run_cmd apt-get update -y

    for pkg in "${SAMBAPACKAGES[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            log_info "Paquet déjà installé : $pkg"
        else
            log_info "Installation du paquet : $pkg"
            run_cmd apt-get install -y "$pkg"
        fi
    done

    check_command testparm "testparm est requis pour valider la configuration Samba."
    log_success "Dépendances Samba installées / vérifiées."
}

############################################
# Sauvegarde de smb.conf
############################################
backup_smb_conf() {
    local smb_conf="/etc/samba/smb.conf"

    if [[ ! -f "$smb_conf" ]]; then
        log_warn "Aucun fichier smb.conf existant. Pas de sauvegarde."
        return
    fi

    mkdir -p "$BACKUP_DIR"

    local timestamp
    timestamp="$(date +'%Y%m%d-%H%M%S')"
    local backup="${BACKUP_DIR}/smb.conf.${timestamp}.bak"

    log_info "Sauvegarde de $smb_conf → $backup"
    run_cmd cp -a "$smb_conf" "$backup"

    ROLLBACK_SMB_CONF="$backup"
    log_success "Sauvegarde effectuée : $backup"
}

############################################
# Génération guidée de smb.conf
############################################
prompt_samba_settings() {
    local default_workgroup="WORKGROUP"
    local default_share_name="shared"
    local default_share_path="$HOME/SHARED"

    read -r -p "Nom du workgroup [$default_workgroup] : " WORKGROUP
    WORKGROUP="${WORKGROUP:-$default_workgroup}"

    read -r -p "Nom du partage [$default_share_name] : " SHARE_NAME
    SHARE_NAME="${SHARE_NAME:-$default_share_name}"

    read -r -p "Chemin du partage [$default_share_path] : " SHARE_PATH
    SHARE_PATH="${SHARE_PATH:-$default_share_path}"

    echo
    echo "Type de partage :"
    echo "  1) Accès invité (guest ok = yes, lecture/écriture)"
    echo "  2) Accès authentifié uniquement (user-level)"
    read -r -p "Choix [1/2] : " SHARE_MODE
    SHARE_MODE="${SHARE_MODE:-1}"

    SAMBA_WORKGROUP="$WORKGROUP"
    SAMBA_SHARE_NAME="$SHARE_NAME"
    SAMBA_SHARE_PATH="$SHARE_PATH"
    SAMBA_SHARE_MODE="$SHARE_MODE"
}

generate_smb_conf() {
    log_header "Génération guidée de /etc/samba/smb.conf"

    prompt_samba_settings

    local smb_conf="/etc/samba/smb.conf"

    log_info "Génération de $smb_conf avec les paramètres choisis…"

    run_cmd mkdir -p "$(dirname "$smb_conf")"

    # shellcheck disable=SC2016
    run_cmd bash -c "cat > '$smb_conf' << 'EOF'
[global]
   workgroup = ${SAMBA_WORKGROUP}
   server string = Samba Server
   netbios name = $(hostname)
   security = user
   map to guest = Bad User
   dns proxy = no

   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file

   server role = standalone server

   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\\snew\\s*password:* %n\\n *Retype\\snew\\s*password:* %n\\n *password\\supdated\\ssuccessfully* .

   pam password change = yes
   obey pam restrictions = yes

   load printers = no
   printing = bsd
   printcap name = /dev/null
   disable spoolss = yes

EOF"

    if [[ "$SAMBA_SHARE_MODE" == "1" ]]; then
        # Partage invité
        run_cmd bash -c "cat >> '$smb_conf' << 'EOF'

[${SAMBA_SHARE_NAME}]
   path = ${SAMBA_SHARE_PATH}
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0664
   directory mask = 0775

EOF"
    else
        # Partage authentifié
        run_cmd bash -c "cat >> '$smb_conf' << 'EOF'

[${SAMBA_SHARE_NAME}]
   path = ${SAMBA_SHARE_PATH}
   browseable = yes
   writable = yes
   guest ok = no
   read only = no
   valid users = @sambashare
   create mask = 0660
   directory mask = 0770

EOF"
    fi

    log_success "Fichier smb.conf généré."
}

############################################
# Validation de la configuration Samba
############################################
validate_samba_config() {
    local smb_conf="/etc/samba/smb.conf"

    if [[ ! -f "$smb_conf" ]]; then
        log_error "Aucun fichier smb.conf trouvé à valider."
        return 1
    fi

    log_header "Validation de la configuration Samba"
    log_info "Commande : testparm -s $smb_conf"

    if run_cmd testparm -s "$smb_conf"; then
        log_success "Configuration Samba valide."
    else
        log_error "Configuration Samba invalide. Envisage un rollback."
        return 1
    fi
}

############################################
# Création / ajustement du dossier partagé
############################################
create_shared_dir() {
    local dir="$SAMBA_SHARE_PATH"

    if [[ -z "${dir:-}" ]]; then
        dir="$HOME/SHARED"
    fi

    log_header "Création / vérification du dossier de partage"
    log_info "Dossier cible : $dir"

    if [[ -d "$dir" ]]; then
        log_info "Le dossier existe déjà : $dir"
    else
        log_info "Création du dossier : $dir"
        run_cmd mkdir -p "$dir"
        ROLLBACK_CREATED_DIR="$dir"
    fi

    log_info "Ajustement des permissions (770)…"
    run_cmd chmod 770 "$dir"

    # Groupe sambashare si mode authentifié
    if [[ "${SAMBA_SHARE_MODE:-1}" == "2" ]]; then
        if ! getent group sambashare >/dev/null 2>&1; then
            log_info "Création du groupe 'sambashare'"
            run_cmd groupadd sambashare
        fi
        log_info "Affectation du groupe sambashare au dossier"
        run_cmd chgrp sambashare "$dir"
    fi

    log_success "Dossier de partage prêt : $dir"
}

############################################
# Gestion des services Samba
############################################
manage_samba_services() {
    log_header "Activation et redémarrage des services Samba"

    for svc in smbd nmbd; do
        if systemctl list-unit-files | grep -q "^${svc}.service"; then
            log_info "Activation du service : $svc"
            run_cmd systemctl enable "$svc"
            log_info "Redémarrage du service : $svc"
            run_cmd systemctl restart "$svc"
        else
            log_warn "Service introuvable : $svc"
        fi
    done

    log_success "Services Samba traités."
}

############################################
# Rollback
############################################
rollback_changes() {
    log_header "Rollback des changements Samba"

    if [[ -n "$ROLLBACK_SMB_CONF" && -f "$ROLLBACK_SMB_CONF" ]]; then
        local target="/etc/samba/smb.conf"
        log_warn "Restauration de la configuration depuis : $ROLLBACK_SMB_CONF"
        run_cmd cp -a "$ROLLBACK_SMB_CONF" "$target"
        log_success "smb.conf restauré."
    else
        log_warn "Aucune sauvegarde smb.conf disponible pour rollback."
    fi

    if [[ -n "$ROLLBACK_CREATED_DIR" && -d "$ROLLBACK_CREATED_DIR" ]]; then
        if [[ -z "$(ls -A "$ROLLBACK_CREATED_DIR")" ]]; then
            log_warn "Suppression du dossier créé : $ROLLBACK_CREATED_DIR"
            run_cmd rmdir "$ROLLBACK_CREATED_DIR"
            log_success "Dossier supprimé."
        else
            log_warn "Dossier non vide, non supprimé : $ROLLBACK_CREATED_DIR"
        fi
    fi

    log_info "Rollback terminé."
}

############################################
# Workflow complet
############################################
full_workflow() {
    install_dependencies
    backup_smb_conf
    generate_smb_conf
    validate_samba_config
    create_shared_dir
    manage_samba_services
}

############################################
# Menu interactif
############################################
show_menu() {
    echo
    echo "================= Gestion avancée de Samba (LM-Scripts) ================="
    echo "1) Installer / vérifier les dépendances Samba"
    echo "2) Sauvegarder la configuration actuelle (smb.conf)"
    echo "3) Générer un nouveau smb.conf (guidé)"
    echo "4) Valider la configuration Samba (testparm)"
    echo "5) Créer / ajuster le dossier de partage"
    echo "6) Activer et redémarrer les services Samba"
    echo "7) Exécuter le workflow complet (1→6)"
    echo "8) Rollback des derniers changements (si possible)"
    echo "0) Quitter"
    echo "=========================================================================="
    echo
}

menu_loop() {
    while true; do
        show_menu
        read -r -p "Votre choix : " choice
        echo

        case "$choice" in
            1) install_dependencies ;;
            2) backup_smb_conf ;;
            3) generate_smb_conf ;;
            4) validate_samba_config ;;
            5) create_shared_dir ;;
            6) manage_samba_services ;;
            7) full_workflow ;;
            8) rollback_changes ;;
            0) log_info "Sortie du module Samba."; break ;;
            *) log_warn "Choix invalide." ;;
        esac
    done
}

############################################
# MAIN
############################################
main() {
    log_header "LM-Scripts — Gestion avancée de Samba"
    check_requirements
    menu_loop
}

main "$@"

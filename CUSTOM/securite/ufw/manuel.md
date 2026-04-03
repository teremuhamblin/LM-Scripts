> 📘 MANUEL UTILISATEUR — UFW & GUFW pour Linux Mint Cinnamon

🧭 Introduction

UFW (Uncomplicated Firewall) est le pare‑feu officiel d’Ubuntu et Linux Mint.  
GUFW est son interface graphique, simple et intuitive, permettant de gérer les règles réseau sans ligne de commande.

Ce manuel couvre :

- l’installation  
- l’activation  
- la configuration  
- les profils de sécurité  
- la gestion des règles  
- les logs  
- les bonnes pratiques  
- le dépannage  
- les commandes avancées  

Il est adapté à Linux Mint Cinnamon, mais fonctionne aussi sur toutes les éditions Mint.

---

🔧 1. Installation

UFW et GUFW sont disponibles dans les dépôts officiels.

Installer UFW (si absent)

`bash
sudo apt update
sudo apt install ufw
`

Installer GUFW (interface graphique)

`bash
sudo apt install gufw
`

Lancer GUFW

Menu → Administration → Firewall Configuration

---

🔐 2. Activer le pare‑feu

Via GUFW

1. Ouvrir GUFW  
2. Activer l’interrupteur Status : ON

Via terminal

`bash
sudo ufw enable
`

---

🛡️ 3. Politiques par défaut

Les politiques par défaut déterminent le comportement du pare‑feu lorsqu’aucune règle n’est définie.

Recommandation Mint :

- Entrant : Deny
- Sortant : Allow

Appliquer via terminal

`bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
`

---

🧱 4. Profils de sécurité recommandés

🟢 Profil BASIC (utilisation standard)

- Incoming : Deny  
- Outgoing : Allow  
- SSH autorisé si nécessaire  
- GUFW en mode simple  

Usage : navigation, bureautique, multimédia.

---

🟠 Profil STRICT (sécurité renforcée)

- Incoming : Deny  
- Outgoing : Allow  
- SSH limité (rate‑limit)  
- Désactivation des services réseau inutiles  
- Logs activés  

Usage : poste professionnel, machine sensible.

---

🔴 Profil REINFORCED (mode paranoïaque)

- Incoming : Deny  
- Outgoing : Deny  
- Autoriser uniquement :
  - DNS (53)
  - HTTPS (443)
  - SSH (22) limité  
- IPv6 contrôlé  
- Tous les services réseau désactivés  

Usage : machine d’analyse, environnement isolé.

---

➕ 5. Ajouter une règle

Via GUFW

1. Ouvrir GUFW  
2. Onglet Rules  
3. Cliquer sur +  
4. Choisir :
   - Simple (port + protocole)
   - Preconfigured (applications)
   - Advanced (IP, interface, direction)

Exemple : autoriser SSH

- Direction : Incoming  
- Port : 22  
- Protocole : TCP  
- Action : Allow  

---

🧪 6. Mode avancé GUFW

Permet :

- filtrage par IP source/destination  
- filtrage par interface  
- règles complexes  
- gestion IPv6  

Activer

GUFW → Preferences → Enable Advanced Mode

---

📊 7. Logs (journalisation)

Activer via GUFW

Preferences → Logging

Niveaux : Off / Low / Medium / High

Emplacement des logs

`
/var/log/ufw.log
`

Voir les logs

`bash
sudo tail -f /var/log/ufw.log
`

---

📡 8. Vérifier les ports ouverts

`bash
ss -tulpen
`

ou

`bash
sudo lsof -i -P -n
`

---

🧹 9. Désactiver les services réseau inutiles

Avahi (découverte réseau)

`bash
sudo systemctl disable --now avahi-daemon
`

Samba (partage Windows)

`bash
sudo systemctl disable --now smbd nmbd
`

CUPS (impression réseau)

`bash
sudo systemctl disable --now cups
`

---

🧰 10. Commandes UFW essentielles

Activer / désactiver

`bash
sudo ufw enable
sudo ufw disable
`

Voir le statut

`bash
sudo ufw status verbose
`

Autoriser un port

`bash
sudo ufw allow 22/tcp
`

Bloquer un port

`bash
sudo ufw deny 23/tcp
`

Limiter SSH (anti-bruteforce)

`bash
sudo ufw limit 22/tcp
`

Autoriser une IP

`bash
sudo ufw allow from 192.168.1.10
`

Réinitialiser UFW

`bash
sudo ufw --force reset
`

---

🛠️ 11. Commandes avancées

Règles brutes (raw)

`bash
sudo ufw show raw
`

Règles numérotées

`bash
sudo ufw status numbered
`

Supprimer une règle

`bash
sudo ufw delete NUMERO
`

---

🧪 12. Audit de sécurité (manuel)

Vérifier les ports ouverts

`bash
ss -tulpen
`

Vérifier les services réseau

`bash
systemctl list-units --type=service --state=running
`

Vérifier sysctl

`bash
sysctl net.ipv4.conf.all.rp_filter
sysctl net.ipv4.tcp_syncookies
`

---

🧯 13. Dépannage

UFW ne démarre pas

`bash
sudo systemctl restart ufw
`

GUFW ne s’ouvre pas

`bash
gufw
`

UFW ne bloque pas un port

- Vérifier si un service écoute réellement  
- Vérifier IPv6  
- Vérifier les règles avancées  

---

📚 14. Ressources officielles

- Documentation UFW : https://help.ubuntu.com/community/UFW  
- Documentation GUFW : https://gufw.org/  
- Linux Mint : https://linuxmint.com/  

---

📝 Licence

Ce manuel est fourni librement pour aider les utilisateurs de Linux Mint à configurer leur pare‑feu de manière simple, claire et sécurisée.

`

---

---

> 📘 MANUEL AVANCÉ UFW — Linux Mint Cinnamon (Illustré)

`markdown

🔥 Manuel Avancé UFW — Linux Mint Cinnamon (Illustré)

UFW (Uncomplicated Firewall) est le pare-feu officiel d’Ubuntu et Linux Mint.  
Ce manuel avancé vous guide dans la maîtrise complète d’UFW, avec schémas, exemples, bonnes pratiques et commandes expertes.

---

🧭 1. Architecture générale d’UFW

UFW est une surcouche simplifiée à iptables (ou nftables selon la version).

Voici son architecture logique :

`
+------------------------------------------------------+
|                    Applications                       |
|   (Firefox, SSH, Samba, CUPS, Avahi, etc.)            |
+---------------------------+--------------------------+
                            |
                            v
+------------------------------------------------------+
|                     UFW (User Rules)                 |
|  - allow / deny / limit                               |
|  - règles IPv4 / IPv6                                 |
|  - profils                                             |
+---------------------------+--------------------------+
                            |
                            v
+------------------------------------------------------+
|              Backend (iptables / nftables)           |
|  - tables : filter, nat, mangle                       |
|  - chains : INPUT, OUTPUT, FORWARD                    |
+------------------------------------------------------+
`

---

🔐 2. Politiques par défaut (illustrées)

Les politiques par défaut déterminent le comportement du pare-feu sans règle explicite.

Recommandation Mint :

`
Incoming : DENY
Outgoing : ALLOW
`

Illustration :

`
INTERNET ---> [X] (bloqué)
SYSTEME  ---> [✓] (autorisé)
`

---

🧱 3. Profils de sécurité avancés

🟢 BASIC (standard Mint)

`
Incoming : DENY
Outgoing : ALLOW
SSH : allow (optionnel)
`

🟠 STRICT (renforcé)

`
Incoming : DENY
Outgoing : ALLOW
SSH : limit (anti-bruteforce)
Services inutiles : désactivés
Logs : activés
`

🔴 REINFORCED (mode paranoïaque)

`
Incoming : DENY
Outgoing : DENY
Autoriser uniquement :
  - DNS (53)
  - HTTPS (443)
  - SSH (22) limit
IPv6 : contrôlé
`

---

➕ 4. Ajouter des règles (illustré)

4.1 Règle simple

`
sudo ufw allow 22/tcp
`

Schéma :

`
INTERNET ---> [22/tcp] ---> SYSTEME
                 ✓ autorisé
`

4.2 Règle avancée (IP source)

`
sudo ufw allow from 192.168.1.10 to any port 22 proto tcp
`

Schéma :

`
192.168.1.10 ---> [22/tcp] ---> SYSTEME
          ✓ autorisé
Autres IP ---> [X] bloqué
`

4.3 Règle avancée (interface)

`
sudo ufw allow in on eth0 to any port 443
`

---

🧪 5. Mode avancé GUFW (illustré)

GUFW propose trois modes :

`
+------------------+
| Simple           |
| Preconfigured    |
| Advanced         |
+------------------+
`

Mode avancé permet :

- filtrage par IP source/destination  
- filtrage par interface  
- règles complexes  
- gestion IPv6  

---

📊 6. Logs UFW (illustrés)

Activer les logs :

`
sudo ufw logging medium
`

Exemple de log :

`
UFW BLOCK IN=eth0 OUT= MAC=... SRC=203.0.113.5 DST=192.168.1.20 ...
`

Schéma :

`
INTERNET ---> [X] ---> LOG
`

---

📡 7. Analyse des ports ouverts

Commande :

`
ss -tulpen
`

Illustration :

`
PORT   SERVICE     ETAT
22     sshd        LISTEN
631    cups        LISTEN
5353   avahi       LISTEN
`

---

🧹 8. Désactivation des services réseau inutiles

Avahi (découverte réseau)

`
sudo systemctl disable --now avahi-daemon
`

Samba (partage Windows)

`
sudo systemctl disable --now smbd nmbd
`

CUPS (impression réseau)

`
sudo systemctl disable --now cups
`

Illustration :

`
[Avahi]   X désactivé
[Samba]   X désactivé
[CUPS]    X désactivé
`

---

🧰 9. Commandes avancées UFW

9.1 Voir les règles numérotées

`
sudo ufw status numbered
`

9.2 Supprimer une règle

`
sudo ufw delete 3
`

9.3 Règles brutes (raw)

`
sudo ufw show raw
`

9.4 Limiter SSH (anti-bruteforce)

`
sudo ufw limit 22/tcp
`

Illustration :

`
SSH ---> [limit] ---> SYSTEME
   (bloque les tentatives rapides)
`

---

🛠️ 10. Hardening réseau (sysctl)

Paramètres recommandés :

`
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.log_martians = 1
`

Schéma :

`
Attaques SYN ---> [SYNCOOKIES] ---> Protégé
IP spoofing ---> [RP_FILTER] ---> Bloqué
`

---

🧪 11. Audit complet (manuel)

Ports ouverts

`
ss -tulpen
`

Services actifs

`
systemctl list-units --type=service --state=running
`

Paramètres sysctl

`
sysctl net.ipv4.conf.all.rp_filter
`

Logs UFW

`
sudo tail -f /var/log/ufw.log
`

---

🧯 12. Dépannage

UFW ne démarre pas

`
sudo systemctl restart ufw
`

GUFW ne s’ouvre pas

`
gufw
`

UFW ne bloque pas un port

- vérifier IPv6  
- vérifier les règles avancées  
- vérifier si un service écoute réellement  

---

📚 13. Ressources utiles

- Documentation UFW : https://help.ubuntu.com/community/UFW  
- Documentation GUFW : https://gufw.org/  
- Linux Mint : https://linuxmint.com/  

---

📝 Licence

Ce manuel est fourni librement pour aider les utilisateurs avancés à maîtriser UFW sur Linux Mint Cinnamon.

`

---

README.md — Pare‑feu GUFW pour Linux Mint

`markdown

🔥 Pare-feu GUFW — Guide complet pour Linux Mint

GUFW est l’interface graphique officielle du pare-feu UFW (Uncomplicated Firewall).  
Il permet de gérer facilement les règles réseau entrantes et sortantes, sans passer par la ligne de commande.

Ce guide explique :

- ce qu’est GUFW  
- comment l’activer  
- comment configurer les profils (simple, strict, renforcé)  
- comment gérer les règles  
- les bonnes pratiques de sécurité  
- comment utiliser GUFW avec Linux Mint

---

📌 1. Présentation de GUFW

GUFW est une interface graphique simple et intuitive permettant de configurer UFW, le pare-feu intégré à Ubuntu et Linux Mint.

✔ Fonctionnalités principales

- Activation/désactivation du pare-feu  
- Gestion des règles entrantes et sortantes  
- Profils préconfigurés  
- Journalisation (logs)  
- Support IPv4 / IPv6  
- Gestion des ports et applications courantes  
- Mode avancé pour les utilisateurs expérimentés  

---

📦 2. Installation de GUFW

GUFW est disponible dans les dépôts officiels de Linux Mint.

`bash
sudo apt update
sudo apt install gufw
`

Une fois installé, lance-le depuis :

Menu → Administration → Firewall Configuration

---

🔐 3. Activer le pare-feu

Dans GUFW :

1. Ouvre l’application  
2. Active l’interrupteur Status : ON  
3. Le pare-feu est maintenant actif avec les règles par défaut

Règles par défaut recommandées :

- Incoming : Deny
- Outgoing : Allow

C’est la configuration standard la plus sûre pour un poste utilisateur.

---

🛡️ 4. Profils de sécurité recommandés

GUFW ne propose pas de profils prédéfinis, mais tu peux appliquer ces modèles selon ton niveau de sécurité souhaité.

---

🟢 Profil BASIC (recommandé pour la plupart des utilisateurs)

- Incoming : Deny
- Outgoing : Allow
- SSH : autorisé uniquement si nécessaire
- Applications courantes : autorisées manuellement

Usage : navigation web, bureautique, multimédia.

---

🟠 Profil STRICT (sécurité renforcée)

- Incoming : Deny
- Outgoing : Allow
- SSH : autorisé avec prudence
- Désactivation des services réseau inutiles (Avahi, Samba, CUPS)
- Journalisation activée

Usage : poste sensible, machine de travail, environnement semi‑professionnel.

---

🔴 Profil REINFORCED (mode paranoïaque)

- Incoming : Deny
- Outgoing : Deny
- Autoriser uniquement les ports nécessaires :
  - DNS (53)
  - HTTPS (443)
  - SSH (22) en rate‑limit
- IPv6 activé mais contrôlé
- Tous les services réseau locaux désactivés

Usage : machine d’analyse, environnement isolé, sécurité maximale.

---

⚙️ 5. Ajouter une règle

➕ Ajouter une règle simple

1. Ouvre GUFW  
2. Clique sur Rules  
3. Clique sur +  
4. Choisis :
   - Simple (port + protocole)
   - Preconfigured (applications courantes)
   - Advanced (IP, ports, direction, interface)

Exemple : autoriser SSH

- Direction : Incoming
- Port : 22
- Protocole : TCP
- Action : Allow

---

🧪 6. Mode avancé

Le mode avancé permet :

- de filtrer par IP source/destination  
- de filtrer par interface réseau  
- de créer des règles complexes  
- de gérer IPv6  
- d’ajouter des règles temporaires  

Pour l’activer :

GUFW → Preferences → Enable Advanced Mode

---

📊 7. Logs (journalisation)

Pour activer les logs :

1. Ouvre GUFW  
2. Menu Preferences  
3. Active Logging  
4. Choisis le niveau : Low / Medium / High

Les logs sont stockés dans :

`
/var/log/ufw.log
`

---

🧹 8. Désactiver les services réseau inutiles

Pour renforcer la sécurité, il est recommandé de désactiver :

- Avahi (découverte réseau)
- Samba (partage Windows)
- CUPS (impression réseau)

Exemples :

`bash
sudo systemctl disable --now avahi-daemon
sudo systemctl disable --now smbd nmbd
sudo systemctl disable --now cups
`

---

🧭 9. Bonnes pratiques de sécurité

✔ Toujours laisser Incoming : Deny

✔ N’autoriser que les ports nécessaires

✔ Activer la journalisation

✔ Utiliser SSH avec rate-limit

✔ Désactiver les services inutiles

✔ Vérifier régulièrement les ports ouverts :

`bash
ss -tulpen
`

✔ Faire un audit régulier (UFW + sysctl + services)

---

🧰 10. Réinitialiser GUFW / UFW

Si tu veux repartir de zéro :

`bash
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
`

---

📚 11. Ressources utiles

- Documentation UFW : https://help.ubuntu.com/community/UFW  
- Documentation GUFW : https://gufw.org/  
- Linux Mint : https://linuxmint.com/  

---

📝 Licence

Ce guide est fourni librement pour aider les utilisateurs de Linux Mint à configurer leur pare-feu de manière simple et sécurisée.

---

💬 Support

Pour toute question ou amélioration, n’hésite pas à ouvrir une issue dans ton dépôt GitHub ou à contribuer au projet.

`

---

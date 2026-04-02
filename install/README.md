install/README.md

---

📦 Installation — LM‑Scripts

Ce dossier contient les scripts dédiés à l’installation des composants essentiels pour Linux Mint.  
Ils permettent de préparer rapidement un système propre, fonctionnel et prêt à l’usage.

📂 Contenu

- install_core.sh — Installe les paquets de base (outils système, utilitaires essentiels)  
- install_drivers.sh — Ouvre l’outil de gestion des pilotes de Linux Mint  
- install_flatpak.sh — Active Flatpak et ajoute le dépôt Flathub  
- install_devtools.sh — Installe les outils de développement (build-essential, Git, Python, etc.)  
- install_all.sh — Script tout‑en‑un regroupant toutes les installations

🎯 Objectif

Fournir un ensemble de scripts simples et modulaires pour :

- préparer un système Linux Mint fraîchement installé  
- installer les outils indispensables  
- configurer Flatpak  
- ajouter les pilotes et outils de développement  

Chaque script est indépendant et peut être exécuté séparément ou via le script global.

🛠️ Utilisation

Depuis la racine du projet :

`bash
./main.sh
`

Ou directement :

`bash
bash install/install_core.sh
`

Pour tout installer d’un coup :

`bash
bash install/install_all.sh --all
`

🧑‍💻 Notes

- Certains scripts nécessitent les droits administrateur (sudo).  
- Le script install_all.sh propose un menu interactif et des options en ligne de commande.  
- Tous les scripts sont conçus pour être modulaires, sûrs et faciles à adapter.

---

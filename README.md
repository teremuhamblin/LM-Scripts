LM-Scripts/README.md

🐧 LM‑Scripts — "Scripts pour Linux Mint"

- Scripts personnels et modulaires pour automatiser l’installation, la configuration, l’optimisation et la maintenance de Linux Mint.  
- Ce projet est inspiré de l’organisation d’Erik Dubois, mais tout le contenu est réécrit, adapté et optimisé pour Linux Mint Edition.

---

🎯 Objectifs du projet

LM‑Scripts vise à fournir :

- des scripts simples, fiables et reproductibles  
- une installation rapide des paquets essentiels  
- une configuration automatisée de Linux Mint  
- des outils de maintenance régulière  
- des utilitaires pratiques pour diagnostiquer ou optimiser le système  
- une structure claire pour permettre l’évolution du projet  

> Le tout en respectant les bonnes pratiques Bash et Linux.

---

🏗️ Structure du dépôt

`
LM-Scripts/ # dépôt principale 
`

Chaque dossier correspond à une catégorie de scripts, pour une organisation claire et évolutive.

---

🚀 Fonctionnalités principales

🔧 Installation
Scripts pour installer rapidement :

- paquets essentiels  
- pilotes  
- Flatpak  
- outils de développement  

🎨 Configuration
Scripts pour configurer :

- Cinnamon  
- Gnome  
- paramètres système  
- apparence (thèmes, icônes)  

🧹 Maintenance
Scripts pour :

- mettre à jour le système  
- nettoyer les fichiers inutiles  
- sauvegarder le dossier utilisateur  

🧰 Utilitaires
Outils pratiques :

- test de connexion  
- informations système  
- benchmark rapide  

---

🛠️ Utilisation

1. Rendre les scripts exécutables
`bash
chmod +x main.sh
chmod -R +x install/ config/ maintenance/ utils/ themes/
`

2. Lancer le script principal
`bash
./main.sh
`

3. Ou exécuter un script spécifique
`bash
./install/install_core.sh
`

---

🔒 Sécurité

Tous les scripts sont :

- écrits en Bash strict (set -euo pipefail)  
- testés sur Linux Mint  
- conçus pour éviter les actions destructrices  
- documentés pour expliquer chaque étape  

---

📄 Licence

Ce projet est publié sous licence MIT, ce qui permet :

- l’utilisation libre  
- la modification  
- la redistribution  

Tu peux adapter la licence selon tes besoins.

---

🤝 Contributions

Les contributions sont les bienvenues !

Merci de :

1. Lire CONTRIBUTING.md  
2. Créer une branche dédiée  
3. Soumettre une Pull Request propre et documentée  

---

🗺️ Roadmap

- Ajout d’un menu interactif dans main.sh  
- Scripts d’optimisation avancée  
- Support pour LMDE  
- Intégration d’un système de logs  
- Ajout de tests automatiques via GitHub Actions  

---

🧑‍💻 Auteur

> Projet maintenu par The MadDoG.tmdg passionné par Linux, l’automatisation et l’optimisation système.

---

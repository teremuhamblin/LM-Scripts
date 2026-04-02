---

📄 CONTRIBUTING.md
(Version complète, professionnelle, adaptée à LM‑Scripts)

`markdown

🤝 Contribuer à LM‑Scripts

Merci de votre intérêt pour LM‑Scripts !  
Ce projet vise à fournir des scripts fiables, propres et reproductibles pour Linux Mint.  
Les contributions sont les bienvenues, qu’il s’agisse de corrections, d’améliorations, de nouvelles fonctionnalités ou de documentation.

---

🧱 Principes généraux

Avant de contribuer, merci de respecter les règles suivantes :

- Le code doit être clair, lisible et commenté.
- Les scripts doivent être écrits en Bash strict :
  `bash

!/usr/bin/env bash
  set -euo pipefail
  `
- Aucune commande destructrice ne doit être ajoutée sans confirmation explicite.
- Les scripts doivent être testés sur Linux Mint avant soumission.
- Les contributions doivent respecter la structure du projet.

---

🗂️ Structure du projet

Merci de placer vos scripts dans les dossiers appropriés :

- install/ → installation de paquets, pilotes, outils
- config/ → configuration du système ou de l’environnement
- maintenance/ → nettoyage, mises à jour, sauvegardes
- utils/ → outils divers (diagnostic, benchmark…)
- themes/ → installation de thèmes et icônes
- docs/ → documentation

---

🧪 Tests

Avant de soumettre une PR :

1. Testez votre script sur Linux Mint.
2. Vérifiez qu’il fonctionne sans erreur :
   `bash
   bash -n script.sh
   `
3. Vérifiez qu’il respecte les bonnes pratiques :
   `bash
   shellcheck script.sh
   `

---

📝 Style des scripts

Merci de respecter :

- indentation : 2 espaces
- variables en MAJUSCULES pour les constantes
- fonctions en snake_case
- messages utilisateur clairs et colorés (optionnel)

Exemple :

`bash
info() { echo -e "\e[32m[INFO]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }
`

---

🔀 Workflow Git

1. Forkez le dépôt
2. Créez une branche :
   `bash
   git checkout -b feature/nom-de-la-feature
   `
3. Faites vos modifications
4. Commitez proprement :
   `bash
   git commit -m "feat: ajout du script d'installation Flatpak"
   `
5. Poussez votre branche
6. Ouvrez une Pull Request

---

🏷️ Convention de commits

Utilisez les préfixes suivants :

- feat: nouvelle fonctionnalité
- fix: correction
- refactor: amélioration interne
- docs: documentation
- style: formatage
- chore: maintenance

---

📄 Licence

En contribuant, vous acceptez que votre code soit publié sous licence MIT, comme le reste du projet.

Merci pour votre contribution !
`

---

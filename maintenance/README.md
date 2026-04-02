maintenance/README.md

---

🧹 Maintenance — LM‑Scripts

Ce dossier contient les scripts dédiés à la maintenance du système sous Linux Mint.  
Ils permettent de garder le système propre, à jour et fonctionnel grâce à des actions simples et reproductibles.

📂 Contenu

- update_system.sh — Met à jour le système (apt update, upgrade, nettoyage)  
- clean_system.sh — Nettoie les fichiers inutiles et optimise l’espace disque  
- backup_home.sh — Crée une sauvegarde compressée du dossier utilisateur  

🎯 Objectif

Fournir des outils fiables pour :

- maintenir un système Linux Mint propre  
- automatiser les tâches de maintenance courantes  
- faciliter les sauvegardes essentielles  

Ces scripts sont conçus pour être sûrs, modulaires et faciles à adapter.

🛠️ Utilisation

Depuis la racine du projet :

`bash
./main.sh
`

Ou directement :

`bash
bash maintenance/update_system.sh
`

🧑‍💻 Notes

- Certains scripts nécessitent les droits administrateur (sudo).  
- Les scripts sont volontairement simples pour rester lisibles et modifiables.  
- Tu peux facilement ajouter d’autres tâches de maintenance selon tes besoins.

---

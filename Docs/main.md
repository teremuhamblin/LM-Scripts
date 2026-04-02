📘 Description détaillée du script main.sh — LM‑Scripts Launcher Premium

Le script main.sh constitue le point d’entrée principal du projet LM‑Scripts.  
Il agit comme un launcher interactif avancé, permettant d’exécuter l’ensemble des scripts du dépôt de manière simple, intuitive et professionnelle.

Ce script est conçu pour offrir :

- une interface moderne en ligne de commande  
- une navigation fluide entre les catégories de scripts  
- une détection automatique des scripts disponibles  
- des options avancées (recherche, exécution rapide, informations système)  
- une sécurité renforcée  
- une architecture modulaire permettant d’ajouter des scripts sans modifier le launcher  

---

🧩 1. Architecture générale du script

Le script est organisé en plusieurs blocs logiques :

1. En-tête et métadonnées  
2. Définition des couleurs et styles modernes  
3. Fonctions d’interface utilisateur (UI)  
4. Vérifications système et dépendances  
5. Mécanismes d’exécution dynamique  
6. Sous‑menus interactifs  
7. Fonctions avancées (recherche, exécution rapide)  
8. Menu principal  
9. Bloc d’exécution final

Cette structure permet une lisibilité optimale, une maintenance facilitée et une extensibilité naturelle.

---

🎨 2. Interface utilisateur moderne

Le script utilise une palette de couleurs avancée basée sur les codes ANSI 256 couleurs :

- Cyan électrique pour les titres  
- Vert néon pour les actions positives  
- Orange pour les sections  
- Rose pour les options avancées  
- Rouge vif pour les erreurs  
- Jaune pour les avertissements  

Une bannière stylisée est affichée à chaque ouverture de menu :

`
╔══════════════════════════════════════════════╗
║        🚀  LM‑Scripts — Launcher Pro         ║
╚══════════════════════════════════════════════╝
`

Cette approche donne une identité visuelle forte au projet.

---

🛡️ 3. Sécurité et robustesse

Le script utilise :

`bash
set -euo pipefail
`

Ce qui garantit :

- arrêt immédiat en cas d’erreur  
- interdiction des variables non définies  
- gestion stricte des pipes  

Le script vérifie également la présence de dépendances essentielles :

- bash  
- ls  
- grep  
- awk  
- tput  

Si une dépendance manque → message d’erreur clair + arrêt propre.

---

⚙️ 4. Détection automatique des scripts

Le launcher ne contient aucune liste codée en dur.

Il détecte automatiquement les scripts présents dans les dossiers :

- install/  
- config/  
- maintenance/  
- utils/  
- themes/  

Grâce à :

`bash
find "$folder" -maxdepth 1 -type f -name "*.sh"
`

👉 Tu ajoutes un script → il apparaît automatiquement dans le menu.

C’est l’un des points forts du design.

---

📂 5. Sous‑menus dynamiques

Chaque catégorie possède un sous‑menu généré automatiquement :

- liste numérotée des scripts  
- exécution du script choisi  
- retour au menu principal  

Les sous‑menus sont stylisés et affichent clairement le contexte :

`
📂 Scripts d'installation
1) install_core.sh
2) install_drivers.sh
3) install_flatpak.sh
0) Retour
`

---

🔍 6. Options avancées

Le script inclut deux fonctionnalités premium :

---

🔎 6.1 Recherche de scripts

Permet de rechercher un script par nom ou mot‑clé :

`bash
grep -Ril "$query" install config maintenance utils themes
`

Affiche tous les scripts contenant le mot recherché.

---

⚡ 6.2 Exécution rapide

Permet d’exécuter un script en entrant directement son chemin :

`
Chemin du script : utils/system_info.sh
`

Très utile pour les utilisateurs avancés.

---

🧠 7. Menu principal

Le menu principal regroupe toutes les catégories et options avancées :

`
1) Installation
2) Configuration
3) Maintenance
4) Utilitaires
5) Thèmes & Icônes
6) Informations système
7) Recherche d’un script
8) Exécution rapide
0) Quitter
`

Chaque option appelle un sous‑menu ou une fonction avancée.

---

🧱 8. Modularité totale

Le script est conçu pour être 100% modulaire :

- tu peux ajouter autant de scripts que tu veux  
- tu peux ajouter de nouveaux dossiers  
- tu peux renommer les scripts  
- tu peux réorganiser les catégories  

👉 Le launcher s’adapte automatiquement.

Aucune modification du main.sh n’est nécessaire.

---

🧪 9. Compatibilité et portabilité

Le script est compatible :

- Linux Mint (toutes éditions)  
- Ubuntu / Debian  
- Bash 4+  
- Terminaux compatibles ANSI  

Il ne dépend d’aucune bibliothèque externe.

---

🧾 10. Résumé des fonctionnalités

| Fonction | Description |
|---------|-------------|
| Menu principal | Interface moderne et intuitive |
| Sous‑menus dynamiques | Détection automatique des scripts |
| Recherche | Recherche par mot‑clé dans tous les scripts |
| Exécution rapide | Exécution directe d’un script |
| Logs colorés | Messages clairs et stylisés |
| Sécurité Bash | set -euo pipefail |
| Modularité | Ajout de scripts sans modification du launcher |
| Vérification des dépendances | Robustesse et fiabilité |

---

🏁 Conclusion

Le script main.sh est un launcher Bash premium, conçu pour offrir une expérience utilisateur moderne, intuitive et puissante.  
Il constitue le cœur du projet LM‑Scripts, garantissant une utilisation simple et professionnelle de tous les scripts du dépôt.

Il est :

- modulaire  
- sécurisé  
- esthétique  
- performant  
- adapté aux utilisateurs débutants comme avancés  

---

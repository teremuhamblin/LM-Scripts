themes/README.md

---

🎨 Thèmes & Icônes — LM‑Scripts

Ce dossier contient les scripts dédiés à l’installation et à la gestion des thèmes et packs d’icônes pour Linux Mint.  
Ils permettent de personnaliser facilement l’apparence du système tout en restant modulaires et simples à adapter.

📂 Contenu

- install_themes.sh — Prépare ou installe des thèmes (GTK, Cinnamon, etc.)  
- install_icons.sh — Prépare ou installe des packs d’icônes  

🎯 Objectif

Fournir une base propre pour :

- installer rapidement des thèmes personnalisés  
- ajouter ou mettre à jour des packs d’icônes  
- organiser les ressources graphiques dans ~/.themes et ~/.icons  

Ces scripts sont volontairement minimalistes afin que tu puisses y intégrer tes propres sources (GitHub, Gnome‑Look, archives locales…).

🛠️ Utilisation

Depuis la racine du projet :

`bash
./main.sh
`

Ou directement :

`bash
bash themes/install_themes.sh
`

🧑‍💻 Notes

- Les scripts ne téléchargent rien par défaut : ils servent de base personnalisable.  
- Tu peux y ajouter tes thèmes favoris (Mint‑Y, Orchis, WhiteSur, Tela, Papirus, etc.).  
- Les dossiers ~/.themes et ~/.icons sont créés automatiquement si nécessaires.

---

# Dossier `CUSTOM/`

Le dossier `CUSTOM/` est destiné à accueillir les scripts personnels de l’utilisateur.  
Il permet d’étendre LM‑Scripts sans modifier les modules officiels du projet.

Ce dossier est **totalement isolé** du cœur du framework :  
- aucun fichier ici ne surcharge les scripts internes  
- aucun conflit de nom n’est possible  
- le chargement est optionnel et contrôlé  
- le contenu peut être privé ou versionné selon vos besoins

---

## 🎯 Objectif

Permettre à chaque utilisateur d’ajouter ses propres scripts, outils ou automatisations, tout en conservant :

- la stabilité du framework LM‑Scripts  
- la propreté du dépôt  
- la modularité du projet  
- la séparation entre scripts officiels et scripts personnels  

---

## 📁 Structure recommandée

Vous pouvez organiser vos scripts comme vous le souhaitez.

---

## ⚙️ Chargement automatique

Si activé dans `main.sh` ou dans la configuration, LM‑Scripts peut charger automatiquement tous les scripts `.sh` présents dans ce dossier.

Exemple de loader (déjà intégré ou à intégrer) :

```bash
CUSTOM_DIR="$ROOT_DIR/custom"

if [[ -d "$CUSTOM_DIR" ]]; then
    for script in "$CUSTOM_DIR"/*.sh; do
        [[ -f "$script" ]] && source "$script"
    done
fi
```

---

🔒 Scripts personnels privés (optionnel)

Si vous souhaitez garder vos scripts personnels hors du dépôt Git, ajoutez dans .gitignore :

`
custom/
`

Le dossier restera local, sans être poussé sur GitHub.

---

🧩 Bonnes pratiques

- Préfixez vos fonctions pour éviter les collisions (ex : my, t, perso_)  
- Documentez vos scripts avec un en-tête clair  
- Évitez de modifier les modules officiels : mettez vos variantes ici  
- Utilisez ce dossier pour vos automatisations locales, tests, prototypes, etc.

---

✔️ Résumé

Le dossier custom/ est votre espace personnel dans LM‑Scripts.  
Il vous permet d’étendre le framework sans jamais interférer avec les modules officiels, tout en gardant une structure propre, maintenable et évolutive.

`
Custom scripts = liberté totale, zéro conflit.
`
`

---

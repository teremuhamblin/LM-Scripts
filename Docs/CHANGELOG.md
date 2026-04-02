---

# 📄 **CHANGELOG.md**  
*(Format professionnel, basé sur Keep a Changelog)*

```markdown
# 📘 CHANGELOG — LM‑Scripts

Ce fichier documente tous les changements notables apportés au projet.  
Le format suit les recommandations de **Keep a Changelog** et le versionnement **SemVer**.

---

## [Unreleased]
### Ajouté
- Nouveau script `system_info.sh`
- Base du menu interactif dans `main.sh`

### Modifié
- Amélioration du script `update_system.sh`

### Corrigé
- Correction d’un problème de permissions dans `install_core.sh`

---

## [1.0.0] — 2026-04-02
### 🎉 Première version stable de LM‑Scripts

#### Ajouté
- Structure complète du projet :
  - `install/`
  - `config/`
  - `maintenance/`
  - `utils/`
  - `themes/`
  - `docs/`
- Scripts d’installation :
  - `install_core.sh`
  - `install_drivers.sh`
  - `install_flatpak.sh`
  - `install_devtools.sh`
- Scripts de configuration :
  - `config_cinnamon.sh`
  - `config_system.sh`
- Scripts de maintenance :
  - `update_system.sh`
  - `clean_system.sh`
  - `backup_home.sh`
- Scripts utilitaires :
  - `check_internet.sh`
  - `benchmark.sh`
- Script principal `main.sh`
- README complet
- Licence MIT
- CONTRIBUTING.md

---

## [0.1.0] — 2026-03-XX
### Prototype initial
- Création du dépôt
- Ajout des premiers scripts de test
- Mise en place de la structure de base

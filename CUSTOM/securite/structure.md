---

🧩 Structure LM‑Scripts du dossier :

> CUSTOM

```
securite/
└── ufw/
        ├── manuel.md
        ├── plugins/
        │   └── gufw/
        │       ├── plugin_logging.sh
        │       ├── plugin_ipv6.sh
        │       ├── plugin_rate_limit.sh
        │       └── plugin_custom_rules.sh
        └── hooks/
            ├── pre_apply.d/
            │   ├── 00-check-root.sh
            │   └── 10-backup-ufw.sh
            └── post_apply.d/
                ├── 00-show-status.sh
                └── 10-reload-services.sh
                ```

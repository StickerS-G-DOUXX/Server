# Server — FiveM Local Server

> 🇫🇷 Instructions en français ci-dessous.

A ready-to-run **FiveM** server skeleton with:
- Organised resource structure (`[base]`, `[core]`, `[standalone]`)
- MySQL / MariaDB database integration via **oxmysql**
- **player_manager** — player registration & persistent data
- **inventory** — database-backed item inventory with weight system
- **spawnmanager** — position save/restore on connect/disconnect

---

## 🚀 Quick Start (English)

### Prerequisites
| Tool | Version |
|------|---------|
| [FiveM server artifact](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) | latest recommended |
| MySQL **or** MariaDB | ≥ 8.0 / ≥ 10.6 |

### 1 — Set up the database

```bash
# Create the database and import the schema
mysql -u root -p < database/schema.sql
```

### 2 — Configure `server.cfg`

Open `server.cfg` and adjust:

```cfg
# Database connection string
set mysql_connection_string "mysql://root:YOUR_PASSWORD@localhost/fivem_server?charset=utf8mb4"

# Server name
sv_hostname "My FiveM Server"
```

### 3 — Install oxmysql (native build)

The `resources/[base]/oxmysql/` folder contains a lightweight Lua wrapper.  
For production use, replace it with the official binary release:

```
https://github.com/overextended/oxmysql/releases
```

Place the downloaded folder at `resources/[base]/oxmysql/`.

### 4 — Start the server

```bash
# Windows
FXServer.exe +exec server.cfg

# Linux
./run.sh +exec server.cfg
```

---

## 🇫🇷 Démarrage rapide (Français)

### Prérequis
| Outil | Version |
|-------|---------|
| [Artefact serveur FiveM](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) | dernière stable |
| MySQL **ou** MariaDB | ≥ 8.0 / ≥ 10.6 |

### 1 — Créer la base de données

```bash
# Crée la base et importe le schéma
mysql -u root -p < database/schema.sql
```

### 2 — Configurer `server.cfg`

Modifiez les lignes suivantes dans `server.cfg` :

```cfg
# Chaîne de connexion à la base de données
set mysql_connection_string "mysql://root:VOTRE_MOT_DE_PASSE@localhost/fivem_server?charset=utf8mb4"

# Nom du serveur
sv_hostname "Mon Serveur FiveM"
```

### 3 — Installer oxmysql (binaire officiel)

Le dossier `resources/[base]/oxmysql/` contient un wrapper Lua léger.  
Pour la production, remplacez-le par la version officielle :

```
https://github.com/overextended/oxmysql/releases
```

Placez le dossier téléchargé dans `resources/[base]/oxmysql/`.

### 4 — Lancer le serveur

```bash
# Windows
FXServer.exe +exec server.cfg

# Linux
./run.sh +exec server.cfg
```

---

## 📁 Structure des ressources

```
resources/
  [base]/
    oxmysql/          ← Connecteur MySQL (à charger EN PREMIER)
  [core]/
    player_manager/   ← Inscription, chargement/sauvegarde des joueurs
    inventory/        ← Inventaire par joueur (server + client)
  [standalone]/
    spawnmanager/     ← Gestion du spawn et sauvegarde de position
database/
  schema.sql          ← Schéma MySQL complet (players, items, inventory)
server.cfg            ← Configuration principale du serveur
```

---

## 🗄️ Tables de la base de données

| Table | Description |
|-------|-------------|
| `players` | Un enregistrement par identifiant Steam/license |
| `items` | Définitions globales des objets (nom, poids, utilisable…) |
| `inventory` | Lien joueur ↔ objet avec quantité |

---

## ⚙️ Commandes en jeu

| Commande | Accès | Description |
|----------|-------|-------------|
| `/openinventory` (ou TAB) | Tous | Affiche l'inventaire |
| `/giveitem <id> <item> <qty>` | Admin | Donne un objet à un joueur |
| `/players` | Admin | Liste les 20 derniers joueurs en base |

---

## 🔒 Sécurité

- La clé de licence FiveM (`sv_licenseKey`) est obligatoire pour un serveur public.
- Ne committez **jamais** votre mot de passe MySQL dans ce dépôt.  
  Utilisez des variables d'environnement ou un fichier `.env` (ajouté au `.gitignore`).

# Pterodactyl Eggs - AI Coding Instructions

## Project Overview

**Purpose:** Production-ready Pterodactyl Panel eggs for automated game server deployment via Docker containers. Currently supports Arma Reforger with expandable architecture for additional games.

**Architecture Pattern:**
- **Unified Docker Image:** Single image (`fabriciojrsilva/steamcmd-eggs:latest`) for both installation and runtime
- **Configuration sync:** Installation scripts embedded in egg JSON via [sync-script-to-json.py](eggs/arma-reforger/sync-script-to-json.py)
- **Panel integration:** Pterodactyl's `config.files` JSON parser auto-substitutes environment variables into server configuration at startup

## Execution Flow (4 Phases)

```
PHASE 1: Docker Image Build
├── Source: docker/steamcmd/Dockerfile
├── Entrypoint: docker/steamcmd/entrypoint.sh
├── User: container (UID 1000)
├── Pre-installed: SteamCMD, jq, curl, tini
└── Output: fabriciojrsilva/steamcmd-eggs:latest

PHASE 2: Server Installation (Pterodactyl)
├── Trigger: "Reinstall" button in Panel
├── Script: egg JSON → scripts.installation.script
├── User: ROOT (Pterodactyl overrides during install)
├── Directory: /mnt/server
├── Steps:
│   1. Configure Steam credentials
│   2. Create directories (steamcmd, steamapps, profile, tmp)
│   3. Download SteamCMD + game files (App ID 1874900)
│   4. Verify ArmaReforgerServer binary
│   5. Generate config.json template
│   6. Generate armareforger-server.sh startup script
│   7. Set permissions: chown container:container /mnt/server
└── Output: Server files ready in /mnt/server

PHASE 3: Server Runtime (Pterodactyl)
├── Trigger: "Start" button in Panel
├── Entrypoint: /entrypoint.sh (from Docker image)
├── User: container (UID 1000)
├── Directory: /home/container (mounted from /mnt/server)
├── Steps:
│   1. Check AUTO_UPDATE variable
│   2. If AUTO_UPDATE=1: run SteamCMD update
│   3. Process STARTUP environment variable
│   4. Execute: cd /home/container && bash armareforger-server.sh
└── Output: ArmaReforgerServer running

PHASE 4: Server Startup Script (armareforger-server.sh)
├── Generated during installation
├── Steps:
│   1. Display server configuration
│   2. Fix boolean values in config.json (sed)
│   3. Ensure password fields are strings (jq)
│   4. Execute ArmaReforgerServer with CLI parameters
└── Output: Game server running
```

## Critical Developer Knowledge

### 1. Script Synchronization Workflow

The shell installation script is embedded in the egg JSON. **Never edit the JSON directly:**

**Workflow:**
```bash
cd eggs/arma-reforger
# 1. Edit the shell script
nano installation-script.sh
# 2. Embed into JSON
python3 sync-script-to-json.py
# 3. Validate
python3 validate-egg.py
# 4. Commit both files
git add installation-script.sh egg-pterodactyl-arma-reforger.json
```

**Constraints:**
- Script converts `\n` → `\r\n` when embedded (Pterodactyl requirement)
- Never manually edit `scripts.installation.script` in JSON
- Validation catches missing variables and placeholder mismatches

### 2. User and Permission Model

| Phase | User | Reason |
|-------|------|--------|
| Docker Build | container (UID 1000) | Default non-privileged user |
| Installation | ROOT | Pterodactyl forces root for apt-get, chown |
| Runtime | container (UID 1000) | Security: non-privileged execution |

**Permission Flow:**
```
Installation (ROOT):
  └── Download files as root
  └── chown -R container:container /mnt/server  ← Critical final step

Runtime (container):
  └── /home/container mounted from /mnt/server
  └── All files already owned by container user
```

### 3. Directory Mapping

| Phase | Path | Contents |
|-------|------|----------|
| Installation | /mnt/server | Server files (Pterodactyl mount point) |
| Runtime | /home/container | Same files (Pterodactyl remounts) |
| SteamCMD | /home/container/steamcmd | Pre-installed in Docker image |

### 4. Three-Layer Configuration Model

```
Panel UI (User editable variables)
  ↓ [egg.variables[]]
Environment variables (${SERVER_NAME}, ${MAX_PLAYERS}, etc.)
  ↓ [egg.config.files parser - Pterodactyl handles this]
config.json file ({{env.SERVER_NAME}} → actual value)
  ↓ [armareforger-server.sh - startup script]
Runtime behavior (boolean fix, password fix, server execution)
```

### 5. Auto-Update Feature

Enabled via `AUTO_UPDATE=1` or `AUTO_UPDATE=true` in Panel variables.

**Flow:**
```
entrypoint.sh
├── Check AUTO_UPDATE variable
├── If enabled:
│   ├── Find SteamCMD at /home/container/steamcmd/steamcmd.sh
│   ├── Run: steamcmd +login +app_update 1874900 +quit
│   └── Continue to startup
└── Execute STARTUP command
```

## File Structure

```
pterodactyl.eggs/
├── .github/
│   └── copilot-instructions.md     # This file
├── docker/
│   ├── steamcmd/
│   │   ├── Dockerfile              # Unified image (install + runtime)
│   │   ├── entrypoint.sh           # Processes STARTUP command
│   │   └── README.md               # Docker Hub documentation
│   └── README.md                   # Docker overview
├── eggs/
│   └── arma-reforger/
│       ├── egg-pterodactyl-arma-reforger.json  # Egg definition (auto-generated)
│       ├── installation-script.sh   # Source of truth for installation
│       ├── sync-script-to-json.py   # Embeds script into JSON
│       ├── validate-egg.py          # Validates egg structure
│       ├── armaconfig.json          # Example config template
│       └── README.md                # Egg documentation
├── scripts/
│   └── build-docker.sh              # Builds Docker image
├── README.md                        # Project documentation
└── LICENSE                          # MIT License
```

## Common Tasks

### Adding a New Variable

1. Add to egg JSON `variables[]` array:
```json
{
    "name": "[Category] Variable Name",
    "env_variable": "VAR_NAME",
    "default_value": "default",
    "user_viewable": true,
    "user_editable": true,
    "rules": "required|string",
    "field_type": "text"
}
```

2. If used in config.json, add to `config.files` parser:
```json
"config.files": {
    "config.json": {
        "parser": "json",
        "find": {
            "game.newSetting": "{{env.VAR_NAME}}"
        }
    }
}
```

3. Validate:
```bash
python3 validate-egg.py
```

### Modifying Installation Script

1. Edit `installation-script.sh`
2. Sync: `python3 sync-script-to-json.py`
3. Validate: `python3 validate-egg.py`
4. Commit both files

### Building Docker Image

```bash
./scripts/build-docker.sh
docker push fabriciojrsilva/steamcmd-eggs:latest
docker push fabriciojrsilva/steamcmd-eggs:arma-reforger
```

### Debugging

**Installation issues:**
- Set `INSTALL_LOG=DEBUG` before reinstall
- Check SteamCMD output for credential errors

**Startup issues:**
- Check entrypoint.sh logs for missing files
- Verify STARTUP variable is set correctly
- Check file permissions on /home/container

## Key Files Reference

| File | Purpose | Edit? |
|------|---------|-------|
| `eggs/arma-reforger/installation-script.sh` | Installation logic | YES - source of truth |
| `eggs/arma-reforger/egg-pterodactyl-arma-reforger.json` | Egg definition | NO - auto-generated |
| `docker/steamcmd/Dockerfile` | Docker image | YES |
| `docker/steamcmd/entrypoint.sh` | Startup command processing | YES |
| `eggs/arma-reforger/sync-script-to-json.py` | Sync tool | Rarely |
| `eggs/arma-reforger/validate-egg.py` | Validation tool | Rarely |

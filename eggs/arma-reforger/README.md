# Arma Reforger - Pterodactyl Egg

Production-ready egg for Arma Reforger Dedicated Server on Pterodactyl Panel.

## Requirements

- Docker Image: `fabriciojrsilva/steamcmd-eggs:latest`
- Minimum 4GB RAM recommended

## Installation

### 1. Import Egg

1. Download `egg-pterodactyl-arma-reforger.json`
2. In Pterodactyl Panel: Admin > Nests > Import Egg
3. Upload the JSON file

### 2. Create Server

1. Create new server with the imported egg
2. Click Install/Reinstall

> **Note:** Anonymous Steam login is used by default. If you need to use a Steam account (e.g., for beta branches), configure `STEAM_USER` and `STEAM_PASS` in the Startup tab.

## Execution Flow

```
Phase 1: Installation (runs as ROOT)
├── Configure Steam credentials
├── Create directories (steamcmd, profile, tmp)
├── Download game via SteamCMD (App ID 1874900)
├── Generate config.json template
├── Generate armareforger-server.sh startup script
└── Set permissions for container user

Phase 2: Runtime (runs as container)
├── Check AUTO_UPDATE variable
├── If enabled: update via SteamCMD
├── Execute startup command
└── Server runs
```

## Configuration Variables

### Server Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_NAME` | Server name in browser | Arma Reforger Server |
| `MAX_PLAYERS` | Maximum players | 64 |
| `SCENARIO_ID` | Mission scenario | Campaign |

### Network

| Variable | Description | Default |
|----------|-------------|---------|
| `A2S_PORT` | Steam query port | 1770 |
| `RCON_PORT` | RCON admin port | 19992 |
| `RCON_PASSWORD` | RCON password | admin123 |

### Features

| Variable | Description | Default |
|----------|-------------|---------|
| `AUTO_UPDATE` | Update on every start | 0 (disabled) |
| `CROSS_PLATFORM` | Enable crossplay | true |
| `BATTLEYE` | Enable BattlEye | false |

## Auto-Update

Enable automatic updates on server start:

1. Set `AUTO_UPDATE=1` in Panel variables
2. Server will check for updates before starting
3. Uses existing Steam credentials

## Files Generated

After installation, these files are created in `/home/container`:

| File | Purpose |
|------|---------|
| `ArmaReforgerServer` | Game server binary |
| `config.json` | Server configuration |
| `armareforger-server.sh` | Startup script |
| `profile/` | Server profiles and logs |

## Debugging

### Enable Debug Logging

Set `INSTALL_LOG=DEBUG` before reinstalling for verbose output.

### Common Issues

**"Missing configuration" error:**
- Verify Steam credentials are set
- Ensure account owns Arma Reforger

**Server not starting:**
- Check if `ArmaReforgerServer` exists
- Verify file permissions

**Config not updating:**
- Panel variables are applied to `config.json` on each start
- Check startup logs for parsing errors

## Development

### Modify Installation Script

```bash
cd eggs/arma-reforger

# 1. Edit the script
nano installation-script.sh

# 2. Sync to JSON
python3 sync-script-to-json.py

# 3. Validate
python3 validate-egg.py
```

### Add New Variable

1. Add to `variables[]` in egg JSON
2. If needed in config.json, add to `config.files` parser
3. Run `validate-egg.py` to check

## License

MIT License

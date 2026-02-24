# Arma Reforger - Pterodactyl Egg

Production-ready egg for Arma Reforger Dedicated Server on Pterodactyl Panel.

## Features

- **A2S Query Support** - Steam server browser integration
- **RCON Admin** - Remote administration interface
- **Crossplay** - PC, Xbox, PlayStation players can join together
- **Auto-Update** - Optional automatic updates on server start
- **Full Configuration** - All server settings configurable via Panel UI

## Requirements

- **Pterodactyl Panel** - Version 1.0 or higher
- **Docker Images:**
  - Installation: `fabriciojrsilva/steamcmd-eggs:installer`
  - Runtime: `fabriciojrsilva/steamcmd-eggs:latest`
- **Minimum RAM:** 4GB recommended
- **Disk Space:** ~10GB for game files

## Installation

### 1. Import Egg

1. Download `egg-pterodactyl-arma-reforger.json` from this directory
2. In Pterodactyl Panel: Navigate to **Admin** > **Nests** > **Import Egg**
3. Upload the JSON file
4. Select a nest (or create a new one) for the egg

### 2. Create Server

1. Create a new server using the imported egg
2. Allocate required ports:
   - **Primary Port** - Game server (default: 2001)
   - **A2S Port** - Steam query (default: 17770)
   - **RCON Port** - Admin interface (default: 19998)
3. Click **Install** or **Reinstall** to download game files

> **Note:** Anonymous Steam login is used by default. If you need to use a Steam account (e.g., for beta branches or private access), configure `STEAM_USER` and `STEAM_PASS` in the Startup tab.

## Execution Flow

```
Phase 1: Installation (Installer Image - runs as root)
├── Pterodactyl creates container from installer image
├── Configure Steam credentials
├── Create directories (steamcmd, profile, tmp)
├── Download SteamCMD and install game (App ID 1874900)
├── Set up Steam SDK libraries (32/64-bit)
├── Generate config.json template with default values
├── Generate armareforger-server.sh startup script
├── Set permissions for container user (UID 1000)
└── Container destroyed after completion

Phase 2: Runtime (Runtime Image - runs as container user)
├── Pterodactyl creates container from runtime image
├── Mounts server files to /home/container
├── Check AUTO_UPDATE variable
├── If enabled: Run SteamCMD to update game files
├── Process and execute startup command
└── Arma Reforger Server runs
```

## Configuration Variables

All variables are configurable through the Pterodactyl Panel UI under the **Startup** tab.

### Server Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_NAME` | Server name in browser | Arma Reforger Server |
| `SERVER_PASS` | Server password (blank = no password) | (blank) |
| `ADMIN_PASS` | Admin password | changeme |
| `MAX_PLAYERS` | Maximum players (1-64) | 64 |
| `SCENARIO_ID` | Mission scenario ID | {ECC61978EDCC2B5A}Missions/23_Campaign.conf |
| `VISIBLE` | Show in server browser | true |

### Network Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_PORT` | Game server port | 2001 |
| `A2S_ADDRESS` | A2S query address | 0.0.0.0 |
| `A2S_PORT` | A2S query port | 17770 |
| `RCON_ADDRESS` | RCON admin address | 0.0.0.0 |
| `RCON_PORT` | RCON admin port | 19998 |
| `RCON_PASSWORD` | RCON password | changeme |

### Game Features

| Variable | Description | Default |
|----------|-------------|---------|
| `CROSS_PLATFORM` | Enable crossplay (PC/Xbox/PS) | true |
| `BATTLEYE` | Enable BattlEye anti-cheat | false |
| `DISABLE_THIRD` | Disable third-person view | false |
| `MODS_REQUIRED` | Require mods by default | false |

### Performance & Operations

| Variable | Description | Default |
|----------|-------------|---------|
| `AUTO_UPDATE` | Update on every start (0=off, 1=on) | 0 |
| `MAX_VIEW_DISTANCE` | Maximum view distance (meters) | 5000 |
| `MIN_GRASS_DISTANCE` | Minimum grass distance (meters) | 50 |
| `NETWORK_VIEW_DISTANCE` | Network view distance (meters) | 1500 |
| `AI_LIMIT` | AI limit (-1 = unlimited) | -1 |
| `DISABLE_AI` | Disable AI completely | false |
| `MAX_FPS` | Maximum server FPS | 60 |

## Auto-Update

Enable automatic updates on every server start:

1. In Pterodactyl Panel, go to **Startup** tab
2. Set `AUTO_UPDATE` variable to `1`
3. Save changes
4. Server will check for updates before starting each time

The auto-update feature uses SteamCMD with your configured Steam credentials to check for and download updates. This ensures your server is always running the latest version.

To disable auto-update, set `AUTO_UPDATE` to `0`.

## Files Generated

After installation, these files are created in `/home/container`:

| File/Directory | Purpose |
|----------------|---------|
| `ArmaReforgerServer` | Game server binary (executable) |
| `config.json` | Server configuration file |
| `armareforger-server.sh` | Startup script (auto-generated) |
| `profile/` | Server profiles, saves, and logs |
| `steamcmd/` | SteamCMD installation directory |
| `.steam/` | Steam SDK libraries (32/64-bit) |

**Important:** Do not manually delete these files. If you need to reset the server, use the **Reinstall** function in Pterodactyl Panel.

## Debugging

### Server Logs

Server logs are located in `/home/container/profile/` directory:
- `console.log` - Main server console output
- `profile.log` - Profile-related logs

View logs through Pterodactyl Panel's **Console** tab or by accessing the files directly.

### Enable Verbose Logging

For more detailed installation logs, you can modify the installation script to include debug output (edit the egg JSON before importing).

### Common Issues

**"Missing configuration" error:**
- Verify `config.json` exists and is valid JSON
- Check file permissions (should be owned by container:container)
- Run **Reinstall** to regenerate configuration

**"Steam authentication failed":**
- Verify Steam credentials are correct
- If using Steam Guard, provide the auth code in `STEAM_AUTH` variable
- For public servers, use anonymous login (blank credentials)

**Server not starting:**
- Check if `ArmaReforgerServer` binary exists
- Verify startup script `armareforger-server.sh` is executable
- Review console logs for error messages
- Ensure all required ports are allocated and not in use

**Config not updating:**
- Panel variables are substituted into `config.json` on each start
- Check startup logs for JSON parsing errors
- Verify variable names match those in the egg configuration

**Port conflicts:**
- Ensure ports are not already in use by another service
- Check firewall rules allow the required ports
- Verify port allocations in Pterodactyl Panel

**Permission denied:**
- All files should be owned by `container:container` (UID/GID 1000)
- Run **Reinstall** to fix permissions

## Port Requirements

The server requires the following ports to be allocated in Pterodactyl Panel:

| Port | Protocol | Purpose | Required |
|------|----------|---------|----------|
| 2001 | UDP | Game server | Yes |
| 17770 | UDP | A2S query (Steam) | Yes |
| 19998 | TCP | RCON admin | Optional |

**Note:** Port numbers can be customized in the server configuration.

## Development

### Modify Installation Script

When making changes to the installation script:

```bash
cd eggs/arma-reforger

# 1. Edit the installation script
nano installation-script.sh

# 2. Sync changes to the egg JSON
python3 sync-script-to-json.py

# 3. Validate the egg configuration
python3 validate-egg.py
```

### Add New Variable

1. Edit `egg-pterodactyl-arma-reforger.json`
2. Add the variable to the `variables[]` array
3. If the variable should be in `config.json`, add it to `config.files` parser
4. Run `validate-egg.py` to verify the changes

### Testing Changes

1. Import the updated egg JSON into a test Pterodactyl Panel
2. Create a test server
3. Run **Reinstall** to test installation
4. Start the server and verify functionality
5. Check all configuration variables work correctly

## Related Documentation

- [Docker Runtime Image](../../docker/steamcmd/README.md) - Runtime image details
- [Docker Installer Image](../../docker/installer/README.md) - Installation image details
- [Main Project README](../../README.md) - Project overview

## Support

For issues, questions, or contributions:
- GitHub Issues: [github.com/binhotm/pterodactyl.eggs/issues](https://github.com/binhotm/pterodactyl.eggs/issues)
- Discord: `mindisgurpe__`

## License

MIT License - see [LICENSE](../../LICENSE)

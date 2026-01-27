# Arma Reforger - Pterodactyl Egg

Production-ready egg for Arma Reforger Dedicated Server on Pterodactyl Panel.

## ⚠️ CRITICAL REQUIREMENT: Steam Authentication

**Arma Reforger Dedicated Server REQUIRES Steam account authentication** - anonymous login will fail.

### Before Installation:

1. **Steam Account Required**: You need a Steam account that **owns Arma Reforger**
2. **Configure Credentials**: Set these variables in Pterodactyl Panel before installation:
   - `STEAM_USER` - Your Steam username (REQUIRED)
   - `STEAM_PASS` - Your Steam password (REQUIRED)
   - `STEAM_AUTH` - Steam Guard code (only if 2FA enabled)

3. **Steam Guard (2FA) Considerations**:
   - **Recommended**: Temporarily disable Steam Guard during first installation
   - **Alternative**: Provide current Steam Guard code in `STEAM_AUTH` variable
   - The code expires quickly, so installation must complete before expiration

### Expected Error Without Authentication:

```
ERROR! Failed to install app '1874900' (Missing configuration)
```

This error indicates Steam credentials are missing or invalid.

## Installation and Execution

### Phase 1: Installation

Container: `fabriciojrsilva/steamcmd-eggs:installer`

The installation process performs the following operations:

1. Dependency verification (jq for JSON validation)
2. Steam credentials configuration (anonymous or authenticated)
3. Directory structure creation (profile/, tmp/)
4. Server files download via SteamCMD (App ID 1874900)
5. Configuration file generation from template
6. Variable substitution using sed
7. JSON validation with jq
8. Permission adjustment for steam user

### Phase 2: Runtime

Container: `cm2network/steamcmd:latest`

The server uses a dedicated startup script (`startup.sh`) that:

1. **Displays server configuration** - Shows all important settings before startup
2. **Logs operational parameters** - Network tuning, performance settings, directories
3. **Converts boolean values** - Transforms JSON string booleans to proper booleans
4. **Starts the server** - Executes ArmaReforgerServer with all configured parameters

Startup command:
```bash
bash startup.sh
```

The startup script displays:
- Server name, scenario, max players
- Bind IP/Port, A2S, RCON configuration
- Crossplay, BattlEye, visibility status
- Network tuning parameters (RPL timeout, NDS, streaming budgets)
- Performance settings (FPS limit, log intervals)
- Directory locations

**Example startup output:**
```
==========================================
Arma Reforger Dedicated Server - Starting
==========================================

[Server Configuration]
  Server Name:    My Arma Reforger Server
  Scenario:       {ECC61978EDCC2B5A}Missions/23_Campaign.conf
  Max Players:    128
  Bind IP:        192.168.1.100
  Bind Port:      2001
  A2S Port:       17777
  RCON Port:      19998
  Crossplay:      true
  BattlEye:       false
  Visible:        true

[Network Tuning]
  RPL Timeout:       10000ms
  NDS Diameter:      1
  Network Resolution: 250m
  Staggering Budget: 2500
  Streaming Budget:  400
  Streams Delta:     250

[Performance]
  Max FPS:        120
  Log Interval:   1000s
  Keep Logs:      10

[Directories]
  Config:         ./config.json
  Profile:        ./profile/
  Logs:           ./profile/console*.log

==========================================
Converting boolean values in config.json...
Starting server...
==========================================
```

## Custom Docker Image

Location: `../docker/arma-reforger/Dockerfile`

Includes pre-installed dependencies:
- jq (JSON validation)
- curl, ca-certificates (mod downloads)
- lib32gcc-s1, lib32stdc++6 (32-bit compatibility)
- iputils-ping (network diagnostics)

Build and publish:
```bash
cd docker/arma-reforger
docker build -t fabriciojrsilva/steamcmd-eggs:installer .
docker push fabriciojrsilva/steamcmd-eggs:installer
```

## Development Workflow

### Modifying the Installation Script

1. Edit `installation-script.sh` directly
2. Synchronize changes to egg JSON:
   ```bash
   python sync-script-to-json.py
   ```
3. Validate JSON structure:
   ```bash
   python -c "import json; json.load(open('egg-pterodactyl-arma-reforger.json'))"
   ```

### Adding Configuration Variables

Refer to `.github/copilot-instructions.md` for detailed instructions.

## Troubleshooting

### Installation Fails with "ERROR! Failed to install app '1874900' (Missing configuration)"

**Cause**: Arma Reforger requires Steam account authentication.

**Solution**:
1. Configure Steam credentials in Pterodactyl Panel:
   - Navigate to server → Startup tab
   - Set `STEAM_USER` to your Steam username
   - Set `STEAM_PASS` to your Steam password
   - If Steam Guard enabled, set `STEAM_AUTH` to current code
2. Ensure the Steam account owns Arma Reforger
3. Retry installation

**Alternative Solutions**:
- Temporarily disable Steam Guard for initial installation
- Use a dedicated server hosting account if available
- Contact Bohemia Interactive for dedicated server licensing

### Installation Errors

**Error: `/mnt/install/install.sh: Permission denied`**

This error typically indicates an issue with the egg import or Pterodactyl configuration:

1. **Re-import the egg**: Delete the old egg and import the latest JSON file
2. **Verify Docker image access**: Ensure Pterodactyl can pull `fabriciojrsilva/steamcmd-eggs:installer`
3. **Check Pterodactyl logs**: View daemon logs for detailed error messages
   ```bash
   # On Pterodactyl host
   docker logs pterodactyl_wings -f
   ```
4. **Verify entrypoint**: Ensure egg JSON has `"entrypoint": "/bin/bash"`

**Debugging Installation Process**

The installation script includes extensive debugging output with `set -x`. Each step shows:
- Current working directory and user
- Dependency availability
- SteamCMD download progress
- File verification with sizes
- JSON validation results
- Directory listings on error

To view full installation logs:
1. Navigate to server console in Pterodactyl Panel
2. Click "Install" or "Reinstall"
3. Watch real-time output for diagnostic information

**Common Issues**

- **SteamCMD fails**: Check network connectivity, Steam service status
- **JSON validation fails**: Review config.json content in debug output
- **Executable not found**: Verify App ID 1874900, check disk space
- **Permission errors during install**: Container runs as root during install phase, this is expected

### Runtime Errors

**Error: Server won't start**

1. Check config.json validity in file manager
2. Verify all boolean values are unquoted (true/false not "true"/"false")
3. Review startup command variables in egg configuration

**Error: Cannot find logs**

Logs are located at `profile/console*.log` - ensure this directory exists and has proper permissions.

## Deprecated Files

The following files are not used by Pterodactyl:
- `docker/arma-reforger/entrypoint.sh` - Egg JSON controls the entrypoint directly

## Technical Notes

- Pterodactyl Panel serves as the single source of truth for all server configurations
- Configuration file is regenerated on every installation to ensure consistency
- JSON validation prevents server crash loops from malformed configuration
- Boolean environment variables are converted from strings at startup
- Installation script runs with debugging enabled (`set -x`) for troubleshooting

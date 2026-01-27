# Arma Reforger - Pterodactyl Egg

Production-ready egg for Arma Reforger Dedicated Server on Pterodactyl Panel.

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

The server startup performs boolean conversion and launches the Arma Reforger server binary.

Startup command:
```bash
sed -i 's/"true"/true/g; s/"false"/false/g' config.json; ./ArmaReforgerServer -config ./config.json -profile ./profile -listScenarios -logStats $(({{LOG_INTERVAL}}*1000)) -maxFPS {{MAX_FPS}} -rpl-timeout-ms 30000
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

## Deprecated Files

The following files are not used by Pterodactyl:
- `docker/arma-reforger/entrypoint.sh` - Egg JSON controls the entrypoint directly

## Technical Notes

- Pterodactyl Panel serves as the single source of truth for all server configurations
- Configuration file is regenerated on every installation to ensure consistency
- JSON validation prevents server crash loops from malformed configuration
- Boolean environment variables are converted from strings at startup

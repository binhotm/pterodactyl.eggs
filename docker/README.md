# Docker Images

This directory contains Docker image sources for Pterodactyl Panel eggs.

## Overview

This project uses **two separate Docker images** following the official Pterodactyl architecture:

1. **Installer Image** - Used during the installation phase to download game files via SteamCMD
2. **Runtime Image** - Used to execute and run the game server with auto-update support

## Images

### installer/ - Installation Image

**Purpose:** Download and prepare game server files during Pterodactyl installation phase.

**Image Tag:** `fabriciojrsilva/steamcmd-eggs:installer`

**Features:**
- Minimal image optimized for SteamCMD downloads
- Includes 32-bit libraries required by SteamCMD
- Includes `jq` for JSON configuration parsing
- No ENTRYPOINT/CMD - Pterodactyl controls execution
- No pre-installed SteamCMD - Downloaded by installation script
- Base: `debian:bookworm-slim`

**Usage Flow:**
```
1. Pterodactyl creates container from installer image
2. Mounts /mnt/install with installation script
3. Executes: /bin/bash /mnt/install/install.sh
4. SteamCMD downloads game files to /mnt/server
5. Installation script generates config.json and startup scripts
6. Container is destroyed
```

### steamcmd/ - Runtime Image

**Purpose:** Execute and run game servers with automatic updates.

**Image Tags:** 
- `fabriciojrsilva/steamcmd-eggs:latest` (recommended for new servers)
- `fabriciojrsilva/steamcmd-eggs:arma-reforger` (version-specific tag)

**Features:**
- Optimized for runtime performance
- Includes entrypoint script for STARTUP command processing
- Auto-update support via SteamCMD (controlled by `AUTO_UPDATE` variable)
- Non-privileged user: `container` (UID 1000)
- Includes network tools for diagnostics
- Base: `debian:bookworm-slim`

**Usage Flow:**
```
1. Pterodactyl creates container from runtime image
2. Mounts server files to /home/container
3. Entrypoint processes STARTUP environment variable
4. Optional: Auto-update via SteamCMD
5. Executes startup command (e.g., bash armareforger-server.sh)
6. Game server runs
```

**Entrypoint Features:**
- Converts Pterodactyl variables: `{{VAR}}` → `${VAR}`
- Handles `STARTUP` command execution
- Auto-update support (set `AUTO_UPDATE=1`)
- SteamCMD integration for game updates

## Building Images

### Build Both Images

```bash
# Build installer image
cd docker/installer
docker build -t fabriciojrsilva/steamcmd-eggs:installer .

# Build runtime image
cd ../steamcmd
docker build -t fabriciojrsilva/steamcmd-eggs:latest -t fabriciojrsilva/steamcmd-eggs:arma-reforger .
```

### Push to Docker Hub

```bash
# Push installer
docker push fabriciojrsilva/steamcmd-eggs:installer

# Push runtime
docker push fabriciojrsilva/steamcmd-eggs:latest
docker push fabriciojrsilva/steamcmd-eggs:arma-reforger
```

## Image Comparison

| Aspect | Installer | Runtime |
|--------|-----------|---------|
| **Purpose** | Download game files | Execute server |
| **Tag** | `installer` | `latest` / `arma-reforger` |
| **User** | root (for installation) | container (UID 1000) |
| **Entrypoint** | None (Pterodactyl controlled) | entrypoint.sh |
| **Pre-installed SteamCMD** | No | No |
| **Size** | ~200MB | ~250MB |
| **Auto-update** | N/A | Yes (optional) |

## Pterodactyl Egg Configuration

The egg JSON defines both images:

```json
"docker_images": {
    "fabriciojrsilva/steamcmd-eggs:installer": "fabriciojrsilva/steamcmd-eggs:installer",
    "fabriciojrsilva/steamcmd-eggs:latest": "fabriciojrsilva/steamcmd-eggs:latest"
}
```

**Installation:**
```
container: fabriciojrsilva/steamcmd-eggs:installer
entrypoint: /bin/bash
```

**Runtime:**
```
image: fabriciojrsilva/steamcmd-eggs:latest
cmd: [ "/bin/bash", "/entrypoint.sh" ]
```

## Dependencies

Both images include:
- **32-bit Libraries:** `lib32gcc-s1`, `lib32stdc++6` (required for SteamCMD)
- **Tools:** `curl`, `tar`, `jq`, `ca-certificates`
- **Locales:** UTF-8 support
- **Network:** `iproute2`, `iputils-ping`, `net-tools`, `netcat-traditional` (runtime only)

## Documentation

- [installer/README.md](installer/README.md) - Installation image details
- [steamcmd/README.md](steamcmd/README.md) - Runtime image details
- [../eggs/arma-reforger/README.md](../eggs/arma-reforger/README.md) - Egg configuration details

## Version History

- **v2.0** - Separated installer and runtime images, refactored installation script
- **v1.0** - Initial unified image

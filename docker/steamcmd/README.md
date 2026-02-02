# SteamCMD Docker Image for Pterodactyl Panel

A lightweight, production-ready Docker image built for **Pterodactyl Panel Eggs**. Optimized for game server installations, runtime execution, and automatic updates.

Based on **Debian Trixie-Slim** for stability and minimal footprint.

---

## Quick Start

Add this image to your Pterodactyl Egg's Docker Images section:

```
fabriciojrsilva/steamcmd-eggs:latest
```

That's it! The image works for both **installation** and **runtime**.

---

## Available Tags

| Tag | Description | Use Case |
|-----|-------------|----------|
| `latest` | Unified image (recommended) | Installation + Runtime |
| `arma-reforger` | Same as latest | Alias for clarity |
| `installer` | Legacy installer image | Backwards compatibility |

---

## Features

### Unified Image
One image for both installation and runtime phases. No need to configure separate images.

### Auto-Update Support
Enable automatic game updates on server start by setting the environment variable:
```
AUTO_UPDATE=1
```
The container will check for and apply updates via SteamCMD before starting the server.

### Debian Trixie-Slim Base
- Stable and lightweight
- Tested on production Arma Reforger servers
- Full UTF-8 locale support

### SteamCMD Pre-installed
SteamCMD is pre-configured and ready to use, significantly reducing installation time.

### Security First
- Runs as non-root user `container` (UID 1000)
- Proper process management with Tini
- Graceful shutdown handling (SIGTERM/SIGINT)

### Pterodactyl Ready
- Correct entrypoint for `STARTUP` command processing
- Compatible with Wings and Pterodactyl install scripts
- Proper volume permissions

---

## Technical Details

| Property | Value |
|----------|-------|
| **Base Image** | `debian:trixie-slim` |
| **User** | `container` (UID 1000) |
| **SteamCMD Path** | `/home/container/steamcmd/steamcmd.sh` |
| **Working Directory** | `/home/container` |
| **Init System** | Tini |
| **Locale** | `en_US.UTF-8` |

### Pre-installed Tools
- `jq` - JSON parsing
- `curl`, `wget` - HTTP tools
- `tar`, `gzip` - Compression
- `nano` - Text editor
- `iputils-ping`, `iproute2` - Network diagnostics
- `procps` - Process utilities

---

## Supported Games

Currently optimized for:

| Game | App ID | Status |
|------|--------|--------|
| Arma Reforger | 1874900 | Tested and Production Ready |

More games can be supported. The image is generic enough for any SteamCMD-based game server.

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AUTO_UPDATE` | Enable auto-updates on start | `0` (disabled) |
| `SRCDS_APPID` | Steam App ID for the game | `1874900` |
| `STEAM_USER` | Steam username for login | `anonymous` |
| `STEAM_PASS` | Steam password | (empty) |
| `STEAM_AUTH` | Steam Guard code | (empty) |

---

## Usage with Pterodactyl

### 1. Configure Your Egg

In your egg JSON, set the Docker image:

```json
"docker_images": {
    "fabriciojrsilva/steamcmd-eggs:latest": "fabriciojrsilva/steamcmd-eggs:latest"
}
```

### 2. Installation Script

The image runs as **root during installation** (required for apt-get, chown, etc.) and as **container user during runtime**.

Your installation script should:
1. Download game files to `/mnt/server`
2. Set permissions: `chown -R container:container /mnt/server` (or use UID 1000)

### 3. Startup Command

Example startup command for Arma Reforger:
```bash
cd /home/container && bash armareforger-server.sh
```

---

## Comparison

| Feature | cm2network/steamcmd | This Image |
|---------|---------------------|------------|
| Entrypoint for Pterodactyl | No | Yes |
| Auto-Update Support | No | Yes |
| Unified Install/Runtime | Separate images | Single image |
| Process Management | Basic | Tini |
| Pre-installed Tools | Minimal | jq, curl, etc. |
| Base | Debian Bookworm | Debian Trixie-Slim |

---

## Troubleshooting

### Server doesn't start automatically
- Verify the entrypoint is processing `STARTUP` correctly
- Check container logs for error messages
- Ensure the startup script exists and is executable

### SteamCMD download fails
- Check network connectivity
- Verify Steam credentials (for non-anonymous games)
- Review the installation logs with `INSTALL_LOG=DEBUG`

### Permission denied errors
- Ensure files are owned by `container:container` (UID/GID 1000)
- The installation script should set permissions correctly

---

## Resources

- **GitHub Repository**: [github.com/binhotm/pterodactyl.eggs](https://github.com/binhotm/pterodactyl.eggs)
- **Pterodactyl Panel**: [pterodactyl.io](https://pterodactyl.io)
- **Discord Community**: [discord.gg/sasbr](https://discord.gg/sasbr)

---

## Author and Support

Maintained by **Fabricio Junior Silva** (SAS BR)

- Email: fabriciojuniorsilva@gmail.com
- GitHub: [@binhotm](https://github.com/binhotm)
- Discord: [discord.gg/sasbr](https://discord.gg/sasbr)

---

## License

MIT License - Feel free to use, modify, and distribute.

# Installer Image - SteamCMD

Docker image for **installation phase only** in Pterodactyl Panel.

## Purpose

This image is used by Pterodactyl Wings to execute installation scripts and download game server files via SteamCMD. It is **not used for runtime** - the game server runs in the runtime image.

## Image Details

**Tag:** `fabriciojrsilva/steamcmd-eggs:installer`

**Base:** `debian:bookworm-slim`

**Size:** ~200MB

## What's Included

- **32-bit Libraries:** `lib32gcc-s1`, `lib32stdc++6` (required for SteamCMD)
- **Tools:** `curl`, `tar`, `jq`, `ca-certificates`
- **Locale Support:** UTF-8 configured
- **Nothing Else:** Minimal and lightweight for fast download/execute

## How It Works

1. **Pterodactyl initiates installation** (user clicks "Reinstall")
2. **Wings creates container** from `fabriciojrsilva/steamcmd-eggs:installer`
3. **Mounts volumes:**
   - `/mnt/install` - Installation script from egg JSON
   - `/mnt/server` - Server files destination
4. **Executes:** `/bin/bash /mnt/install/install.sh`
5. **Installation script:**
   - Downloads SteamCMD from Steam CDN
   - Runs SteamCMD with game App ID
   - Installs 32/64-bit Steam SDK libraries
   - Generates `config.json` template
   - Generates startup script
   - Sets file permissions for runtime user
6. **Container destroyed** - files remain in `/mnt/server`

## Building

```bash
docker build -t fabriciojrsilva/steamcmd-eggs:installer .
```

## Pushing

```bash
docker push fabriciojrsilva/steamcmd-eggs:installer
```

## Environment Variables (during installation)

These are passed by Pterodactyl to the installation script:

| Variable | Description | Example |
|----------|-------------|---------|
| `STEAM_USER` | Steam username (blank = anonymous) | `anonymous` |
| `STEAM_PASS` | Steam password | (blank for anon) |
| `STEAM_AUTH` | Steam auth code (2FA) | (optional) |
| `SRCDS_APPID` | Steam App ID | `1874900` (Arma Reforger) |
| `EXTRA_FLAGS` | Extra SteamCMD flags | `validate` |

## Example Installation Script

```bash
#!/bin/bash
# Download SteamCMD
cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd

# Install game files
cd /mnt/server/steamcmd
./steamcmd.sh \
    +force_install_dir /mnt/server \
    +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
    +app_update ${SRCDS_APPID} ${EXTRA_FLAGS} validate \
    +quit

# Set up Steam SDK
mkdir -p /mnt/server/.steam/sdk32
cp linux32/steamclient.so /mnt/server/.steam/sdk32/

mkdir -p /mnt/server/.steam/sdk64
cp linux64/steamclient.so /mnt/server/.steam/sdk64/

# Generate config files
# ... (handled by egg installation script)

# Set permissions for runtime
chown -R container:container /mnt/server
```

## No ENTRYPOINT/CMD

Unlike the runtime image, this installer image has **no ENTRYPOINT or CMD** configured. Pterodactyl completely controls what script to execute via the egg JSON `scripts.installation.script` field.

## Notes

- **Network Required:** Downloads SteamCMD and game files from Steam CDN
- **Root User:** Installation runs as root (Pterodactyl requirement)
- **Temporary:** Container is destroyed after installation completes
- **No SteamCMD Pre-installed:** Downloaded fresh during each installation
- **User ID:** Not relevant for installer (no user created)

## Related

- [Runtime Image](../steamcmd/README.md) - Used to execute the server
- [Installation Script](../../eggs/arma-reforger/installation-script.sh) - What gets executed
- [Egg Configuration](../../eggs/arma-reforger/README.md) - Full egg docs

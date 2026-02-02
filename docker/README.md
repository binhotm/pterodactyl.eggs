# Docker Images

This directory contains Docker image sources for Pterodactyl eggs.

## steamcmd/

Unified Docker image for SteamCMD-based game servers.

- Works for both installation and runtime phases
- Pre-installed: SteamCMD, jq, curl, tini
- User: container (UID 1000)
- Base: debian:trixie-slim

### Build

```bash
./scripts/build-docker.sh
```

### Push

```bash
docker push fabriciojrsilva/steamcmd-eggs:latest
docker push fabriciojrsilva/steamcmd-eggs:arma-reforger
```

See [steamcmd/README.md](steamcmd/README.md) for detailed documentation.

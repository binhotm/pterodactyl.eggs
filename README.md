# Pterodactyl Eggs

![License](https://img.shields.io/github/license/fabriciojrsilva/pterodactyl.eggs)
![Pterodactyl](https://img.shields.io/badge/Pterodactyl-v1.0+-blue)
![Docker](https://img.shields.io/badge/Docker-Ready-blue)

Production-ready Pterodactyl Panel eggs for automated game server deployment. Features unified Docker images, automatic updates, and validated configurations.

## Available Eggs

| Game | Status | Features |
|------|--------|----------|
| [Arma Reforger](./eggs/arma-reforger/) | Stable | A2S, RCON, Crossplay, Auto-Update |

## Quick Start

### 1. Import the Egg

1. Download `egg-pterodactyl-arma-reforger.json` from [eggs/arma-reforger/](./eggs/arma-reforger/)
2. In Pterodactyl Panel: Admin > Nests > Import Egg
3. Upload the JSON file

### 2. Create Server

1. Create new server using the imported egg
2. Configure Steam credentials (required for Arma Reforger)
3. Start the server

## Docker Image

All eggs use a unified Docker image that works for both installation and runtime:

```
fabriciojrsilva/steamcmd-eggs:latest
```

### Features

- **Unified Image**: Single image for installation and runtime
- **Auto-Update**: Set `AUTO_UPDATE=1` to update on every start
- **Pre-installed Tools**: SteamCMD, jq, curl ready to use
- **Non-root Runtime**: Runs as unprivileged user for security
- **Tini Init**: Proper signal handling for graceful shutdown

### Build Locally

```bash
./scripts/build-docker.sh
```

## Project Structure

```
pterodactyl.eggs/
├── docker/
│   └── steamcmd/           # Docker image source
│       ├── Dockerfile
│       ├── entrypoint.sh
│       └── README.md
├── eggs/
│   └── arma-reforger/      # Arma Reforger egg
│       ├── egg-pterodactyl-arma-reforger.json
│       ├── installation-script.sh
│       └── README.md
├── scripts/
│   └── build-docker.sh     # Build Docker image
└── README.md
```

## Execution Flow

```
1. Docker Image Build
   └── Creates fabriciojrsilva/steamcmd-eggs:latest

2. Server Installation (Pterodactyl)
   └── Downloads game via SteamCMD
   └── Generates config.json and startup script
   └── Sets file permissions

3. Server Runtime
   └── Optional: Auto-update via SteamCMD
   └── Executes startup command
   └── Game server runs
```

## Configuration

All server settings are configurable through the Pterodactyl Panel UI. The egg automatically:

- Substitutes variables into `config.json`
- Converts string booleans to JSON booleans
- Ensures proper field types for passwords

## Contributing

1. Fork the repository
2. Create feature branch
3. For installation script changes:
   ```bash
   cd eggs/arma-reforger
   # Edit installation-script.sh
   python3 sync-script-to-json.py
   python3 validate-egg.py
   ```
4. Submit pull request

## License

MIT License - see [LICENSE](LICENSE)

---

Maintained by Fabricio Junior Silva

Discord: `mindisgurpe__`

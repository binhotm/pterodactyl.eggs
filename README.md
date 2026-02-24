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

## Docker Images

This project uses **two separate Docker images** following the official Pterodactyl architecture:

### Installation Image
```
fabriciojrsilva/steamcmd-eggs:installer
```
- Used during server installation to download game files via SteamCMD
- Minimal image optimized for installation phase
- Includes jq for JSON configuration parsing

### Runtime Image
```
fabriciojrsilva/steamcmd-eggs:latest
```
- Used to execute and run the game server
- Includes auto-update support via SteamCMD
- Runs as unprivileged `container` user for security
- Optimized for runtime performance

### Features

- **Two-Image Architecture**: Separate images for installation and runtime phases
- **Auto-Update**: Set `AUTO_UPDATE=1` to update on every server start
- **Pre-installed Tools**: SteamCMD, jq, curl, networking tools
- **Non-root Runtime**: Runs as unprivileged user for security
- **Graceful Shutdown**: Proper signal handling

### Build Locally

```bash
# Build installer image
docker build -t fabriciojrsilva/steamcmd-eggs:installer ./docker/installer

# Build runtime image
docker build -t fabriciojrsilva/steamcmd-eggs:latest ./docker/steamcmd
```

## Project Structure

```
pterodactyl.eggs/
├── docker/
│   ├── installer/           # Installation-only Docker image
│   │   ├── Dockerfile
│   │   └── README.md
│   ├── steamcmd/            # Runtime Docker image
│   │   ├── Dockerfile
│   │   ├── entrypoint.sh
│   │   └── README.md
│   └── README.md            # Docker images overview
├── eggs/
│   └── arma-reforger/       # Arma Reforger egg
│       ├── egg-pterodactyl-arma-reforger.json
│       ├── installation-script.sh
│       ├── README.md
│       ├── sync-script-to-json.py
│       └── validate-egg.py
├── scripts/
│   └── build-docker.sh      # Build Docker images
└── README.md
```

## Execution Flow

```
1. Installation Phase (Installer Image)
   ├── Pterodactyl creates container from fabriciojrsilva/steamcmd-eggs:installer
   ├── Downloads SteamCMD and game files
   ├── Generates config.json and startup script
   ├── Sets file permissions for container user
   └── Container destroyed after installation

2. Runtime Phase (Runtime Image)
   ├── Pterodactyl creates container from fabriciojrsilva/steamcmd-eggs:latest
   ├── Mounts server files to /home/container
   ├── Optional: Auto-update via SteamCMD (if AUTO_UPDATE=1)
   ├── Executes startup command
   └── Game server runs
```

## Configuration

All server settings are configurable through the Pterodactyl Panel UI. The installation script automatically:

- Downloads game files via SteamCMD
- Generates `config.json` with default values
- Creates startup script (`armareforger-server.sh`)
- Sets proper file permissions

The startup script processes configuration variables:
- Substitutes Pterodactyl variables into `config.json`
- Converts string booleans to JSON booleans
- Ensures proper field types for passwords

## Development

### Modify Installation Script

When making changes to the installation script:

```bash
cd eggs/arma-reforger

# 1. Edit installation-script.sh
nano installation-script.sh

# 2. Sync changes to egg JSON
python3 sync-script-to-json.py

# 3. Validate egg configuration
python3 validate-egg.py
```

### Testing

After making changes:
1. Import the updated egg JSON into Pterodactyl Panel
2. Create or reinstall a test server
3. Verify installation completes successfully
4. Test server startup and configuration

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes and test thoroughly
4. Submit a pull request with a clear description

## Support

For questions, bug reports, or feature requests:
- GitHub Issues: [github.com/binhotm/pterodactyl.eggs/issues](https://github.com/binhotm/pterodactyl.eggs/issues)
- Discord: `mindisgurpe__`

## License

MIT License - see [LICENSE](LICENSE)

---

**Maintained by Fabricio Junior Silva**

Discord: `mindisgurpe__`  
Email: fabriciojuniorsilva@gmail.com  
GitHub: [@binhotm](https://github.com/binhotm)

# Pterodactyl Eggs

![License](https://img.shields.io/github/license/SEU_USUARIO/pterodactyl.eggs)
![Pterodactyl](https://img.shields.io/badge/Pterodactyl-v1.0+-blue)

Production-ready Pterodactyl Panel eggs for game server deployment. This repository provides validated, enterprise-grade server configurations with enhanced reliability features.

## Available Server Eggs

| Game | Engine | Status | Key Features |
| :--- | :--- | :--- | :--- |
| Arma Reforger | Enfusion | Stable | JSON validation, automated configuration, optimized installation |

## Arma Reforger Server

Location: [`/eggs/arma-reforger/`](./eggs/arma-reforger/)

This egg includes several improvements over standard configurations:

**Configuration Management**
- JSON validation using `jq` prevents malformed configurations and crash loops
- Idempotent configuration regeneration ensures consistency across reinstalls
- Panel serves as single source of truth for all server settings

**Installation Process**
- Custom Docker image with pre-installed dependencies (`jq`, `curl`, 32-bit libraries)
- Dual-container strategy: root privileges for installation, unprivileged runtime
- Automated validation at every step

**Platform Support**
- Native crossplay configuration for PC, Xbox, and PlayStation platforms
- A2S query support for server browser integration
- RCON remote administration capability

### Installation Instructions

1. Download `egg-pterodactyl-arma-reforger.json` from the repository
2. Navigate to Pterodactyl Panel Admin area
3. Select Nests, then Import Egg
4. Upload the JSON file and configure nest settings
5. Create new server instance using the imported egg

### System Requirements

- Docker image: `fabriciojrsilva/steamcmd-eggs:installer` (installation) / `cm2network/steamcmd:latest` (runtime)
- Minimum RAM: 4GB recommended for stable operation
- Network: Ports configurable via panel (default: game 2001, A2S 17777, RCON 19998)

## Contributing

Contributions are accepted for script improvements, new configuration variables, and additional game server eggs.

Standard workflow:
1. Fork the repository
2. Create feature branch
3. Submit pull request with detailed description

## License

MIT License - see [LICENSE](LICENSE) file for complete terms.

---

Maintained by Fabricio Junior
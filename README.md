# Pterodactyl Eggs by SAS BR

![License](https://img.shields.io/github/license/SEU_USUARIO/pterodactyl.eggs)
![Pterodactyl](https://img.shields.io/badge/Pterodactyl-v1.0+-blue)

This repository contains high-performance, validated Eggs for [Pterodactyl Panel](https://pterodactyl.io).

Created to solve the scarcity of reliable, production-ready configurations for specific games, starting with **Arma Reforger**.

## 🚀 Available Eggs

| Game | Engine | Status | Highlights |
| :--- | :--- | :--- | :--- |
| **Arma Reforger** | Enfusion | ✅ Stable | JSON validation (`jq`), Auto-config, Optimized Install |

---

## 🛠️ Arma Reforger Egg

Located in: [`/arma-reforger/`](./arma-reforger/)

This is not just a copy-paste of the default egg. It includes several engineering improvements for stability and data integrity.

### Key Features
* **Safety First:** Implements `jq` to validate the generated `config.json` before starting the server. If the JSON is invalid, the server won't start, preventing crash loops.
* **Hybrid Installation:** Uses `cm2network/steamcmd:root` for installation (ensuring dependencies like `jq` and `curl` are present) and drops privileges correctly for runtime.
* **Idempotent Configuration:** The `config.json` is regenerated on every install/reinstall based on environment variables, ensuring the Panel is always the Single Source of Truth.
* **Crossplay Ready:** Native support for Xbox/PSN crossplay configuration variables.

### Installation
1.  Download the `egg-pterodactyl-arma-reforger.json` file.
2.  Go to your Pterodactyl Panel > **Nests** > **Import Egg**.
3.  Select the file and import it into the desired Nest.
4.  Create a new server using this Egg.

### Requirements
* **Docker Images:** Utilizes `cm2network/steamcmd` (standard) or compatible custom images.
* **Resources:** Recommended minimum of 4GB RAM for a stable Reforger instance.

---

## 🤝 Contributing

Contributions are welcome! If you have improvements for the install scripts or new variables:
1.  Fork this repository.
2.  Create a branch (`feature/new-variable`).
3.  Commit your changes.
4.  Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Maintained by Fabricio Junior (SAS BR Team)*
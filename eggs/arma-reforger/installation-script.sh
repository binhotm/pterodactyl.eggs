#!/bin/bash
# Arma Reforger Installation Script
# Container: cm2network/steamcmd:root (runs as ROOT during install)
# Runtime: cm2network/steamcmd:latest (runs as non-root)
#
# Server Files: /mnt/server (becomes /home/container at runtime)

##
# Variables
# SRCDS_APPID - 1874900 (Arma Reforger Dedicated Server)
##

cd /mnt/server

echo "=========================================="
echo "Arma Reforger Server - Installation"
echo "=========================================="

## Check if jq is available (should be in custom Docker image)
if ! command -v jq &> /dev/null; then
    echo "[1/6] Installing jq for JSON validation..."
    apt-get update > /dev/null 2>&1
    apt-get install -y --no-install-recommends jq > /dev/null 2>&1
else
    echo "[1/6] Dependencies verified (jq available)"
fi

## Clean input variables
SERVER_NAME="$(echo "$SERVER_NAME" | xargs)"
RCON_PASSWORD="$(echo "$RCON_PASSWORD" | xargs)"
ADMIN_PASS="$(echo "$ADMIN_PASS" | xargs)"

## Set default steam credentials
if [ -z "${STEAM_USER}" ] || [ -z "${STEAM_PASS}" ]; then
    echo "[2/6] Using anonymous Steam login..."
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo "[2/6] Using Steam account: ${STEAM_USER}"
fi

## Create required directories
echo "[3/6] Creating server directories..."
mkdir -p /mnt/server/profile /mnt/server/tmp

## Fix permissions for steam user
chown -R steam:steam /mnt/server

## Install game files via SteamCMD (must run as 'steam' user, not root)
echo "[4/6] Downloading Arma Reforger Server files (App ID: ${SRCDS_APPID})..."
echo "This may take several minutes depending on your connection..."

su - steam -c "/home/steam/steamcmd/steamcmd.sh +force_install_dir /mnt/server +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +app_update ${SRCDS_APPID} ${INSTALL_FLAGS} validate +quit"

## Verify installation
if [ ! -f "/mnt/server/ArmaReforgerServer" ]; then
    echo "=========================================="
    echo "ERROR: Installation failed!"
    echo "The ArmaReforgerServer executable was not found."
    echo "=========================================="
    echo "Possible causes:"
    echo "  - Invalid Steam credentials"
    echo "  - Network connectivity issues"
    echo "  - Insufficient disk space"
    echo "  - Steam service is down"
    echo "=========================================="
    exit 1
fi

## Generate initial config.json
echo "[5/6] Generating default configuration..."
cat > /mnt/server/config.json << 'EOFCONFIG'
{
	"bindAddress": "0.0.0.0",
	"bindPort": SERVER_PORT_PLACEHOLDER,
	"publicAddress": "SERVER_IP_PLACEHOLDER",
	"publicPort": SERVER_PORT_PLACEHOLDER,
	"a2s": {
		"address": "A2S_ADDRESS_PLACEHOLDER",
		"port": A2S_PORT_PLACEHOLDER
	},
	"rcon": {
		"address": "RCON_ADDRESS_PLACEHOLDER",
		"port": RCON_PORT_PLACEHOLDER,
		"password": "RCON_PASSWORD_PLACEHOLDER",
		"permission": "admin"
	},
	"game": {
		"name": "SERVER_NAME_PLACEHOLDER",
		"password": "SERVER_PASS_PLACEHOLDER",
		"passwordAdmin": "ADMIN_PASS_PLACEHOLDER",
		"admins": ADMINS_JSON_PLACEHOLDER,
		"scenarioId": "SCENARIO_ID_PLACEHOLDER",
		"maxPlayers": MAX_PLAYERS_PLACEHOLDER,
		"visible": VISIBLE_PLACEHOLDER,
		"crossPlatform": CROSS_PLATFORM_PLACEHOLDER,
		"supportedPlatforms": ["PLATFORM_PC", "PLATFORM_XBL", "PLATFORM_PSN"],
		"gameProperties": {
			"serverMaxViewDistance": MAX_VIEW_DISTANCE_PLACEHOLDER,
			"serverMinGrassDistance": MIN_GRASS_DISTANCE_PLACEHOLDER,
			"networkViewDistance": NETWORK_VIEW_DISTANCE_PLACEHOLDER,
			"disableThirdPerson": DISABLE_THIRD_PLACEHOLDER,
			"fastValidation": true,
			"battlEye": BATTLEYE_PLACEHOLDER,
			"VONDisableUI": VON_DISABLE_UI_PLACEHOLDER,
			"VONDisableDirectSpeechUI": VON_DISABLE_DIRECT_UI_PLACEHOLDER,
			"VONCanTransmitCrossFaction": VON_CROSS_FACTION_PLACEHOLDER,
			"missionHeader": {}
		},
		"modsRequiredByDefault": MODS_REQUIRED_PLACEHOLDER,
		"mods": MODS_JSON_PLACEHOLDER
	},
	"operating": {
		"aiLimit": AI_LIMIT_PLACEHOLDER,
		"disableAI": DISABLE_AI_PLACEHOLDER,
		"disableCrashReporter": false,
		"disableNavmeshStreaming": [],
		"disableServerShutdown": DISABLE_SHUTDOWN_PLACEHOLDER,
		"joinQueue": {
			"maxSize": QUEUE_MAX_SIZE_PLACEHOLDER
		},
		"lobbyPlayerSynchronise": true,
		"playerSaveTime": PLAYER_SAVE_TIME_PLACEHOLDER,
		"slotReservationTimeout": SLOT_RESERVATION_TIMEOUT_PLACEHOLDER
	}
}
EOFCONFIG

## Replace placeholders with actual values using sed
sed -i "s/SERVER_PORT_PLACEHOLDER/${SERVER_PORT}/g" /mnt/server/config.json
sed -i "s/SERVER_IP_PLACEHOLDER/${SERVER_IP}/g" /mnt/server/config.json
sed -i "s/A2S_ADDRESS_PLACEHOLDER/${A2S_ADDRESS}/g" /mnt/server/config.json
sed -i "s/A2S_PORT_PLACEHOLDER/${A2S_PORT}/g" /mnt/server/config.json
sed -i "s/RCON_ADDRESS_PLACEHOLDER/${RCON_ADDRESS}/g" /mnt/server/config.json
sed -i "s/RCON_PORT_PLACEHOLDER/${RCON_PORT}/g" /mnt/server/config.json
sed -i "s/RCON_PASSWORD_PLACEHOLDER/${RCON_PASSWORD}/g" /mnt/server/config.json
sed -i "s/SERVER_NAME_PLACEHOLDER/${SERVER_NAME}/g" /mnt/server/config.json
sed -i "s/SERVER_PASS_PLACEHOLDER/${SERVER_PASS}/g" /mnt/server/config.json
sed -i "s/ADMIN_PASS_PLACEHOLDER/${ADMIN_PASS}/g" /mnt/server/config.json
sed -i "s/ADMINS_JSON_PLACEHOLDER/${ADMINS_JSON}/g" /mnt/server/config.json
sed -i "s|SCENARIO_ID_PLACEHOLDER|${SCENARIO_ID}|g" /mnt/server/config.json
sed -i "s/MAX_PLAYERS_PLACEHOLDER/${MAX_PLAYERS}/g" /mnt/server/config.json
sed -i "s/VISIBLE_PLACEHOLDER/${VISIBLE}/g" /mnt/server/config.json
sed -i "s/CROSS_PLATFORM_PLACEHOLDER/${CROSS_PLATFORM}/g" /mnt/server/config.json
sed -i "s/MAX_VIEW_DISTANCE_PLACEHOLDER/${MAX_VIEW_DISTANCE}/g" /mnt/server/config.json
sed -i "s/MIN_GRASS_DISTANCE_PLACEHOLDER/${MIN_GRASS_DISTANCE}/g" /mnt/server/config.json
sed -i "s/NETWORK_VIEW_DISTANCE_PLACEHOLDER/${NETWORK_VIEW_DISTANCE}/g" /mnt/server/config.json
sed -i "s/DISABLE_THIRD_PLACEHOLDER/${DISABLE_THIRD}/g" /mnt/server/config.json
sed -i "s/BATTLEYE_PLACEHOLDER/${BATTLEYE}/g" /mnt/server/config.json
sed -i "s/VON_DISABLE_UI_PLACEHOLDER/${VON_DISABLE_UI}/g" /mnt/server/config.json
sed -i "s/VON_DISABLE_DIRECT_UI_PLACEHOLDER/${VON_DISABLE_DIRECT_UI}/g" /mnt/server/config.json
sed -i "s/VON_CROSS_FACTION_PLACEHOLDER/${VON_CROSS_FACTION}/g" /mnt/server/config.json
sed -i "s/MODS_REQUIRED_PLACEHOLDER/${MODS_REQUIRED}/g" /mnt/server/config.json
sed -i "s/MODS_JSON_PLACEHOLDER/${MODS_JSON}/g" /mnt/server/config.json
sed -i "s/AI_LIMIT_PLACEHOLDER/${AI_LIMIT}/g" /mnt/server/config.json
sed -i "s/DISABLE_AI_PLACEHOLDER/${DISABLE_AI}/g" /mnt/server/config.json
sed -i "s/DISABLE_SHUTDOWN_PLACEHOLDER/${DISABLE_SHUTDOWN}/g" /mnt/server/config.json
sed -i "s/QUEUE_MAX_SIZE_PLACEHOLDER/${QUEUE_MAX_SIZE}/g" /mnt/server/config.json
sed -i "s/PLAYER_SAVE_TIME_PLACEHOLDER/${PLAYER_SAVE_TIME}/g" /mnt/server/config.json
sed -i "s/SLOT_RESERVATION_TIMEOUT_PLACEHOLDER/${SLOT_RESERVATION_TIMEOUT}/g" /mnt/server/config.json

## Validate generated config.json
echo "[6/6] Validating configuration file..."
if jq empty /mnt/server/config.json 2>/dev/null; then
    echo "config.json is valid JSON"
else
    echo "=========================================="
    echo "ERROR: config.json validation failed!"
    echo "The generated configuration contains invalid JSON."
    echo "=========================================="
    echo "Debugging info:"
    jq empty /mnt/server/config.json 2>&1
    echo "=========================================="
    exit 1
fi

## Fix permissions one more time
chown -R steam:steam /mnt/server

echo "=========================================="
echo "Installation completed successfully!"
echo "Server binary: /mnt/server/ArmaReforgerServer"
echo "Config file: /mnt/server/config.json (validated)"
echo "Profile directory: /mnt/server/profile"
echo "=========================================="

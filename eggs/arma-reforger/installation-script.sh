#!/bin/bash
#
# Pterodactyl Panel - Arma Reforger Installation Script
# ====================================================
#
# Purpose: Install Arma Reforger server files via SteamCMD
# Image:   fabriciojrsilva/steamcmd-eggs:installer
# Runtime: fabriciojrsilva/steamcmd-eggs:latest (with auto-update)
#
# Variables:
#   STEAM_USER   - Steam username (leave blank for anonymous)
#   STEAM_PASS   - Steam password
#   STEAM_AUTH   - Steam guard auth token (if 2FA enabled)
#   SRCDS_APPID  - App ID (1874900 = Arma Reforger)
#   EXTRA_FLAGS  - Extra SteamCMD flags (beta, validate, etc)
#

##
# Set default Steam user to anonymous
##
if [ "${STEAM_USER}" == "" ]; then
    echo -e "Steam user is not set.\n"
    echo -e "Using anonymous user.\n"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "Steam user set to ${STEAM_USER}"
fi

##
# Download and install SteamCMD
##
echo "Downloading SteamCMD..."
cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd

# Fix steamcmd disk write error when this folder is missing
mkdir -p /mnt/server/steamapps

cd /mnt/server/steamcmd

# SteamCMD fails otherwise for some reason, even running as root.
# This is changed at the end of the install process anyways.
chown -R root:root /mnt
export HOME=/mnt/server

##
# Install game using SteamCMD
##
echo "Installing Arma Reforger (App ID: ${SRCDS_APPID:-1874900})..."
./steamcmd.sh \
    +force_install_dir /mnt/server \
    +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
    +app_update ${SRCDS_APPID:-1874900} ${EXTRA_FLAGS} validate \
    +quit

##
# Set up 32-bit libraries
##
echo "Setting up 32-bit Steam libraries..."
mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so /mnt/server/.steam/sdk32/steamclient.so

##
# Set up 64-bit libraries
##
echo "Setting up 64-bit Steam libraries..."
mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so /mnt/server/.steam/sdk64/steamclient.so

##
# Verify installation
##
if [ ! -f "/mnt/server/ArmaReforgerServer" ]; then
    echo "ERROR: ArmaReforgerServer binary not found!"
    ls -la /mnt/server/ || true
    exit 1
fi

echo "(OK) ArmaReforgerServer binary verified: $(du -h /mnt/server/ArmaReforgerServer | cut -f1)"

##
# Generate default config.json
##
echo "Generating default config.json..."
cat > /mnt/server/config.json << 'EOFCONFIG'
{
    "bindAddress": "0.0.0.0",
    "bindPort": 2001,
    "publicAddress": "0.0.0.0",
    "publicPort": 2001,
    "a2s": {
        "address": "0.0.0.0",
        "port": 17770
    },
    "rcon": {
        "address": "0.0.0.0",
        "port": 19998,
        "password": "changeme",
        "permission": "admin"
    },
    "game": {
        "name": "Arma Reforger Server",
        "password": "",
        "passwordAdmin": "changeme",
        "admins": [],
        "scenarioId": "{ECC61978EDCC2B5A}Missions/23_Campaign.conf",
        "maxPlayers": 64,
        "visible": true,
        "crossPlatform": true,
        "supportedPlatforms": ["PLATFORM_PC", "PLATFORM_XBL", "PLATFORM_PSN"],
        "gameProperties": {
            "serverMaxViewDistance": 5000,
            "serverMinGrassDistance": 50,
            "networkViewDistance": 1500,
            "disableThirdPerson": false,
            "fastValidation": true,
            "battlEye": false,
            "VONDisableUI": false,
            "VONDisableDirectSpeechUI": false,
            "VONCanTransmitCrossFaction": false,
            "missionHeader": {}
        },
        "modsRequiredByDefault": false,
        "mods": []
    },
    "operating": {
        "aiLimit": -1,
        "disableAI": false,
        "disableCrashReporter": false,
        "disableServerShutdown": false,
        "joinQueue": {
            "maxSize": 30
        },
        "playerSaveTime": 120,
        "slotReservationTimeout": 60
    }
}
EOFCONFIG

# Validate config.json
if ! jq empty /mnt/server/config.json 2>/dev/null; then
    echo "ERROR: Generated config.json is invalid!"
    exit 1
fi
echo "(OK) config.json validated"

##
# Generate startup script
##
echo "Generating armareforger-server.sh..."
cat > /mnt/server/armareforger-server.sh << 'EOFSTARTUP'
#!/bin/bash
# Arma Reforger Server - Startup Script

echo "=========================================="
echo "Arma Reforger Dedicated Server"
echo "=========================================="

# Display server configuration
if [ -f "config.json" ]; then
    echo "Server:   $(jq -r '.game.name // "N/A"' config.json)"
    echo "Players:  $(jq -r '.game.maxPlayers // "N/A"' config.json)"
    echo "Scenario: $(jq -r '.game.scenarioId // "N/A"' config.json)"
    echo "Port:     $(jq -r '.bindPort // "N/A"' config.json)"
fi
echo ""

# Fix boolean values in config.json (ensure true/false are not strings)
sed -i 's/"true"/true/g; s/"false"/false/g' config.json

# Ensure password fields are strings (jq forces them to be strings)
jq '.game.password = (.game.password | tostring) | 
    .game.passwordAdmin = (.game.passwordAdmin | tostring) | 
    .rcon.password = (.rcon.password | tostring)' config.json > config.json.tmp && mv config.json.tmp config.json

# Create profile directory if it doesn't exist
mkdir -p ./profile

echo "Starting Arma Reforger Server..."
echo "=========================================="

exec ./ArmaReforgerServer \
    -config ./config.json \
    -profile ./profile \
    -logStats $((${LOG_INTERVAL:-60}*1000)) \
    -maxFPS ${MAX_FPS:-60} \
    -rpl-timeout-ms ${RPL_TIMEOUT:-30000} \
    -nds ${NDS:-0} \
    -nwkResolution ${NWK_RESOLUTION:-500} \
    -staggeringBudget ${STAGGERING_BUDGET:-100} \
    -streamingBudget ${STREAMING_BUDGET:-10000} \
    -streamsDelta ${STREAMS_DELTA:-50} \
    -keepNumOfLogs ${KEEP_NUM_LOGS:-10} \
    -autoreload 10 \
    -autoshutdown
EOFSTARTUP

chmod +x /mnt/server/armareforger-server.sh
echo "(OK) armareforger-server.sh created and executable"

##
# Set permissions for runtime (container user)
##
echo "Setting file permissions for container user..."
chown -R container:container /mnt/server || chown -R 1000:1000 /mnt/server
echo "(OK) Permissions set"

echo ""
echo "=========================================="
echo "Installation completed successfully!"
echo "=========================================="
echo "Binary:      ArmaReforgerServer"
echo "Total Size:  $(du -sh /mnt/server 2>/dev/null | cut -f1)"
echo "Config:      config.json"
echo "Startup:     armareforger-server.sh"
echo "=========================================="

#!/bin/bash
# Arma Reforger Installation Script
# Container: fabriciojrsilva/steamcmd-eggs:latest (unified image)
# Runtime: fabriciojrsilva/steamcmd-eggs:latest (same image)
# Server Files: /mnt/server (mounted to /home/container at runtime)

set -e

##
# Variables
# SRCDS_APPID - 1874900 (Arma Reforger Dedicated Server)
# INSTALL_LOG - DEBUG or INFO (default: INFO)
##

INSTALL_LOG="${INSTALL_LOG:-INFO}"
[ "${INSTALL_LOG}" = "DEBUG" ] && set -x

log_info() { echo "$1"; }
log_debug() { [ "${INSTALL_LOG}" = "DEBUG" ] && echo "  [DEBUG] $1"; }
log_step() { echo "[$1] $2"; }
log_error() { echo "ERROR: $1"; }

log_info "=========================================="
log_info "Arma Reforger Server - Installation"
log_info "=========================================="

cd /mnt/server
export HOME=/mnt/server

## Configure Steam credentials
log_step "1/5" "Configuring Steam credentials..."
if [ -z "${STEAM_USER}" ] || [ -z "${STEAM_PASS}" ]; then
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
    log_info "  Using: anonymous login"
else
    log_info "  Using: ${STEAM_USER}"
fi

## Create directories
log_step "2/5" "Preparing directories..."
mkdir -p /mnt/server/{steamcmd,steamapps,profile,tmp}

## Test network connectivity
if ! curl -s --connect-timeout 5 -o /dev/null http://steamcommunity.com\; then
    log_error "No network connectivity - cannot reach Steam servers"
    exit 1
fi

## Download SteamCMD
log_step "3/5" "Downloading server files..."
cd /tmp
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzf steamcmd.tar.gz -C /mnt/server/steamcmd
cd /mnt/server/steamcmd

## SteamCMD download with retry logic
MAX_RETRIES=5
RETRY_COUNT=0
DOWNLOAD_SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    log_info "  Attempt ${RETRY_COUNT}/${MAX_RETRIES}..."
    
    if timeout 1800 /mnt/server/steamcmd/steamcmd.sh \
        +force_install_dir /mnt/server \
        +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
        +app_update ${SRCDS_APPID} ${INSTALL_FLAGS} validate \
        +quit; then
        DOWNLOAD_SUCCESS=true
        break
    fi
    
    [ $RETRY_COUNT -lt $MAX_RETRIES ] && sleep $((RETRY_COUNT * 5))
done

if [ "$DOWNLOAD_SUCCESS" != "true" ]; then
    log_error "SteamCMD download failed after ${MAX_RETRIES} attempts"
    exit 1
fi

## Setup Steam SDK libraries
mkdir -p /mnt/server/.steam/{sdk32,sdk64}
cp /mnt/server/steamcmd/linux32/steamclient.so /mnt/server/.steam/sdk32/ 2>/dev/null || true
cp /mnt/server/steamcmd/linux64/steamclient.so /mnt/server/.steam/sdk64/ 2>/dev/null || true

## Verify installation
log_step "4/5" "Verifying installation..."
if [ ! -f "/mnt/server/ArmaReforgerServer" ]; then
    log_error "ArmaReforgerServer binary not found"
    [ "${INSTALL_LOG}" = "DEBUG" ] && ls -la /mnt/server/
    exit 1
fi
log_info "  Binary: $(du -h /mnt/server/ArmaReforgerServer | cut -f1)"

## Generate config.json template
log_step "5/5" "Generating configuration..."
cat > /mnt/server/config.json << 'EOFCONFIG'
{
	"bindAddress": "0.0.0.0",
	"bindPort": 2001,
	"publicAddress": "0.0.0.0",
	"publicPort": 2001,
	"a2s": {
		"address": "0.0.0.0",
		"port": 1770
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

## Validate JSON
if ! jq empty /mnt/server/config.json 2>/dev/null; then
    log_error "Generated config.json is invalid"
    exit 1
fi

## Generate startup script
cat > /mnt/server/armareforger-server.sh << 'EOFSTARTUP'
#!/bin/bash
# Arma Reforger Server - Startup Script

echo "=========================================="
echo "Arma Reforger Dedicated Server"
echo "=========================================="

# Display config
if [ -f "config.json" ]; then
    echo "Server: $(jq -r '.game.name // "N/A"' config.json)"
    echo "Players: $(jq -r '.game.maxPlayers // "N/A"' config.json)"
    echo "Scenario: $(jq -r '.game.scenarioId // "N/A"' config.json)"
fi
echo ""

# Fix boolean values in config.json
sed -i 's/"true"/true/g; s/"false"/false/g' config.json

# Ensure password fields are strings
jq '.game.password = (.game.password | tostring) | 
    .game.passwordAdmin = (.game.passwordAdmin | tostring) | 
    .rcon.password = (.rcon.password | tostring)' config.json > config.json.tmp && mv config.json.tmp config.json

echo "Starting server..."
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
    -keepNumOfLogs ${KEEP_NUM_LOGS:-10}
EOFSTARTUP

chmod +x /mnt/server/armareforger-server.sh

## Set permissions for runtime user
if id "container" &>/dev/null; then
    RUNTIME_USER="container"
elif id "steam" &>/dev/null; then
    RUNTIME_USER="steam"
else
    RUNTIME_USER="1000"
fi
chown -R ${RUNTIME_USER}:${RUNTIME_USER} /mnt/server

log_info "=========================================="
log_info "Installation completed!"
log_info "  Binary: ArmaReforgerServer"
log_info "  Size: $(du -sh /mnt/server 2>/dev/null | cut -f1)"
log_info "=========================================="

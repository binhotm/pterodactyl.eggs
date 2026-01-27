#!/bin/bash
# Arma Reforger Installation Script
# Container: cm2network/steamcmd:root (runs as ROOT during install)
# Runtime: cm2network/steamcmd:latest (runs as non-root)
#
# Server Files: /mnt/server (becomes /home/container at runtime)

# Enable error reporting
set -e  # Exit on any error

##
# Variables
# SRCDS_APPID - 1874900 (Arma Reforger Dedicated Server)
# INSTALL_LOG - DEBUG or INFO (default: INFO)
##

# Configure logging level
INSTALL_LOG="${INSTALL_LOG:-INFO}"

if [ "${INSTALL_LOG}" = "DEBUG" ]; then
    set -x  # Print each command before executing (verbose mode)
fi

# Logging functions
log_info() {
    echo "$1"
}

log_debug() {
    if [ "${INSTALL_LOG}" = "DEBUG" ]; then
        echo "  [DEBUG] $1"
    fi
}

log_step() {
    echo "[$1] $2"
}

log_substep() {
    echo "  -> $1"
}

log_error() {
    echo "=========================================="
    echo "ERROR: $1"
    echo "=========================================="
}

log_info "=========================================="
log_info "Arma Reforger Server - Installation"
log_info "Logging Level: ${INSTALL_LOG}"
log_info "=========================================="

log_debug "Working directory: $(pwd)"
log_debug "User: $(whoami)"
log_debug "App ID: ${SRCDS_APPID}"

cd /mnt/server

## Check if jq is available (should be in custom Docker image)
log_step "1/6" "Checking dependencies..."
if ! command -v jq &> /dev/null; then
    log_substep "jq not found, installing..."
    apt-get update > /dev/null 2>&1
    apt-get install -y --no-install-recommends jq > /dev/null 2>&1
    log_substep "jq installed successfully"
else
    log_debug "jq available: $(which jq)"
fi

## Clean input variables
log_step "2/6" "Configuring installation parameters..."
SERVER_NAME="$(echo "$SERVER_NAME" | xargs)"
RCON_PASSWORD="$(echo "$RCON_PASSWORD" | xargs)"
ADMIN_PASS="$(echo "$ADMIN_PASS" | xargs)"
log_debug "Server name: ${SERVER_NAME}"
log_debug "App ID: ${SRCDS_APPID}"

## Set default steam credentials
if [ -z "${STEAM_USER}" ] || [ -z "${STEAM_PASS}" ]; then
    log_substep "Using anonymous Steam login"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    log_substep "Using Steam account: ${STEAM_USER}"
fi

## Create required directories
log_step "3/6" "Creating server directories..."
mkdir -p /mnt/server/profile /mnt/server/tmp
log_debug "Directories created: profile, tmp"
log_debug "Setting permissions for steam user..."
chown -R steam:steam /mnt/server

## Install game files via SteamCMD (must run as 'steam' user, not root)
log_step "4/6" "Downloading Arma Reforger Server files (App ${SRCDS_APPID})..."
log_debug "Install directory: /mnt/server"

## Test network connectivity before attempting download
log_debug "Testing network connectivity..."
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    log_debug "Network connectivity OK (8.8.8.8)"
elif ping -c 1 1.1.1.1 > /dev/null 2>&1; then
    log_debug "Network connectivity OK (1.1.1.1)"
else
    log_error "No network connectivity!"
    log_info "The container cannot reach the internet."
    log_info ""
    log_info "Troubleshooting steps:"
    log_info "  1. Check Pterodactyl Wings network configuration"
    log_info "  2. Verify Docker network: docker network ls"
    log_info "  3. Check firewall rules on the host"
    log_info "  4. Test: docker run --rm alpine ping -c 1 8.8.8.8"
    log_info ""
    log_info "Common causes:"
    log_info "  - Wings network_mode misconfiguration"
    log_info "  - Docker bridge network issues"
    log_info "  - Host firewall blocking container traffic"
    log_info "  - DNS resolution problems"
    log_info "=========================================="
    exit 1
fi

## Test Steam connectivity
log_debug "Testing Steam connectivity..."
if ping -c 1 steamcontent.com > /dev/null 2>&1 || ping -c 1 steamcdn-a.akamaihd.net > /dev/null 2>&1; then
    log_debug "Steam servers reachable"
else
    log_debug "WARNING: Cannot ping Steam servers (may still work)"
fi

log_substep "Starting SteamCMD download (this may take several minutes)..."

su - steam -c "/home/steam/steamcmd/steamcmd.sh +force_install_dir /mnt/server +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +app_update ${SRCDS_APPID} ${INSTALL_FLAGS} validate +quit"

log_substep "Download completed"

## Verify installation
log_step "5/6" "Verifying installation..."

if [ ! -f "/mnt/server/ArmaReforgerServer" ]; then
    log_error "Installation failed!"
    log_info "The ArmaReforgerServer executable was not found."
    log_info "=========================================="
    if [ "${INSTALL_LOG}" = "DEBUG" ]; then
        log_info "Directory contents:"
        ls -lah /mnt/server/ || log_info "Cannot list directory"
        log_info "=========================================="
    fi
    log_info "Possible causes:"
    log_info "  - Invalid Steam credentials"
    log_info "  - Network connectivity issues"
    log_info "  - Insufficient disk space"
    log_info "  - Steam service is down"
    log_info "  - Wrong App ID (current: ${SRCDS_APPID})"
    log_info "=========================================="
    exit 1
fi

log_substep "ArmaReforgerServer found ($(du -h /mnt/server/ArmaReforgerServer | cut -f1))"

## Generate initial config.json
log_step "6/6" "Generating default configuration..."
cat > /mnt/server/config.json << 'EOFCONFIG'
{
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
sed -i "s/SERVER_IP_PLACEHOLDER/${SERVER_IP}/g" /mnt/server/config.json
sed -i "s/SERVER_PORT_PLACEHOLDER/${SERVER_PORT}/g" /mnt/server/config.json
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

log_debug "Configuration template generated"
log_debug "Placeholders replaced with actual values"

## Validate generated config.json
log_substep "Validating JSON structure..."
if jq empty /mnt/server/config.json 2>/dev/null; then
    log_substep "config.json is valid ✓"
else
    log_error "config.json validation failed!"
    log_info "The generated configuration contains invalid JSON."
    log_info "=========================================="
    if [ "${INSTALL_LOG}" = "DEBUG" ]; then
        log_info "config.json content:"
        cat /mnt/server/config.json || log_info "Cannot read config.json"
        log_info "=========================================="
        log_info "Validation errors:"
        jq empty /mnt/server/config.json 2>&1
    fi
    log_info "=========================================="
    exit 1
fi

## Generate startup script with informative logging
echo "  -> Generating startup script..."
cat > /mnt/server/startup.sh << 'EOFSTARTUP'
#!/bin/bash
# Arma Reforger Server - Startup Script
# This script displays server configuration and starts the Arma Reforger server

echo "=========================================="
echo "Arma Reforger Dedicated Server - Starting"
echo "=========================================="
echo ""

# Display server configuration
echo "[Server Configuration]"
if [ -f "config.json" ]; then
    echo "  Server Name:    $(jq -r '.game.name // "N/A"' config.json)"
    echo "  Scenario:       $(jq -r '.game.scenarioId // "N/A"' config.json)"
    echo "  Max Players:    $(jq -r '.game.maxPlayers // "N/A"' config.json)"
    echo "  Bind IP:        ${SERVER_IP:-0.0.0.0}"
    echo "  Bind Port:      ${SERVER_PORT:-2001}"
    echo "  A2S Port:       $(jq -r '.a2s.port // "N/A"' config.json)"
    echo "  RCON Port:      $(jq -r '.rcon.port // "N/A"' config.json)"
    echo "  Crossplay:      $(jq -r '.game.crossPlatform // "N/A"' config.json)"
    echo "  BattlEye:       $(jq -r '.game.gameProperties.battlEye // "N/A"' config.json)"
    echo "  Visible:        $(jq -r '.game.visible // "N/A"' config.json)"
    echo ""
else
    echo "  WARNING: config.json not found!"
    echo ""
fi

echo "[Network Tuning]"
echo "  RPL Timeout:       ${RPL_TIMEOUT:-30000}ms"
echo "  NDS Diameter:      ${NDS:-0}"
echo "  Network Resolution: ${NWK_RESOLUTION:-500}m"
echo "  Staggering Budget: ${STAGGERING_BUDGET:-100}"
echo "  Streaming Budget:  ${STREAMING_BUDGET:-10000}"
echo "  Streams Delta:     ${STREAMS_DELTA:-50}"
echo ""

echo "[Performance]"
echo "  Max FPS:        ${MAX_FPS:-unlimited}"
echo "  Log Interval:   ${LOG_INTERVAL}s"
echo "  Keep Logs:      ${KEEP_NUM_LOGS:-10}"
echo ""

echo "[Directories]"
echo "  Config:         ./config.json"
echo "  Profile:        ./profile/"
echo "  Logs:           ./profile/console*.log"
echo ""

echo "=========================================="
echo "Converting boolean values in config.json..."
sed -i 's/"true"/true/g; s/"false"/false/g' config.json
echo "Starting server..."
echo "=========================================="
echo ""

# Start the Arma Reforger server with all parameters
exec ./ArmaReforgerServer \
    -bindIP "${SERVER_IP:-0.0.0.0}" \
    -bindPort "${SERVER_PORT:-2001}" \
    -config ./config.json \
    -profile ./profile \
    -logStats $((${LOG_INTERVAL}*1000)) \
    -maxFPS ${MAX_FPS} \
    -rpl-timeout-ms ${RPL_TIMEOUT} \
    -nds ${NDS} \
    -nwkResolution ${NWK_RESOLUTION} \
    -staggeringBudget ${STAGGERING_BUDGET} \
    -streamingBudget ${STREAMING_BUDGET} \
    -streamsDelta ${STREAMS_DELTA} \
    -keepNumOfLogs ${KEEP_NUM_LOGS}
EOFSTARTUP

chmod +x /mnt/server/startup.sh
log_substep "Startup script created: startup.sh"

## Fix permissions one more time
log_debug "Setting final permissions..."
chown -R steam:steam /mnt/server

log_info "=========================================="
log_info "Installation completed successfully!"
log_info "=========================================="
log_info "Summary:"
log_info "  Server Binary: ArmaReforgerServer ($(du -h /mnt/server/ArmaReforgerServer | cut -f1))"
log_info "  Startup Script: startup.sh"
log_info "  Config File: config.json (validated)"
log_info "  Server Name: ${SERVER_NAME}"
log_info "  Max Players: ${MAX_PLAYERS}"
log_info "  Install Size: $(du -sh /mnt/server 2>/dev/null | cut -f1 || echo 'N/A')"
log_info "=========================================="

if [ "${INSTALL_LOG}" = "DEBUG" ]; then
    log_debug "Final directory listing:"
    ls -lah /mnt/server/ | head -20
    log_debug "========================================="
fi

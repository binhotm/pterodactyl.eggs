#!/bin/bash
# Arma Reforger Installation Script
# Container: fabriciojrsilva/steamcmd-eggs:installer (runs as ROOT during install)
# Runtime: cm2network/steamcmd:latest (runs as non-root steam user)
#
# Server Files: /mnt/server (mounted to /home/container at runtime)

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
mkdir -p /mnt/server/steamcmd
mkdir -p /mnt/server/steamapps
mkdir -p /mnt/server/profile
mkdir -p /mnt/server/tmp
log_debug "Directories created: steamcmd, steamapps, profile, tmp"
log_debug "Setting HOME environment variable..."
export HOME=/mnt/server

## Install game files via SteamCMD (runs as ROOT with HOME=/mnt/server)
log_step "4/6" "Downloading Arma Reforger Server files (App ${SRCDS_APPID})..."
log_debug "Install directory: /mnt/server"
log_debug "SteamCMD directory: /mnt/server/steamcmd"

## Test network connectivity before attempting download
log_debug "Testing network connectivity..."

# Enhanced network diagnostics in DEBUG mode
if [ "${INSTALL_LOG}" = "DEBUG" ]; then
    log_debug "Network interface information:"
    ip addr show 2>/dev/null || ifconfig 2>/dev/null || log_debug "Cannot list network interfaces"
    log_debug "Routing table:"
    ip route show 2>/dev/null || route -n 2>/dev/null || log_debug "Cannot show routing table"
    log_debug "DNS configuration:"
    cat /etc/resolv.conf 2>/dev/null || log_debug "Cannot read DNS config"
fi

# Test HTTP connectivity (more reliable than ICMP ping which is often blocked)
if curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" http://www.google.com 2>/dev/null | grep -q "200\|301\|302"; then
    log_debug "Network connectivity OK (HTTP test successful)"
elif curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" http://cloudflare.com 2>/dev/null | grep -q "200\|301\|302"; then
    log_debug "Network connectivity OK (HTTP fallback successful)"
else
    log_error "No network connectivity!"
    log_info "The container cannot reach the internet via HTTP."
    log_info ""
    
    # Additional diagnostics in DEBUG mode
    if [ "${INSTALL_LOG}" = "DEBUG" ]; then
        log_info "Network Diagnostics:"
        log_info "  Default Gateway: $(ip route show default 2>/dev/null | awk '{print $3}' || echo 'Unknown')"
        log_info "  Container IP: $(hostname -i 2>/dev/null || echo 'Unknown')"
        log_info "  DNS Servers: $(grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ' || echo 'Unknown')"
        log_info ""
        log_info "Testing connectivity methods:"
        log_info "  HTTP test: $(curl -s --connect-timeout 3 -o /dev/null -w "%{http_code}" http://www.google.com 2>&1 || echo 'Failed')"
        log_info "  DNS test: $(nslookup google.com 8.8.8.8 2>&1 | grep -A1 'Name:' | tail -1 || echo 'Failed')"
        log_info ""
    fi
    
    log_info "Troubleshooting steps:"
    log_info "  1. Check Pterodactyl Wings network configuration (/etc/pterodactyl/config.yml)"
    log_info "  2. Verify Docker network: docker network ls"
    log_info "  3. Check Docker daemon config: /etc/docker/daemon.json"
    log_info "     - Ensure 'iptables' is set to true"
    log_info "  4. Test from host: docker run --rm alpine curl -s http://google.com"
    log_info "  5. Check firewall rules and FORWARD policy: iptables -L FORWARD -n"
    log_info "  6. Verify IP forwarding: cat /proc/sys/net/ipv4/ip_forward (should be 1)"
    log_info ""
    log_info "Common causes:"
    log_info "  - Docker daemon.json has 'iptables': false (prevents NAT)"
    log_info "  - UFW FORWARD policy blocking container traffic"
    log_info "  - Docker bridge network not configured correctly"
    log_info "  - Host firewall blocking container traffic (check UFW, firewalld)"
    log_info "  - DNS resolution problems (check /etc/resolv.conf in container)"
    log_info "  - SELinux blocking container networking (check: getenforce)"
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

## Download and extract SteamCMD
log_substep "Downloading SteamCMD..."
cd /tmp
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd
cd /mnt/server/steamcmd
log_debug "SteamCMD extracted to /mnt/server/steamcmd"

## Prepare SteamCMD execution environment
# Set permissions for root to execute steamcmd
chown -R root:root /mnt

log_substep "Starting SteamCMD download (this may take several minutes)..."

## SteamCMD download with retry logic (running as ROOT with HOME=/mnt/server)
MAX_RETRIES=10
RETRY_COUNT=0
RETRY_DELAY=5  # Start with 5 seconds, increases with each attempt

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    if [ $RETRY_COUNT -gt 1 ]; then
        log_substep "Retry attempt $RETRY_COUNT of $MAX_RETRIES (waiting ${RETRY_DELAY}s before retry)..."
        sleep $RETRY_DELAY
        # Increase delay for next retry (exponential backoff: 5s, 10s, 15s, 20s, etc.)
        RETRY_DELAY=$((RETRY_DELAY + 5))
    else
        log_substep "Attempt 1 of $MAX_RETRIES..."
    fi
    
    # Run SteamCMD as ROOT with HOME=/mnt/server (not as steam user)
    # This ensures SteamCMD can properly manage files in /mnt/server
    if timeout 1800 /mnt/server/steamcmd/steamcmd.sh +force_install_dir /mnt/server +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +app_update ${SRCDS_APPID} ${INSTALL_FLAGS} validate +quit; then
        log_substep "Download completed successfully"
        RETRY_COUNT=$MAX_RETRIES  # Exit loop
    else
        STEAMCMD_EXIT_CODE=$?
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            if [ $STEAMCMD_EXIT_CODE -eq 124 ]; then
                log_debug "SteamCMD timeout (exit code 124) - retrying..."
            else
                log_debug "SteamCMD failed with exit code $STEAMCMD_EXIT_CODE - retrying..."
            fi
        else
            log_error "SteamCMD download failed after $MAX_RETRIES attempts!"
            log_info "Last exit code: $STEAMCMD_EXIT_CODE"
            log_info "=========================================="
            log_info "Troubleshooting:"
            log_info "  - Check Steam service status: https://steamstatus.com"
            log_info "  - Verify Steam credentials are correct"
            log_info "  - Ensure Steam account owns Arma Reforger"
            log_info "  - Check network connectivity: curl -s https://steampowered.com | head -n 5"
            log_info "  - Review detailed logs above for specific errors"
            log_info "=========================================="
            exit 1
        fi
    fi
done

## Set up Steam SDK libraries (required for server binary)
log_substep "Configuring Steam SDK libraries..."
mkdir -p /mnt/server/.steam/sdk32
mkdir -p /mnt/server/.steam/sdk64
cp -v /mnt/server/steamcmd/linux32/steamclient.so /mnt/server/.steam/sdk32/steamclient.so 2>/dev/null || log_debug "32-bit library not found (may be OK)"
cp -v /mnt/server/steamcmd/linux64/steamclient.so /mnt/server/.steam/sdk64/steamclient.so 2>/dev/null || log_debug "64-bit library not found (may be OK)"

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

## Generate minimal config.json template (Pterodactyl will populate via config.files parser)
log_step "6/6" "Generating configuration template..."
cat > /mnt/server/config.json << 'EOFCONFIG'
{
	"bindAddress": "0.0.0.0",
	"bindPort": 2001,
	"publicAddress": "0.0.0.0",
	"publicPort": 2001,
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
		"disableNavmeshStreaming": [],
		"disableServerShutdown": true,
		"joinQueue": {
			"maxSize": 30
		},
		"lobbyPlayerSynchronise": true,
		"playerSaveTime": 120,
		"slotReservationTimeout": 60
	}
}
EOFCONFIG

log_substep "Configuration template created (will be populated by panel)"
log_debug "Panel will update config.json via config.files parser on server start"

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
cat > /mnt/server/armareforger-server.sh << 'EOFSTARTUP'
#!/bin/bash
# Arma Reforger Server - Startup Script
# This script displays server configuration and starts the Arma Reforger server

echo "=========================================="
echo "Arma Reforger Dedicated Server - Starting"
echo "=========================================="
echo ""

# Diagnostic information
echo "[Startup Diagnostics]"
echo "  Current User:       $(whoami)"
echo "  Working Directory:  $(pwd)"
echo "  Script Location:    $0"
echo "  Home Directory:     $HOME"
echo ""

# List files in current directory for verification
echo "[Server Files in Working Directory]"
ls -lh ArmaReforgerServer config.json armareforger-server.sh 2>/dev/null || echo "  WARNING: Some expected files not found"
echo ""

# Display server configuration
echo "[Server Configuration]"
if [ -f "config.json" ]; then
    echo "  Server Name:    $(jq -r '.game.name // "N/A"' config.json)"
    echo "  Scenario:       $(jq -r '.game.scenarioId // "N/A"' config.json)"
    echo "  Max Players:    $(jq -r '.game.maxPlayers // "N/A"' config.json)"
    echo "  Bind IP:        ${SERVER_IP:-0.0.0.0}"
    echo "  Bind Port:      ${SERVER_PORT:-2001}"
    echo "  A2S IP:         ${SERVER_IP:-0.0.0.0}"
    echo "  A2S Port:       ${A2S_PORT:-17777}"
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
echo "Validating and fixing config.json format..."

# Fix boolean values: convert string booleans to JSON booleans
sed -i 's/"true"/true/g; s/"false"/false/g' config.json

# Fix password fields: ensure they are always strings (not integers)
# If a password field is empty or null, set it to empty string
jq '.game.password = (.game.password | tostring) | 
    .game.passwordAdmin = (.game.passwordAdmin | tostring) | 
    .rcon.password = (.rcon.password | tostring)' config.json > config.json.tmp && mv config.json.tmp config.json

echo "Config.json validated and fixed"
echo "Starting server..."
echo "=========================================="
echo ""

# Start the Arma Reforger server with all parameters
# Network parameters (bind IP/port, A2S address/port) are now configured via config.json
# and automatically applied by Pterodactyl's config.files parser on startup
exec ./ArmaReforgerServer \
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

chmod +x /mnt/server/armareforger-server.sh
log_substep "Startup script created: armareforger-server.sh"

## Verify startup script was created
if [ ! -f "/mnt/server/armareforger-server.sh" ]; then
    log_error "Startup script generation failed!"
    log_info "The armareforger-server.sh file was not created."
    log_info "==========================================="
    exit 1
fi

log_debug "Startup script verified and executable"
log_debug "Startup script size: $(du -h /mnt/server/armareforger-server.sh | cut -f1)"

## Fix permissions: Set steam user as owner for runtime execution
log_debug "Setting final permissions for steam user..."
chown -R steam:steam /mnt/server

log_info "=========================================="
log_info "Installation completed successfully!"
log_info "=========================================="
log_info "Summary:"
log_info "  Server Binary: ArmaReforgerServer ($(du -h /mnt/server/ArmaReforgerServer | cut -f1))"
log_info "  Startup Script: armareforger-server.sh"
log_info "  Config File: config.json (validated)"
log_info "  Server Name: ${SERVER_NAME}"
log_info "  Max Players: ${MAX_PLAYERS}"
log_info "  Install Size: $(du -sh /mnt/server 2>/dev/null | cut -f1 || echo 'N/A')"
log_info "=========================================="

if [ "${INSTALL_LOG}" = "DEBUG" ]; then
    log_debug "Final directory listing:"
    ls -lah /mnt/server/ | head -25
    log_debug "========================================="
    log_debug "Server binary location: $(which ArmaReforgerServer 2>/dev/null || echo 'Not in PATH')"
    log_debug "Executable check: $(file /mnt/server/ArmaReforgerServer 2>/dev/null)"
    log_debug "========================================="
fi

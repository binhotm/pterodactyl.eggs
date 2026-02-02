#!/bin/bash
############################################################
# Entrypoint for Pterodactyl Panel - Arma Reforger
# This script is CRITICAL for the startup command to work
############################################################

# Colors for output (optional, improves readability)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo -e "Pterodactyl Container Entrypoint v2.0"
echo -e "==========================================${NC}"
echo ""

# Diagnostic Information
echo -e "${YELLOW}[Container Info]${NC}"
echo "  User:      $(whoami) (UID: $(id -u))"
echo "  Home:      ${HOME}"
echo "  Workdir:   $(pwd)"
echo "  Date:      $(date)"
echo ""

# Check if the working directory exists
if [ ! -d "/home/container" ]; then
    echo -e "${RED}ERROR: /home/container does not exist!${NC}"
    exit 1
fi

cd /home/container || exit 1

############################################################
# AUTO-UPDATE of Arma Reforger
# Enabled via variable AUTO_UPDATE=1 or AUTO_UPDATE=true
############################################################
if [ "${AUTO_UPDATE}" == "1" ] || [ "${AUTO_UPDATE}" == "true" ]; then
    echo -e "${YELLOW}[Auto-Update]${NC} Checking for Arma Reforger updates..."
    
    # Check if SteamCMD is available
    STEAMCMD_PATH=""
    if [ -f "/home/container/steamcmd/steamcmd.sh" ]; then
        STEAMCMD_PATH="/home/container/steamcmd/steamcmd.sh"
    elif [ -f "/home/steam/steamcmd/steamcmd.sh" ]; then
        STEAMCMD_PATH="/home/steam/steamcmd/steamcmd.sh"
    fi
    
    if [ -n "${STEAMCMD_PATH}" ]; then
        echo -e "  SteamCMD: ${STEAMCMD_PATH}"
        echo -e "  App ID:   ${SRCDS_APPID:-1874900}"
        echo ""
        
        # Define Steam credentials
        STEAM_USER="${STEAM_USER:-anonymous}"
        STEAM_PASS="${STEAM_PASS:-}"
        STEAM_AUTH="${STEAM_AUTH:-}"
        
        # Execute update
        echo -e "${YELLOW}[Auto-Update]${NC} Executing SteamCMD..."
        ${STEAMCMD_PATH} +force_install_dir /home/container \
            +login "${STEAM_USER}" "${STEAM_PASS}" "${STEAM_AUTH}" \
            +app_update ${SRCDS_APPID:-1874900} \
            +quit
        
        UPDATE_EXIT_CODE=$?
        if [ ${UPDATE_EXIT_CODE} -eq 0 ]; then
            echo -e "${GREEN}[Auto-Update]${NC} Update completed successfully!"
        else
            echo -e "${YELLOW}[Auto-Update]${NC} SteamCMD returned code ${UPDATE_EXIT_CODE} (may be normal if already updated)"
        fi
    else
        echo -e "${YELLOW}[Auto-Update]${NC} SteamCMD not found, skipping update..."
        echo -e "  Tip: Run reinstall to download SteamCMD and server files"
    fi
    echo ""
fi

############################################################
# Processing the STARTUP Command
# This is the CRITICAL part that makes Pterodactyl work
############################################################

# Pterodactyl passes the command via the STARTUP variable
# It can also use MODIFIED_STARTUP (already with substituted variables)
STARTUP_CMD="${MODIFIED_STARTUP:-${STARTUP}}"

if [ -z "${STARTUP_CMD}" ]; then
    echo -e "${RED}[ERROR]${NC} No STARTUP command defined!"
    echo "  STARTUP: ${STARTUP:-<not defined>}"
    echo "  MODIFIED_STARTUP: ${MODIFIED_STARTUP:-<not defined>}"
    echo ""
    echo "Check the egg configuration in the Pterodactyl Panel."
    echo ""
    echo "Tip: The 'startup' field in the egg should contain the command to start the server."
    echo "Example: cd /home/container && bash armareforger-server.sh"
    exit 1
fi

echo -e "${YELLOW}[Startup Command]${NC}"
echo "  ${STARTUP_CMD}"
echo ""

# List important files for debugging
echo -e "${YELLOW}[Server Files Check]${NC}"
if [ -f "ArmaReforgerServer" ]; then
    echo -e "  ${GREEN} (OK)${NC} ArmaReforgerServer encontrado ($(du -h ArmaReforgerServer 2>/dev/null | cut -f1))"
else
    echo -e "  ${RED} (MISSING)${NC} ArmaReforgerServer NOT found"
    echo -e "    Run reinstall in the Pterodactyl Panel to download the files"
fi

if [ -f "armareforger-server.sh" ]; then
    echo -e "  ${GREEN} (OK)${NC} armareforger-server.sh encontrado"
else
    echo -e "  ${RED} (MISSING)${NC} armareforger-server.sh NOT found"
    echo -e "    Run reinstall in the Pterodactyl Panel to create the script"
fi

if [ -f "config.json" ]; then
    echo -e "  ${GREEN} (OK)${NC} config.json encontrado"
else
    echo -e "  ${YELLOW} !${NC} config.json not found (will be created by the startup script)"
fi

if [ -d "profile" ]; then
    echo -e "  ${GREEN} (OK)${NC} profile/ directory exists"
else
    echo -e "  ${YELLOW} !${NC} profile/ directory does not exist (will be created)"
    mkdir -p profile
fi
echo ""

############################################################
# Executing the Startup Command
############################################################
echo -e "${GREEN}=========================================="
echo -e "Executing Startup Command..."
echo -e "==========================================${NC}"
echo ""

# Substitute environment variables in the STARTUP command
# Pterodactyl usually does this, but we ensure it here

# Important: exec replaces this process with the server (PID 1)
# This allows signals (SIGTERM, SIGINT) to be correctly received by the server
exec env ${STARTUP_CMD}

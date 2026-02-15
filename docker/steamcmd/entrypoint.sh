#!/bin/bash

#
# Pterodactyl Panel - Entrypoint Script
# Handles SteamCMD auto-update and server startup
#
# Author: Fabricio Junior Silva <fabriciojuniorsilva@gmail.com>
# Based on: pterodactyl/yolks by Matthew Penner
#

# Give everything time to initialize for preventing SteamCMD deadlock
sleep 1

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Default steam user to anonymous if not set
if [ "${STEAM_USER}" == "" ]; then
    echo -e "Steam user is not set.\n"
    echo -e "Using anonymous user.\n"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "Steam user set to ${STEAM_USER}"
fi

# Auto-update: if AUTO_UPDATE is not set or equals 1, update the server
if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" ]; then
    # Update Source Server via SteamCMD
    if [ ! -z ${SRCDS_APPID} ]; then
        ./steamcmd/steamcmd.sh +force_install_dir /home/container \
            +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
            +app_update ${SRCDS_APPID} \
            $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) \
            $( [[ -z ${SRCDS_BETAPASS} ]] || printf %s "-betapassword ${SRCDS_BETAPASS}" ) \
            $( [[ -z ${VALIDATE} ]] || printf %s "validate" ) \
            +quit
    else
        echo -e "No SRCDS_APPID set. Skipping auto-update."
    fi
else
    echo -e "Auto-update disabled (AUTO_UPDATE=0). Starting server..."
fi

# ==========================================
# INJEÇÃO DO JEMALLOC (SAS BR Otimização)
# ==========================================
JEMALLOC_PATH="/usr/lib/x86_64-linux-gnu/libjemalloc.so.2"
if [ -f "$JEMALLOC_PATH" ]; then
    printf "\033[1m\033[32m[SAS Otimização] Injetando jemalloc para gestão de memória avançada...\033[0m\n"
    export LD_PRELOAD="$JEMALLOC_PATH"
else
    printf "\033[1m\033[31m[SAS Aviso] libjemalloc.so.2 não encontrado. Rodando com glibc padrão.\033[0m\n"
fi

# Display the command we're running in the output, and then execute it
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n" "$PARSED"

# Execute the startup command
# shellcheck disable=SC2086
exec env LD_PRELOAD="${LD_PRELOAD}" ${PARSED}

#
# Pterodactyl Panel - SteamCMD Runtime Image
# ==========================================
#
# PURPOSE: This image is used for RUNTIME execution of game servers.
#          It contains all dependencies needed to run game servers that
#          were previously installed via the installer image.
#
# USAGE:   Pterodactyl Wings uses this image to start and run game servers.
#          The entrypoint handles auto-updates and executes the STARTUP command.
#
# FLOW:    1. Pterodactyl creates a container from this image
#          2. Mounts server files to /home/container
#          3. Executes entrypoint.sh which:
#             - Optionally runs SteamCMD auto-update
#             - Processes the STARTUP environment variable
#             - Executes the game server
#
# INSTALL: For installation, use the installer image (steamcmd-installer)
#          which is optimized for downloading game files.
#
# Author: Fabricio Junior Silva <fabriciojuniorsilva@gmail.com>
# GitHub: github.com/binhotm
# Based on: pterodactyl/yolks by Matthew Penner
# Date:   February 2026
#

FROM        debian:bookworm-slim

# ============================================
# Image Identification Labels
# ============================================
LABEL       maintainer="fabriciojuniorsilva@gmail.com"
LABEL       author="Fabricio Junior Silva"

# OCI Standard Labels
LABEL       org.opencontainers.image.title="Pterodactyl SteamCMD Runtime"
LABEL       org.opencontainers.image.description="Runtime image for Pterodactyl Panel. Executes game servers with auto-update support."
LABEL       org.opencontainers.image.version="2.0.0"
LABEL       org.opencontainers.image.source="https://github.com/binhotm/pterodactyl.eggs"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.authors="Fabricio Junior Silva <fabriciojuniorsilva@gmail.com>"

# Pterodactyl-specific Labels
LABEL       io.pterodactyl.purpose="runtime"
LABEL       io.pterodactyl.egg="steamcmd-runtime"
LABEL       io.pterodactyl.version="2.0.0"
LABEL       io.pterodactyl.runtime="true"

# ============================================
# Environment Configuration
# ============================================
ENV         DEBIAN_FRONTEND=noninteractive
ENV         LANG=en_US.UTF-8
ENV         LC_ALL=en_US.UTF-8

# ============================================
# Dependency Installation
# ============================================
# Runtime dependencies for game servers and SteamCMD auto-update
#
RUN         dpkg --add-architecture i386 \
            && apt-get update \
            && apt-get upgrade -y \
            && apt-get install -y --no-install-recommends \
                #
                # 32-bit Libraries (REQUIRED for SteamCMD)
                #
                lib32gcc-s1 \
                lib32stdc++6 \
                #
                # Core Tools
                #
                ca-certificates \
                tar \
                curl \
                #
                # Networking (required for server runtime)
                #
                iproute2 \
                #
                # JSON Parsing (for config.json manipulation)
                #
                jq \
                #
                # Locale Support
                #
                locales \
                #
                # Network Diagnostics (useful for debugging)
                #
                iputils-ping \
                net-tools \
                netcat-traditional \
                #
                # Process Management
                #
                procps \
                #
                # Otimizacao de Memoria (SAS BR)
                #
                libjemalloc2 \
            #
            # Configure UTF-8 locale
            #
            && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
            && dpkg-reconfigure --frontend=noninteractive locales \
            && update-locale LANG=en_US.UTF-8 \
            #
            # Create non-privileged user 'container' (Pterodactyl default)
            #
            && useradd -m -d /home/container container \
            #
            # Cleanup to reduce image size
            #
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ============================================
# Runtime Configuration
# ============================================
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh
CMD         [ "/bin/bash", "/entrypoint.sh" ]


#
# Pterodactyl Panel - SteamCMD Installer Image
# ============================================
#
# PURPOSE: This image is used ONLY for the INSTALLATION phase in Pterodactyl.
#          It contains all dependencies needed to run SteamCMD and download
#          game server files. This image is NOT used for runtime.
#
# USAGE:   Pterodactyl Wings uses this image to execute the installation script
#          defined in the egg JSON (scripts.installation.script).
#
# FLOW:    1. Pterodactyl creates a container from this image
#          2. Mounts /mnt/server (server files) and /mnt/install (install script)
#          3. Executes: /bin/bash /mnt/install/install.sh
#          4. SteamCMD downloads game files to /mnt/server
#          5. Container is destroyed after installation
#
# RUNTIME: For server runtime, use the runtime image (steamcmd:latest)
#          which is lighter and optimized for running the game server.
#
# Author: Fabricio Junior Silva <fabriciojuniorsilva@gmail.com>
# GitHub: github.com/binhotm
# Date:   February 2026
#

FROM        debian:bookworm-slim

# ============================================
# Image Identification Labels
# ============================================
LABEL       maintainer="fabriciojuniorsilva@gmail.com"
LABEL       author="Fabricio Junior Silva"

# OCI Standard Labels
LABEL       org.opencontainers.image.title="Pterodactyl SteamCMD Installer"
LABEL       org.opencontainers.image.description="Installation-only image for Pterodactyl Panel. Contains SteamCMD and dependencies to download game servers."
LABEL       org.opencontainers.image.version="2.0.0"
LABEL       org.opencontainers.image.source="https://github.com/binhotm/pterodactyl.eggs"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.authors="Fabricio Junior Silva <fabriciojuniorsilva@gmail.com>"

# Pterodactyl-specific Labels
LABEL       io.pterodactyl.purpose="installer"
LABEL       io.pterodactyl.egg="steamcmd-installer"
LABEL       io.pterodactyl.version="2.0.0"
LABEL       io.pterodactyl.runtime="false"

# ============================================
# Environment Configuration
# ============================================
ENV         DEBIAN_FRONTEND=noninteractive
ENV         LANG=en_US.UTF-8
ENV         LC_ALL=en_US.UTF-8

# ============================================
# Dependency Installation
# ============================================
# These packages are required for SteamCMD to function properly
# and for the installation script to process configuration files.
#
RUN         dpkg --add-architecture i386 \
            && apt-get update \
            && apt-get upgrade -y \
            && apt-get install -y --no-install-recommends \
                #
                # 32-bit Libraries (REQUIRED for SteamCMD)
                # SteamCMD is a 32-bit application and needs these libs
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
                # JSON Parsing (for config.json manipulation)
                # Critical for Arma Reforger configuration
                #
                jq \
                #
                # Locale Support (prevents character encoding issues)
                #
                locales \
            #
            # Configure UTF-8 locale
            #
            && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
            && dpkg-reconfigure --frontend=noninteractive locales \
            && update-locale LANG=en_US.UTF-8 \
            #
            # Cleanup to reduce image size
            #
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ============================================
# Notes
# ============================================
# - No USER directive: Pterodactyl runs installation as root
# - No ENTRYPOINT/CMD: Pterodactyl controls execution
# - No WORKDIR: Pterodactyl mounts volumes as needed
# - SteamCMD is downloaded by the installation script, not pre-installed
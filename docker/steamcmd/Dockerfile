############################################################
# Dockerfile ready for Arma Reforger - Pterodactyl Panel
# Works for INSTALLATION and RUNTIME in a single image
# Base: debian:trixie-slim (stable and lightweight) tested by me
# on all Arma Reforger servers of SAS (South America Servers)
# Author: Fabricio Junior Silva
# Email: fabriciojuniorsilva@gmail.com
# GitHub: binhotm
# Date: Feb 2026
############################################################

FROM debian:trixie-slim

LABEL maintainer="fabriciojuniorsilva@gmail.com"
LABEL description="Docker Image mixed for Arma Reforger server installation and runtime in Pterodactyl Panel."
LABEL version="2.0.0"
LABEL org.opencontainers.image.source="https://github.com/fabriciojrsilva/pterodactyl.eggs"
LABEL org.opencontainers.image.licenses="MIT"

# Labels for Pterodactyl (help with identification)
LABEL io.pterodactyl.egg="arma-reforger"
LABEL io.pterodactyl.version="2.0.0"

# Environment configurations
ARG PUID=1000
ARG PGID=1000

ENV USER=container
ENV HOME=/home/container
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# SteamCMD directories (compatible with Pterodactyl)
ENV STEAMCMDDIR="/home/container/steamcmd"

############################################################
# Dependency Installation
############################################################
RUN set -x \
    # Update repositories and install essential dependencies
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        # 32-bit libraries (required for SteamCMD)
        lib32stdc++6 \
        lib32gcc-s1 \
        # Network and system tools
        ca-certificates \
        curl \
        wget \
        # JSON parsing (critical for config.json)
        jq \
        # Network diagnostics
        iputils-ping \
        iproute2 \
        # UTF-8 locale
        locales \
        # Compression
        tar \
        gzip \
        # Editor (useful for debugging)
        nano \
        # Procps for process management
        procps \
        # Tini for process management (alternative to dumb-init)
        tini \
    # Configure UTF-8 locale (prevents issues with special characters)
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8 \
    # Create non-privileged user 'container' (Pterodactyl default)
    && useradd -u ${PUID} -m -d /home/container -s /bin/bash container \
    # Clean apt cache to reduce image size
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

############################################################
# Pre-install SteamCMD
# This significantly speeds up egg installation
############################################################
USER container
RUN mkdir -p "${STEAMCMDDIR}" \
    && curl -fsSL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' \
        | tar xvzf - -C "${STEAMCMDDIR}" \
    && "${STEAMCMDDIR}/steamcmd.sh" +quit \
    # Create symlinks for SDK (required for some games)
    && mkdir -p "${HOME}/.steam/sdk32" \
    && mkdir -p "${HOME}/.steam/sdk64" \
    && ln -sf "${STEAMCMDDIR}/linux32/steamclient.so" "${HOME}/.steam/sdk32/steamclient.so" 2>/dev/null || true \
    && ln -sf "${STEAMCMDDIR}/linux64/steamclient.so" "${HOME}/.steam/sdk64/steamclient.so" 2>/dev/null || true

############################################################
# Entrypoint Configuration for Pterodactyl
############################################################
# Switch back to root to copy the entrypoint
USER root

# The entrypoint is CRITICAL for Pterodactyl to execute the startup command
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Define the default user as 'container' (Pterodactyl may override to root during installation)
USER container

# Default working directory (where server files reside)
WORKDIR /home/container

# STOPSIGNAL for graceful shutdown
STOPSIGNAL SIGINT

# Use tini as init system for better process management
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]

# Default command: runs the entrypoint that processes STARTUP
CMD ["/bin/bash", "/entrypoint.sh"]


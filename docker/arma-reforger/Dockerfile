# Baseado na da CM2 oficial e otimizada, sim este comentario esta em portugues, se vc e BR fique a vontade :)
# https://hub.docker.com/r/cm2network/steamcmd
# Use a imagem base oficial do SteamCMD
# Esta imagem já inclui o SteamCMD pré-instalado e configurado

FROM cm2network/steamcmd:root

LABEL maintainer="fabriciojuniorsilva@gmail.com"
LABEL description="Docker image otimizada para Arma Reforger usando SteamCMD como base."
LABEL version="1.0.0"

# Instala dependências de Runtime E Instalação de uma vez só
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    curl \
    ca-certificates \
    lib32gcc-s1 \
    lib32stdc++6 \
    iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Volta para o usuário steam para segurança
USER steam

# Define o Entrypoint padrão (opcional, pode manter o da base)
WORKDIR /home/steam/steamcmd
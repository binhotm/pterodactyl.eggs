# Baseado na imagem oficial otimizada
FROM cm2network/steamcmd:root

LABEL maintainer="fabriciojuniorsilva@gmail.com"

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
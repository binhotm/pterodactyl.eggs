#!/bin/bash
############################################################
# Build script for Arma Reforger Unified Docker Image
# Esta imagem funciona para INSTALAÇÃO e RUNTIME
############################################################

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Change to the project root directory
cd "$(dirname "$0")/.."

# Define variables
IMAGE_NAME="fabriciojrsilva/steamcmd-eggs"
DOCKER_DIR="docker/arma-reforger"

echo -e "${BLUE}=========================================="
echo -e "Pterodactyl Eggs - Docker Image Builder"
echo -e "==========================================${NC}"
echo ""

# Build unified image (recommended)
echo -e "${YELLOW}[1/2]${NC} Building unified image (installer + runtime)..."
docker build \
    -t "${IMAGE_NAME}:arma-reforger" \
    -t "${IMAGE_NAME}:latest" \
    -f "${DOCKER_DIR}/Dockerfile.unified" \
    "${DOCKER_DIR}"

echo -e "${GREEN}✓${NC} Unified image built: ${IMAGE_NAME}:arma-reforger"
echo ""

# Optional: Build legacy installer image (for backwards compatibility)
echo -e "${YELLOW}[2/2]${NC} Building legacy installer image..."
docker build \
    -t "${IMAGE_NAME}:installer" \
    -f "${DOCKER_DIR}/Dockerfile" \
    "${DOCKER_DIR}"

echo -e "${GREEN}✓${NC} Legacy installer built: ${IMAGE_NAME}:installer"
echo ""

echo -e "${GREEN}=========================================="
echo -e "Build Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Available images:"
echo "  - ${IMAGE_NAME}:arma-reforger (RECOMMENDED - unified image)"
echo "  - ${IMAGE_NAME}:latest (alias for arma-reforger)"
echo "  - ${IMAGE_NAME}:installer (legacy, for backwards compatibility)"
echo ""
echo "To push to Docker Hub:"
echo "  docker push ${IMAGE_NAME}:arma-reforger"
echo "  docker push ${IMAGE_NAME}:latest"
echo "  docker push ${IMAGE_NAME}:installer"
echo ""
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "Atualize o egg JSON para usar a nova imagem unificada:"
echo '  "docker_images": {'
echo '      "fabriciojrsilva/steamcmd-eggs:arma-reforger": "fabriciojrsilva/steamcmd-eggs:arma-reforger"'
echo '  }'

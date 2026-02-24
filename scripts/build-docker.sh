#!/bin/bash
############################################################
# Build Script - Pterodactyl Eggs Docker Image
# Builds the unified SteamCMD image for installation and runtime
############################################################

set -e

cd "$(dirname "$0")/.."

IMAGE_NAME="fabriciojrsilva/steamcmd-eggs"
DOCKER_DIR="docker/steamcmd"

echo "=========================================="
echo "Pterodactyl Eggs - Docker Build"
echo "=========================================="
echo ""

# Build unified image
echo "Building unified image..."
docker build \
    -t "${IMAGE_NAME}:latest" \
    -t "${IMAGE_NAME}:arma-reforger" \
    -f "${DOCKER_DIR}/Dockerfile" \
    "${DOCKER_DIR}"

echo ""
echo "Build complete!"
echo ""
echo "Image: ${IMAGE_NAME}:latest"
echo ""
echo "To push to Docker Hub:"
echo "  docker push ${IMAGE_NAME}:latest"
echo "  docker push ${IMAGE_NAME}:arma-reforger"

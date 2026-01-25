#!/bin/bash

# Build script for Arma Reforger Docker image
# This script builds the custom Docker image for Arma Reforger servers

set -e

# Change to the project root directory
cd "$(dirname "$0")/.."

# Define variables
IMAGE_NAME="pterodactyl-steamcmd-eggs/installer"
IMAGE_TAG="arma-reforger"
DOCKER_DIR="docker/arma-reforger"

echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Using Dockerfile from: ${DOCKER_DIR}"

# Build the Docker image
docker build \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -f "${DOCKER_DIR}/Dockerfile" \
    "${DOCKER_DIR}"

echo "Build complete!"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To push to registry:"
echo "  docker push ${IMAGE_NAME}:${IMAGE_TAG}"
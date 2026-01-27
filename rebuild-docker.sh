#!/bin/bash
cd docker/arma-reforger
echo "Building Docker image..."
docker build -t fabriciojrsilva/steamcmd-eggs:installer .
echo ""
echo "Image built successfully!"
echo ""
echo "To push to Docker Hub, run:"
echo "  docker push fabriciojrsilva/steamcmd-eggs:installer"

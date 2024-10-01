#!/bin/bash

# Prompt for the version if not provided
read -p "Enter the plugin version (e.g., v1.0.8): " VERSION

# Check if a version was provided
if [ -z "$VERSION" ]; then
  echo "Error: You must provide a version."
  exit 1
fi

# Prompt for the architecture if not provided
read -p "Enter the target architecture (amd64/arm64): " ARCHITECTURE

# Validate the architecture input
if [ "$ARCHITECTURE" != "amd64" ] && [ "$ARCHITECTURE" != "arm64" ]; then
  echo "Invalid architecture. Please enter either 'amd64' or 'arm64'."
  exit 1
fi

# Step 1: Build the new plugin binary inside a temporary docker container with the selected architecture
docker build --build-arg ARCHITECTURE=$ARCHITECTURE -f ../Dockerfile.$ARCHITECTURE.pluginbuild -t vault-ethereum-builder ..

# Check if the docker build command was successful
if [ $? -ne 0 ]; then
  echo "Docker build failed. Exiting."
  exit 1
fi

# Step 2: Create the container
docker create --name vault-ethereum-builder-container vault-ethereum-builder

# Step 3: Create the binaries folder if it doesn't exist
if [ ! -d "../binaries" ]; then
  mkdir ../binaries
  echo "Created 'binaries' directory."
fi

# Step 4: Copy the binary and SHA256SUM from Docker and into the host system, using the version as part of the filename
docker cp vault-ethereum-builder-container:/build/bin/vault-ethereum ../binaries/vault-ethereum-$VERSION-$ARCHITECTURE
docker cp vault-ethereum-builder-container:/build/bin/SHA256SUMS ../binaries/SHA256SUMS-$VERSION-$ARCHITECTURE

# Step 5: Remove the temporary container
docker rm vault-ethereum-builder-container

# Step 6: Remove the built Docker image
docker rmi vault-ethereum-builder

echo "Plugin binary and SHA256SUMS copied to the 'binaries' folder with version $VERSION and architecture $ARCHITECTURE, and temporary container removed."
#!/bin/bash

# Determine the directory of this script and the project root.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Prompt for the plugin name; default to "vault-ethereum" if not provided.
read -p "Enter the plugin name (default: vault-ethereum): " PLUGIN
if [ -z "$PLUGIN" ]; then
  PLUGIN="vault-ethereum"
fi

# Check that the plugin directory exists.
if [ ! -d "$PROJECT_DIR/$PLUGIN" ]; then
  echo "Error: Plugin folder '$PLUGIN' does not exist in the project root."
  exit 1
fi

# Prompt for the version if not provided.
read -p "Enter the plugin version (e.g., v1.0.8): " VERSION
if [ -z "$VERSION" ]; then
  echo "Error: You must provide a version."
  exit 1
fi

# Prompt for the target architecture (amd64/arm64).
read -p "Enter the target architecture (amd64/arm64): " ARCHITECTURE
if [ "$ARCHITECTURE" != "amd64" ] && [ "$ARCHITECTURE" != "arm64" ]; then
  echo "Invalid architecture. Please enter either 'amd64' or 'arm64'."
  exit 1
fi

# Step 1: Build the plugin binary inside a temporary Docker container using the provided Dockerfile.
# Note: We use the plugin folder as the build context.
docker build \
  --build-arg ARCHITECTURE="$ARCHITECTURE" \
  -f "$PROJECT_DIR/Dockerfile.pluginbuild" \
  -t vault-"$PLUGIN"-builder "$PROJECT_DIR/$PLUGIN"

if [ $? -ne 0 ]; then
  echo "Docker build failed. Exiting."
  exit 1
fi

# Step 2: Create a temporary container from the built image.
CONTAINER_NAME="vault-${PLUGIN}-builder-container"
docker create --name "$CONTAINER_NAME" vault-"$PLUGIN"-builder

# Step 3: Ensure the binaries folder exists.
BINARIES_DIR="$SCRIPT_DIR/out"
if [ ! -d "$BINARIES_DIR" ]; then
  mkdir "$BINARIES_DIR"
  echo "Created 'binaries' directory at $BINARIES_DIR."
fi

# Step 4: Copy the plugin binary and SHA256SUMS file from the container.
docker cp "$CONTAINER_NAME":/build/bin/plugin "$BINARIES_DIR/$PLUGIN-$VERSION-$ARCHITECTURE"
docker cp "$CONTAINER_NAME":/build/bin/SHA256SUMS "$BINARIES_DIR/SHA256SUMS-$PLUGIN-$VERSION-$ARCHITECTURE"

# Step 5: Clean up the temporary container and Docker image.
docker rm "$CONTAINER_NAME"
docker rmi vault-"$PLUGIN"-builder

echo "Plugin '$PLUGIN' built successfully."
echo "Binary: $BINARIES_DIR/$PLUGIN-$VERSION-$ARCHITECTURE"
echo "SHA256SUMS: $BINARIES_DIR/SHA256SUMS-$PLUGIN-$VERSION-$ARCHITECTURE"

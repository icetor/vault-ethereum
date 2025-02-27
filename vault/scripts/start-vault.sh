#!/bin/bash

# Determine the directory of this script and the project root.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

DATE=$(date +'%s')

# Use provided version or default to "1.17" if not provided.
if [ -z "$1" ]; then
  echo "No version provided. Using default version: 1.17"
  VERSION=1.17
else
  VERSION=$1
fi

# Use provided port or default to "9200" if not provided.
if [ -z "$2" ]; then
  echo "No port provided. Using default port: 9200"
  PORT=9200
else
  PORT=$2
fi

# Use provided container name or default to "vault_server" if not provided.
if [ -z "$3" ]; then
  echo "No container name provided. Using default name: vault_server"
  CONTAINER_NAME=vault_server
else
  PORT=$3
fi

# Step 1: Build the corresponding Vault Docker image using the Dockerfile in the project directory
docker build -f "$PROJECT_DIR/Dockerfile.vaultbuild" \
  --build-arg always_upgrade=$DATE \
  --build-arg VERSION=$VERSION \
  -t hashicorp/vault:$VERSION "$PROJECT_DIR"
  
# Check if the docker build command was successful
if [ $? -ne 0 ]; then
  echo "Docker build failed. Exiting."
  exit 1
fi

# Step 2: Ensure the Docker network exists
if ! docker network ls | grep -q production; then
  echo "Creating 'production' network..."
  docker network create production
  if [ $? -ne 0 ]; then
    echo "Failed to create 'production' network. Exiting."
    exit 1
  fi
fi

# Get the absolute path for the config directory from the project root
CONFIG_DIR=$(realpath "$PROJECT_DIR/config")

# Step 4: Create and run the container using the absolute path
docker run -d \
  --name $CONTAINER_NAME \
  --network production \
  -p $PORT:9200 \
  -v "$CONFIG_DIR":/home/vault/config:rw \
  --user 0:0 \
  --restart always \
  hashicorp/vault:$VERSION /home/vault/config/entrypoint.sh

# Check if the container started successfully
if [ $? -ne 0 ]; then
  echo "Failed to start the Vault container."
  exit 1
fi

echo "Vault container is up and running with version $VERSION on port $PORT."
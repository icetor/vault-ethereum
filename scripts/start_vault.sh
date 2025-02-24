#!/bin/bash

DATE=$(date +'%s')

# Use provided version or default to "1.17" if not provided.
if [ -z "$1" ]; then
  echo "No version provided. Using default version: 1.17"
  VERSION=1.17
else
  VERSION=$1
fi

# Step 1: Build the corresponding Vault Docker image using the Dockerfile in the current directory
docker build -f ../Dockerfile.vaultbuild --build-arg always_upgrade="$DATE" --build-arg VERSION=$VERSION -t hashicorp/vault:$VERSION ..

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

# Step 3: Stop and remove the existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q vault_server; then
  docker stop vault_server && docker rm vault_server
fi

# Get the absolute path for the config directory
CONFIG_DIR=$(realpath ../config)

# Step 4: Create and run the container using the absolute path
docker run -d \
  --name vault_server \
  --network production \
  -p 9200:9200 \
  -v "$CONFIG_DIR":/home/vault/config:rw \
  --user 0:0 \
  --restart always \
  hashicorp/vault:$VERSION /home/vault/config/entrypoint.sh

# Check if the container started successfully
if [ $? -ne 0 ]; then
  echo "Failed to start the Vault container."
  exit 1
fi

echo "Vault container is up and running with version $VERSION."

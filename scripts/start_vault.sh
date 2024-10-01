#!/bin/bash

DATE=$(date +'%s')

# Check if a version was provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

# Store the version parameter
VERSION=$1

# Step 1: Build the corresponding Vault Docker image
docker build -f ../Dockerfile.vaultbuild --build-arg always_upgrade="$DATE" -t icecorp/vault:$VERSION ..

# Check if the docker build command was successful
if [ $? -ne 0 ]; then
  echo "Docker build failed. Exiting."
  exit 1
fi

# Step 2: Ensure the Docker network exists
# Check if the network exists, if not create it
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
CONFIG_DIR=$(realpath ../docker/config)

# Step 4: Create and run the container using the absolute path
docker run -d \
  --name vault_server \
  --network production \
  -p 9200:9200 \
  -v "$CONFIG_DIR":/home/vault/config:rw \
  --user 0:0 \
  --restart always \
  icecorp/vault:$VERSION /home/vault/config/entrypoint.sh

# Check if the container started successfully
if [ $? -ne 0 ]; then
  echo "Failed to start the Vault container."
  exit 1
fi

echo "Vault container is up and running with version $VERSION."

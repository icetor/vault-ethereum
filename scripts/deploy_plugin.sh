#!/bin/bash

# Helper function to prompt for missing environment variables
prompt_if_missing() {
  local var_name=$1
  local prompt_message=$2
  local default_value=$3

  if [ -z "${!var_name}" ]; then
    read -p "$prompt_message" value
    if [ -z "$value" ] && [ -n "$default_value" ]; then
      value="$default_value"
    fi
    export "$var_name"="$value"
  fi
}

# Prompt for missing variables
prompt_if_missing "PLUGIN_BINARY_PATH" "Enter the path to the plugin binary: " ""
prompt_if_missing "VAULT_CONTAINER_ID" "Enter the Vault container ID or name: " ""
prompt_if_missing "VAULT_USERNAME" "Enter the Vault username: " ""
prompt_if_missing "VAULT_PASSWORD" "Enter the Vault password: " ""
prompt_if_missing "VAULT_ADDR" "Enter the Vault address: " ""
prompt_if_missing "PLUGIN_SHA256" "Enter the plugin binary SHA256 checksum: " ""
prompt_if_missing "PLUGIN_VERSION" "Enter the plugin version: " ""

# Step 1: Copy the plugin binary into the existing Vault container
echo "Copying the plugin binary into the Vault container..."
docker cp "${PLUGIN_BINARY_PATH}" "${VAULT_CONTAINER_ID}:/home/vault/plugins/vault-ethereum-${PLUGIN_VERSION}"

# Check if the copy command was successful
if [ $? -ne 0 ]; then
  echo "Failed to copy the plugin binary into the Vault container."
  exit 1
fi

# Step 2: Set permissions for the Vault user to use the new binary
echo "Setting permissions inside the Vault container..."
docker exec "${VAULT_CONTAINER_ID}" /bin/sh -c "
  chmod 755 /home/vault/plugins/vault-ethereum-${PLUGIN_VERSION} &&
  chown vault:vault /home/vault/plugins/vault-ethereum-${PLUGIN_VERSION}
"

# Step 3: Prepare the environment and register the plugin
echo "Setting Vault environment variables..."
export VAULT_SKIP_VERIFY=true

echo "Logging into Vault as ${VAULT_USERNAME}..."
vault login -method=userpass username="${VAULT_USERNAME}" password="${VAULT_PASSWORD}"

# Check if login was successful
if [ $? -ne 0 ]; then
  echo "Failed to log into Vault."
  exit 1
fi

echo "Registering the plugin with Vault..."

# Register the plugin
vault write sys/plugins/catalog/secret/vault-ethereum \
    sha_256="${PLUGIN_SHA256}" \
    version="${PLUGIN_VERSION}" \
    command="vault-ethereum-${PLUGIN_VERSION}"

# Check if plugin registration was successful
if [ $? -ne 0 ]; then
  echo "Failed to register the plugin."
  exit 1
fi

# Enable the secret engine only for the first time vault-ethereum is initialized
vault secrets list | grep -q "vault-ethereum/" || vault secrets enable -path=vault-ethereum -plugin-name=vault-ethereum plugin

if [ $? -ne 0 ]; then
  echo "Failed to enable the plugin."
  exit 1
fi

echo "Listing registered plugins..."
vault plugin list -detailed

# Step 4: Pin the new version to the vault-ethereum plugin
echo "Pinning the new plugin version..."
vault write sys/plugins/pins/secret/vault-ethereum version="${PLUGIN_VERSION}"

# Check if pinning was successful
if [ $? -ne 0 ]; then
  echo "Failed to pin the plugin version."
  exit 1
fi

echo "Checking the currently pinned version..."
vault read sys/plugins/pins/secret/vault-ethereum || true

# Step 5: Reload the plugin with the new version
echo "Reloading the plugin..."
vault plugin reload -type=secret -plugin=vault-ethereum -scope=global

# Check if the reload was successful
if [ $? -ne 0 ]; then
  echo "Failed to reload the plugin."
  exit 1
fi

# Verify the plugin has been updated
echo "Verifying the plugin update..."
vault secrets list -detailed | grep vault-ethereum

# Final confirmation
echo "Plugin update completed successfully."

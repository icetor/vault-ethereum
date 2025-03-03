#!/bin/bash

# Unset any previous values for a clean start
unset PLUGIN_NAME VAULT_TOKEN PLUGIN_BINARY_PATH VAULT_CONTAINER_ID VAULT_ADDR PLUGIN_SHA256 PLUGIN_VERSION VAULT_CACERT VAULT_CLIENT_CERT VAULT_CLIENT_KEY

# Helper function to prompt for each variable, ignoring any previous environment settings.
read_with_default() {
  local var_name="$1"
  local prompt_message="$2"
  local default_value="$3"
  local value
  read -p "$prompt_message" value
  if [ -z "$value" ]; then
      value="$default_value"
  fi
  export "$var_name"="$value"
}

# Prompt for each variable
read_with_default "PLUGIN_NAME" "Enter the plugin name (default: vault-ethereum): " "vault-ethereum"
read_with_default "VAULT_TOKEN" "Enter vault token with required capabilities: " ""
read_with_default "PLUGIN_BINARY_PATH" "Enter the path to the plugin binary: " ""
read_with_default "VAULT_CONTAINER_ID" "Enter the Vault container ID or name: " ""
read_with_default "VAULT_ADDR" "Enter the Vault address (default: https://localhost:9200): " "https://localhost:9200"
read_with_default "PLUGIN_SHA256" "Enter the plugin binary SHA256 checksum string: " ""
read_with_default "PLUGIN_VERSION" "Enter the plugin version (default: v1.0.0): " "v1.0.0"
read_with_default "VAULT_CACERT" "Enter the path to the CA certificate (default: ./root.crt): " "./root.crt"
read_with_default "VAULT_CLIENT_CERT" "Enter the path to the client certificate (default: ./client.crt): " "./client.crt"
read_with_default "VAULT_CLIENT_KEY" "Enter the path to the client key (default: ./client.key): " "./client.key"

# Display summary of inputs and ask for confirmation before proceeding
echo ""
echo "==================== Configuration Summary ===================="
echo "PLUGIN_NAME          : ${PLUGIN_NAME}"
echo "VAULT_TOKEN          : ${VAULT_TOKEN}"
echo "PLUGIN_BINARY_PATH   : ${PLUGIN_BINARY_PATH}"
echo "VAULT_CONTAINER_ID   : ${VAULT_CONTAINER_ID}"
echo "VAULT_ADDR           : ${VAULT_ADDR}"
echo "PLUGIN_SHA256        : ${PLUGIN_SHA256}"
echo "PLUGIN_VERSION       : ${PLUGIN_VERSION}"
echo "VAULT_CACERT         : ${VAULT_CACERT}"
echo "VAULT_CLIENT_CERT    : ${VAULT_CLIENT_CERT}"
echo "VAULT_CLIENT_KEY     : ${VAULT_CLIENT_KEY}"
echo "===================================================================="
echo ""

read -p "Proceed with these settings? (y/N): " confirmation
if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
  echo "Aborting deployment."
  exit 1
fi

# Step 1: Copy the plugin binary into the existing Vault container
echo "Copying the plugin binary into the Vault container..."
docker cp "${PLUGIN_BINARY_PATH}" "${VAULT_CONTAINER_ID}:/home/vault/plugins/${PLUGIN_NAME}-${PLUGIN_VERSION}"

if [ $? -ne 0 ]; then
  echo "Failed to copy the plugin binary into the Vault container."
  exit 1
fi

# Step 2: Set permissions for the Vault user to use the new binary
echo "Setting permissions inside the Vault container..."
docker exec "${VAULT_CONTAINER_ID}" /bin/sh -c "
  chmod 755 /home/vault/plugins/${PLUGIN_NAME}-${PLUGIN_VERSION} &&
  chown vault:vault /home/vault/plugins/${PLUGIN_NAME}-${PLUGIN_VERSION}
"

# Step 3: Register the plugin
echo "Registering the plugin with Vault..."
vault write sys/plugins/catalog/secret/${PLUGIN_NAME} \
    sha_256="${PLUGIN_SHA256}" \
    version="${PLUGIN_VERSION}" \
    command="${PLUGIN_NAME}-${PLUGIN_VERSION}"

if [ $? -ne 0 ]; then
  echo "Failed to register the plugin."
  exit 1
fi

# Step 4: Enable the secret engine only for the first time the plugin is initialized
vault secrets list | grep -q "${PLUGIN_NAME}/" || vault secrets enable -path=${PLUGIN_NAME} -plugin-name=${PLUGIN_NAME} plugin

if [ $? -ne 0 ]; then
  echo "Failed to enable the plugin."
  exit 1
fi

echo "Listing registered plugins..."
vault plugin list -detailed

# Step 5: Pin the new version to the plugin
echo "Pinning the new plugin version..."
vault write sys/plugins/pins/secret/${PLUGIN_NAME} version="${PLUGIN_VERSION}"

if [ $? -ne 0 ]; then
  echo "Failed to pin the plugin version."
  exit 1
fi

echo "Checking the currently pinned version..."
vault read sys/plugins/pins/secret/${PLUGIN_NAME} || true

# Step 6: Reload the plugin with the new version
echo "Reloading the plugin..."
vault plugin reload -type=secret -plugin=${PLUGIN_NAME} -scope=global

if [ $? -ne 0 ]; then
  echo "Failed to reload the plugin."
  exit 1
fi

echo "Verifying the plugin update..."
vault secrets list -detailed | grep ${PLUGIN_NAME}

echo "Plugin update completed successfully."
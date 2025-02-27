#!/bin/bash

COMMAND=$1

# Determine the directory of this script and the project root.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

OPERATOR_JSON="$PROJECT_DIR/config/operator.json"
UNSEAL_JSON="$PROJECT_DIR/config/unseal.json"
OPERATOR_SECRETS=$(cat $OPERATOR_JSON)

export VAULT_CACERT="$PROJECT_DIR/config/certificates/root.crt"
export VAULT_CLIENT_CERT="$PROJECT_DIR/config/certificates/vault-client.crt"
export VAULT_CLIENT_KEY="$PROJECT_DIR/config/certificates/vault-client.key"

# Prompt the user for the Vault address with a default value.
read -p "Enter Vault address (default: https://localhost:9200): " input_vault_addr
VAULT_ADDRESS="${input_vault_addr:-https://localhost:9200}"
export VAULT_ADDR=$VAULT_ADDRESS

function authenticate() {
    echo "Authenticating to $VAULT_ADDR as root"
    ROOT=$(echo $OPERATOR_SECRETS | jq -r .root_token)
    export VAULT_TOKEN=$ROOT
}

function unseal() {
    echo "Unsealing $VAULT_ADDR..."
    UNSEAL=$(echo $OPERATOR_SECRETS | jq -r '.unseal_keys_hex[0]')
    vault operator unseal $UNSEAL
}

function status() {
    vault status
    vault secrets list
}

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <command>"
    exit 1
fi

case $COMMAND in
    auth)
        authenticate
        ;;
    unseal)
        authenticate
        unseal
        ;;
    status)
        authenticate
        status
        ;;
    *)
        echo "Unknown command: $COMMAND"
        exit 1
        ;;
esac

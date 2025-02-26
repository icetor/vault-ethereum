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
export VAULT_ADDR=https://localhost:9200

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
    echo "Illegal number of parameters"
    exit 1
fi

if [ $COMMAND = "auth" ]; then
    authenticate
elif [ $COMMAND = "unseal" ]; then
    authenticate
    unseal
elif [ $COMMAND = "status" ]; then
    authenticate
    status
fi

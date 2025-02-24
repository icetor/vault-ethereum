#!/bin/bash

OPERATOR_JSON="/home/vault/config/operator.json"
UNSEAL_JSON="/home/vault/config/unseal.json"

function banner() {
  echo "+----------------------------------------------------------------------------------+"
  printf "| %-80s |\n" "$(date)"
  echo "|                                                                                  |"
  printf "| %-80s |\n" "$@"
  echo "+----------------------------------------------------------------------------------+"
}

function unseal() {
    banner "Unsealing $VAULT_ADDR..."
    if [ -f "$UNSEAL_JSON" ]; then
        UNSEAL=$(jq -r '.unseal_keys_hex[0]' "$UNSEAL_JSON")
        vault operator unseal $UNSEAL
    else
        echo "Unseal file $UNSEAL_JSON not found!"
    fi
}

function status() {
    vault status
}

function init() {
    OPERATOR_SECRETS=$(vault operator init -key-shares=1 -key-threshold=1 -format=json)
    echo "$OPERATOR_SECRETS" > "$OPERATOR_JSON"
    echo "$OPERATOR_SECRETS" | jq '{unseal_keys_hex}' > "$UNSEAL_JSON"
}

sleep 20
if [ -f "$UNSEAL_JSON" ]; then
    unseal
    status
else
    init
    unseal
    status
fi

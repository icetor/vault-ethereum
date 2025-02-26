#!/bin/bash

OPERATOR_JSON="/home/vault/config/operator.json"

function banner() {
  echo "+----------------------------------------------------------------------------------+"
  printf "| %-80s |\n" "$(date)"
  echo "|                                                                                  |"
  printf "| %-80s |\n" "$@"
  echo "+----------------------------------------------------------------------------------+"
}

function unseal() {
    banner "Unsealing $VAULT_ADDR..."
    UNSEAL=$(jq -r '.unseal_keys_hex[0]' "$OPERATOR_JSON")
    vault operator unseal "$UNSEAL"
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

# Check Vault's initialization status using its own status command.
if vault status | grep -q 'Initialized.*true'; then
  banner "Vault has already been initialized. Skipping the initialization process."
  if vault status | grep -q 'Sealed.*true'; then
    banner "Vault is currently sealed. It must be unsealed to proceed with operations."
  fi
else
  init
  unseal
  status
fi

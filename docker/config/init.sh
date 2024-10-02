#!/bin/bash

OPERATOR_JSON="/home/vault/config/operator.json"
OPERATOR_SECRETS=$(cat $OPERATOR_JSON)


function banner() {
  echo "+----------------------------------------------------------------------------------+"
  printf "| %-80s |\n" "`date`"
  echo "|                                                                                  |"
  printf "| %-80s |\n" "$@"
  echo "+----------------------------------------------------------------------------------+"
}

function unseal() {
    banner "Unsealing $VAULT_ADDR..."
    UNSEAL=$(echo $OPERATOR_SECRETS | jq -r '.unseal_keys_hex[0]')
    vault operator unseal $UNSEAL
}

function status() {
    vault status
}

function init() {
    OPERATOR_SECRETS=$(vault operator init -key-shares=1 -key-threshold=1 -format=json | jq .)
    echo $OPERATOR_SECRETS > $OPERATOR_JSON
}
sleep 20
if [ -f "$OPERATOR_JSON" ]; then
    unseal
    status
else
    init
    unseal
    status
fi

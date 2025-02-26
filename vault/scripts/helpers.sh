#!/bin/bash

COMMAND=$1

# Determine the directory of this script and the project root.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"


function remove_container() {
    read -p "Are you sure you want to stop and remove Vault docker container? This action cannot be undone. (y/N): " confirmation
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo "Clear command aborted."
        exit 1
    fi


    if docker ps --format '{{.Names}}' | grep -q "^vault_server$"; then
        echo "Stopping vault_server..."
        docker stop vault_server
    fi
    if docker ps -a --format '{{.Names}}' | grep -q "^vault_server$"; then
        echo "Removing vault_server..."
        docker rm vault_server
    else
        echo "vault_server container not found."
    fi
}

function clear() {
    read -p "Are you sure you want to clear vault data? This action cannot be undone. (y/N): " confirmation
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo "Clear command aborted."
        exit 1
    fi

    echo "Clearing vault data..."
    echo "rm $OPERATOR_JSON"
    rm "$OPERATOR_JSON"
    rm "$UNSEAL_JSON"
    rm $PROJECT_DIR/config/certificates/*.key
    rm $PROJECT_DIR/config/certificates/*.crt
    rm $PROJECT_DIR/config/certificates/*.srl
    rm $PROJECT_DIR/config/certificates/*.csr
    rm $PROJECT_DIR/config/raft/*.db
    rm -rf $PROJECT_DIR/config/raft/raft
}

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

if [ $COMMAND = "clear" ]; then
    clear
elif [ $COMMAND = "remove-container" ]; then
    remove_container
fi
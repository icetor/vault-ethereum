#!/bin/bash

COMMAND=$1

# Determine the directory of this script and the project root.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"


function remove_container() {
    read -p "Enter the container name to stop and remove (default: vault_server): " container_name
    container_name="${container_name:-vault_server}"
    
    read -p "Are you sure you want to stop and remove container '${container_name}'? This action cannot be undone. (y/N): " confirmation
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo "Clear command aborted."
        exit 1
    fi

    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "Stopping ${container_name}..."
        docker stop ${container_name}
    fi
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "Removing ${container_name}..."
        docker rm ${container_name}
    else
        echo "Container '${container_name}' not found."
    fi
}

function clear_certs() {
    read -p "Are you sure you want to clear vault certificates? This action cannot be undone. (y/N): " confirmation
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo "Clear command aborted."
        exit 1
    fi

    echo "Clearing certificates..."
    rm $PROJECT_DIR/config/certificates/*.key
    rm $PROJECT_DIR/config/certificates/*.crt
    rm $PROJECT_DIR/config/certificates/*.srl
    rm $PROJECT_DIR/config/certificates/*.csr
}

function clear_data() {
    read -p "Are you sure you want to clear vault data? This action cannot be undone. (y/N): " confirmation
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo "Clear command aborted."
        exit 1
    fi

    echo "Clearing vault data..."
    rm $PROJECT_DIR/config/operator.json
    rm $PROJECT_DIR/config/raft/*.db
    rm -rf $PROJECT_DIR/config/raft/raft
}

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

if [ $COMMAND = "clear-data" ]; then
    clear_data
elif [ $COMMAND = "clear-certs" ]; then
    clear_certs
elif [ $COMMAND = "clear-all" ]; then
    clear_data
    clear_certs
elif [ $COMMAND = "remove-container" ]; then
    remove_container
fi
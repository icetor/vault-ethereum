#!/bin/bash

CONFIG_DIR="/home/vault/config"
CERTS_DIR="$CONFIG_DIR/certificates"
INIT_SCRIPT="$CONFIG_DIR/init.sh"
CA_CERT="$CERTS_DIR/root.crt"
CA_KEY="$CERTS_DIR/root.key"
TLS_KEY="$CERTS_DIR/vault.key"
TLS_CERT="$CERTS_DIR/vault.crt"
OPENSSL_CONFIG="$CERTS_DIR/vault.cnf"
CSR="$CERTS_DIR/vault.csr"

# Client certificate variables
CLIENT_KEY="$CERTS_DIR/vault-client.key"
CLIENT_CERT="$CERTS_DIR/vault-client.crt"
CLIENT_CSR="$CERTS_DIR/vault-client.csr"

export VAULT_ADDR="https://127.0.0.1:9200"
export VAULT_CACERT="$CA_CERT"
export VAULT_CLIENT_CERT="$CLIENT_CERT"
export VAULT_CLIENT_KEY="$CLIENT_KEY"

function gencerts {
    # Verify that the external OpenSSL config file exists
    if [ ! -f "$OPENSSL_CONFIG" ]; then
        echo "Error: External OpenSSL config file $OPENSSL_CONFIG not found. Exiting."
        exit 1
    fi

    # Generate a self-signed CA certificate (used to sign the Vault server cert)
    openssl req \
        -new \
        -sha256 \
        -newkey rsa:2048 \
        -days 36500 \
        -nodes \
        -x509 \
        -subj "/C=US/ST=Maryland/L=icecorp/O=icecorp" \
        -keyout "$CA_KEY" \
        -out "$CA_CERT"

    # Generate a private key for the Vault server
    openssl genrsa -out "$TLS_KEY" 2048

    # Generate a Certificate Signing Request (CSR) using the external OpenSSL config
    openssl req \
        -new -key "$TLS_KEY" \
        -out "$CSR" \
        -config "$OPENSSL_CONFIG"

    # Sign the CSR with the CA certificate to produce the Vault server certificate
    openssl x509 \
        -req \
        -days 36500 \
        -in "$CSR" \
        -CA "$CA_CERT" \
        -CAkey "$CA_KEY" \
        -CAcreateserial \
        -sha256 \
        -extensions v3_req \
        -extfile "$OPENSSL_CONFIG" \
        -out "$TLS_CERT"

    # Display server certificate details
    openssl x509 -in "$TLS_CERT" -noout -text

    # --- Generate the client certificate ---
    # Generate a private key for the client
    openssl genrsa -out "$CLIENT_KEY" 2048

    # Generate a CSR for the client certificate (using a simple subject)
    openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" -subj "/CN=vault-client"

    # Sign the client CSR with the CA certificate to produce the client certificate
    openssl x509 \
        -req \
        -days 36500 \
        -in "$CLIENT_CSR" \
        -CA "$CA_CERT" \
        -CAkey "$CA_KEY" \
        -CAcreateserial \
        -sha256 \
        -out "$CLIENT_CERT"

    # Display client certificate details
    openssl x509 -in "$CLIENT_CERT" -noout -text

    # Adjust permissions for the certificates directory
    chown -R nobody:nobody "$CERTS_DIR" && chmod -R 777 "$CERTS_DIR"
}

# Check if certificates exist; if not, generate them.
if [ ! -f "$CA_CERT" ] || [ ! -f "$TLS_KEY" ] || [ ! -f "$TLS_CERT" ] || [ ! -f "$CLIENT_CERT" ] || [ ! -f "$CLIENT_KEY" ]; then
    echo "Certificates not found. Generating certificates..."
    gencerts
else
    echo "Certificates already exist. Skipping generation."
fi

# Start the Vault server in the background
if [ ! -f "$CONFIG_DIR/vault.hcl" ]; then
    echo "Error: Vault configuration file $CONFIG_DIR/vault.hcl not found. Exiting."
    exit 1
fi

nohup vault server -log-level=debug -config "$CONFIG_DIR/vault.hcl" &
VAULT_PID=$!

which bash

# Run the initialization script if it exists
if [ -f "$INIT_SCRIPT" ]; then
    /bin/bash "$INIT_SCRIPT"
fi

# Wait for the Vault server process to exit
wait $VAULT_PID

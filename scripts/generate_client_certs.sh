#!/bin/bash

# Create output directory if it doesn't exist
OUTPUT_DIR="$(pwd)/out"
mkdir -p "$OUTPUT_DIR"

# Prompt for inputs
read -p "Enter client common name: " CLIENT_NAME
read -p "Enter path to CA certificate (e.g., /path/to/root.crt): " CA_CERT
read -p "Enter path to CA key (e.g., /path/to/root.key): " CA_KEY

# Check if the provided CA files exist
if [ ! -f "$CA_CERT" ]; then
    echo "Error: CA certificate file not found at '$CA_CERT'"
    exit 1
fi

if [ ! -f "$CA_KEY" ]; then
    echo "Error: CA key file not found at '$CA_KEY'"
    exit 1
fi

# Define output file paths
CLIENT_KEY="$OUTPUT_DIR/${CLIENT_NAME}.key"
CLIENT_CSR="$OUTPUT_DIR/${CLIENT_NAME}.csr"
CLIENT_CERT="$OUTPUT_DIR/${CLIENT_NAME}.crt"

# Generate a 2048-bit private key for the client
openssl genrsa -out "$CLIENT_KEY" 2048

# Generate a Certificate Signing Request (CSR) with the provided common name
openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" -subj "/CN=$CLIENT_NAME"

# Sign the CSR with the CA certificate and key to generate the client certificate
openssl x509 -req -days 36500 -in "$CLIENT_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" \
    -CAcreateserial -sha256 -out "$CLIENT_CERT"

echo "Client certificate generation complete."
echo "Files generated in $OUTPUT_DIR:"
echo "  Client Key:         $CLIENT_KEY"
echo "  Client CSR:         $CLIENT_CSR"
echo "  Client Certificate: $CLIENT_CERT"
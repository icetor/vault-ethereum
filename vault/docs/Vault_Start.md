## Vault Start  
 
This document provides instructions for starting a new Vault instance using Docker.  
 
## How It Works  
 
- **Image and Container Setup:**  
  - The `hashicorp/vault` image is pulled from Docker Hub and run in the `vault_server` container.  
  - The project's `config` folder is symlinked to `/home/vault/config` inside the container. This folder contains Vault certificates and data.  
 
- **Entrypoint and TLS Certificates:**  
  - The container starts by executing the `entrypoint.sh` script, which:  
    - Launches the Vault server.  
    - Ensures that TLS certificates are available. If they are missing, the script creates them.  
  - The project enforces mTLS, so both the server and clients require valid certificates.  
 
- **Certificate Configuration:**  
  - When deploying in a new environment, add the server's IP address or DNS name to the certificate's Subject Alternative Names (SANs) in `config/certificates/vault.cnf` to ensure proper validation.  
  - Since the CA is self-signed, distribute the generated `root.crt` to all client machines to establish mutual trust.  
 
  Example SAN configuration in `vault.cnf`:  
  ```bash
  [alt_names]
  IP.1  = 127.0.0.1
  DNS.1 = localhost
  ```  
 
- **Configuration File:**  
  - Vault uses the `config/vault.hcl` configuration file. Modify this file if you need to change any settings.  
 
- **Initialization and Unsealing:**  
  - Once the Vault server starts via the entrypoint script, the `init.sh` script is executed. This script:  
    - Initializes and unseals the Vault instance using the Vault CLI.  
    - Saves the root token and unseal keys in the `config/operator.json` file.  
  - **Security Note:** Securely store these tokens, and after doing so, consider removing the `operator.json` file from the filesystem.  
  - When the container restarts or shuts down, Vault will automatically be sealed. The unseal key is required to reopen and persist the data.  
 
- **Client Configuration:**  
  - For clients to interact with the Vault server, they must have:  
    - The CA certificate (distributed to each client).  
    - A client private key and certificate issued by the same CA.  
  - Use the `generate-client-certs.sh` script to generate client certificates and keys, or customize the certificate generation process for enhanced security.  
 
## How To Start  
 
1. **Run the Start Script:**  
   Execute the `start_vault.sh` script with optional parameters for Vault version and port:  
   ```bash
   bash ./start_vault.sh X.XX XXXX
   ```  
   - If no version is provided, the script defaults to version `1.17`.  
   - If no port is provided, the script defaults to port `9200`.  
 
After running the script, Vault will be built, and the container will start with the specified configuration.
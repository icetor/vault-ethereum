# Vault Plugin Deployment
This document contains information on how to update Vault Ethereum plugin binary and how to deploy it to a Vault instance.

## Vault Ethereum Plugin Deployment Using the [vault-ethereum](https://github.com/icetor/vault-ethereum/tree/master) Repository
1. Start by cloning the ```vault-ethereum``` repository and switch to deployment branch. 
    ```bash
    git clone https://github.com/icetor/vault-ethereum
    git checkout deployment
    ```

2. Create a new plugin binary from the source
   
   - Build the new plugin binary inside a temporary docker container.
        ```bash
        docker build -f Dockerfile.pluginbuild -t vault-ethereum-builder .
        ```
   - Create the temporary container 
        ```bash
        docker create --name vault-ethereum-builder-container vault-ethereum-builder
        ```
   - Copy the binary and SHA256SUM from the temporary container to the host system. 
        ```bash
        docker cp vault-ethereum-builder-container:/build/bin/vault-ethereum ./vault-ethereum-v1.0.5
        docker cp vault-ethereum-builder-container:/build/bin/SHA256SUMS .
        ```
   - Remove the temporary container
        ```bash
        docker rm vault-ethereum-builder-container
        ```

3. Prepare a policy to deploy plugins to the Vault instance. Create the following policy and assign it to a user.
     ```json
     {
          "policy": "path \"sys/plugins/catalog/secret/vault-ethereum\" {\n  capabilities = [\"create\", \"update\", \"delete\", \"read\", \"sudo\"]\n}\n\npath \"sys/plugins/pins/secret/vault-ethereum\" {\n  capabilities = [\"create\", \"update\", \"delete\", \"read\", \"sudo\"]\n}\n\npath \"sys/plugins/reload/secret/vault-ethereum\" {\n  capabilities = [\"update\", \"sudo\"]\n}\n\npath \"sys/plugins/pins\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"sys/plugins/pins/*\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"sys/mounts\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"sys/mounts/vault-ethereum\" {\n  capabilities = [\"create\", \"update\", \"read\", \"sudo\"]\n}\n\npath \"sys/plugins/catalog\" {\n  capabilities = [\"read\", \"list\"]\n}\n"
     }
     ```

4. Deploy the plugin binary by either setting following parameters in environment or providing them during the script phases of ```deploy_plugin.sh```.
     ```bash
     export PLUGIN_BINARY_PATH=absolute_path
     export VAULT_CONTAINER_ID=docker_container_id
     export VAULT_TOKEN=user_token
     export VAULT_ADDR=vault_api_address
     export PLUGIN_SHA256=string
     export PLUGIN_VERSION=v1.0.5_etc

     bash ./scripts/deploy_plugin.sh
     ```

## ```deploy_plugin.sh``` Steps Explained 
1. Copy the new plugin binary to the Vault container 
     ```bash
     docker cp vault-ethereum-v1.0.5 e74e89eda904:/home/vault/plugins/vault-ethereum-v1.0.5
     ```

2. Set permissions for vault user to be able to use the new binary 
     ```bash
     docker exec -it e74e89eda904 /bin/sh
     chmod 755 /home/vault/plugins/vault-ethereum-v1.0.5
     chown vault:vault /home/vault/plugins/vault-ethereum-v1.0.5
     exit
     ```

3. In order to interact with the Vault CLI without providing certificate credentials, set below value in the environment. Also if Vault address is different from the default address (which is ```localhost:8200```) set VAULT_ADDR variable accordingly.
     ```bash
     export VAULT_SKIP_VERIFY=true
     export VAULT_ADDR="https://localhost:9200"
     ```

4. The VAULT_TOKEN variable is used by Vault CLI commands for authentication. You can use the login command to automatically set this variable in the environment. However, if a Vault token is already set in the environment, the login command will not override it, and the new token must be manually exported to the environment.
     ```bash
     vault login -method=userpass username=pluginupdater password=12345
     ```

5. Register the plugin using vault cli's write command on the path ```sys/plugins/catalog/secret```.
     ```bash
     vault write sys/plugins/catalog/secret/vault-ethereum \
     sha_256="${PLUGIN_SHA256}" \
     version="${PLUGIN_VERSION}" \
     command="vault-ethereum-${PLUGIN_VERSION}"
     ```

> **Note:** To view the registered plugins, use ```"vault plugin list -detailed"``` command. Multiple versions of the `vault-ethereum` plugin can coexist on this list. To specify which version Vault should use, you need to pin the desired version explicitly.


6. When a secrets plugin is added to the Vault environment for the first time, you must enable the secrets engine on the vault-ethereum path. This step is only required during the initial setup and is not needed for subsequent plugin updates. 
     ```bash 
     vault secrets list | grep -q "vault-ethereum/" || vault secrets enable -path=vault-ethereum -plugin-name=vault-ethereum plugin
     ```

7. Pin the new version of the vault-ethereum.
     ```bash
     vault write sys/plugins/pins/secret/vault-ethereum version="v1.0.5”
     ```

> **Note:** You can view currently pinned version of the secret plugin with the command: `"vault read sys/plugins/pins/secret/vault-ethereum"`

8. As the final step, the plugin must be reloaded with the new version, which updates the plugin binary. If the new version is compatible with the existing backend, the plugin can continue to be used without any loss of access to data.
     ```bash
     vault plugin reload -type=secret -plugin=vault-ethereum -scope=global
     ```

> **Note:** You can view the current status of running secrets plugins using the following command `"vault secrets list -detailed"`
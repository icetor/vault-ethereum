# Vault Secrets Plugin Deployment  
This document outlines the steps required to update and deploy custom Vault secrets engine plugins to a running Vault instance.  
 
**Note on Plugin Deployment Permissions**  
While it is technically possible to deploy Vault plugins using the root token, this practice is strongly discouraged.  
For security and to adhere to the principle of least privilege, create a dedicated token with only the necessary capabilities for plugin deployment.  
 
Below is an example policy for the **vault-ethereum** plugin.  
If you are deploying a different plugin, simply replace every occurrence of `vault-ethereum` with your desired plugin name.  
 
```json
{
     "policy": "path \"sys/plugins/catalog/secret/vault-ethereum\" {\n  capabilities = [\"create\", \"update\", \"delete\", \"read\", \"sudo\"]\n}\n\npath \"sys/plugins/pins/secret/vault-ethereum\" {\n  capabilities = [\"create\", \"update\", \"delete\", \"read\", \"sudo\"]\n}\n\npath \"sys/plugins/reload/secret/vault-ethereum\" {\n  capabilities = [\"update\", \"sudo\"]\n}\n\npath \"sys/plugins/pins\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"sys/plugins/pins/*\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"sys/mounts\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"sys/mounts/vault-ethereum\" {\n  capabilities = [\"create\", \"update\", \"read\", \"sudo\"]\n}\n\npath \"sys/plugins/catalog\" {\n  capabilities = [\"read\", \"list\"]\n}\n"
}
```  
 
**2. Setting Environment Variables and Deploying the Plugin**  
Variables required will be provided interactively during the deployment process using deploy_secrets_plugin.sh.

List of required variables:
- PLUGIN_NAME: vault-ethereum
- PLUGIN_BINARY_PATH: absolute_path
- VAULT_CONTAINER_ID: docker_container_id
- VAULT_TOKEN: user_token
- VAULT_ADDR: vault_api_address
- PLUGIN_SHA256: string
- PLUGIN_VERSION: v1.0.5_etc
- VAULT_CACERT: path/to/root.crt
- VAULT_CLIENT_CERT: path/to/client.crt
- VAULT_CLIENT_KEY: path/to/client.key

Run the script with:
```bash ./scripts/deploy_secrets_plugin.sh```
 
**deploy_secrets_plugin.sh Steps Explained**  
 
1. **Copy the Plugin Binary to the Vault Container**  
   The script uses Docker to copy the new plugin binary into the Vault container:  
   ```bash
   docker cp vault-ethereum-v1.0.5 e74e89eda904:/home/vault/plugins/vault-ethereum-v1.0.5
   ```  
 
2. **Set Permissions for the Vault User**  
   After copying, the script sets the correct file permissions so the Vault user can execute the binary:  
   ```bash
   docker exec -it e74e89eda904 /bin/sh
   chmod 755 /home/vault/plugins/vault-ethereum-v1.0.5
   chown vault:vault /home/vault/plugins/vault-ethereum-v1.0.5
   exit
   ```  
 
3. **Register the Plugin**  
   Register the plugin using the Vault CLI with the following command.  
   This command writes the plugin metadata (including the SHA256 checksum, version, and command) to the Vault catalog:  
   ```bash
   vault write sys/plugins/catalog/secret/vault-ethereum \
       sha_256="${PLUGIN_SHA256}" \
       version="${PLUGIN_VERSION}" \
       command="vault-ethereum-${PLUGIN_VERSION}"
   ```  
 
   > **Note:** Use `vault plugin list -detailed` to view registered plugins. Multiple versions can coexist; pin the desired version explicitly.  
 
4. **Enable the Secrets Engine (Initial Setup Only)**  
   For the first-time deployment of the plugin, enable the secrets engine on the `vault-ethereum` path:  
   ```bash
   vault secrets list | grep -q "vault-ethereum/" || vault secrets enable -path=vault-ethereum -plugin-name=vault-ethereum plugin
   ```  
 
5. **Pin the New Plugin Version**  
   Pin the new version to ensure Vault uses the updated plugin binary:  
   ```bash
   vault write sys/plugins/pins/secret/vault-ethereum version="${PLUGIN_VERSION}"
   ```  
 
   > **Note:** To check the currently pinned version, run:  
   ```bash
   vault read sys/plugins/pins/secret/vault-ethereum
   ```  
 
6. **Reload the Plugin**  
   Finally, reload the plugin so that the new version is active:  
   ```bash
   vault plugin reload -type=secret -plugin=vault-ethereum -scope=global
   ```  
 
   > **Note:** Verify the update by running `vault secrets list -detailed`.  
 
**Final Confirmation**  
Once all steps are completed successfully, the script outputs a confirmation that the plugin update is complete. 

This streamlined process helps ensure secure and efficient deployment of your Vault plugins. Later, you can pin any deployed version and reload the plugin to seamlessly switch between versions, making version management and upgrades straightforward and efficient.
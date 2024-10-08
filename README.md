# Vault Ethereum Plugin Deployment

# Start vault if not already started with desired version parameter.

```bash
bash ./scripts/start_vault.sh X.XX
```

# Prepare a policy to deploy plugins to the vault environment
Use the following example policy and assign it to the user.
```json
{
  "policy": "path \"sys/plugins/catalog/secret/vault-ethereum\" {\n  capabilities = [\"create\", \"update\", \"delete\", \"read\", \"sudo\"]\n}\n\npath \"sys/plugins/pins/secret/vault-ethereum\" {\n  capabilities = [\"create\", \"update\", \"delete\", \"read\", \"sudo\"]\n}\n\npath \"sys/plugins/reload/secret/vault-ethereum\" {\n  capabilities = [\"update\", \"sudo\"]\n}\n\npath \"sys/plugins/pins\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"sys/plugins/pins/*\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"sys/mounts\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"sys/mounts/vault-ethereum\" {\n  capabilities = [\"create\", \"update\", \"read\", \"sudo\"]\n}\n\npath \"sys/plugins/catalog\" {\n  capabilities = [\"read\", \"list\"]\n}\n"
}
```

# Deploy plugin binary by either setting following parameters in environment or providing during script phase.
```bash
export PLUGIN_BINARY_PATH=
export VAULT_CONTAINER_ID=
export VAULT_TOKEN=
export VAULT_ADDR=
export PLUGIN_SHA256=
export PLUGIN_VERSION=

bash ./scripts/deploy_plugin.sh
```
## TODO modify this
# Vault Ethereum Plugin v0.3.0

### Start Vault
```bash
cd ./scripts
bash ./start_vault.sh
```

### Deployment Finalization
It is advised to save the contents of operator.json to a safe place and remove it from the filesystem.

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

### Ethereum Account Operations
  - **Create Account:** `/accounts/{name}`
    - Create an Ethereum account using a generated or provided passphrase.
  - **Get Account Balance:** `/accounts/{name}/balance`
    - Return the balance for an account.
  - **Deploy Smart Contract:** `/accounts/{name}/deploy`
    - Deploy a smart contract from an account.
  - **ERC-20 Operations:**
    - **Approve Spending:** `/accounts/{name}/erc20/approve`
      - Allow spender to withdraw from your account.
    - **Get ERC-20 Balance:** `/accounts/{name}/erc20/balanceOf`
      - Return the balance for an address's ERC-20 holdings.
    - **Get ERC-20 Total Supply:** `/accounts/{name}/erc20/totalSupply`
      - Return the total supply for an ERC-20 token.
    - **Transfer ERC-20:** `/accounts/{name}/erc20/transfer`
      - Transfer ERC-20 holdings to another address.
    - **Transfer From ERC-20:** `/accounts/{name}/erc20/transferFrom`
      - Transfer ERC-20 holdings from another address to this address.
  - **Signing Operations:**
    - **Sign Message:** `/accounts/{name}/sign`
      - Sign a message.
    - **Sign Transaction:** `/accounts/{name}/sign-tx`
      - Sign a transaction.
  - **Transfer ETH:** `/accounts/{name}/transfer`
    - Send ETH from an account.
  - **List Accounts:** `/accounts/`
    - List all Ethereum accounts at this path.
  ### Plugin Configuration
  - **Configure Plugin:** `/config`
    - Configure the Vault Ethereum plugin.
  ### Ethereum Unit Conversion
  - **Convert Units:** `/convert`
    - Convert any Ethereum unit to another.
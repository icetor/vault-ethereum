
## Backup and Restore Operations

In order to backup your Vault data you can use snapshots which requires Raft backend which we have already setup in ```config/vault.hcl```. 

At any point snapshot of the database can be taken with below command

```curl
curl -X GET "${VAULT_URL}/v1/sys/storage/raft/snapshot" \
  -H "X-Vault-Token: ${authToken}" \
  --output "${pathPrefix}$(date).snap"
```

This snapshot can be used to revert the Vault instance from which it was taken to it's previous state, as well as to restore a completely different Vault instance to this state.

**a)** For restoring on the same Vault instance use the below command:
```curl
curl -X PUT "${VAULT_URL}/v1/sys/storage/raft/snapshot" \
  -H "X-Vault-Token: ${vaultToken}" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@${snapshotPath}"
```

**b)** Restoring a snapshot on a different Vault instance will override all data on that instance and replace its root token, seal key, and unseal keys with those from the snapshot.

```curl
curl -X PUT "${VAULT_URL}/v1/sys/storage/raft/snapshot-force" \
  -H "X-Vault-Token: ${vaultToken}" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@${snapshotPath}"
```

Once the restoration is complete, Vault will seal itself and must be unsealed using the b64 unseal key from the Vault operator where the snapshot was taken.

```curl
curl --location 'https://localhost:9200/v1/sys/unseal' \
--header 'Content-Type: text/plain' \
--data '{
  "key": "b64_unseal_key"
}'
```

> **Note:** If restoring on a different Vault instance remember to deploy the same plugin binaries seperately. Although restoration restores the data written by the plugin to the Vault storage, it does not copy the plugin binaries.

> **Note:** All curl commands can be replaced with Vault CLI commands.
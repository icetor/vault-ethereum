default_lease_ttl = "24h"
disable_mlock = "true"
max_lease_ttl = "43800h"

storage "raft" {
   path = "/home/vault/config/raft"
   node_id = "raft_node_1"
}

api_addr = "https://localhost:9200"
cluster_addr = "https://localhost:9201"
ui = "false"

plugin_directory = "/home/vault/plugins"
listener "tcp" {
address = "0.0.0.0:9200"
tls_cert_file = "/home/vault/config/certificates/vault.crt"
tls_client_ca_file = "/home/vault/config/certificates/root.crt"
tls_key_file = "/home/vault/config/certificates/vault.key"
tls_require_and_verify_client_cert = true
}

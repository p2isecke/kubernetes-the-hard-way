#!/bin/bash

KUBERNETES_THE_HARD_WAY_LOCAL_FILE_DIR="$HOME/kubernetes-the-hard-way-pki-infra"
KUBERNETES_ENCRYPTION_CONFIG_FILE="encryption-config.yaml"
TF_STATE_DIR="$HOME/git/kubernetes-the-hard-way/terraform"

create_encryption_config() {
  local encryption_key=$(head -c 32 /dev/urandom | base64)

cat > "$KUBERNETES_ENCRYPTION_CONFIG_FILE" <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${encryption_key}
      - identity: {}
EOF
}

distribute_controller_encryption_config() {
  for instance in controller-0 controller-1 controller-2; do
    scp_to_node ${instance} "${KUBERNETES_ENCRYPTION_CONFIG_FILE}"
  done
}

scp_to_node() {
  local instance="$1"
  local files_names="$2"
  pushd $TF_STATE_DIR
  local jump_server_ip=$(terraform output -json jump-server)
  local node_ip=$(terraform output -json ${instance} | tr -d '"' | tr -d '\r') 
  popd
  eval "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o 'ProxyJump ubuntu@${jump_server_ip}' "${files_names}" ubuntu@${node_ip}:~/"
}

# Assumes worker nodes are provisioned with Terraform
# Assumes the kubernetes-the-hard-way is checked out at $HOME
main() {
    pushd $KUBERNETES_THE_HARD_WAY_LOCAL_FILE_DIR
    create_encryption_config
    distribute_controller_encryption_config
    popd
}

main

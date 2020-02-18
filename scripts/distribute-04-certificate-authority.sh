#!/bin/bash

KUBERNETES_THE_HARD_WAY_LOCAL_FILE_DIR="$HOME/kubernetes-the-hard-way-pki-infra"
TF_STATE_DIR="$HOME/git/kubernetes-the-hard-way/terraform"

distribute_worker_certs() {
  for instance in worker-0 worker-1 worker-2; do
    local worker_node_files="ca.pem ${instance}-key.pem ${instance}.pem"
    scp_to_node ${instance} "${worker_node_files}"
  done
}

distribute_controller_certs() {
  for instance in controller-0 controller-1 controller-2; do
    local controller_files="ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem"
    scp_to_node ${instance} "${controller_files}"
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
    distribute_worker_certs
    distribute_controller_certs
    popd
}

main

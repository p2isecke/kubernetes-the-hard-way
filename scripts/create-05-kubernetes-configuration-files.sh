#!/bin/bash

KUBERNETES_THE_HARD_WAY_LOCAL_FILE_DIR="$HOME/kubernetes-the-hard-way-pki-infra"
TF_STATE_DIR="$HOME/git/kubernetes-the-hard-way/terraform"

create_workernode_kubeconfig() {
  for instance in worker-0 worker-1 worker-2; do
    pushd $TF_STATE_DIR
    local kubernetes_public_address=$(terraform output -json kubernetes-public-ip)
    popd

    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://${kubernetes_public_address}:6443 \
      --kubeconfig=${instance}.kubeconfig
    
    kubectl config set-credentials system:node:${instance} \
      --client-certificate=${instance}.pem \
      --client-key=${instance}-key.pem \
      --embed-certs=true \
      --kubeconfig=${instance}.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:node:${instance} \
      --kubeconfig=${instance}.kubeconfig

    kubectl config use-context default --kubeconfig=${instance}.kubeconfig
  done
}

create_kubeproxy_kubeconfig() {
  pushd $TF_STATE_DIR
  local kubernetes_public_address=$(terraform output -json kubernetes-public-ip)
  popd

  kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${kubernetes_public_address}:443 \
  --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

create_kubecontroller_kubeconfig() {
  kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}

create_kubescheduler_kubeconfig() {
  kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}

create_admin_kubeconfig() {
  kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}

main() {
    if [ !-d "$KUBERNETES_THE_HARD_WAY_LOCAL_FILE_DIR" ]; then
      echo "The following commands must be run in the same directory used to generate the SSL certificates during the Generating TLS Certificates lab."
      echo "Do this lab first to create prerequisite files and directory."
      exit 1
    fi
    pushd $KUBERNETES_THE_HARD_WAY_LOCAL_FILE_DIR
    create_workernode_kubeconfig
    create_kubeproxy_kubeconfig
    create_kubecontroller_kubeconfig
    create_kubescheduler_kubeconfig
    create_admin_kubeconfig
    popd
}

main

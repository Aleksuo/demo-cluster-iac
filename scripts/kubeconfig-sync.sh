#!/usr/bin/env bash
set -e

TOFU_DIR="${TOFU_DIR:-hetzner-k3s}"
OUTPUT_NAME="${OUTPUT_NAME:-master_node_public_ip}"
SSH_USER="${SSH_USER:-admin}"

MASTER_IP="$(tofu -chdir="$TOFU_DIR" output -raw "$OUTPUT_NAME")"

mkdir -p ~/.kube
TMP="/tmp/k3s-${MASTER_IP}.yaml"

ssh "${SSH_USER}@${MASTER_IP}" "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed "s#https://127.0.0.1:6443#https://${MASTER_IP}:6443#g" \
  > "$TMP"

# Merge with existing kubeconfig (or create it)
if [ -f ~/.kube/config ]; then
  KUBECONFIG=~/.kube/config:"$TMP" kubectl config view --flatten > /tmp/kubeconfig.merged
  mv /tmp/kubeconfig.merged ~/.kube/config
else
  cp "$TMP" ~/.kube/config
fi

chmod 600 ~/.kube/config

echo "Added kubeconfig. Contexts now:"
kubectl config get-contexts
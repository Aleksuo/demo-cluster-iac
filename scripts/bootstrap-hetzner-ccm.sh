#!/usr/bin/env bash
set -euo pipefail

HCLOUD_CCM_NAMESPACE="${HCLOUD_CCM_NAMESPACE:-kube-system}"


kubectl -n $HCLOUD_CCM_NAMESPACE create secret generic hcloud \
    --from-literal=token="$HCLOUD_TOKEN"
helm repo add hcloud https://charts.hetzner.cloud
helm repo update hcloud
helm install hccm hcloud/hcloud-cloud-controller-manager -n $HCLOUD_CCM_NAMESPACE

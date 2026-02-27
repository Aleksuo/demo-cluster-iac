#!/usr/bin/env bash
set -euo pipefail

CILIUM_NAMESPACE="${CILIUM_NAMESPACE:-kube-system}"

kubectl apply -k kubernetes/addons/gateway-api-crds
helm dependency build kubernetes/addons/cilium
helm upgrade --install cilium kubernetes/addons/cilium -n $CILIUM_NAMESPACE

kubectl -n $CILIUM_NAMESPACE rollout status ds/cilium
kubectl -n $CILIUM_NAMESPACE rollout status deploy/cilium-operator
kubectl get nodes -o wide
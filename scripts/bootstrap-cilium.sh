#!/usr/bin/env bash
set -euo pipefail

CILIUM_NAMESPACE="${CILIUM_NAMESPACE:-kube-system}"

helm repo add cilium https://helm.cilium.io
helm repo update

# Gateway crds https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/#prerequisites
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml

# Install cilium using helm with talos recommended options https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium#method-1:-helm-install
helm install cilium cilium/cilium --version 1.18.5 \
   --namespace $CILIUM_NAMESPACE \
   --set ipam.mode=kubernetes \
   --set kubeProxyReplacement=true \
   --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
   --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
   --set cgroup.autoMount.enabled=false \
   --set cgroup.hostRoot=/sys/fs/cgroup \
   --set k8sServiceHost=localhost \
   --set k8sServicePort=7445 \
   --set gatewayAPI.enabled=true \
   --set gatewayAPI.enableAlpn=true \
   --set gatewayAPI.enableAppProtocol=true


kubectl -n $CILIUM_NAMESPACE rollout status ds/cilium
kubectl -n $CILIUM_NAMESPACE rollout status deploy/cilium-operator
kubectl get nodes -o wide
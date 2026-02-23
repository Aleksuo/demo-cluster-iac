#!/usr/bin/env bash
set -euo pipefail

helm repo add argo https://argoproj.github.io/argo-helm
helm dependency build kubernetes/addons/argocd
helm upgrade --install argocd kubernetes/addons/argocd \
  -n argocd \
  --create-namespace

kubectl -n argocd rollout status deploy/argocd-server
kubectl -n argocd get pods

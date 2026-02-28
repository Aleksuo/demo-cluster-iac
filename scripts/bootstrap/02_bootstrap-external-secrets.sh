#!/usr/bin/env bash
set -euo pipefail

kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret -n external-secrets generic infisical-universal-auth \
  --from-literal=clientId="${EXTERNAL_SECRETS_CLIENT_ID}" \
  --from-literal=clientSecret="${EXTERNAL_SECRETS_CLIENT_SECRET}" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

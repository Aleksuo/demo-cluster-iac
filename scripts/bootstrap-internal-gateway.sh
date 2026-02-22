#!/usr/bin/env bash
set -euo pipefail

INTERNAL_GATEWAY_NAMESPACE="${INTERNAL_GATEWAY_NAMESPACE:-internal-gateway}"
INTERNAL_GATEWAY_DOMAIN="${INTERNAL_GATEWAY_DOMAIN:-internal.aleksuo.dev}"
INTERNAL_GATEWAY_TLS_SECRET="${INTERNAL_GATEWAY_TLS_SECRET:-internal-aleksuo-dev-tls}"

kubectl apply -k kubernetes/addons/internal-gateway

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 365 \
  -keyout "${tmpdir}/tls.key" \
  -out "${tmpdir}/tls.crt" \
  -subj "/CN=${INTERNAL_GATEWAY_DOMAIN}" \
  -addext "subjectAltName=DNS:${INTERNAL_GATEWAY_DOMAIN},DNS:*.${INTERNAL_GATEWAY_DOMAIN}"

kubectl -n "${INTERNAL_GATEWAY_NAMESPACE}" create secret tls "${INTERNAL_GATEWAY_TLS_SECRET}" \
  --cert="${tmpdir}/tls.crt" \
  --key="${tmpdir}/tls.key" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

kubectl apply -k kubernetes/addons/hubble

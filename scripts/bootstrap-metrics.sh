#!/usr/bin/env bash
set -euo pipefail

kubectl apply -k kubernetes/addons/kubelet-serving-certificate-approver
kubectl apply -k kubernetes/addons/metrics-server
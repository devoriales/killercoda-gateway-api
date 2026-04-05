#!/bin/bash
# Verify: Gateway API CRDs are installed (check for httproutes CRD)
set -e

if ! kubectl get crd httproutes.gateway.networking.k8s.io &>/dev/null; then
  echo "HTTPRoute CRD not found. Run:"
  echo "  kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml"
  exit 1
fi

if ! kubectl get crd gatewayclasses.gateway.networking.k8s.io &>/dev/null; then
  echo "GatewayClass CRD not found."
  exit 1
fi

if ! kubectl get crd gateways.gateway.networking.k8s.io &>/dev/null; then
  echo "Gateway CRD not found."
  exit 1
fi

echo "Gateway API CRDs installed successfully."
exit 0

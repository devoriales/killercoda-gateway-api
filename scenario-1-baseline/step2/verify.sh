#!/bin/bash
# Verify: ingress-nginx controller pod is Running
set -e

RUNNING=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller \
  --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

if [ "$RUNNING" -lt 1 ]; then
  echo "ingress-nginx controller is not running yet."
  echo "Run: kubectl get pods -n ingress-nginx"
  exit 1
fi

# Also verify IngressClass exists
if ! kubectl get ingressclass nginx &>/dev/null; then
  echo "IngressClass 'nginx' not found."
  exit 1
fi

echo "ingress-nginx controller is running and IngressClass 'nginx' exists."
exit 0

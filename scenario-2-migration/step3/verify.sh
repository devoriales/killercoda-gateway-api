#!/bin/bash
# Verify: GatewayClass is accepted and Gateway is programmed
set -e

# Check GatewayClass accepted
ACCEPTED=$(kubectl get gatewayclass traefik \
  -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

if [ "$ACCEPTED" != "True" ]; then
  echo "GatewayClass 'traefik' is not Accepted yet (got: '$ACCEPTED')."
  echo "Run: kubectl get gatewayclass traefik"
  exit 1
fi

# Check Gateway exists in bookstore namespace
if ! kubectl get gateway bookstore-gateway -n bookstore &>/dev/null; then
  echo "Gateway 'bookstore-gateway' not found in namespace 'bookstore'."
  echo "Run: kubectl apply -f /root/manifests/03-gateway-api/gateway-http.yaml"
  exit 1
fi

# Check Gateway programmed
PROGRAMMED=$(kubectl get gateway bookstore-gateway -n bookstore \
  -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null)

if [ "$PROGRAMMED" != "True" ]; then
  echo "Gateway 'bookstore-gateway' is not Programmed yet (got: '$PROGRAMMED')."
  echo "Run: kubectl describe gateway bookstore-gateway -n bookstore"
  exit 1
fi

echo "GatewayClass accepted and Gateway programmed."
exit 0

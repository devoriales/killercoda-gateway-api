#!/bin/bash
# Verify: canary HTTPRoute exists with two weighted backends
set -e

if ! kubectl get httproute bookstore-canary -n bookstore &>/dev/null; then
  echo "HTTPRoute 'bookstore-canary' not found."
  echo "Run: kubectl apply -f /root/manifests/05-advanced/canary-route.yaml"
  exit 1
fi

BACKENDS=$(kubectl get httproute bookstore-canary -n bookstore \
  -o jsonpath='{.spec.rules[0].backendRefs[*].name}' 2>/dev/null)

if [[ "$BACKENDS" != *"bookstore-v2"* ]]; then
  echo "Canary route does not reference 'bookstore-v2'. Check the manifest."
  exit 1
fi

V2_RUNNING=$(kubectl get pods -n bookstore -l app=bookstore,version=v2 \
  --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

if [ "$V2_RUNNING" -lt 1 ]; then
  echo "No running bookstore-v2 pods. Check: kubectl get pods -n bookstore"
  exit 1
fi

echo "Canary HTTPRoute in place with bookstore-v2 running."
exit 0

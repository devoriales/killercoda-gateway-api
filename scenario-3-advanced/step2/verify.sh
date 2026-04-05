#!/bin/bash
# Verify: header-based route exists and has a headers match rule
set -e

# The header-based route may reuse the bookstore-canary name or use a new one.
# Check either exists with a headers match.
ROUTE_NAME=""
for name in bookstore-header-route bookstore-canary bookstore-route; do
  if kubectl get httproute "$name" -n bookstore &>/dev/null; then
    HEADERS=$(kubectl get httproute "$name" -n bookstore \
      -o jsonpath='{.spec.rules[*].matches[*].headers}' 2>/dev/null)
    if [ -n "$HEADERS" ]; then
      ROUTE_NAME="$name"
      break
    fi
  fi
done

if [ -z "$ROUTE_NAME" ]; then
  echo "No HTTPRoute with a headers match found in namespace 'bookstore'."
  echo "Run: kubectl apply -f /root/tutorial/manifests/04-httproutes/header-based-route.yaml"
  exit 1
fi

echo "Header-based HTTPRoute '$ROUTE_NAME' is in place."
exit 0

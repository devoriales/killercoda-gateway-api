#!/bin/bash
# Verify: Traefik routes bookstore.local traffic correctly via HTTPRoute
set -e

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Host: bookstore.local" \
  http://localhost:30090/health 2>/dev/null)

if [ "$HTTP_CODE" != "200" ]; then
  echo "Expected HTTP 200 from Traefik on port 30090, got: $HTTP_CODE"
  echo "Check: kubectl get httproute -n bookstore"
  echo "Check: kubectl describe httproute bookstore-route -n bookstore"
  exit 1
fi

# Verify the HTTPRoute exists
if ! kubectl get httproute bookstore-route -n bookstore &>/dev/null; then
  echo "HTTPRoute 'bookstore-route' not found in namespace 'bookstore'."
  exit 1
fi

echo "HTTPRoute is routing bookstore.local correctly through Traefik (HTTP $HTTP_CODE)."
exit 0

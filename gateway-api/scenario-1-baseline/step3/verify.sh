#!/bin/bash
# Verify: curl through ingress-nginx returns HTTP 200 for /health
set -e

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Host: bookstore.local" \
  http://localhost:30080/health 2>/dev/null)

if [ "$HTTP_CODE" != "200" ]; then
  echo "Expected HTTP 200 from ingress-nginx on port 30080, got: $HTTP_CODE"
  echo "Check: kubectl get ingress -n bookstore"
  echo "Check: kubectl get pods -n ingress-nginx"
  exit 1
fi

echo "ingress-nginx is routing bookstore.local correctly (HTTP $HTTP_CODE)."
exit 0
